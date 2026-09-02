import 'package:cloud_firestore/cloud_firestore.dart';

/// Rooms are capped in size. This isn't arbitrary — it directly bounds the
/// mesh route calculation (member-to-member + member-to-destination), which
/// is O(n) route calls per refresh in this app's design. See ALGORITHMS.md
/// "Route Generation" section for the reasoning.
const int kMaxRoomMembers = 10;

class RoomModel {
  final String roomId;
  final String roomName;
  final String createdBy;
  final DateTime createdAt;
  final List<String> members;
  final GeoPoint? destination;
  final String? destinationName;

  RoomModel({
    required this.roomId,
    required this.roomName,
    required this.createdBy,
    required this.createdAt,
    required this.members,
    this.destination,
    this.destinationName,
  });

  bool get isFull => members.length >= kMaxRoomMembers;

  factory RoomModel.fromMap(Map<String, dynamic> map, String id) {
    return RoomModel(
      roomId: id,
      roomName: map['roomName'] ?? 'Untitled trip',
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      members: List<String>.from(map['members'] ?? const []),
      destination: map['destination'] as GeoPoint?,
      destinationName: map['destinationName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomName': roomName,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'members': members,
      if (destination != null) 'destination': destination,
      if (destinationName != null) 'destinationName': destinationName,
    };
  }
}
