# Algorithms Used in Trip Sync

This document describes the key algorithms and computational techniques implemented in the Trip Sync application.

---

## Table of Contents

1. [Room ID Generation Algorithm](#1-room-id-generation-algorithm)
2. [GPS Location Tracking Algorithm](#2-gps-location-tracking-algorithm)
3. [Route Calculation Algorithm](#3-route-calculation-algorithm)
4. [Distance Calculation Algorithm](#4-distance-calculation-algorithm)
5. [User Status Detection Algorithm](#5-user-status-detection-algorithm)
6. [Real-time Data Synchronization](#6-real-time-data-synchronization)
7. [Mesh Route Generation Algorithm](#7-mesh-route-generation-algorithm)
8. [Notification Management Algorithm](#8-notification-management-algorithm)

---

## 1. Room ID Generation Algorithm

### Purpose
Generate unique 4-digit room IDs for trip coordination groups.

### Algorithm Type
**Pseudo-Random Number Generation (PRNG)**

### Implementation
Located in: [`room_controller.dart`](file:///e:/trip_sync/lib/controllers/room_controller.dart#L16-L19)

```dart
String generateRoomId() {
  var r = Random();
  return (1000 + r.nextInt(9000)).toString();
}
```

### Steps
1. Initialize Dart's `Random()` class
2. Generate random integer in range [0, 8999]
3. Add 1000 to shift range to [1000, 9999]
4. Convert to string for easy sharing

### Characteristics
- **Output Range**: 1000-9999 (4-digit codes)
- **Collision Probability**: 1/9000 for each new room
- **Time Complexity**: O(1)
- **Space Complexity**: O(1)

### Trade-offs
- **Pros**: Easy to remember and share verbally
- **Cons**: Limited namespace (9000 possible IDs), potential collisions
- **Improvement**: Could implement collision detection with Firestore query before assignment

---

## 2. GPS Location Tracking Algorithm

### Purpose
Continuously capture and update user's geographic coordinates in real-time.

### Algorithm Type
**Periodic Polling with Background Service**

### Implementation
Located in: [`location_service.dart`](file:///e:/trip_sync/lib/services/location_service.dart#L54-L82)

```dart
Timer.periodic(const Duration(seconds: 2), (timer) async {
  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
  
  await FirebaseFirestore.instance.collection('users').doc(userId).set({
    'location': GeoPoint(position.latitude, position.longitude),
    'lastActive': DateTime.now().toIso8601String(),
  }, SetOptions(merge: true));
});
```

### Steps
1. **Initialization**: Start background service with foreground notification
2. **Periodic Execution**: Timer triggers every 2 seconds
3. **GPS Query**: Request current position from device GPS sensor
4. **Accuracy Setting**: Use `LocationAccuracy.high` for precise coordinates
5. **Data Upload**: Write coordinates to Firestore with timestamp
6. **Merge Strategy**: Use `SetOptions(merge: true)` to preserve other user data

### Parameters
- **Update Frequency**: 2 seconds
- **Accuracy**: High (typically ±5-10 meters)
- **Service Type**: Foreground service (Android) for persistent tracking

### Optimization Techniques
1. **Battery Efficiency**: 2-second interval balances accuracy vs battery drain
2. **Background Execution**: Uses Flutter Background Service for continuous operation
3. **Error Handling**: Try-catch blocks prevent service crashes
4. **Merge Updates**: Only updates location fields, preserves other user data

### Time Complexity
- **Per Update**: O(1) - constant time GPS read and Firestore write
- **Overall**: Continuous operation with fixed interval

---

## 3. Route Calculation Algorithm

### Purpose
Calculate optimal navigation paths between two geographic coordinates.

### Algorithm Type
**Multi-Source Routing with Fallback Strategy**

### Implementation
Located in: [`map_controller.dart`](file:///e:/trip_sync/lib/controllers/map_controller.dart#L181-L212)

### Routing Services Hierarchy

```
1. MapTiler Bicycle API (Primary)
   ↓ (if fails)
2. MapTiler Driving API (Secondary)
   ↓ (if fails)
3. OSRM Public API (Tertiary)
   ↓ (if fails)
4. Straight Line (Ultimate Fallback)
```

### Algorithm Steps

#### Step 1: API Request Construction
```dart
String urlString = '$baseUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson&overview=full';
```

**Parameters**:
- `geometries=geojson`: Request GeoJSON format for route geometry
- `overview=full`: Get complete route with all waypoints

#### Step 2: HTTP Request
```dart
final response = await http.get(url);
```

#### Step 3: Response Parsing
```dart
if (response.statusCode == 200) {
  final data = json.decode(response.body);
  final geometry = data['routes'][0]['geometry'];
  List<dynamic> coords = geometry['coordinates'];
  return coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
}
```

#### Step 4: Coordinate Transformation
- **Input Format**: GeoJSON coordinates `[longitude, latitude]`
- **Output Format**: `LatLng(latitude, longitude)`
- **Transformation**: Swap indices and convert to double

### Fallback Strategy

```dart
Future<List<LatLng>> fetchRoute(LatLng start, LatLng end) async {
  // Try MapTiler Bicycle
  List<LatLng>? route = await _requestRoute('...bicycle', start, end, apiKey: mapTilerKey);
  if (route != null) return route;
  
  // Try MapTiler Driving
  route = await _requestRoute('...driving', start, end, apiKey: mapTilerKey);
  if (route != null) return route;
  
  // Try OSRM Public
  route = await _requestRoute('...osrm.../driving', start, end, apiKey: null);
  if (route != null) return route;
  
  // Ultimate fallback: straight line
  return [start, end];
}
```

### Routing Algorithms Used by APIs

#### MapTiler API
- **Algorithm**: Modified Dijkstra's algorithm with A* heuristic
- **Graph**: OpenStreetMap road network
- **Optimization**: Considers road types, speed limits, turn restrictions

#### OSRM (Open Source Routing Machine)
- **Algorithm**: Contraction Hierarchies (CH)
- **Preprocessing**: Creates hierarchical graph structure
- **Query Time**: O(log n) where n is number of nodes
- **Trade-off**: Fast queries but requires preprocessing

### Time Complexity
- **API Request**: O(1) - constant time HTTP call
- **Route Calculation (Server-side)**: 
  - OSRM: O(log n) with Contraction Hierarchies
  - A*: O(b^d) where b is branching factor, d is depth
- **Coordinate Parsing**: O(k) where k is number of waypoints in route

### Space Complexity
- **Route Storage**: O(k) where k is number of coordinate points
- **Typical Route**: 50-500 points depending on distance and detail level

---

## 4. Distance Calculation Algorithm

### Purpose
Calculate geographic distance between two coordinate points.

### Algorithm Type
**Haversine Formula**

### Implementation
Located in: [`map_controller.dart`](file:///e:/trip_sync/lib/controllers/map_controller.dart#L154)

```dart
double dist = const Distance().as(LengthUnit.Meter, start, end);
```

### Mathematical Formula

The Haversine formula calculates the great-circle distance between two points on a sphere:

```
a = sin²(Δφ/2) + cos(φ₁) × cos(φ₂) × sin²(Δλ/2)
c = 2 × atan2(√a, √(1−a))
d = R × c
```

Where:
- **φ₁, φ₂**: Latitude of point 1 and point 2 (in radians)
- **Δφ**: Difference in latitude
- **Δλ**: Difference in longitude
- **R**: Earth's radius (6,371 km or 3,959 miles)
- **d**: Distance between points

### Algorithm Steps

1. **Convert to Radians**
   ```
   φ₁ = lat₁ × π/180
   φ₂ = lat₂ × π/180
   Δφ = (lat₂ - lat₁) × π/180
   Δλ = (lon₂ - lon₁) × π/180
   ```

2. **Calculate Haversine**
   ```
   a = sin²(Δφ/2) + cos(φ₁) × cos(φ₂) × sin²(Δλ/2)
   ```

3. **Calculate Angular Distance**
   ```
   c = 2 × atan2(√a, √(1−a))
   ```

4. **Calculate Final Distance**
   ```
   d = R × c
   ```

### Characteristics
- **Accuracy**: ±0.5% for most distances
- **Earth Model**: Assumes perfect sphere (slight inaccuracy for oblate spheroid)
- **Time Complexity**: O(1) - constant time calculation
- **Space Complexity**: O(1)

### Use Cases in Trip Sync
1. **User-to-Destination Distance**: Calculate how far each user is from trip destination
2. **User-to-User Distance**: Calculate distances between group members
3. **Distance Display**: Show real-time distance updates on map

### Output Format
- **Unit**: Meters (can be converted to kilometers, miles, etc.)
- **Precision**: Double-precision floating point

---

## 5. User Status Detection Algorithm

### Purpose
Detect when users go offline or lose connection based on location update timestamps.

### Algorithm Type
**Time-based Heartbeat Detection**

### Implementation
Located in: [`map_controller.dart`](file:///e:/trip_sync/lib/controllers/map_controller.dart#L98-L139)

### Algorithm Steps

#### Step 1: Periodic Status Check
```dart
Timer.periodic(const Duration(seconds: 5), (timer) {
  _checkUserStatus();
});
```

#### Step 2: Timestamp Comparison
```dart
for (var user in participants) {
  Duration diff = DateTime.now().difference(user.lastActive);
  if (diff.inSeconds > 30 && user.isConnected) {
    // User is offline
  }
}
```

#### Step 3: State Change Detection
```dart
void _manageNotifications(List<UserModel> users) {
  for (var user in users) {
    bool isOffline = DateTime.now().difference(user.lastActive).inSeconds > 20;
    
    if (lastKnownConnectionStatus.containsKey(user.uid)) {
      bool wasOffline = !lastKnownConnectionStatus[user.uid]!;
      
      if (!wasOffline && isOffline) {
        // User just went offline - trigger notification
        NotificationService().showNotification(
          "Alert",
          "${user.name} went offline!",
        );
      }
    }
    lastKnownConnectionStatus[user.uid] = !isOffline;
  }
}
```

### Thresholds
- **Offline Detection**: 20-30 seconds without update
- **Check Frequency**: Every 5 seconds
- **Location Update Frequency**: Every 2 seconds (from background service)

### State Machine

```
[Online] ──(no update for 20s)──> [Offline]
    ↑                                  │
    └────(new location update)─────────┘
```

### Notification Logic
- **State Storage**: `Map<String, bool> lastKnownConnectionStatus`
- **Trigger Condition**: Transition from online → offline
- **Debouncing**: Only notify once per state change

### Time Complexity
- **Per Check**: O(n) where n is number of participants
- **Overall**: O(n) every 5 seconds

### Accuracy Considerations
1. **Network Latency**: May cause false positives during poor connectivity
2. **Grace Period**: 20-30 second threshold reduces false alarms
3. **Update Frequency**: 2-second location updates provide quick detection

---

## 6. Real-time Data Synchronization

### Purpose
Synchronize location data across all users in real-time using Firebase Firestore.

### Algorithm Type
**Observer Pattern with Cloud Streams**

### Implementation
Located in: [`map_controller.dart`](file:///e:/trip_sync/lib/controllers/map_controller.dart#L64-L88)

### Architecture Pattern

```
Firebase Firestore (Server)
         │
         │ WebSocket Connection
         │
         ↓
   Stream Listener (Client)
         │
         ↓
   Reactive State Update (GetX)
         │
         ↓
   UI Auto-Rebuild
```

### Algorithm Steps

#### Step 1: Stream Subscription
```dart
_usersSubscription = firestore
  .collection('users')
  .where('currentRoomId', isEqualTo: roomId)
  .snapshots()
  .listen((snapshot) { ... });
```

#### Step 2: Data Transformation
```dart
List<UserModel> users = snapshot.docs.map((doc) {
  var data = doc.data();
  UserModel user = UserModel.fromMap(data);
  
  if (data.containsKey('location')) {
    GeoPoint? gp = data['location'];
    if (gp != null) {
      userLocations[user.uid] = LatLng(gp.latitude, gp.longitude);
    }
  }
  return user;
}).toList();
```

#### Step 3: Reactive State Update
```dart
participants.value = users;  // Triggers UI rebuild automatically
```

### Firestore Query Optimization
- **Indexed Query**: `where('currentRoomId', isEqualTo: roomId)`
- **Automatic Indexing**: Firestore creates composite index
- **Query Complexity**: O(log n + k) where n is total users, k is room members

### Data Flow

```
User A Location Update
         ↓
   Firestore Write
         ↓
   Firestore Triggers Stream Event
         ↓
   User B, C, D Receive Update
         ↓
   Local State Updated
         ↓
   Map Markers Re-rendered
```

### Synchronization Characteristics
- **Latency**: Typically 100-500ms
- **Consistency**: Eventually consistent
- **Conflict Resolution**: Last-write-wins (timestamp-based)
- **Offline Support**: Firestore caches data locally

### Optimization Techniques
1. **Selective Listening**: Only subscribe to users in current room
2. **Reactive Updates**: GetX `.obs` triggers minimal UI rebuilds
3. **Merge Writes**: `SetOptions(merge: true)` prevents data loss
4. **Stream Cancellation**: Properly dispose subscriptions to prevent memory leaks

---

## 7. Mesh Route Generation Algorithm

### Purpose
Generate routes between all pairs of users and from each user to the destination.

### Algorithm Type
**Complete Graph Route Generation**

### Implementation
Located in: [`map_controller.dart`](file:///e:/trip_sync/lib/controllers/map_controller.dart#L141-L179)

### Graph Theory Representation

For n users, create:
- **n routes** from each user to destination
- **n(n-1)/2 routes** between all user pairs (complete graph)

### Algorithm Steps

#### Step 1: User-to-Destination Routes
```dart
for (var user in participants) {
  if (userLocations.containsKey(user.uid)) {
    LatLng start = userLocations[user.uid]!;
    LatLng end = destination.value!;
    
    List<LatLng> routePoints = await fetchRoute(start, end);
    routes["${user.uid}_to_dest"] = routePoints;
    
    double dist = const Distance().as(LengthUnit.Meter, start, end);
    distancesToDest["${user.uid}_to_dest"] = dist;
  }
}
```

#### Step 2: User-to-User Routes (Mesh Network)
```dart
List<UserModel> userList = participants;
for (int i = 0; i < userList.length; i++) {
  for (int j = i + 1; j < userList.length; j++) {
    String uid1 = userList[i].uid;
    String uid2 = userList[j].uid;
    
    if (userLocations.containsKey(uid1) && userLocations.containsKey(uid2)) {
      LatLng p1 = userLocations[uid1]!;
      LatLng p2 = userLocations[uid2]!;
      
      List<LatLng> routePoints = await fetchRoute(p1, p2);
      routes["${uid1}_to_${uid2}"] = routePoints;
      
      double dist = const Distance().as(LengthUnit.Meter, p1, p2);
      distancesToDest["${uid1}_to_${uid2}"] = dist;
    }
  }
}
```

### Complexity Analysis

#### Time Complexity
- **User-to-Destination**: O(n × R) where n is users, R is route calculation time
- **User-to-User**: O(n² × R) for complete graph
- **Total**: O(n² × R)

#### Space Complexity
- **Routes Storage**: O(n² × k) where k is average waypoints per route
- **Distance Storage**: O(n²)

### Example: 4 Users

```
Users: A, B, C, D
Destination: X

Routes Generated:
1. A → X
2. B → X
3. C → X
4. D → X
5. A ↔ B
6. A ↔ C
7. A ↔ D
8. B ↔ C
9. B ↔ D
10. C ↔ D

Total: 4 + (4×3)/2 = 4 + 6 = 10 routes
```

### Optimization Strategies

#### Current Implementation
- **Periodic Updates**: Recalculate every 5 seconds
- **Async Execution**: Routes fetched asynchronously
- **Caching**: Routes stored in reactive map

#### Potential Optimizations
1. **Incremental Updates**: Only recalculate routes for users whose positions changed significantly
2. **Distance Threshold**: Skip route update if user moved < 10 meters
3. **Priority Queue**: Calculate closest users first
4. **Lazy Loading**: Only calculate visible routes on map

### Update Frequency
```dart
Timer.periodic(const Duration(seconds: 5), (timer) {
  _updateRoutes();
});
```

### Scalability Considerations

| Users | Routes | API Calls/5s | Bandwidth |
|-------|--------|--------------|-----------|
| 2     | 3      | 3            | Low       |
| 5     | 15     | 15           | Medium    |
| 10    | 55     | 55           | High      |
| 20    | 210    | 210          | Very High |

**Recommendation**: Limit room size to 5-10 users for optimal performance

---

## 8. Notification Management Algorithm

### Purpose
Trigger notifications for important events (user offline, arrival, etc.) while preventing spam.

### Algorithm Type
**Event-Driven State Machine with Debouncing**

### Implementation
Located in: [`map_controller.dart`](file:///e:/trip_sync/lib/controllers/map_controller.dart#L120-L139)

### State Tracking
```dart
Map<String, bool> lastKnownConnectionStatus = {};
```

### Algorithm Steps

#### Step 1: Current State Detection
```dart
bool isOffline = DateTime.now().difference(user.lastActive).inSeconds > 20;
```

#### Step 2: Previous State Retrieval
```dart
if (lastKnownConnectionStatus.containsKey(user.uid)) {
  bool wasOffline = !lastKnownConnectionStatus[user.uid]!;
```

#### Step 3: State Transition Detection
```dart
if (!wasOffline && isOffline) {
  // State changed: online → offline
  NotificationService().showNotification(
    "Alert",
    "${user.name} went offline!",
  );
}
```

#### Step 4: State Update
```dart
lastKnownConnectionStatus[user.uid] = !isOffline;
```

### State Transition Diagram

```
         ┌─────────────┐
         │   Unknown   │
         └──────┬──────┘
                │ First Check
                ↓
         ┌─────────────┐
    ┌───→│   Online    │←───┐
    │    └──────┬──────┘    │
    │           │            │
    │  >20s no update   Location
    │           │          Update
    │           ↓            │
    │    ┌─────────────┐    │
    └────│   Offline   │────┘
         └─────────────┘
         
Notification triggered only on: Online → Offline
```

### Debouncing Strategy
- **State Memory**: Store last known state per user
- **Edge Detection**: Only trigger on state change
- **No Spam**: Prevents repeated notifications for same state

### Notification Types

| Event | Trigger Condition | Priority |
|-------|------------------|----------|
| User Offline | No update for 20s | High |
| User Online | New update after offline | Medium |
| Near Destination | Distance < 100m | High |
| All Arrived | All users at destination | High |

### Time Complexity
- **Per User Check**: O(1) - hash map lookup
- **All Users**: O(n) where n is number of participants

### Memory Complexity
- **State Storage**: O(n) - one boolean per user

---

## Summary of Computational Complexity

| Algorithm | Time Complexity | Space Complexity | Update Frequency |
|-----------|----------------|------------------|------------------|
| Room ID Generation | O(1) | O(1) | On-demand |
| GPS Tracking | O(1) per update | O(1) | Every 2s |
| Route Calculation | O(log n) server-side | O(k) waypoints | Every 5s |
| Distance Calculation | O(1) | O(1) | Every 5s |
| Status Detection | O(n) users | O(n) | Every 5s |
| Data Sync | O(log n + k) | O(k) | Real-time |
| Mesh Routes | O(n² × R) | O(n² × k) | Every 5s |
| Notifications | O(n) | O(n) | Event-driven |

**Legend**:
- n = number of users
- k = number of waypoints in route
- R = route calculation time

---

## Performance Optimizations

### 1. Battery Optimization
- 2-second GPS polling (balance between accuracy and battery)
- Foreground service with low-priority notification
- Efficient Firestore merge writes

### 2. Network Optimization
- Compressed GeoJSON route format
- Firestore query indexing
- Fallback routing APIs to ensure reliability

### 3. Computational Optimization
- Haversine formula (O(1)) instead of complex geodesic calculations
- Reactive state management (minimal UI rebuilds)
- Async route fetching (non-blocking)

### 4. Scalability Optimization
- Room-based user filtering
- Periodic cleanup of old location data
- Stream subscription management

---

## Future Algorithm Enhancements

### 1. Predictive Location
- **Kalman Filter**: Smooth GPS noise and predict next position
- **Benefits**: More accurate location, reduced jitter on map

### 2. Intelligent Route Updates
- **Delta Detection**: Only recalculate if position changed > threshold
- **Benefits**: Reduce API calls, save bandwidth

### 3. Clustering Algorithm
- **DBSCAN**: Group nearby users into clusters
- **Benefits**: Simplify visualization for large groups

### 4. ETA Calculation
- **Algorithm**: Current speed × distance to destination
- **Benefits**: Show estimated arrival time for each user

### 5. Geofencing
- **Point-in-Polygon**: Detect when users enter/exit defined areas
- **Benefits**: Automatic notifications for waypoints

---

## References

### Academic Papers
- Dijkstra, E. W. (1959). "A note on two problems in connexion with graphs"
- Hart, P. E.; Nilsson, N. J.; Raphael, B. (1968). "A Formal Basis for the Heuristic Determination of Minimum Cost Paths"

### Technical Documentation
- [Haversine Formula](https://en.wikipedia.org/wiki/Haversine_formula)
- [OSRM Routing Engine](http://project-osrm.org/)
- [Contraction Hierarchies](https://en.wikipedia.org/wiki/Contraction_hierarchies)
- [Firebase Firestore Queries](https://firebase.google.com/docs/firestore/query-data/queries)

### Libraries Used
- [Geolocator](https://pub.dev/packages/geolocator) - GPS location services
- [latlong2](https://pub.dev/packages/latlong2) - Distance calculations
- [flutter_map](https://pub.dev/packages/flutter_map) - Map rendering
- [GetX](https://pub.dev/packages/get) - Reactive state management
