import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:new_amst_flutter/Model/fb_journey_plan.dart';

import '../Model/fb_journey_stop.dart';
import 'firebase_services.dart';





class FbJourneyPlanRepo {
  static CollectionReference<Map<String, dynamic>> get _plans =>
      Fb.db.collection('journeyPlans');

  static String dayKey(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);


  static Future<void> createJourneyPlan({
    required String supervisorId,
    required String periodType,
    required DateTime startDate,
    required DateTime endDate,
    required List<FbLocation> stops,
  }) async {
    if (Fb.uid == null) throw Exception('Not signed in');

    final doc = _plans.doc();
    final batch = Fb.db.batch();

    batch.set(doc, {
      'supervisorId': supervisorId,
      'periodType': periodType,
      'startDate': Timestamp.fromDate(_dateOnly(startDate)),
      'endDate': Timestamp.fromDate(_dateOnly(endDate)),
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': Fb.uid,
    });

    final stopsCol = doc.collection('stops');
    int i = 0;
    for (final s in stops) {
      final stopId = s.id;
      final stopDoc = stopsCol.doc(stopId);
      batch.set(stopDoc, {
        'locationId': s.id,
        'name': s.name,
        'allowedLocation': GeoPoint(s.lat, s.lng),
        'allowedRadiusMeters': s.radiusMeters,
        'sortIndex': i,
      });
      i++;
    }

    await batch.commit();
  }

  static Future<void> deletePlan(String planId) async {
    final ref = _plans.doc(planId);
    final batch = Fb.db.batch();

    // delete legacy stops
    final stops = await ref.collection('stops').get();
    for (final d in stops.docs) {
      batch.delete(d.reference);
    }

    // delete new days docs (if exist)
    final days = await ref.collection('days').get();
    for (final d in days.docs) {
      batch.delete(d.reference);
    }

    // delete visits
    final visits = await ref.collection('visits').get();
    for (final d in visits.docs) {
      batch.delete(d.reference);
    }

    batch.delete(ref);
    await batch.commit();
  }


  static Future<FbJourneyPlan?> fetchActivePlanOnce({
    required String supervisorId,
    required DateTime now,
  }) async {
    final q = await _plans.where('supervisorId', isEqualTo: supervisorId).get();

    FbJourneyPlan? best;
    final n = _dateOnly(now);

    for (final d in q.docs) {
      final plan = FbJourneyPlan.fromDoc(d.id, d.data());
      final s = _dateOnly(plan.startDate);
      final e = _dateOnly(plan.endDate);

      final inRange = !n.isBefore(s) && !n.isAfter(e);
      if (!inRange) continue;

      if (best == null || plan.startDate.isAfter(best.startDate)) {
        best = plan;
      }
    }
    return best;
  }


  static Future<List<FbJourneyStop>> fetchStopsForDay({
    required String planId,
    required String dayKey, 
  }) async {
    final planRef = _plans.doc(planId);

    final planSnap = await planRef.get();
    final planData = planSnap.data() ?? <String, dynamic>{};

    final snapshotAny = planData['locationsSnapshot'];
    final Map<String, dynamic> snapshotMap =
        (snapshotAny is Map<String, dynamic>) ? snapshotAny : <String, dynamic>{};

    final daySnap = await planRef.collection('days').doc(dayKey).get();
    final dayData = daySnap.data() ?? <String, dynamic>{};

    final idsAny = dayData['locationIds'];
    final locationIds = (idsAny is List)
        ? idsAny.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    final out = <FbJourneyStop>[];
    for (final id in locationIds) {
      final itemAny = snapshotMap[id];
      if (itemAny is Map) {
        out.add(
          FbJourneyStop.fromSnapshot(
            id,
            Map<String, dynamic>.from(itemAny),
          ),
        );
      }
    }
    return out;
  }

  /// Legacy fallback: read /stops (only if you still have old plans)
  static Future<List<FbJourneyStop>> fetchStopsOnce({required String planId}) async {
    final snap = await _plans.doc(planId).collection('stops').orderBy('sortIndex').get();
    return snap.docs.map((d) => FbJourneyStop.fromStopsDoc(d.id, d.data())).toList();
  }

  /// Read visited location ids for a specific day.
  static Future<Set<String>> fetchVisitedLocationIdsForDay({
    required String planId,
    required String dayKey, // yyyy-mm-dd
  }) async {
    final snap = await _plans
        .doc(planId)
        .collection('visits')
        .where('dayKey', isEqualTo: dayKey)
        .get();

    final out = <String>{};
    for (final d in snap.docs) {
      final locId = (d.data()['locationId'] ?? '').toString();
      if (locId.isNotEmpty) out.add(locId);
    }
    return out;
  }

  static Future<void> addVisit({
    required String planId,
    required FbJourneyStop stop,
    required String comment,
    required DateTime? checkIn,
    required DateTime? checkOut,
    Map<String, dynamic>? form,
    String? photoBase64,
    String? dayKey,
  }) async {
    if (Fb.uid == null) throw Exception('Not signed in');

    final ref = _plans.doc(planId).collection('visits').doc();
    final now = DateTime.now();

    String mkDayKey(DateTime dt) => FbJourneyPlanRepo.dayKey(dt);

    await ref.set({
      'supervisorId': Fb.uid,
      'locationId': stop.locationId,
      'stopName': stop.name,
      'comment': comment,
      'checkIn': checkIn == null ? null : Timestamp.fromDate(checkIn),
      'checkOut': checkOut == null ? null : Timestamp.fromDate(checkOut),
      if (form != null) 'form': form,
      if (photoBase64 != null) 'photoBase64': photoBase64,
      'dayKey': dayKey ?? mkDayKey(now),
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': Fb.uid,
    });
  }
}
