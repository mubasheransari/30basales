import 'package:cloud_firestore/cloud_firestore.dart';

class FbLocation {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final double radiusMeters;

  const FbLocation({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
  });

  static FbLocation fromDoc(String id, Map<String, dynamic> d) {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.trim()) ?? 0.0;
      return 0.0;
    }

    final name = (d['name'] ?? d['title'] ?? id).toString();

    double lat = 0.0;
    double lng = 0.0;

    final gp = d['allowedLocation'];
    if (gp is GeoPoint) {
      lat = gp.latitude.toDouble();
      lng = gp.longitude.toDouble();
    } else if (gp is Map) {
      lat = toDouble(gp['lat'] ?? gp['latitude']);
      lng = toDouble(gp['lng'] ?? gp['longitude']);
    }

    // fallback support
    if (lat == 0.0 && lng == 0.0) {
      if (d.containsKey('lat') || d.containsKey('lng')) {
        lat = toDouble(d['lat']);
        lng = toDouble(d['lng']);
      } else if (d.containsKey('latitude') || d.containsKey('longitude')) {
        lat = toDouble(d['latitude']);
        lng = toDouble(d['longitude']);
      }

      final altGp = d['geo'] ?? d['location'] ?? d['coordinates'] ?? d['latLng'];
      if (altGp is GeoPoint) {
        lat = altGp.latitude.toDouble();
        lng = altGp.longitude.toDouble();
      } else if (altGp is Map) {
        lat = toDouble(altGp['lat'] ?? altGp['latitude']);
        lng = toDouble(altGp['lng'] ?? altGp['longitude']);
      }
    }

    double radiusMeters = 0.0;
    if (d.containsKey('allowedRadiusMeters')) {
      radiusMeters = toDouble(d['allowedRadiusMeters']);
    } else if (d.containsKey('radiusMeters')) {
      radiusMeters = toDouble(d['radiusMeters']);
    } else if (d.containsKey('radius')) {
      radiusMeters = toDouble(d['radius']);
    } else if (d.containsKey('radiusKm')) {
      radiusMeters = toDouble(d['radiusKm']) * 1000;
    }

    return FbLocation(
      id: id,
      name: name,
      lat: lat,
      lng: lng,
      radiusMeters: radiusMeters == 0 ? 100 : radiusMeters,
    );
  }
}
