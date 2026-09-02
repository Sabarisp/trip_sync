import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trip_sync/controllers/auth_controller.dart';
import 'package:trip_sync/controllers/map_controller.dart';
import 'package:trip_sync/controllers/room_controller.dart';
import 'package:trip_sync/models/room_model.dart';
import 'package:trip_sync/services/location_service.dart';
import 'package:trip_sync/theme/app_theme.dart';
import 'package:trip_sync/views/room_options_view.dart';
import 'package:trip_sync/widgets/member_avatar.dart';

class MapView extends StatefulWidget {
  final String roomId;
  const MapView({super.key, required this.roomId});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapControllerX _map = Get.put(MapControllerX());
  final RoomController _roomController = Get.put(RoomController());
  final fm.MapController _flutterMap = fm.MapController();

  RoomModel? _room;

  @override
  void initState() {
    super.initState();
    final uid = Get.find<AuthController>().uid;
    if (uid != null) {
      _map.start(roomId: widget.roomId, selfId: uid);
    }
    _roomController.watchRoom(widget.roomId).listen((room) {
      if (!mounted) return;
      setState(() => _room = room);
      if (room?.destination != null) {
        _map.setDestination(room!.destination!);
      }
    });
  }

  @override
  void dispose() {
    _map.stop();
    super.dispose();
  }

  Future<void> _onLongPress(LatLng point) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Set as destination?'),
        content: const Text('Everyone in this trip will see this pin and their route to it.'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Get.back(result: true), child: const Text('Set pin')),
        ],
      ),
    );
    if (confirmed == true) {
      await _roomController.setDestination(
        roomId: widget.roomId,
        point: GeoPoint(point.latitude, point.longitude),
      );
    }
  }

  void _shareCode() {
    Clipboard.setData(ClipboardData(text: widget.roomId));
    Get.snackbar('Copied', 'Trip code copied — send it to your group',
        backgroundColor: AppColors.surfaceElevated, colorText: AppColors.textPrimary);
  }

  void _openMembersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _MembersSheet(map: _map, room: _room),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Obx(() {
            final members = _map.members.values.toList();
            final dest = _map.destination.value;

            final markers = <fm.Marker>[
              for (final m in members)
                if (m.currentLocation != null)
                  fm.Marker(
                    point: LatLng(m.currentLocation!.latitude, m.currentLocation!.longitude),
                    width: 42,
                    height: 42,
                    child: MemberAvatar(
                      userId: m.userId,
                      displayName: m.displayName,
                      isOnline: m.isOnline(LocationService.staleThreshold),
                      size: 38,
                    ),
                  ),
              if (dest != null)
                fm.Marker(
                  point: LatLng(dest.latitude, dest.longitude),
                  width: 44,
                  height: 44,
                  child: const Icon(Icons.location_on, color: AppColors.danger, size: 44),
                ),
            ];

            final polylines = <fm.Polyline>[
              for (final entry in _map.routesToDestination.entries)
                fm.Polyline(
                  points: entry.value.route.points,
                  strokeWidth: 4,
                  color: AppColors.colorForUser(entry.key).withOpacity(0.8),
                ),
            ];

            final initialCenter = markers.isNotEmpty
                ? markers.first.point
                : const LatLng(20.5937, 78.9629); // fallback: India centroid

            return fm.FlutterMap(
              mapController: _flutterMap,
              options: fm.MapOptions(
                initialCenter: initialCenter,
                initialZoom: 14,
                onLongPress: (_, point) => _onLongPress(point),
              ),
              children: [
                fm.TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.tripsync.app',
                ),
                fm.PolylineLayer(polylines: polylines),
                fm.MarkerLayer(markers: markers),
              ],
            );
          }),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Get.offAll(() => const RoomOptionsView()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _shareCode,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _room?.roomName ?? 'Loading trip…',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(widget.roomId,
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2)),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy, size: 14, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _RoundIconButton(icon: Icons.groups, onTap: _openMembersSheet),
                ],
              ),
            ),
          ),

          // Offline banner
          Obx(() {
            if (!_map.isOffline.value) return const SizedBox.shrink();
            return Positioned(
              top: 88,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off, color: AppColors.warning, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'One or more members haven\'t updated their location recently',
                          style: TextStyle(color: AppColors.warning, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Bottom "my status" card
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Obx(() {
              final uid = Get.find<AuthController>().uid;
              final myEta = uid != null ? _map.etaFor(uid) : null;
              final myDist = uid != null ? _map.distanceToDestinationMeters(uid) : null;
              final tracking = _map.isTracking.value;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(
                      tracking ? Icons.my_location : Icons.location_disabled,
                      color: tracking ? AppColors.success : AppColors.danger,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tracking ? 'Sharing your live location' : 'Location sharing off',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (myDist != null)
                            Text(
                              '${(myDist / 1000).toStringAsFixed(1)} km to destination'
                              '${myEta != null ? ' · ETA ${_formatDuration(myEta)}' : ''}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12.5),
                            )
                          else
                            const Text('Long-press the map to set a destination',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes}m';
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withOpacity(0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

class _MembersSheet extends StatelessWidget {
  final MapControllerX map;
  final RoomModel? room;
  const _MembersSheet({required this.map, required this.room});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Obx(() {
          final members = map.members.values.toList();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${members.length} / $kMaxRoomMembers travelers',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              ...members.map((m) {
                final dist = map.distanceToDestinationMeters(m.userId);
                final eta = map.etaFor(m.userId);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      MemberAvatar(
                        userId: m.userId,
                        displayName: m.displayName,
                        isOnline: m.isOnline(LocationService.staleThreshold),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.displayName.isNotEmpty ? m.displayName : 'Member',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            if (dist != null)
                              Text(
                                '${(dist / 1000).toStringAsFixed(1)} km'
                                '${eta != null ? ' · ${eta.inMinutes}m' : ''}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary, fontSize: 12.5),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        }),
      ),
    );
  }
}
