import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Rxn<User> firebaseUser = Rxn<User>();
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
  }

  bool get isLoggedIn => _auth.currentUser != null;
  String? get uid => _auth.currentUser?.uid;

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    errorMessage.value = '';
    isLoading.value = true;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user?.updateDisplayName(displayName.trim());

      await _db.collection('users').doc(cred.user!.uid).set({
        'email': email.trim(),
        'displayName': displayName.trim(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _friendlyError(e.code);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    errorMessage.value = '';
    isLoading.value = true;
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _friendlyError(e.code);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with that email';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password';
      case 'email-already-in-use':
        return 'An account already exists with that email';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'That email address looks invalid';
      case 'network-request-failed':
        return 'Network error — check your connection';
      default:
        return 'Something went wrong. Please try again';
    }
  }
}
