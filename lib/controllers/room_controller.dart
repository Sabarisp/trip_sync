import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:trip_sync/models/room_model.dart';

/// ALGORITHM FIX (see ALGORITHMS.md "Room ID Generation"):
/// The original design generated a 4-digit random code with no uniqueness
/// check — roughly a 1-in-9000 chance of colliding with an existing room,
/// which silently drops a stranger into someone else's trip. This version
/// uses a larger 6-character alphanumeric code (36^6 ≈ 2.1 billion
/// combinations) AND verifies the code doesn't already exist in Firestore
/// before using it, retrying on the rare collision.
class RoomController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I
  static const int _codeLength = 6;
  static const int _maxGenerationAttempts = 5;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rxn<RoomModel> activeRoom = Rxn<RoomModel>();

  String _generateCode() {
    final rand = Random.secure();
    return List.generate(_codeLength, (_) => _chars[rand.nextInt(_chars.length)])
        .join();
  }

  Future<String> _generateUniqueRoomId() async {
    for (var attempt = 0; attempt < _maxGenerationAttempts; attempt++) {
      final code = _generateCode();
      final doc = await _db.collection('rooms').doc(code).get();
      if (!doc.exists) return code;
    }
    // Extremely unlikely fallback: widen with a timestamp suffix.
    return '${_generateCode()}${DateTime.now().millisecondsSinceEpoch % 100}';
  }

  Future<String?> createRoom({
    required String roomName,
    required String createdBy,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final roomId = await _generateUniqueRoomId();
      final room = RoomModel(
        roomId: roomId,
        roomName: roomName.trim(),
        createdBy: createdBy,
        createdAt: DateTime.now(),
        members: [createdBy],
      );
      await _db.collection('rooms').doc(roomId).set(room.toMap());
      return roomId;
    } catch (e) {
      errorMessage.value = 'Could not create the trip. Please try again.';
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> joinRoom({required String roomId, required String userId}) async {
    isLoading.value = true;
    errorMessage.value = '';
    final code = roomId.trim().toUpperCase();
    try {
      final ref = _db.collection('rooms').doc(code);

      // Transaction avoids a race where two people join at once and both
      // read a member list that's about to be stale.
      final joined = await _db.runTransaction<bool>((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) {
          errorMessage.value = 'No trip found with that code';
          return false;
        }
        final room = RoomModel.fromMap(snap.data()!, snap.id);
        if (room.members.contains(userId)) return true;
        if (room.isFull) {
          errorMessage.value = 'This trip is full (max $kMaxRoomMembers members)';
          return false;
        }
        tx.update(ref, {
          'members': FieldValue.arrayUnion([userId]),
        });
        return true;
      });

      return joined;
    } catch (e) {
      errorMessage.value = 'Could not join the trip. Check the code and try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> leaveRoom({required String roomId, required String userId}) async {
    final ref = _db.collection('rooms').doc(roomId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final room = RoomModel.fromMap(snap.data()!, snap.id);

    if (room.members.length <= 1) {
      // Last member leaving — clean up the room and its location subtree.
      await ref.delete();
    } else {
      await ref.update({
        'members': FieldValue.arrayRemove([userId]),
      });
    }
    await _db
        .collection('locations')
        .doc(roomId)
        .collection('members')
        .doc(userId)
        .delete();
  }

  Future<void> setDestination({
    required String roomId,
    required GeoPoint point,
    String? name,
  }) async {
    await _db.collection('rooms').doc(roomId).update({
      'destination': point,
      'destinationName': name,
    });
  }

  Stream<RoomModel?> watchRoom(String roomId) {
    return _db.collection('rooms').doc(roomId).snapshots().map((snap) {
      if (!snap.exists) return null;
      final room = RoomModel.fromMap(snap.data()!, snap.id);
      activeRoom.value = room;
      return room;
    });
  }
}
