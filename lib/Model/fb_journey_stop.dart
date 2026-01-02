import 'package:cloud_firestore/cloud_firestore.dart';

class FbJourneyStop {
  final String id;
  final String locationId;
  final String name;
  final double lat;
  final double lng;
  final double radiusMeters;

  bool isVisited;
  DateTime? checkIn;
  DateTime? checkOut;
  int? durationMinutes;

  FbJourneyStop({
    required this.id,
    required this.locationId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
    this.isVisited = false,
    this.checkIn,
    this.checkOut,
    this.durationMinutes,
  });

  /// Backward-compatible parser used by older repo code.
  ///
  /// Some parts of the app call `FbJourneyStop.fromDoc(...)` while others use
  /// `FbJourneyStop.fromStopsDoc(...)` or `fromSnapshot(...)`.
  ///
  /// Keep this method so both compile, and parse using the stops-doc schema.
  static FbJourneyStop fromDoc(String id, Map<String, dynamic> d) {
    return FbJourneyStop.fromStopsDoc(id, d);
  }

  // ✅ legacy stops doc (allowedLocation + allowedRadiusMeters)
  factory FbJourneyStop.fromStopsDoc(String id, Map<String, dynamic> d) {
    final gp = d['allowedLocation'];
    double lat = 0;
    double lng = 0;

    if (gp is GeoPoint) {
      lat = gp.latitude;
      lng = gp.longitude;
    } else if (gp is Map) {
      lat = (gp['lat'] as num?)?.toDouble() ?? 0;
      lng = (gp['lng'] as num?)?.toDouble() ?? 0;
    }

    return FbJourneyStop(
      id: id,
      locationId: (d['locationId'] ?? id).toString(),
      name: (d['name'] ?? '').toString(),
      lat: lat,
      lng: lng,
      radiusMeters: (d['allowedRadiusMeters'] as num?)?.toDouble() ?? 100,
    );
  }

  // ✅ new snapshot item (lat/lng/radiusMeters)
  factory FbJourneyStop.fromSnapshot(String locationId, Map<String, dynamic> snap) {
    double toD(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    return FbJourneyStop(
      id: locationId,
      locationId: locationId,
      name: (snap['name'] ?? '').toString(),
      lat: toD(snap['lat']),
      lng: toD(snap['lng']),
      radiusMeters: toD(snap['radiusMeters'] ?? snap['allowedRadiusMeters']),
    );
  }
}
