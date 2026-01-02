import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:new_amst_flutter/Firebase/firebase_services.dart';

class FbLocationRepo {
  static CollectionReference<Map<String, dynamic>> get _col =>
      Fb.db.collection('locations');

  static List<FbLocation>? _cache;
  static DateTime? _cacheAt;

  static List<FbLocation> get cachedLocations =>
      List.unmodifiable(_cache ?? const <FbLocation>[]);

  static Future<List<FbLocation>> warmCache({Duration ttl = const Duration(minutes: 5)}) async {
    final now = DateTime.now();
    final isFresh = _cacheAt != null && now.difference(_cacheAt!) < ttl;
    if (_cache != null && isFresh) return cachedLocations;

    try {
      final list = await fetchLocationsOnce();
      _cache = list;
      _cacheAt = now;
      return cachedLocations;
    } catch (_) {
      return cachedLocations;
    }
  }

  static Stream<List<FbLocation>> watchLocations() {
    return _col.orderBy('name').snapshots().map((q) {
      final list = q.docs
          .map((d) => FbLocation.fromDoc(d.id, d.data()))
          .toList(growable: false);
      _cache = list;
      _cacheAt = DateTime.now();
      return list;
    });
  }

  static Future<List<FbLocation>> fetchLocationsOnce() async {
    final q = await _col.orderBy('name').get();
    final list = q.docs
        .map((d) => FbLocation.fromDoc(d.id, d.data()))
        .toList(growable: false);
    _cache = list;
    _cacheAt = DateTime.now();
    return list;
  }

  static Future<void> upsertLocation({
    String? id,
    required String name,
    required double lat,
    required double lng,
    required double radiusMeters,
  }) async {
    final ref = (id == null || id.isEmpty) ? _col.doc() : _col.doc(id);
    await ref.set({
      'name': name.trim(),
      'allowedLocation': GeoPoint(lat, lng),
      'allowedRadiusMeters': radiusMeters,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> deleteLocation(String id) async {
    await _col.doc(id).delete();
  }

  static Future<void> setCurrentUserLocationFromLocation(String locationId) async {
    final uid = Fb.uid;
    if (uid == null) throw Exception('No active session. Please login again.');

    final snap = await _col.doc(locationId).get();
    if (!snap.exists) throw Exception('Selected location not found');

    final data = snap.data() ?? <String, dynamic>{};
    final loc = FbLocation.fromDoc(snap.id, data);
    await applyLocationToUser(uid: uid, location: loc);
  }

  static Future<void> applyLocationToUser({
    required String uid,
    required FbLocation location,
  }) async {
    await Fb.db.collection('users').doc(uid).set({
      'locationId': location.id,
      'locationName': location.name,
      'allowedLocation': GeoPoint(location.lat, location.lng),
      'allowedRadiusMeters': location.radiusMeters,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
