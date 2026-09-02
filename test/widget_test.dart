// Basic smoke test for Trip Sync.
//
// The default `flutter create` template generates a counter-app test that
// references a `MyApp` widget — this project's root widget is
// `TripSyncApp` (see lib/main.dart), so that default test fails to compile.
// This replaces it with a minimal smoke test appropriate for an app that
// needs Firebase initialized before it can render its real UI.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_sync/theme/app_theme.dart';

void main() {
  testWidgets('App theme applies without throwing', (WidgetTester tester) async {
    // We don't pump TripSyncApp directly here because it calls
    // Firebase.initializeApp() in main(), which needs platform channels
    // that aren't available in a plain widget test. Instead this verifies
    // the theme/colors used throughout the app build correctly on their
    // own, which is enough to catch a broken AppTheme.dark getter.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Center(child: Text('Trip Sync')),
        ),
      ),
    );

    expect(find.text('Trip Sync'), findsOneWidget);
  });
}
