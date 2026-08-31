# Module Description

## Overview
Trip Sync is a real-time location tracking and group coordination application built with Flutter. The application enables users to create or join trip rooms, share their live locations with group members, view routes between participants, and coordinate group travel activities.

---

## Architecture Pattern
The application follows the **MVC (Model-View-Controller)** architecture pattern with **GetX** for state management and dependency injection.

```
lib/
├── controllers/     # Business logic and state management
├── models/          # Data models
├── services/        # External services and utilities
└── views/           # UI components
```

---

## Module Breakdown

### 1. Authentication Module

#### Components
- **[auth_controller.dart](file:///e:/trip_sync/lib/controllers/auth_controller.dart)** - Authentication state management
- **[login_view.dart](file:///e:/trip_sync/lib/views/login_view.dart)** - Login interface
- **[signup_view.dart](file:///e:/trip_sync/lib/views/signup_view.dart)** - User registration interface

#### Functionality
- **User Registration**: Email and password-based account creation
- **User Login**: Secure authentication via Firebase Auth
- **Session Management**: Persistent login state across app restarts
- **Auto-redirect**: Automatic navigation based on authentication status
- **Logout**: Secure session termination

#### Technologies
- Firebase Authentication v5.3.1
- GetX state management
- Email/password authentication provider

#### Key Features
- Real-time authentication state monitoring
- Error handling and validation
- Secure credential storage
- Automatic session restoration

---

### 2. Room Management Module

#### Components
- **[room_controller.dart](file:///e:/trip_sync/lib/controllers/room_controller.dart)** - Room state and operations
- **[room_model.dart](file:///e:/trip_sync/lib/models/room_model.dart)** - Room data structure
- **[create_room_view.dart](file:///e:/trip_sync/lib/views/create_room_view.dart)** - Room creation interface
- **[join_room_view.dart](file:///e:/trip_sync/lib/views/join_room_view.dart)** - Room joining interface
- **[room_options_view.dart](file:///e:/trip_sync/lib/views/room_options_view.dart)** - Room selection interface

#### Functionality
- **Room Creation**: Generate unique room IDs using UUID
- **Room Joining**: Join existing rooms via room ID
- **Member Management**: Track and display all room participants
- **Room Persistence**: Store room data in Cloud Firestore
- **Real-time Sync**: Live updates of room members and status
- **Destination Pinning**: Set and share trip destination on map
- **Route Display**: Show routes from all members to destination

#### Technologies
- Cloud Firestore v5.4.4
- UUID v4.5.1 for unique room IDs
- GetX reactive state management

#### Data Model
```dart
Room {
  String roomId
  String roomName
  String createdBy
  DateTime createdAt
  List<String> members
  LatLng? destination
}
```

#### Key Features
- Unique room ID generation
- Real-time member list updates
- Room data validation
- Automatic member addition on join
- Destination coordinate storage

---

### 3. Location Tracking Module

#### Components
- **[location_service.dart](file:///e:/trip_sync/lib/services/location_service.dart)** - Location operations
- **[map_controller.dart](file:///e:/trip_sync/lib/controllers/map_controller.dart)** - Map state management

#### Functionality
- **GPS Tracking**: Continuous location monitoring
- **Background Tracking**: Location updates when app is in background
- **Permission Handling**: Request and manage location permissions
- **Location Accuracy**: High-precision GPS coordinates
- **Distance Calculation**: Calculate distances between users
- **Position Streaming**: Real-time location updates
- **Firestore Sync**: Upload location data to cloud database

#### Technologies
- Geolocator v13.0.1
- Permission Handler v11.3.1
- Flutter Background Service v5.0.10
- Cloud Firestore for location storage

#### Key Features
- Real-time GPS coordinate capture
- Automatic permission requests
- Background location service
- Location accuracy settings
- Distance calculations between coordinates
- Continuous location stream

---

### 4. Map Visualization Module

#### Components
- **[map_view.dart](file:///e:/trip_sync/lib/views/map_view.dart)** - Interactive map interface
- **[map_controller.dart](file:///e:/trip_sync/lib/controllers/map_controller.dart)** - Map logic and state

#### Functionality
- **Interactive Map**: Pan, zoom, and navigate map interface
- **User Markers**: Display all room members on map
- **Live Updates**: Real-time position updates for all users
- **Route Rendering**: Display navigation routes between users
- **Destination Marker**: Show pinned trip destination
- **Distance Display**: Show distance from user to destination
- **Map Layers**: OpenStreetMap tile rendering
- **Custom Markers**: Differentiate between users with custom icons

#### Technologies
- flutter_map v7.0.2
- latlong2 v0.9.1
- OpenStreetMap tiles
- HTTP v1.2.2 for tile loading

#### Key Features
- Real-time marker position updates
- Polyline route rendering
- Custom marker icons
- Map gesture controls
- Zoom level management
- Center on user location
- Multi-user visualization

---

### 5. Notification Module

#### Components
- **[notification_service.dart](file:///e:/trip_sync/lib/services/notification_service.dart)** - Notification management

#### Functionality
- **Push Notifications**: Receive Firebase Cloud Messages
- **Local Notifications**: Display in-app notifications
- **Background Notifications**: Receive notifications when app is closed
- **Notification Channels**: Organize notifications by type
- **Custom Actions**: Handle notification tap events
- **Scheduled Notifications**: Time-based notification delivery

#### Technologies
- Firebase Cloud Messaging v15.1.3
- Flutter Local Notifications v18.0.0

#### Key Features
- Real-time push notification delivery
- Custom notification sounds and icons
- Notification permission handling
- Background message handling
- Notification action callbacks

---

### 6. Network Connectivity Module

#### Functionality
- **Connection Monitoring**: Track network status
- **Offline Detection**: Detect loss of connectivity
- **Auto-reconnect**: Resume services when connection restored
- **Connection Type**: Identify Wi-Fi vs mobile data

#### Technologies
- connectivity_plus v6.1.0

#### Key Features
- Real-time connectivity status
- Connection type detection
- Stream-based connectivity updates
- Offline mode handling

---

### 7. User Management Module

#### Components
- **[user_model.dart](file:///e:/trip_sync/lib/models/user_model.dart)** - User data structure

#### Functionality
- **User Profiles**: Store user information
- **User Location**: Track user's current position
- **User Status**: Online/offline status tracking
- **User Identification**: Unique user IDs via Firebase Auth

#### Data Model
```dart
User {
  String userId
  String email
  String displayName
  LatLng? currentLocation
  DateTime lastUpdated
  bool isOnline
}
```

#### Technologies
- Cloud Firestore for user data storage
- Firebase Auth for user identification

---

## Data Flow

### 1. Authentication Flow
```
User Input → AuthController → Firebase Auth → Session Storage → Auto Navigation
```

### 2. Room Creation Flow
```
User Input → RoomController → Generate UUID → Firestore (rooms collection) → Navigate to Map
```

### 3. Location Tracking Flow
```
GPS Sensor → LocationService → MapController → Firestore (user locations) → Real-time Sync
```

### 4. Map Update Flow
```
Firestore Stream → MapController → Map Widget → Render Markers/Routes
```

---

## Database Structure

### Firestore Collections

#### `users` Collection
```
users/{userId}
  ├── email: String
  ├── displayName: String
  ├── currentLocation: GeoPoint
  ├── lastUpdated: Timestamp
  └── isOnline: Boolean
```

#### `rooms` Collection
```
rooms/{roomId}
  ├── roomName: String
  ├── createdBy: String
  ├── createdAt: Timestamp
  ├── members: Array<String>
  └── destination: GeoPoint
```

#### `locations` Collection (Real-time tracking)
```
locations/{roomId}/members/{userId}
  ├── latitude: Number
  ├── longitude: Number
  ├── timestamp: Timestamp
  └── accuracy: Number
```

---

## Security & Privacy

### Firebase Security Rules
- Users can only read/write their own location data
- Room members can only access their room's data
- Authentication required for all database operations

### Data Privacy
- Location data encrypted in transit (HTTPS)
- No location data stored permanently
- Users control when location sharing starts/stops
- Room data deleted when all members leave

---

## Performance Optimizations

1. **Efficient Location Updates**: Throttled updates to reduce battery consumption
2. **Lazy Loading**: Map tiles loaded on-demand
3. **State Management**: GetX reactive programming for minimal rebuilds
4. **Background Service**: Optimized for battery efficiency
5. **Network Optimization**: Compressed data transmission to Firestore

---

## Future Enhancements

1. **Chat Module**: In-room messaging between members
2. **Offline Maps**: Cached map tiles for offline use
3. **Route Planning**: Multi-stop route optimization
4. **ETA Calculation**: Estimated arrival time for members
5. **Geofencing**: Alerts when members enter/exit areas
6. **History**: Trip history and analytics
