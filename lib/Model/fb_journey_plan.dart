import 'package:cloud_firestore/cloud_firestore.dart';

class FbJourneyPlan {
  final String id;
  final String supervisorId;
  final String periodType; // weekly/monthly
  final DateTime startDate;
  final DateTime endDate;

  // optional but useful
  final Map<String, dynamic> locationsSnapshot;

  const FbJourneyPlan({
    required this.id,
    required this.supervisorId,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    required this.locationsSnapshot,
  });

  static DateTime _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static FbJourneyPlan fromDoc(String id, Map<String, dynamic> d) {
    final snapAny = d['locationsSnapshot'];
    final Map<String, dynamic> snapshot =
        (snapAny is Map<String, dynamic>) ? snapAny : <String, dynamic>{};

    return FbJourneyPlan(
      id: id,
      supervisorId: (d['supervisorId'] ?? '').toString(),
      periodType: (d['periodType'] ?? 'weekly').toString(),
      startDate: _toDate(d['startDate']),
      endDate: _toDate(d['endDate']),
      locationsSnapshot: snapshot,
    );
  }
}
