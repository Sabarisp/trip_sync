# Trip Sync

A real-time location tracking and group coordination application built with Flutter. Trip Sync enables users to create or join trip rooms, share their live locations with group members, view routes between participants, and coordinate group travel activities.

## Features

- 🔐 **User Authentication** - Secure email/password authentication via Firebase
- 🗺️ **Interactive Maps** - Real-time map visualization with OpenStreetMap
- 📍 **Live Location Tracking** - Continuous GPS tracking with background service support
- 👥 **Group Rooms** - Create or join trip rooms with unique room IDs
- 🚗 **Route Display** - View navigation routes between group members
- 📌 **Destination Pinning** - Set and share trip destinations on the map
- 📏 **Distance Calculation** - Real-time distance tracking between users
- 🔔 **Push Notifications** - Stay updated with Firebase Cloud Messaging
- 🌐 **Offline Detection** - Network connectivity monitoring

## Documentation

- **[Hardware & Software Requirements](REQUIREMENTS.md)** - Detailed system requirements, dependencies, and platform support
- **[Module Description](MODULE_DESCRIPTION.md)** - Comprehensive module breakdown, architecture, and data flow
- **[Algorithms Used](ALGORITHMS.md)** - Detailed explanation of algorithms including routing, location tracking, and distance calculation

## Getting Started

### Prerequisites

- Flutter SDK 3.9.2 or higher
- Dart SDK 3.9.2 or higher
- Android Studio / VS Code with Flutter extensions
- Firebase project configured

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd trip_sync
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - Add your `google-services.json` (Android) to `android/app/`
   - Add your `GoogleService-Info.plist` (iOS) to `ios/Runner/`

4. Run the application:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── controllers/          # Business logic and state management
│   ├── auth_controller.dart
│   ├── map_controller.dart
│   └── room_controller.dart
├── models/              # Data models
│   ├── room_model.dart
│   └── user_model.dart
├── services/            # External services
│   ├── location_service.dart
│   └── notification_service.dart
├── views/               # UI components
│   ├── create_room_view.dart
│   ├── join_room_view.dart
│   ├── login_view.dart
│   ├── map_view.dart
│   ├── room_options_view.dart
│   └── signup_view.dart
└── main.dart           # Application entry point
```

## Technologies Used

- **Flutter** - Cross-platform UI framework
- **Firebase** - Backend services (Auth, Firestore, Cloud Messaging)
- **GetX** - State management and dependency injection
- **flutter_map** - Interactive map rendering
- **Geolocator** - GPS location tracking
- **OpenStreetMap** - Map tile provider

## License

This project is licensed under the MIT License.

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [GetX Documentation](https://pub.dev/packages/get)
