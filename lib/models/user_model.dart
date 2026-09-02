import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String email;
  final String displayName;
  final GeoPoint? currentLocation;
  final DateTime lastUpdated;
  final double? heading; // degrees, for directional marker rotation
  final double? speed; // m/s, used for ETA estimation

  UserModel({
    required this.userId,
    required this.email,
    required this.displayName,
    this.currentLocation,
    required this.lastUpdated,
    this.heading,
    this.speed,
  });

  /// A user counts as "online" if we've heard from them recently.
  /// Uses a threshold (see LocationService.staleThreshold) rather than
  /// a stored boolean, so there's a single source of truth for liveness
  /// and no separate flag that can drift out of sync with reality.
  bool isOnline(Duration staleThreshold) {
    return DateTime.now().difference(lastUpdated) < staleThreshold;
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      userId: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 'Traveler',
      currentLocation: map['currentLocation'] as GeoPoint?,
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      heading: (map['heading'] as num?)?.toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      if (currentLocation != null) 'currentLocation': currentLocation,
      'lastUpdated': FieldValue.serverTimestamp(),
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
    };
  }
}
