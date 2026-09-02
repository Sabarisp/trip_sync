class Validators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\-\.]+$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Must be at least 6 characters';
    return null;
  }

  static String? displayName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name is too short';
    return null;
  }

  static String? roomName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Trip name is required';
    return null;
  }

  /// Room codes are 6 alphanumeric chars (see RoomController._generateRoomId).
  static String? roomCode(String? value) {
    if (value == null || value.trim().isEmpty) return 'Room code is required';
    final code = value.trim().toUpperCase();
    if (code.length != 6) return 'Room codes are 6 characters';
    return null;
  }
}
