import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Handles all direct interaction with device GPS + permissions.
///
/// ALGORITHM FIX (see ALGORITHMS.md "GPS Tracking"):
/// The original design polled location on a `Timer.periodic(2s)`, which
/// queries the GPS chip and writes to Firestore every 2 seconds *regardless
/// of whether the user moved*. That drains battery and multiplies Firestore
/// writes for no benefit while someone is sitting still.
///
/// Instead, this uses `Geolocator.getPositionStream` with a `distanceFilter`,
/// so the OS only emits a new position once the device has physically moved
/// past the threshold. A separate, much slower heartbeat (see
/// [heartbeatInterval]) keeps "last seen" timestamps fresh even when
/// stationary, so offline-detection still works correctly.
class LocationService {
  static const int distanceFilterMeters = 8;
  static const Duration heartbeatInterval = Duration(seconds: 20);

  /// A user is considered offline once their last update is older than this.
  /// Kept larger than [heartbeatInterval] with margin, so a single missed
  /// beat doesn't flip someone's status — avoids the "flapping" bug in the
  /// original fixed-20s-no-hysteresis design.
  static const Duration staleThreshold = Duration(seconds: 45);

  StreamSubscription<Position>? _positionSub;
  Timer? _heartbeatTimer;

  Future<bool> ensurePermissions() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  Future<Position?> currentPosition() async {
    final ok = await ensurePermissions();
    if (!ok) return null;
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Starts streaming positions. [onPosition] fires on real movement;
  /// [onHeartbeat] fires on a fixed interval regardless of movement, so
  /// callers can refresh "last seen" without re-querying GPS.
  Future<bool> startTracking({
    required void Function(Position) onPosition,
    required void Function() onHeartbeat,
  }) async {
    final ok = await ensurePermissions();
    if (!ok) return false;

    await stopTracking();

    final settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilterMeters,
    );

    _positionSub =
        Geolocator.getPositionStream(locationSettings: settings).listen(onPosition);

    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) => onHeartbeat());

    return true;
  }

  Future<void> stopTracking() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  void dispose() {
    _positionSub?.cancel();
    _heartbeatTimer?.cancel();
  }
}
