import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

/// Fetches a driving route between two points via the public OSRM demo
/// server (no API key needed — matches this project's "no paid map API
/// required" goal). Falls back to a straight-line result if the request
/// fails, so a flaky network never breaks the map, it just shows a
/// straight line instead of a road-following one.
class RouteService {
  static const _base = 'https://router.project-osrm.org/route/v1/driving';
  static const Distance _distanceCalc = Distance();

  Future<RouteResult> getRoute(LatLng from, LatLng to) async {
    final url = Uri.parse(
      '$_base/${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return _straightLine(from, to);

      final data = jsonDecode(response.body);
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return _straightLine(from, to);

      final route = routes.first;
      final coords = route['geometry']['coordinates'] as List;
      final points = coords
          .map<LatLng>((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();

      return RouteResult(
        points: points,
        distanceMeters: (route['distance'] as num).toDouble(),
        durationSeconds: (route['duration'] as num).toDouble(),
      );
    } catch (_) {
      return _straightLine(from, to);
    }
  }

  RouteResult _straightLine(LatLng from, LatLng to) {
    final dist = _distanceCalc.as(LengthUnit.Meter, from, to);
    const assumedSpeedMs = 11.0; // ~40 km/h fallback assumption
    return RouteResult(
      points: [from, to],
      distanceMeters: dist,
      durationSeconds: dist / assumedSpeedMs,
    );
  }
}
