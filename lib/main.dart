import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:trip_sync/controllers/auth_controller.dart';
import 'package:trip_sync/services/notification_service.dart';
import 'package:trip_sync/theme/app_theme.dart';
import 'package:trip_sync/views/login_view.dart';
import 'package:trip_sync/views/room_options_view.dart';

// NOTE: If you've run `flutterfire configure`, it generates
// lib/firebase_options.dart with the real project keys. Import it here and
// pass `options: DefaultFirebaseOptions.currentPlatform` to
// Firebase.initializeApp() below. Without it, Firebase falls back to the
// native config files (google-services.json / GoogleService-Info.plist),
// which also works fine for Android/iOS.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().init();
  runApp(const TripSyncApp());
}

class TripSyncApp extends StatelessWidget {
  const TripSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Trip Sync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AuthGate(),
    );
  }
}

/// Routes to the map/room flow if already logged in, otherwise to login.
/// Reacts live to auth state changes (e.g. token expiry, manual sign-out
/// from another device).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.put(AuthController());
    return Obx(() {
      final user = auth.firebaseUser.value;
      if (user == null) return const LoginView();
      return const RoomOptionsView();
    });
  }
}
