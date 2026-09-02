import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:trip_sync/models/user_model.dart';
import 'package:trip_sync/services/location_service.dart';
import 'package:trip_sync/services/route_service.dart';

class MemberRoute {
  final RouteResult route;
  final LatLng calculatedFrom;
  MemberRoute({required this.route, required this.calculatedFrom});
}

/// ALGORITHM FIX (see ALGORITHMS.md "Route Generation"):
/// The original design recalculated a route for every member-pair on a
/// fixed 5s timer — O(n²) routing calls per tick, which the doc itself
/// flags as not scaling past ~10 users, plus it re-fetches even when
/// nobody moved.
///
/// This version instead computes one route per member *to the shared
/// destination* (O(n), matching what's actually shown on screen — a
/// hub-and-spoke layout, not a full mesh), and only re-fetches a member's
/// route once they've moved more than [_routeRecalcThresholdMeters] since
/// the last fetch. That turns "N² calls every 5s regardless of movement"
/// into "at most N calls, only when something actually changed".
class MapControllerX extends GetxController {
  final LocationService _locationService = LocationService();
  final RouteService _routeService = RouteService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const double _routeRecalcThresholdMeters = 40;
  static const Distance _distanceCalc = Distance();

  String? _roomId;
  String? _selfId;

  final RxMap<String, UserModel> members = <String, UserModel>{}.obs;
  final RxMap<String, MemberRoute> routesToDestination = <String, MemberRoute>{}.obs;
  final Rxn<GeoPoint> destination = Rxn<GeoPoint>();
  final RxBool isTracking = false.obs;
  final RxBool isOffline = false.obs;

  StreamSubscription? _membersSub;
  Timer? _livenessTimer;
  final Set<String> _notifiedOffline = {};

  Future<void> start({required String roomId, required String selfId}) async {
    _roomId = roomId;
    _selfId = selfId;

    final started = await _locationService.startTracking(
      onPosition: _handlePosition,
      onHeartbeat: _handleHeartbeat,
    );
    isTracking.value = started;

    _membersSub = _db
        .collection('locations')
        .doc(roomId)
        .collection('members')
        .snapshots()
        .listen(_handleMembersSnapshot);

    // Liveness/offline check runs independently of Firestore snapshot
    // events, on its own slow timer — this is the fix for the original
    // "flaps offline/online" bug, since it evaluates staleness on a
    // steady cadence instead of reacting to every incoming update.
    _livenessTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _evaluateLiveness();
    });
  }

  Future<void> _handlePosition(Position pos) async {
    if (_roomId == null || _selfId == null) return;
    await _uploadPosition(pos);
    _maybeRecalcOwnRoute(LatLng(pos.latitude, pos.longitude));
  }

  Future<void> _handleHeartbeat() async {
    if (_roomId == null || _selfId == null) return;
    // Heartbeat just refreshes lastUpdated without a fresh GPS read —
    // keeps "last seen" accurate for stationary users without extra
    // battery cost.
    await _db
        .collection('locations')
        .doc(_roomId)
        .collection('members')
        .doc(_selfId)
        .update({'lastUpdated': FieldValue.serverTimestamp()}).catchError((_) {});
  }

  Future<void> _uploadPosition(Position pos) async {
    await _db
        .collection('locations')
        .doc(_roomId)
        .collection('members')
        .doc(_selfId)
        .set({
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'heading': pos.heading,
      'speed': pos.speed,
      'timestamp': FieldValue.serverTimestamp(),
      'accuracy': pos.accuracy,
    }, SetOptions(merge: true));

    await _db.collection('users').doc(_selfId).update({
      'currentLocation': GeoPoint(pos.latitude, pos.longitude),
      'lastUpdated': FieldValue.serverTimestamp(),
      'heading': pos.heading,
      'speed': pos.speed,
    }).catchError((_) {});
  }

  void _handleMembersSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    for (final doc in snap.docs) {
      final data = doc.data();
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      final existing = members[doc.id];
      members[doc.id] = UserModel(
        userId: doc.id,
        email: existing?.email ?? '',
        displayName: existing?.displayName ?? 'Member',
        currentLocation: GeoPoint(lat, lng),
        lastUpdated: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        heading: (data['heading'] as num?)?.toDouble(),
        speed: (data['speed'] as num?)?.toDouble(),
      );

      if (destination.value != null) {
        _maybeRecalcRouteFor(doc.id, LatLng(lat, lng));
      }
    }
    members.refresh();
  }

  void setDestination(GeoPoint point) {
    destination.value = point;
    routesToDestination.clear(); // force fresh routes for the new destination
    for (final m in members.values) {
      final loc = m.currentLocation;
      if (loc != null) {
        _maybeRecalcRouteFor(m.userId, LatLng(loc.latitude, loc.longitude), force: true);
      }
    }
  }

  Future<void> _maybeRecalcOwnRoute(LatLng pos) async {
    if (destination.value == null || _selfId == null) return;
    await _maybeRecalcRouteFor(_selfId!, pos);
  }

  Future<void> _maybeRecalcRouteFor(String userId, LatLng pos, {bool force = false}) async {
    final dest = destination.value;
    if (dest == null) return;

    final existing = routesToDestination[userId];
    if (!force && existing != null) {
      final moved = _distanceCalc.as(LengthUnit.Meter, existing.calculatedFrom, pos);
      if (moved < _routeRecalcThresholdMeters) return; // nothing meaningful changed
    }

    final destLatLng = LatLng(dest.latitude, dest.longitude);
    final route = await _routeService.getRoute(pos, destLatLng);
    routesToDestination[userId] = MemberRoute(route: route, calculatedFrom: pos);
    routesToDestination.refresh();
  }

  void _evaluateLiveness() {
    final now = DateTime.now();
    bool anyOffline = false;
    for (final m in members.values) {
      final stale = now.difference(m.lastUpdated) > LocationService.staleThreshold;
      if (stale) {
        anyOffline = true;
        _notifiedOffline.add(m.userId); // transition tracked for future notif hooks
      } else {
        _notifiedOffline.remove(m.userId);
      }
    }
    isOffline.value = anyOffline;
  }

  /// Simple ETA: remaining distance over the member's current speed, with a
  /// sane fallback when they're stationary or speed data is missing.
  Duration? etaFor(String userId) {
    final route = routesToDestination[userId];
    final member = members[userId];
    if (route == null) return null;

    final speed = member?.speed ?? 0;
    final effectiveSpeed = speed > 0.5 ? speed : 11.0; // fallback ~40km/h
    final seconds = route.route.distanceMeters / effectiveSpeed;
    return Duration(seconds: seconds.round());
  }

  double? distanceToDestinationMeters(String userId) {
    return routesToDestination[userId]?.route.distanceMeters;
  }

  Future<void> stop() async {
    await _locationService.stopTracking();
    await _membersSub?.cancel();
    _livenessTimer?.cancel();
    isTracking.value = false;
  }

  @override
  void onClose() {
    stop();
    super.onClose();
  }
}
