import 'package:cloud_firestore/cloud_firestore.dart';

class FbJourneyPlan {
  final String id;
  final String locationId;
  final String name;
  final double lat;
  final double lng;
  final double radiusMeters;

  FbJourneyPlan({
    required this.id,
    required this.locationId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
  });

  // ✅ for /stops docs (your createJourneyPlan method)
  factory FbJourneyPlan.fromStopsDoc(String id, Map<String, dynamic> data) {
    final gp = data['allowedLocation'];
    final geo = (gp is GeoPoint) ? gp : const GeoPoint(0, 0);

    return FbJourneyPlan(
      id: id,
      locationId: (data['locationId'] ?? id).toString(),
      name: (data['name'] ?? '').toString(),
      lat: geo.latitude,
      lng: geo.longitude,
      radiusMeters: (data['allowedRadiusMeters'] is num)
          ? (data['allowedRadiusMeters'] as num).toDouble()
          : 13000,
    );
  }

  // ✅ for locationsSnapshot items inside plan doc
  factory FbJourneyPlan.fromSnapshotMap(String locationId, Map<String, dynamic> snap) {
    return FbJourneyPlan(
      id: locationId,
      locationId: locationId,
      name: (snap['name'] ?? '').toString(),
      lat: (snap['lat'] is num) ? (snap['lat'] as num).toDouble() : 0,
      lng: (snap['lng'] is num) ? (snap['lng'] as num).toDouble() : 0,
      radiusMeters: (snap['radiusMeters'] is num)
          ? (snap['radiusMeters'] as num).toDouble()
          : 13000,
    );
  }
}
