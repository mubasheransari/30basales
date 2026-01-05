import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../Firebase/firebase_services.dart'
    show Fb, FbLocation, FbLocationRepo, FbSupervisorRepo, FbSupervisorProfile;

import 'package:new_amst_flutter/Firebase/fb_journey_plan_repo.dart' as jrepo;




// class JourneyPlansManagementTab extends StatefulWidget {
//   const JourneyPlansManagementTab({super.key});

//   @override
//   State<JourneyPlansManagementTab> createState() => _JourneyPlansManagementTabState();
// }
// class JourneyPlansTab extends StatelessWidget {
//   const JourneyPlansTab({super.key});

//   @override
//   Widget build(BuildContext context) => const JourneyPlansManagementTab();
// }

// class _JourneyPlansManagementTabState extends State<JourneyPlansManagementTab> {
//   static const _bg = Color(0xFFF6F7FA);

//   String? _selectedSupervisorId;
//   String _periodType = 'weekly';

//   DateTime _startDate = DateTime.now();
//   DateTime _endDate = DateTime.now().add(const Duration(days: 6));

//   final List<FbLocation> _locations = [];
//   bool _loadingLocations = true;
//   bool _saving = false;

//   String? _error;
//   String? _locationError;

//   StreamSubscription<List<FbLocation>>? _locationSub;

//   // per-day selection: yyyy-mm-dd -> {locationIds}
//   final Map<String, Set<String>> _dayToLocationIds = {};
//   String _activeDayKey = '';

//   // last weekly info (for copy-to-month snackbar + internal use)
//   Map<String, List<String>>? _lastWeeklyDaysMap;
//   String? _lastWeeklySupervisorId;
//   DateTime? _lastWeeklyStartDate;

//   // editing state (one supervisor has one plan)
//   String? _editingPlanId;
//   String? _editingSupervisorId;

//   // monthly prefill info
//   bool _monthlyPrefilledFromWeekly = false;

//   @override
//   void initState() {
//     super.initState();
//     _recalcEndDate();
//     _ensureDays();
//     _listenLocations();
//   }

//   @override
//   void dispose() {
//     _locationSub?.cancel();
//     super.dispose();
//   }

//   // ================= LOCATIONS =================

//   void _listenLocations() {
//     setState(() {
//       _loadingLocations = true;
//       _locationError = null;
//     });

//     _locationSub?.cancel();

//     _locationSub = FbLocationRepo.watchLocations().listen(
//       (list) {
//         if (!mounted) return;
//         setState(() {
//           _locations
//             ..clear()
//             ..addAll(list);
//           _loadingLocations = false;
//         });
//       },
//       onError: (e) {
//         if (!mounted) return;
//         setState(() {
//           _locationError = e.toString();
//           _loadingLocations = false;
//         });
//       },
//     );
//   }

//   // ================= DATE / DAYS =================

//   void _recalcEndDate() {
//     final base = DateTime(_startDate.year, _startDate.month, _startDate.day);
//     if (_periodType == 'weekly') {
//       _endDate = base.add(const Duration(days: 6));
//     } else {
//       _endDate = base.add(const Duration(days: 29)); // 30 days
//     }
//   }

//   List<DateTime> _daysInRange(DateTime start, DateTime end) {
//     final s = DateTime(start.year, start.month, start.day);
//     final e = DateTime(end.year, end.month, end.day);
//     final out = <DateTime>[];
//     for (int i = 0;; i++) {
//       final d = s.add(Duration(days: i));
//       out.add(d);
//       if (!d.isBefore(e)) break;
//     }
//     return out;
//   }

//   String _dayKey(DateTime dt) =>
//       '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

//   DateTime? _dateFromKey(String key) {
//     try {
//       final parts = key.split('-');
//       if (parts.length != 3) return null;
//       final y = int.parse(parts[0]);
//       final m = int.parse(parts[1]);
//       final d = int.parse(parts[2]);
//       return DateTime(y, m, d);
//     } catch (_) {
//       return null;
//     }
//   }

//   void _ensureDays() {
//     final days = _daysInRange(_startDate, _endDate);
//     if (days.isEmpty) return;

//     for (final d in days) {
//       final k = _dayKey(d);
//       _dayToLocationIds.putIfAbsent(k, () => <String>{});
//     }

//     final allowed = days.map(_dayKey).toSet();
//     _dayToLocationIds.removeWhere((k, _) => !allowed.contains(k));

//     final firstKey = _dayKey(days.first);
//     if (_activeDayKey.isEmpty || !_dayToLocationIds.containsKey(_activeDayKey)) {
//       _activeDayKey = firstKey;
//     }
//   }

//   Future<void> _pickStartDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: _startDate,
//       firstDate: DateTime(2022),
//       lastDate: DateTime(2100),
//     );
//     if (picked == null) return;

//     setState(() {
//       _startDate = picked;
//       _recalcEndDate();
//       _ensureDays();
//     });
//   }

//   // ======== FULL DATE FORMAT: 01-jan-2026 ========
//   String _fullDate(DateTime dt) {
//     // dd-MMM-yyyy -> 01-Jan-2026, we need 01-jan-2026
//     final s = DateFormat('dd-MMM-yyyy').format(dt);
//     final parts = s.split('-');
//     if (parts.length == 3) {
//       return '${parts[0]}-${parts[1].toLowerCase()}-${parts[2]}';
//     }
//     return s.toLowerCase();
//   }

//   // ================= LABEL HELPERS =================

//   static const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
//   String _weekdayShort(DateTime d) => _wd[(d.weekday - 1).clamp(0, 6)];

//   // ================= UI: DAY CHIP =================

//   Widget _dayChip(DateTime date, bool active, VoidCallback onTap, double s) {
//     final k = _dayKey(date);
//     final selectedCount = _dayToLocationIds[k]?.length ?? 0;

//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         margin: EdgeInsets.only(right: 8 * s, bottom: 8 * s),
//         padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 9 * s),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(999),
//           gradient: active
//               ? const LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)])
//               : null,
//           color: active ? null : const Color(0xFFEFF2F8),
//           border: Border.all(
//             color: selectedCount > 0 && !active
//                 ? const Color(0xFF7F53FD).withOpacity(0.35)
//                 : Colors.transparent,
//           ),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Day name
//             Text(
//               _weekdayShort(date),
//               style: TextStyle(
//                 fontFamily: 'ClashGrotesk',
//                 fontWeight: FontWeight.w900,
//                 color: active ? Colors.white : const Color(0xFF111827),
//                 fontSize: 13 * s,
//               ),
//             ),
//             SizedBox(width: 10 * s),

//             // Full date (01-jan-2026)
//             Text(
//               _fullDate(date),
//               style: TextStyle(
//                 fontFamily: 'ClashGrotesk',
//                 fontWeight: FontWeight.w900,
//                 color: active ? Colors.white : const Color(0xFF111827),
//                 fontSize: 12.5 * s,
//               ),
//             ),
//             SizedBox(width: 10 * s),

//             // Selected count pill
//             Container(
//               padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 3 * s),
//               decoration: BoxDecoration(
//                 color: active ? Colors.white.withOpacity(0.18) : Colors.white,
//                 borderRadius: BorderRadius.circular(999),
//               ),
//               child: Text(
//                 '$selectedCount',
//                 style: TextStyle(
//                   fontFamily: 'ClashGrotesk',
//                   fontWeight: FontWeight.w900,
//                   color: active ? Colors.white : const Color(0xFF7F53FD),
//                   fontSize: 11 * s,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ================= COPY HELPERS =================

//   void _copyActiveDayToAllDays() {
//     final src = _dayToLocationIds[_activeDayKey] ?? <String>{};
//     final days = _daysInRange(_startDate, _endDate);
//     for (final d in days) {
//       _dayToLocationIds[_dayKey(d)] = {...src};
//     }
//     setState(() {});
//   }

//   Map<String, List<String>> _repeatWeekPatternTo30Days({
//     required DateTime start,
//     required Map<String, List<String>> weeklyDaysMap,
//   }) {
//     final weeklyDays = _daysInRange(start, start.add(const Duration(days: 6)));
//     final weekKeys = weeklyDays.map(_dayKey).toList();

//     final weekPattern = List<List<String>>.generate(7, (i) {
//       final k = weekKeys[i];
//       return (weeklyDaysMap[k] ?? const <String>[]).toList();
//     });

//     final monthDays = _daysInRange(start, start.add(const Duration(days: 29)));
//     final out = <String, List<String>>{};

//     for (int i = 0; i < monthDays.length; i++) {
//       final dk = _dayKey(monthDays[i]);
//       out[dk] = List<String>.from(weekPattern[i % 7]);
//     }

//     return out;
//   }

//   Map<String, List<String>> _currentWeekDaysMap() {
//     final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
//     final weekDays = _daysInRange(start, start.add(const Duration(days: 6)));
//     final out = <String, List<String>>{};
//     for (final d in weekDays) {
//       final k = _dayKey(d);
//       out[k] = (_dayToLocationIds[k] ?? <String>{}).toList()..sort();
//     }
//     return out;
//   }

//   void _applyWeeklyPatternToMonthly() {
//     final weekMap = _currentWeekDaysMap();
//     final hasAny = weekMap.values.any((v) => v.isNotEmpty);
//     if (!hasAny) return;

//     final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
//     final monthlyMap = _repeatWeekPatternTo30Days(start: start, weeklyDaysMap: weekMap);

//     _dayToLocationIds.clear();
//     monthlyMap.forEach((k, ids) {
//       _dayToLocationIds[k] = ids.toSet();
//     });

//     _monthlyPrefilledFromWeekly = true;
//     _ensureDays();
//   }

//   // ================= FIRESTORE: ONE SUPERVISOR ONE PLAN =================

//   Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _getSupervisorPlanDoc(String supervisorId) async {
//     final q = await Fb.db.collection('journeyPlans').where('supervisorId', isEqualTo: supervisorId).limit(1).get();
//     if (q.docs.isEmpty) return null;
//     return q.docs.first;
//   }

//   Future<void> _upsertPlanForSupervisor({
//     required String supervisorId,
//     required String periodType,
//     required DateTime startDate,
//     required DateTime endDate,
//     required Map<String, List<String>> daysMap,
//     required Map<String, dynamic> locationsSnapshot,
//   }) async {
//     final now = Timestamp.now();

//     final existing = await _getSupervisorPlanDoc(supervisorId);
//     final planRef = existing == null ? Fb.db.collection('journeyPlans').doc() : existing.reference;

//     await planRef.set({
//       'supervisorId': supervisorId,
//       'periodType': periodType,
//       'startDate': Timestamp.fromDate(DateTime(startDate.year, startDate.month, startDate.day)),
//       'endDate': Timestamp.fromDate(DateTime(endDate.year, endDate.month, endDate.day)),
//       'updatedAt': now,
//       'createdAt': existing == null ? now : (existing.data()['createdAt'] ?? now),
//       'days': daysMap,
//       'locationsSnapshot': locationsSnapshot,
//       'daysCount': daysMap.length,
//       'selectedDaysCount': daysMap.entries.where((e) => e.value.isNotEmpty).length,
//       'copiedFrom': _monthlyPrefilledFromWeekly ? 'weekly' : null,
//     }, SetOptions(merge: true));

//     // rewrite subcollection /days so old keys don't remain
//     final oldDays = await planRef.collection('days').get();
//     final batch = Fb.db.batch();

//     for (final doc in oldDays.docs) {
//       batch.delete(doc.reference);
//     }

//     for (final entry in daysMap.entries) {
//       batch.set(planRef.collection('days').doc(entry.key), {
//         'date': entry.key,
//         'locationIds': entry.value,
//         'updatedAt': now,
//       });
//     }

//     await batch.commit();

//     _editingPlanId = planRef.id;
//     _editingSupervisorId = supervisorId;
//   }

//   Future<void> _loadSupervisorPlanIntoEditor(String supervisorId) async {
//     setState(() {
//       _saving = true;
//       _error = null;
//     });

//     try {
//       final doc = await _getSupervisorPlanDoc(supervisorId);
//       if (doc == null) {
//         setState(() {
//           _editingPlanId = null;
//           _editingSupervisorId = supervisorId;
//         });
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('No existing plan for this supervisor')),
//           );
//         }
//         return;
//       }

//       final data = doc.data();
//       final type = (data['periodType'] ?? 'weekly').toString();
//       final start = (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
//       final end = (data['endDate'] as Timestamp?)?.toDate() ?? start.add(const Duration(days: 6));

//       final daysAny = data['days'];
//       final Map<String, dynamic> daysMap = (daysAny is Map<String, dynamic>) ? daysAny : {};

//       _dayToLocationIds.clear();
//       for (final entry in daysMap.entries) {
//         final k = entry.key;
//         final v = entry.value;
//         final ids = (v is List) ? v.map((e) => e.toString()).toSet() : <String>{};
//         _dayToLocationIds[k] = ids;
//       }

//       setState(() {
//         _selectedSupervisorId = supervisorId;
//         _periodType = type;
//         _startDate = DateTime(start.year, start.month, start.day);
//         _endDate = DateTime(end.year, end.month, end.day);

//         _editingPlanId = doc.id;
//         _editingSupervisorId = supervisorId;

//         _monthlyPrefilledFromWeekly = false;

//         _ensureDays();
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Plan loaded. Edit and save now.')),
//         );
//       }
//     } catch (e) {
//       setState(() => _error = e.toString());
//     } finally {
//       if (mounted) setState(() => _saving = false);
//     }
//   }

//   // ================= PLAN DETAILS DIALOG (SAME THEME) =================

//   Future<void> _openPlanDetails({
//     required String planId,
//     required Map<String, dynamic> data,
//     required Map<String, FbSupervisorProfile> supMap,
//   }) async {
//     final supId = (data['supervisorId'] ?? '').toString();
//     final type = (data['periodType'] ?? '').toString();
//     final start = (data['startDate'] as Timestamp?)?.toDate();
//     final end = (data['endDate'] as Timestamp?)?.toDate();

//     final sup = supMap[supId];
//     final supLabel = sup == null ? supId : '${sup.email} • ${sup.city}';

//     final daysAny = data['days'];
//     final Map<String, dynamic> daysMap = (daysAny is Map<String, dynamic>) ? daysAny : <String, dynamic>{};

//     int plannedDays = 0;
//     daysMap.forEach((_, v) {
//       if (v is List && v.isNotEmpty) plannedDays++;
//     });

//     final locationsSnapshotAny = data['locationsSnapshot'];
//     final Map<String, dynamic> locationsSnapshot =
//         (locationsSnapshotAny is Map<String, dynamic>) ? locationsSnapshotAny : <String, dynamic>{};

//     final keys = daysMap.keys.toList()..sort((a, b) => a.compareTo(b));

//     await showDialog(
//       context: context,
//       builder: (ctx) {
//         final s = MediaQuery.sizeOf(ctx).width / 390.0;

//         return Dialog(
//           insetPadding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 16 * s),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           child: Container(
//             padding: EdgeInsets.all(14 * s),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: const [
//                 BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6)),
//               ],
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // header
//                 Row(
//                   children: [
//                     Container(
//                       width: 10 * s,
//                       height: 36 * s,
//                       decoration: const BoxDecoration(
//                         borderRadius: BorderRadius.all(Radius.circular(999)),
//                         gradient: LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)]),
//                       ),
//                     ),
//                     SizedBox(width: 10 * s),
//                     Expanded(
//                       child: Text(
//                         'Plan Details',
//                         style: TextStyle(
//                           fontFamily: 'ClashGrotesk',
//                           fontWeight: FontWeight.w900,
//                           fontSize: 16 * s,
//                           color: const Color(0xFF0F172A),
//                         ),
//                       ),
//                     ),
//                     IconButton(
//                       onPressed: () => Navigator.pop(ctx),
//                       icon: const Icon(Icons.close),
//                     ),
//                   ],
//                 ),

//                 SizedBox(height: 8 * s),
//                 _infoRow('Supervisor', supLabel, s),
//                 _infoRow('Type', type.toUpperCase(), s),
//                 _infoRow('Start', start == null ? '--' : _fullDate(start), s),
//                 _infoRow('End', end == null ? '--' : _fullDate(end), s),
//                 _infoRow('Planned Days', '$plannedDays / ${keys.length}', s),
//                 SizedBox(height: 10 * s),
//                 const Divider(),
//                 SizedBox(height: 10 * s),

//                 Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(
//                     'Day wise breakdown',
//                     style: TextStyle(
//                       fontFamily: 'ClashGrotesk',
//                       fontWeight: FontWeight.w900,
//                       fontSize: 14 * s,
//                       color: const Color(0xFF0F172A),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 10 * s),

//                 Flexible(
//                   child: keys.isEmpty
//                       ? const Text(
//                           'No day data found in this plan.',
//                           style: TextStyle(fontFamily: 'ClashGrotesk'),
//                         )
//                       : SingleChildScrollView(
//                           child: Column(
//                             children: keys.map((k) {
//                               final dt = _dateFromKey(k);
//                               final dayName = dt == null ? '--' : _weekdayShort(dt);

//                               final v = daysMap[k];
//                               final ids = (v is List) ? v.map((e) => e.toString()).toList() : <String>[];
//                               final count = ids.length;

//                               final names = <String>[];
//                               for (final id in ids) {
//                                 final item = locationsSnapshot[id];
//                                 if (item is Map && item['name'] != null) {
//                                   names.add(item['name'].toString());
//                                 }
//                               }

//                               return Container(
//                                 margin: EdgeInsets.only(bottom: 10 * s),
//                                 padding: EdgeInsets.all(12 * s),
//                                 decoration: BoxDecoration(
//                                   color: const Color(0xFFF6F7FA),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       '$dayName • ${dt == null ? k : _fullDate(dt)}',
//                                       style: TextStyle(
//                                         fontFamily: 'ClashGrotesk',
//                                         fontWeight: FontWeight.w900,
//                                         fontSize: 13.5 * s,
//                                       ),
//                                     ),
//                                     SizedBox(height: 6 * s),
//                                     Text(
//                                       'Locations: $count',
//                                       style: TextStyle(
//                                         fontFamily: 'ClashGrotesk',
//                                         fontWeight: FontWeight.w700,
//                                         color: const Color(0xFF6B7280),
//                                         fontSize: 12.5 * s,
//                                       ),
//                                     ),
//                                     if (names.isNotEmpty) ...[
//                                       SizedBox(height: 6 * s),
//                                       Text(
//                                         names.join(', '),
//                                         style: TextStyle(
//                                           fontFamily: 'ClashGrotesk',
//                                           fontWeight: FontWeight.w700,
//                                           fontSize: 12.5 * s,
//                                         ),
//                                       ),
//                                     ],
//                                   ],
//                                 ),
//                               );
//                             }).toList(),
//                           ),
//                         ),
//                 ),

//                 SizedBox(height: 10 * s),
//                 const Divider(),
//                 SizedBox(height: 10 * s),

//                 Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(
//                     'Supervisor activity (visits)',
//                     style: TextStyle(
//                       fontFamily: 'ClashGrotesk',
//                       fontWeight: FontWeight.w900,
//                       fontSize: 14 * s,
//                       color: const Color(0xFF0F172A),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 10 * s),

//                 // ✅ Live visits stream (shows form data entered by supervisor)
//                 Flexible(
//                   child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//                     stream: Fb.db
//                         .collection('journeyPlans')
//                         .doc(planId)
//                         .collection('visits')
//                         // ✅ NO-INDEX query: only orderBy, filter in app (avoids composite index requirement)
//                         .orderBy('createdAt', descending: true)
//                         .limit(200)
//                         .snapshots(),
//                     builder: (ctx, snap) {
//                       if (snap.hasError) {
//                         return Container(
//                           padding: EdgeInsets.all(12 * s),
//                           decoration: BoxDecoration(
//                             color: const Color(0xFFFFF1F2),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Text(
//                             'Failed to load visits: ${snap.error}',
//                             style: TextStyle(
//                               fontFamily: 'ClashGrotesk',
//                               fontWeight: FontWeight.w700,
//                               fontSize: 12.5 * s,
//                               color: const Color(0xFF991B1B),
//                             ),
//                           ),
//                         );
//                       }

//                       if (!snap.hasData) {
//                         return const Center(child: CircularProgressIndicator());
//                       }

//                       final allDocs = snap.data!.docs;

//                       // ✅ NO-INDEX filtering (Firestore index not required)
//                       final docs = allDocs.where((d) {
//                         final m = d.data();
//                         return (m['supervisorId'] ?? '').toString() == supId;
//                       }).toList(growable: false);
//                       if (docs.isEmpty) {
//                         return Container(
//                           padding: EdgeInsets.all(12 * s),
//                           decoration: BoxDecoration(
//                             color: const Color(0xFFF6F7FA),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Text(
//                             'No visits submitted yet.',
//                             style: TextStyle(
//                               fontFamily: 'ClashGrotesk',
//                               fontWeight: FontWeight.w700,
//                               fontSize: 12.5 * s,
//                               color: const Color(0xFF6B7280),
//                             ),
//                           ),
//                         );
//                       }

//                       String _fmtTs(Timestamp? t) {
//                         if (t == null) return '--';
//                         final dt = t.toDate();
//                         return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
//                       }

//                       int _durationMin(Timestamp? a, Timestamp? b) {
//                         if (a == null || b == null) return 0;
//                         return b.toDate().difference(a.toDate()).inMinutes;
//                       }

//                       Uint8List? _tryDecodeBase64(String? s) {
//                         if (s == null || s.trim().isEmpty) return null;
//                         try {
//                           return base64Decode(s);
//                         } catch (_) {
//                           return null;
//                         }
//                       }

//                       return ListView.separated(
//                         padding: EdgeInsets.zero,
//                         itemCount: docs.length,
//                         separatorBuilder: (_, __) => SizedBox(height: 8 * s),
//                         itemBuilder: (_, i) {
//                           final d = docs[i].data();

//                           final stopName = (d['stopName'] ?? '--').toString();
//                           final dayKey = (d['dayKey'] ?? '--').toString();
//                           final comment = (d['comment'] ?? '').toString();
//                           final checkIn = d['checkIn'] as Timestamp?;
//                           final checkOut = d['checkOut'] as Timestamp?;
//                           final duration = _durationMin(checkIn, checkOut);

//                           final formAny = d['form'];
//                           final form = (formAny is Map)
//                               ? Map<String, dynamic>.from(formAny)
//                               : <String, dynamic>{};

//                           final outletCondition = (form['outletCondition'] ?? '').toString();
//                           final stockAvailable = form['stockAvailable'];
//                           final displayOk = form['displayOk'];
//                           final stockQty = (form['stockQty'] ?? '').toString();

//                           final imgBytes = _tryDecodeBase64(d['photoBase64']?.toString());

//                           return Container(
//                             decoration: BoxDecoration(
//                               color: const Color(0xFFF6F7FA),
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(color: const Color(0xFFE5E7EB)),
//                             ),
//                             child: Theme(
//                               data: Theme.of(ctx).copyWith(dividerColor: Colors.transparent),
//                               child: ExpansionTile(
//                                 tilePadding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 2 * s),
//                                 childrenPadding: EdgeInsets.fromLTRB(12 * s, 0, 12 * s, 12 * s),
//                                 title: Text(
//                                   stopName,
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                   style: TextStyle(
//                                     fontFamily: 'ClashGrotesk',
//                                     fontWeight: FontWeight.w900,
//                                     fontSize: 13.5 * s,
//                                     color: const Color(0xFF0F172A),
//                                   ),
//                                 ),
//                                 subtitle: Text(
//                                   'Day: $dayKey • In: ${_fmtTs(checkIn)} • Out: ${_fmtTs(checkOut)}${duration > 0 ? ' • $duration min' : ''}',
//                                   maxLines: 2,
//                                   overflow: TextOverflow.ellipsis,
//                                   style: TextStyle(
//                                     fontFamily: 'ClashGrotesk',
//                                     fontWeight: FontWeight.w700,
//                                     fontSize: 11.5 * s,
//                                     color: const Color(0xFF6B7280),
//                                   ),
//                                 ),
//                                 children: [
//                                   if (imgBytes != null) ...[
//                                     ClipRRect(
//                                       borderRadius: BorderRadius.circular(12),
//                                       child: Image.memory(
//                                         imgBytes,
//                                         height: 160 * s,
//                                         width: double.infinity,
//                                         fit: BoxFit.cover,
//                                       ),
//                                     ),
//                                     SizedBox(height: 10 * s),
//                                   ],

//                                   // form chips
//                                   Wrap(
//                                     spacing: 8,
//                                     runSpacing: 8,
//                                     children: [
//                                       if (outletCondition.isNotEmpty)
//                                         _visitChip('Condition: $outletCondition'),
//                                       if (stockQty.isNotEmpty)
//                                         _visitChip('Stock Qty: $stockQty'),
//                                       if (stockAvailable is bool)
//                                         _visitChip(stockAvailable ? 'Stock: Yes' : 'Stock: No'),
//                                       if (displayOk is bool)
//                                         _visitChip(displayOk ? 'Display: OK' : 'Display: Not OK'),
//                                     ],
//                                   ),
//                                   if (comment.trim().isNotEmpty) ...[
//                                     SizedBox(height: 10 * s),
//                                     Align(
//                                       alignment: Alignment.centerLeft,
//                                       child: Text(
//                                         'Comment',
//                                         style: TextStyle(
//                                           fontFamily: 'ClashGrotesk',
//                                           fontWeight: FontWeight.w900,
//                                           fontSize: 12.5 * s,
//                                           color: const Color(0xFF0F172A),
//                                         ),
//                                       ),
//                                     ),
//                                     SizedBox(height: 6 * s),
//                                     Align(
//                                       alignment: Alignment.centerLeft,
//                                       child: Text(
//                                         comment,
//                                         style: TextStyle(
//                                           fontFamily: 'ClashGrotesk',
//                                           fontWeight: FontWeight.w700,
//                                           fontSize: 12.5 * s,
//                                           color: const Color(0xFF374151),
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       );
//                     },
//                   ),
//                 ),

//                 SizedBox(height: 10 * s),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 46 * s,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       elevation: 0,
//                       backgroundColor: const Color(0xFF0F172A),
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14 * s)),
//                     ),
//                     onPressed: () => Navigator.pop(ctx),
//                     child: Text(
//                       'Close',
//                       style: TextStyle(
//                         fontFamily: 'ClashGrotesk',
//                         fontWeight: FontWeight.w900,
//                         fontSize: 13.5 * s,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _infoRow(String k, String v, double s) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: 6 * s),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 105 * s,
//             child: Text(
//               '$k:',
//               style: TextStyle(
//                 fontFamily: 'ClashGrotesk',
//                 fontWeight: FontWeight.w800,
//                 fontSize: 12.5 * s,
//                 color: const Color(0xFF111827),
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               v,
//               style: TextStyle(
//                 fontFamily: 'ClashGrotesk',
//                 fontWeight: FontWeight.w700,
//                 fontSize: 12.5 * s,
//                 color: const Color(0xFF374151),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _visitChip(String text) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: const Color(0xFFE5E7EB)),
//       ),
//       child: Text(
//         text,
//         style: const TextStyle(
//           fontFamily: 'ClashGrotesk',
//           fontWeight: FontWeight.w800,
//           fontSize: 11.5,
//           color: Color(0xFF111827),
//         ),
//       ),
//     );
//   }

//   // ================= CREATE / SAVE PLAN (UPSERT) =================

//   Future<void> _createPlan() async {
//     setState(() => _error = null);

//     if (_selectedSupervisorId == null) {
//       setState(() => _error = 'Select supervisor');
//       return;
//     }

//     final days = _daysInRange(_startDate, _endDate);
//     if (days.isEmpty) {
//       setState(() => _error = 'Invalid date range');
//       return;
//     }

//     final hasAny = days.any((d) => (_dayToLocationIds[_dayKey(d)]?.isNotEmpty ?? false));
//     if (!hasAny) {
//       setState(() => _error = 'Select at least one location in at least one day');
//       return;
//     }

//     final allSelectedIds = <String>{};
//     for (final d in days) {
//       allSelectedIds.addAll(_dayToLocationIds[_dayKey(d)] ?? const <String>{});
//     }

//     final locationById = {for (final l in _locations) l.id: l};
//     final missing = allSelectedIds.where((id) => !locationById.containsKey(id)).toList();
//     if (missing.isNotEmpty) {
//       setState(() => _error = 'Some selected locations not found. Tap refresh.');
//       return;
//     }

//     setState(() => _saving = true);

//     try {
//       final Map<String, List<String>> daysMap = {};
//       for (final d in days) {
//         final k = _dayKey(d);
//         final ids = (_dayToLocationIds[k] ?? <String>{}).toList()..sort();
//         daysMap[k] = ids;
//       }

//       final locationsSnapshot = <String, dynamic>{
//         for (final id in allSelectedIds)
//           id: {
//             'id': id,
//             'name': locationById[id]!.name,
//             'lat': locationById[id]!.lat,
//             'lng': locationById[id]!.lng,
//             'radiusMeters': locationById[id]!.radiusMeters,
//           }
//       };

//       // ✅ one supervisor = one plan (create or update)
//       await _upsertPlanForSupervisor(
//         supervisorId: _selectedSupervisorId!,
//         periodType: _periodType,
//         startDate: _startDate,
//         endDate: _endDate,
//         daysMap: daysMap,
//         locationsSnapshot: locationsSnapshot,
//       );

//       if (!mounted) return;

//       // remember weekly for Copy-To-Month snackbar action
//       if (_periodType == 'weekly') {
//         _lastWeeklyDaysMap = daysMap;
//         _lastWeeklySupervisorId = _selectedSupervisorId;
//         _lastWeeklyStartDate = DateTime(_startDate.year, _startDate.month, _startDate.day);

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Text('Weekly plan saved'),
//             action: SnackBarAction(
//               label: 'COPY TO MONTH',
//               onPressed: () => _createMonthlyFromLastWeekly(),
//             ),
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Plan saved')),
//         );
//       }
//     } catch (e) {
//       setState(() => _error = e.toString());
//     } finally {
//       if (mounted) setState(() => _saving = false);
//     }
//   }

//   Future<void> _createMonthlyFromLastWeekly() async {
//     if (_lastWeeklyDaysMap == null || _lastWeeklySupervisorId == null || _lastWeeklyStartDate == null) return;

//     setState(() {
//       _saving = true;
//       _error = null;
//     });

//     try {
//       final start = DateTime(_lastWeeklyStartDate!.year, _lastWeeklyStartDate!.month, _lastWeeklyStartDate!.day);
//       final end = start.add(const Duration(days: 29));
//       final daysMap = _repeatWeekPatternTo30Days(start: start, weeklyDaysMap: _lastWeeklyDaysMap!);

//       final locationById = {for (final l in _locations) l.id: l};
//       final allSelectedIds = <String>{};
//       for (final v in daysMap.values) {
//         allSelectedIds.addAll(v);
//       }

//       final locationsSnapshot = <String, dynamic>{
//         for (final id in allSelectedIds)
//           if (locationById.containsKey(id))
//             id: {
//               'id': id,
//               'name': locationById[id]!.name,
//               'lat': locationById[id]!.lat,
//               'lng': locationById[id]!.lng,
//               'radiusMeters': locationById[id]!.radiusMeters,
//             }
//       };

//       _monthlyPrefilledFromWeekly = true;

//       await _upsertPlanForSupervisor(
//         supervisorId: _lastWeeklySupervisorId!,
//         periodType: 'monthly',
//         startDate: start,
//         endDate: end,
//         daysMap: daysMap,
//         locationsSnapshot: locationsSnapshot,
//       );

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Monthly plan created from weekly plan')),
//       );
//     } catch (e) {
//       setState(() => _error = e.toString());
//     } finally {
//       if (mounted) setState(() => _saving = false);
//     }
//   }

//   Future<void> _confirmDeletePlan(String planId) async {
//     final ok = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text(
//           'Delete plan?',
//           style: TextStyle(fontFamily: 'ClashGrotesk', fontWeight: FontWeight.w800),
//         ),
//         content: const Text(
//           'This will delete the plan. Continue?',
//           style: TextStyle(fontFamily: 'ClashGrotesk'),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx, false),
//             child: const Text('Cancel', style: TextStyle(fontFamily: 'ClashGrotesk')),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(ctx, true),
//             child: const Text('Delete', style: TextStyle(fontFamily: 'ClashGrotesk')),
//           ),
//         ],
//       ),
//     );
//     if (ok != true) return;

//     try {
//       await jrepo.FbJourneyPlanRepo.deletePlan(planId);
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Plan deleted')),
//       );

//       // clear editing state if same plan deleted
//       if (_editingPlanId == planId) {
//         setState(() {
//           _editingPlanId = null;
//           _editingSupervisorId = null;
//         });
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Delete failed: $e')),
//       );
//     }
//   }

//   // ================= UI HELPERS =================

//   Widget _cardShell({required Widget child, EdgeInsets? padding}) {
//     return Container(
//       padding: padding ?? const EdgeInsets.all(13),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: const [
//           BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6)),
//         ],
//       ),
//       child: child,
//     );
//   }

//   Widget _chip(String label, bool active, VoidCallback onTap, {double s = 1}) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 8 * s),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(999),
//           gradient: active
//               ? const LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)])
//               : null,
//           color: active ? null : const Color(0xFFEFF2F8),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             fontFamily: 'ClashGrotesk',
//             fontWeight: FontWeight.w800,
//             color: active ? Colors.white : const Color(0xFF111827),
//             fontSize: 13,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _locationCard(FbLocation l, bool checked, double s) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12 * s),
//         boxShadow: const [
//           BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 6)),
//         ],
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 9 * s,
//             height: 92 * s,
//             decoration: const BoxDecoration(
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(12),
//                 bottomLeft: Radius.circular(12),
//               ),
//               gradient: LinearGradient(
//                 colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//               ),
//             ),
//           ),
//           Expanded(
//             child: InkWell(
//               borderRadius: BorderRadius.circular(12 * s),
//               onTap: () {
//                 setState(() {
//                   final set = _dayToLocationIds.putIfAbsent(_activeDayKey, () => <String>{});
//                   if (checked) {
//                     set.remove(l.id);
//                   } else {
//                     set.add(l.id);
//                   }
//                 });
//               },
//               child: Padding(
//                 padding: EdgeInsets.fromLTRB(12 * s, 10 * s, 12 * s, 10 * s),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             l.name,
//                             style: TextStyle(
//                               fontFamily: 'ClashGrotesk',
//                               fontWeight: FontWeight.w900,
//                               color: const Color(0xFF0F172A),
//                               fontSize: 15 * s,
//                             ),
//                           ),
//                           SizedBox(height: 6 * s),
//                           Text(
//                             '(${l.lat.toStringAsFixed(6)}, ${l.lng.toStringAsFixed(6)})',
//                             style: TextStyle(
//                               fontFamily: 'ClashGrotesk',
//                               color: const Color(0xFF6B7280),
//                               fontSize: 12.5 * s,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           SizedBox(height: 4 * s),
//                           Text(
//                             'Radius: ${l.radiusMeters.toStringAsFixed(0)} m',
//                             style: TextStyle(
//                               fontFamily: 'ClashGrotesk',
//                               color: const Color(0xFF6B7280),
//                               fontSize: 12.5 * s,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     SizedBox(width: 10 * s),
//                     Container(
//                       width: 22 * s,
//                       height: 22 * s,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: checked ? const Color(0xFF22C55E) : const Color(0xFFE5E7EB),
//                       ),
//                       child: Icon(
//                         checked ? Icons.check : Icons.circle_outlined,
//                         size: 14 * s,
//                         color: checked ? Colors.white : const Color(0xFF9CA3AF),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ================= BUILD =================

//   @override
//   Widget build(BuildContext context) {
//     final s = MediaQuery.sizeOf(context).width / 390.0;
//     final padBottom = MediaQuery.paddingOf(context).bottom;

//     final days = _daysInRange(_startDate, _endDate);
//     final activeSet = _dayToLocationIds[_activeDayKey] ?? <String>{};
//     final activeDate = _dateFromKey(_activeDayKey);

//     return Scaffold(
//       backgroundColor: _bg,
//       body: SafeArea(
//         child: RefreshIndicator(
//           onRefresh: () async => _listenLocations(),
//           child: ListView(
//             physics: const AlwaysScrollableScrollPhysics(),
//             padding: EdgeInsets.fromLTRB(16 * s, 10 * s, 16 * s, 24 * s + padBottom),
//             children: [
//               SizedBox(height: 12 * s),

//               // Supervisor dropdown + edit button
//               _cardShell(
//                 child: StreamBuilder<List<FbSupervisorProfile>>(
//                   stream: FbSupervisorRepo.watchSupervisors(),
//                   builder: (_, snap) {
//                     final items = snap.data ?? const <FbSupervisorProfile>[];

//                     return Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         DropdownButtonFormField<String>(
//                           value: _selectedSupervisorId,
//                           decoration: const InputDecoration(
//                             labelText: 'Select Supervisor',
//                             labelStyle: TextStyle(fontFamily: 'ClashGrotesk', fontWeight: FontWeight.w700),
//                             border: InputBorder.none,
//                             enabledBorder: InputBorder.none,
//                             focusedBorder: InputBorder.none,
//                             disabledBorder: InputBorder.none,
//                             errorBorder: InputBorder.none,
//                             focusedErrorBorder: InputBorder.none,
//                             isDense: true,
//                             contentPadding: EdgeInsets.zero,
//                           ),
//                           items: items
//                               .map(
//                                 (sp) => DropdownMenuItem(
//                                   value: sp.uid,
//                                   child: Text(
//                                     '${sp.email} • ${sp.city}',
//                                     style: const TextStyle(fontFamily: 'ClashGrotesk'),
//                                   ),
//                                 ),
//                               )
//                               .toList(),
//                           onChanged: (v) => setState(() => _selectedSupervisorId = v),
//                         ),
//                         SizedBox(height: 10 * s),

//                         // edit/load existing plan
//                         SizedBox(
//                           width: double.infinity,
//                           child: OutlinedButton.icon(
//                             onPressed: (_selectedSupervisorId == null || _saving)
//                                 ? null
//                                 : () => _loadSupervisorPlanIntoEditor(_selectedSupervisorId!),
//                             icon: const Icon(Icons.edit),
//                             label: const Text(
//                               'Edit this supervisor plan',
//                               style: TextStyle(fontFamily: 'ClashGrotesk'),
//                             ),
//                           ),
//                         ),

//                         if (_editingPlanId != null && _editingSupervisorId == _selectedSupervisorId) ...[
//                           SizedBox(height: 8 * s),
//                           Text(
//                             'Editing existing plan',
//                             style: TextStyle(
//                               fontFamily: 'ClashGrotesk',
//                               fontWeight: FontWeight.w800,
//                               fontSize: 12.5 * s,
//                               color: const Color(0xFF7F53FD),
//                             ),
//                           ),
//                         ],
//                       ],
//                     );
//                   },
//                 ),
//               ),

//               SizedBox(height: 12 * s),

//               // Plan type + start/end
//               _cardShell(
//                 padding: EdgeInsets.all(10 * s),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Plan type',
//                       style: TextStyle(
//                         fontFamily: 'ClashGrotesk',
//                         fontWeight: FontWeight.w800,
//                         color: const Color(0xFF111827),
//                         fontSize: 13 * s,
//                       ),
//                     ),
//                     SizedBox(height: 10 * s),

//                     // Use Wrap to avoid overflow
//                     Wrap(
//                       spacing: 10 * s,
//                       runSpacing: 10 * s,
//                       children: [
//                         _chip('Weekly', _periodType == 'weekly', () {
//                           setState(() {
//                             _periodType = 'weekly';
//                             _monthlyPrefilledFromWeekly = false;
//                             _recalcEndDate();
//                             _ensureDays();
//                           });
//                         }, s: s),
//                         _chip('Monthly (30 days)', _periodType == 'monthly', () {
//                           setState(() {
//                             final wasWeekly = _periodType == 'weekly';

//                             _periodType = 'monthly';
//                             _recalcEndDate();
//                             _ensureDays();

//                             // ✅ if switching from weekly to monthly, keep selections by repeating pattern
//                             if (wasWeekly) {
//                               _applyWeeklyPatternToMonthly();
//                             }
//                           });
//                         }, s: s),
//                         OutlinedButton.icon(
//                           onPressed: _pickStartDate,
//                           icon: const Icon(Icons.date_range),
//                           label: Text(
//                             'Start: ${_fullDate(_startDate)}',
//                             style: const TextStyle(fontFamily: 'ClashGrotesk'),
//                           ),
//                         ),
//                       ],
//                     ),

//                     SizedBox(height: 10 * s),
//                     Text(
//                       'End: ${_fullDate(_endDate)}',
//                       style: TextStyle(
//                         fontFamily: 'ClashGrotesk',
//                         color: const Color(0xFF6B7280),
//                         fontSize: 12.5 * s,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               SizedBox(height: 12 * s),

//               // Day selector + copy day
//               _cardShell(
//                 padding: EdgeInsets.all(10 * s),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Select day (plan per-day)',
//                       style: TextStyle(
//                         fontFamily: 'ClashGrotesk',
//                         fontWeight: FontWeight.w900,
//                         color: const Color(0xFF0F172A),
//                         fontSize: 14.5 * s,
//                       ),
//                     ),
//                     SizedBox(height: 10 * s),

//                     SingleChildScrollView(
//                       scrollDirection: Axis.horizontal,
//                       child: Row(
//                         children: List.generate(days.length, (i) {
//                           final d = days[i];
//                           final k = _dayKey(d);
//                           return _dayChip(
//                             d,
//                             k == _activeDayKey,
//                             () => setState(() => _activeDayKey = k),
//                             s,
//                           );
//                         }),
//                       ),
//                     ),

//                     SizedBox(height: 10 * s),
//                     Container(
//                       width: double.infinity,
//                       padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 10 * s),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFF6F7FA),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         activeDate == null
//                             ? 'Selected day: --'
//                             : 'Selected day: ${_weekdayShort(activeDate)} • ${_fullDate(activeDate)}',
//                         style: TextStyle(
//                           fontFamily: 'ClashGrotesk',
//                           fontWeight: FontWeight.w900,
//                           fontSize: 13.5 * s,
//                           color: const Color(0xFF0F172A),
//                         ),
//                       ),
//                     ),

//                     SizedBox(height: 10 * s),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: OutlinedButton.icon(
//                             onPressed: _copyActiveDayToAllDays,
//                             icon: const Icon(Icons.copy),
//                             label: const Text(
//                               'Copy this day → all days',
//                               style: TextStyle(fontFamily: 'ClashGrotesk'),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),

//                     SizedBox(height: 8 * s),
//                     Text(
//                       'Locations selected for this day: ${activeSet.length}',
//                       style: TextStyle(
//                         fontFamily: 'ClashGrotesk',
//                         color: const Color(0xFF6B7280),
//                         fontSize: 12.5 * s,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               SizedBox(height: 12 * s),

//               // Locations header
//               Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       'Select locations (for selected day)',
//                       style: TextStyle(
//                         fontFamily: 'ClashGrotesk',
//                         fontWeight: FontWeight.w900,
//                         color: const Color(0xFF0F172A),
//                         fontSize: 16 * s,
//                       ),
//                     ),
//                   ),
//                   IconButton(
//                     tooltip: 'Reload locations',
//                     onPressed: _listenLocations,
//                     icon: const Icon(Icons.refresh),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 8 * s),

//               // Locations list
//               if (_loadingLocations)
//                 Padding(
//                   padding: EdgeInsets.only(top: 30 * s, bottom: 10 * s),
//                   child: const Center(child: CircularProgressIndicator()),
//                 )
//               else if (_locationError != null)
//                 _cardShell(
//                   child: Text(
//                     'Locations error:\n$_locationError',
//                     style: const TextStyle(
//                       fontFamily: 'ClashGrotesk',
//                       color: Colors.red,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 )
//               else if (_locations.isEmpty)
//                 _cardShell(
//                   child: const Text(
//                     'No locations found',
//                     style: TextStyle(
//                       fontFamily: 'ClashGrotesk',
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 )
//               else
//                 ..._locations.map((l) {
//                   final checked = (_dayToLocationIds[_activeDayKey] ?? <String>{}).contains(l.id);
//                   return Padding(
//                     padding: EdgeInsets.only(bottom: 12 * s),
//                     child: _locationCard(l, checked, s),
//                   );
//                 }),

//               if (_error != null) ...[
//                 SizedBox(height: 6 * s),
//                 Text(
//                   _error!,
//                   style: const TextStyle(
//                     fontFamily: 'ClashGrotesk',
//                     color: Colors.red,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ],

//               SizedBox(height: 12 * s),

//               // Save/Create button (upsert)
//               SizedBox(
//                 width: double.infinity,
//                 height: 50 * s,
//                 child: ElevatedButton.icon(
//                   onPressed: _saving ? null : _createPlan,
//                   style: ElevatedButton.styleFrom(
//                     elevation: 0,
//                     backgroundColor: const Color(0xFF0F172A),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14 * s),
//                     ),
//                   ),
//                   icon: _saving
//                       ? const SizedBox(
//                           height: 18,
//                           width: 18,
//                           child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
//                         )
//                       : const Icon(Icons.save, color: Colors.white),
//                   label: Text(
//                     _saving ? 'Saving...' : 'Save Journey Plan',
//                     style: TextStyle(
//                       fontFamily: 'ClashGrotesk',
//                       fontWeight: FontWeight.w900,
//                       fontSize: 14 * s,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),

//               SizedBox(height: 18 * s),
//               const Divider(),
//               SizedBox(height: 8 * s),

//               Text(
//                 'Existing plans (latest 30)',
//                 style: TextStyle(
//                   fontFamily: 'ClashGrotesk',
//                   fontWeight: FontWeight.w900,
//                   color: const Color(0xFF0F172A),
//                   fontSize: 16 * s,
//                 ),
//               ),
//               SizedBox(height: 10 * s),

//               SizedBox(
//                 height: 300 * s,
//                 child: _cardShell(
//                   padding: EdgeInsets.zero,
//                   child: StreamBuilder<List<FbSupervisorProfile>>(
//                     stream: FbSupervisorRepo.watchSupervisors(),
//                     builder: (context, supSnap) {
//                       final supList = supSnap.data ?? const <FbSupervisorProfile>[];
//                       final supMap = {for (final sp in supList) sp.uid: sp};

//                       return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//                         stream: Fb.db
//                             .collection('journeyPlans')
//                             .orderBy('createdAt', descending: true)
//                             .limit(30)
//                             .snapshots(),
//                         builder: (context, snap) {
//                           if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
//                           if (!snap.hasData) return const Center(child: CircularProgressIndicator());

//                           final docs = snap.data!.docs;
//                           if (docs.isEmpty) {
//                             return const Center(
//                               child: Text('No plans found.', style: TextStyle(fontFamily: 'ClashGrotesk')),
//                             );
//                           }

//                           int selectedDaysCount(Map<String, dynamic> data) {
//                             final days = data['days'];
//                             if (days is Map) {
//                               int c = 0;
//                               days.forEach((_, v) {
//                                 if (v is List && v.isNotEmpty) c++;
//                               });
//                               return c;
//                             }
//                             return (data['selectedDaysCount'] as int?) ?? 0;
//                           }

//                           return ListView.separated(
//                             itemCount: docs.length,
//                             separatorBuilder: (_, __) => const Divider(height: 1),
//                             itemBuilder: (_, i) {
//                               final d = docs[i];
//                               final data = d.data();

//                               final supId = (data['supervisorId'] ?? '').toString();
//                               final type = (data['periodType'] ?? '').toString();

//                               final start = (data['startDate'] as Timestamp?)?.toDate();
//                               final end = (data['endDate'] as Timestamp?)?.toDate();

//                               final sup = supMap[supId];
//                               final supLabel = sup == null ? supId : '${sup.email} • ${sup.city}';

//                               final totalDays = (data['daysCount'] as int?) ?? 0;
//                               final plannedDays = selectedDaysCount(data);

//                               return ListTile(
//                                 dense: true,
//                                 onTap: () => _openPlanDetails(planId: d.id, data: data, supMap: supMap),
//                                 title: Text(
//                                   'Supervisor: $supLabel',
//                                   style: const TextStyle(
//                                     fontFamily: 'ClashGrotesk',
//                                     fontWeight: FontWeight.w900,
//                                   ),
//                                 ),
//                                 subtitle: Text(
//                                   '${type.toUpperCase()} • '
//                                   '${start == null ? '--' : _fullDate(start)} → ${end == null ? '--' : _fullDate(end)}\n'
//                                   'Planned days: $plannedDays / ${totalDays == 0 ? '--' : totalDays}\n'
//                                   'Tap to view details',
//                                   style: const TextStyle(
//                                     fontFamily: 'ClashGrotesk',
//                                     color: Color(0xFF6B7280),
//                                     fontWeight: FontWeight.w600,
//                                     height: 1.25,
//                                   ),
//                                 ),
//                                 trailing: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     IconButton(
//                                       tooltip: 'Edit',
//                                       icon: const Icon(Icons.edit),
//                                       onPressed: () => _loadSupervisorPlanIntoEditor(supId),
//                                     ),
//                                     IconButton(
//                                       tooltip: 'Delete',
//                                       icon: const Icon(Icons.delete_outline),
//                                       onPressed: () => _confirmDeletePlan(d.id),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             },
//                           );
//                         },
//                       );
//                     },
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../Firebase/firebase_services.dart'
    show Fb, FbLocation, FbLocationRepo, FbSupervisorRepo, FbSupervisorProfile;

import 'package:new_amst_flutter/Firebase/fb_journey_plan_repo.dart' as jrepo;

class JourneyPlansManagementTab extends StatefulWidget {
  const JourneyPlansManagementTab({super.key});

  @override
  State<JourneyPlansManagementTab> createState() => _JourneyPlansManagementTabState();
}

class JourneyPlansTab extends StatelessWidget {
  const JourneyPlansTab({super.key});

  @override
  Widget build(BuildContext context) => const JourneyPlansManagementTab();
}

class _JourneyPlansManagementTabState extends State<JourneyPlansManagementTab> {
  static const _bg = Color(0xFFF6F7FA);

  String? _selectedSupervisorId;
  String _periodType = 'weekly';

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 6));

  final List<FbLocation> _locations = [];
  bool _loadingLocations = true;
  bool _saving = false;

  String? _error;
  String? _locationError;

  StreamSubscription<List<FbLocation>>? _locationSub;

  // per-day selection: yyyy-mm-dd -> {locationIds}
  final Map<String, Set<String>> _dayToLocationIds = {};
  String _activeDayKey = '';

  // last weekly info (for copy-to-month snackbar + internal use)
  Map<String, List<String>>? _lastWeeklyDaysMap;
  String? _lastWeeklySupervisorId;
  DateTime? _lastWeeklyStartDate;

  // editing state (one supervisor has one plan)
  String? _editingPlanId;
  String? _editingSupervisorId;

  // monthly prefill info
  bool _monthlyPrefilledFromWeekly = false;

  @override
  void initState() {
    super.initState();
    _recalcEndDate();
    _ensureDays();
    _listenLocations();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  // ================= LOCATIONS =================

  void _listenLocations() {
    setState(() {
      _loadingLocations = true;
      _locationError = null;
    });

    _locationSub?.cancel();

    _locationSub = FbLocationRepo.watchLocations().listen(
      (list) {
        if (!mounted) return;
        setState(() {
          _locations
            ..clear()
            ..addAll(list);
          _loadingLocations = false;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _locationError = e.toString();
          _loadingLocations = false;
        });
      },
    );
  }

  // ================= DATE / DAYS =================

  void _recalcEndDate() {
    final base = DateTime(_startDate.year, _startDate.month, _startDate.day);
    if (_periodType == 'weekly') {
      _endDate = base.add(const Duration(days: 6));
    } else {
      _endDate = base.add(const Duration(days: 29)); // 30 days
    }
  }

  List<DateTime> _daysInRange(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    final out = <DateTime>[];
    for (int i = 0;; i++) {
      final d = s.add(Duration(days: i));
      out.add(d);
      if (!d.isBefore(e)) break;
    }
    return out;
  }

  String _dayKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  DateTime? _dateFromKey(String key) {
    try {
      final parts = key.split('-');
      if (parts.length != 3) return null;
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }

  void _ensureDays() {
    final days = _daysInRange(_startDate, _endDate);
    if (days.isEmpty) return;

    for (final d in days) {
      final k = _dayKey(d);
      _dayToLocationIds.putIfAbsent(k, () => <String>{});
    }

    final allowed = days.map(_dayKey).toSet();
    _dayToLocationIds.removeWhere((k, _) => !allowed.contains(k));

    final firstKey = _dayKey(days.first);
    if (_activeDayKey.isEmpty || !_dayToLocationIds.containsKey(_activeDayKey)) {
      _activeDayKey = firstKey;
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2022),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    setState(() {
      _startDate = picked;
      _recalcEndDate();
      _ensureDays();
    });
  }

  // ======== FULL DATE FORMAT: 01-jan-2026 ========
  String _fullDate(DateTime dt) {
    final s = DateFormat('dd-MMM-yyyy').format(dt);
    final parts = s.split('-');
    if (parts.length == 3) {
      return '${parts[0]}-${parts[1].toLowerCase()}-${parts[2]}';
    }
    return s.toLowerCase();
  }

  // ================= LABEL HELPERS =================

  static const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  String _weekdayShort(DateTime d) => _wd[(d.weekday - 1).clamp(0, 6)];

  // ================= UI: DAY CHIP =================

  Widget _dayChip(DateTime date, bool active, VoidCallback onTap, double s) {
    final k = _dayKey(date);
    final selectedCount = _dayToLocationIds[k]?.length ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: 8 * s, bottom: 8 * s),
        padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 9 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: active
              ? const LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)])
              : null,
          color: active ? null : const Color(0xFFEFF2F8),
          border: Border.all(
            color: selectedCount > 0 && !active
                ? const Color(0xFF7F53FD).withOpacity(0.35)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _weekdayShort(date),
              style: TextStyle(
                fontFamily: 'ClashGrotesk',
                fontWeight: FontWeight.w900,
                color: active ? Colors.white : const Color(0xFF111827),
                fontSize: 13 * s,
              ),
            ),
            SizedBox(width: 10 * s),
            Text(
              _fullDate(date),
              style: TextStyle(
                fontFamily: 'ClashGrotesk',
                fontWeight: FontWeight.w900,
                color: active ? Colors.white : const Color(0xFF111827),
                fontSize: 12.5 * s,
              ),
            ),
            SizedBox(width: 10 * s),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 3 * s),
              decoration: BoxDecoration(
                color: active ? Colors.white.withOpacity(0.18) : Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$selectedCount',
                style: TextStyle(
                  fontFamily: 'ClashGrotesk',
                  fontWeight: FontWeight.w900,
                  color: active ? Colors.white : const Color(0xFF7F53FD),
                  fontSize: 11 * s,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= COPY HELPERS =================

  void _copyActiveDayToAllDays() {
    final src = _dayToLocationIds[_activeDayKey] ?? <String>{};
    final days = _daysInRange(_startDate, _endDate);
    for (final d in days) {
      _dayToLocationIds[_dayKey(d)] = {...src};
    }
    setState(() {});
  }

  Map<String, List<String>> _repeatWeekPatternTo30Days({
    required DateTime start,
    required Map<String, List<String>> weeklyDaysMap,
  }) {
    final weeklyDays = _daysInRange(start, start.add(const Duration(days: 6)));
    final weekKeys = weeklyDays.map(_dayKey).toList();

    final weekPattern = List<List<String>>.generate(7, (i) {
      final k = weekKeys[i];
      return (weeklyDaysMap[k] ?? const <String>[]).toList();
    });

    final monthDays = _daysInRange(start, start.add(const Duration(days: 29)));
    final out = <String, List<String>>{};

    for (int i = 0; i < monthDays.length; i++) {
      final dk = _dayKey(monthDays[i]);
      out[dk] = List<String>.from(weekPattern[i % 7]);
    }

    return out;
  }

  Map<String, List<String>> _currentWeekDaysMap() {
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final weekDays = _daysInRange(start, start.add(const Duration(days: 6)));
    final out = <String, List<String>>{};
    for (final d in weekDays) {
      final k = _dayKey(d);
      out[k] = (_dayToLocationIds[k] ?? <String>{}).toList()..sort();
    }
    return out;
  }

  void _applyWeeklyPatternToMonthly() {
    final weekMap = _currentWeekDaysMap();
    final hasAny = weekMap.values.any((v) => v.isNotEmpty);
    if (!hasAny) return;

    final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final monthlyMap = _repeatWeekPatternTo30Days(start: start, weeklyDaysMap: weekMap);

    _dayToLocationIds.clear();
    monthlyMap.forEach((k, ids) {
      _dayToLocationIds[k] = ids.toSet();
    });

    _monthlyPrefilledFromWeekly = true;
    _ensureDays();
  }

  // ================= FIRESTORE: ONE SUPERVISOR ONE PLAN =================

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _getSupervisorPlanDoc(String supervisorId) async {
    final q = await Fb.db
        .collection('journeyPlans')
        .where('supervisorId', isEqualTo: supervisorId)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return q.docs.first;
  }

  Future<void> _upsertPlanForSupervisor({
    required String supervisorId,
    required String periodType,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, List<String>> daysMap,
    required Map<String, dynamic> locationsSnapshot,
  }) async {
    final now = Timestamp.now();

    final existing = await _getSupervisorPlanDoc(supervisorId);
    final planRef = existing == null ? Fb.db.collection('journeyPlans').doc() : existing.reference;

    await planRef.set({
      'supervisorId': supervisorId,
      'periodType': periodType,
      'startDate': Timestamp.fromDate(DateTime(startDate.year, startDate.month, startDate.day)),
      'endDate': Timestamp.fromDate(DateTime(endDate.year, endDate.month, endDate.day)),
      'updatedAt': now,
      'createdAt': existing == null ? now : (existing.data()['createdAt'] ?? now),
      'days': daysMap,
      'locationsSnapshot': locationsSnapshot,
      'daysCount': daysMap.length,
      'selectedDaysCount': daysMap.entries.where((e) => e.value.isNotEmpty).length,
      'copiedFrom': _monthlyPrefilledFromWeekly ? 'weekly' : null,
    }, SetOptions(merge: true));

    // rewrite subcollection /days so old keys don't remain
    final oldDays = await planRef.collection('days').get();
    final batch = Fb.db.batch();

    for (final doc in oldDays.docs) {
      batch.delete(doc.reference);
    }

    for (final entry in daysMap.entries) {
      batch.set(planRef.collection('days').doc(entry.key), {
        'date': entry.key,
        'locationIds': entry.value,
        'updatedAt': now,
      });
    }

    await batch.commit();

    _editingPlanId = planRef.id;
    _editingSupervisorId = supervisorId;
  }

  Future<void> _loadSupervisorPlanIntoEditor(String supervisorId) async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final doc = await _getSupervisorPlanDoc(supervisorId);
      if (doc == null) {
        setState(() {
          _editingPlanId = null;
          _editingSupervisorId = supervisorId;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No existing plan for this supervisor')),
          );
        }
        return;
      }

      final data = doc.data();
      final type = (data['periodType'] ?? 'weekly').toString();
      final start = (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
      final end = (data['endDate'] as Timestamp?)?.toDate() ?? start.add(const Duration(days: 6));

      final daysAny = data['days'];
      final Map<String, dynamic> daysMap = (daysAny is Map<String, dynamic>) ? daysAny : {};

      _dayToLocationIds.clear();
      for (final entry in daysMap.entries) {
        final k = entry.key;
        final v = entry.value;
        final ids = (v is List) ? v.map((e) => e.toString()).toSet() : <String>{};
        _dayToLocationIds[k] = ids;
      }

      setState(() {
        _selectedSupervisorId = supervisorId;
        _periodType = type;
        _startDate = DateTime(start.year, start.month, start.day);
        _endDate = DateTime(end.year, end.month, end.day);

        _editingPlanId = doc.id;
        _editingSupervisorId = supervisorId;

        _monthlyPrefilledFromWeekly = false;

        _ensureDays();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan loaded. Edit and save now.')),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ================= PLAN DETAILS DIALOG (SAME THEME) =================

  Future<void> _openPlanDetails({
    required String planId,
    required Map<String, dynamic> data,
    required Map<String, FbSupervisorProfile> supMap,
  }) async {
    final supId = (data['supervisorId'] ?? '').toString();
    final type = (data['periodType'] ?? '').toString();
    final start = (data['startDate'] as Timestamp?)?.toDate();
    final end = (data['endDate'] as Timestamp?)?.toDate();

    final sup = supMap[supId];
    final supLabel = sup == null ? supId : '${sup.email} • ${sup.city}';

    final daysAny = data['days'];
    final Map<String, dynamic> daysMap =
        (daysAny is Map<String, dynamic>) ? daysAny : <String, dynamic>{};

    int plannedDays = 0;
    daysMap.forEach((_, v) {
      if (v is List && v.isNotEmpty) plannedDays++;
    });

    final locationsSnapshotAny = data['locationsSnapshot'];
    final Map<String, dynamic> locationsSnapshot =
        (locationsSnapshotAny is Map<String, dynamic>) ? locationsSnapshotAny : <String, dynamic>{};

    final keys = daysMap.keys.toList()..sort((a, b) => a.compareTo(b));

    await showDialog(
      context: context,
      builder: (ctx) {
        final s = MediaQuery.sizeOf(ctx).width / 390.0;

        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 16 * s),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: EdgeInsets.all(14 * s),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // header
                Row(
                  children: [
                    Container(
                      width: 10 * s,
                      height: 36 * s,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                        gradient: LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)]),
                      ),
                    ),
                    SizedBox(width: 10 * s),
                    Expanded(
                      child: Text(
                        'Plan Details',
                        style: TextStyle(
                          fontFamily: 'ClashGrotesk',
                          fontWeight: FontWeight.w900,
                          fontSize: 16 * s,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                SizedBox(height: 8 * s),
                _infoRow('Supervisor', supLabel, s),
                _infoRow('Type', type.toUpperCase(), s),
                _infoRow('Start', start == null ? '--' : _fullDate(start), s),
                _infoRow('End', end == null ? '--' : _fullDate(end), s),
                _infoRow('Planned Days', '$plannedDays / ${keys.length}', s),
                SizedBox(height: 10 * s),
                const Divider(),
                SizedBox(height: 10 * s),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Day wise breakdown',
                    style: TextStyle(
                      fontFamily: 'ClashGrotesk',
                      fontWeight: FontWeight.w900,
                      fontSize: 14 * s,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                SizedBox(height: 10 * s),

                Flexible(
                  child: keys.isEmpty
                      ? const Text(
                          'No day data found in this plan.',
                          style: TextStyle(fontFamily: 'ClashGrotesk'),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: keys.map((k) {
                              final dt = _dateFromKey(k);
                              final dayName = dt == null ? '--' : _weekdayShort(dt);

                              final v = daysMap[k];
                              final ids = (v is List) ? v.map((e) => e.toString()).toList() : <String>[];
                              final count = ids.length;

                              final names = <String>[];
                              for (final id in ids) {
                                final item = locationsSnapshot[id];
                                if (item is Map && item['name'] != null) {
                                  names.add(item['name'].toString());
                                }
                              }

                              return Container(
                                margin: EdgeInsets.only(bottom: 10 * s),
                                padding: EdgeInsets.all(12 * s),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6F7FA),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$dayName • ${dt == null ? k : _fullDate(dt)}',
                                      style: TextStyle(
                                        fontFamily: 'ClashGrotesk',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13.5 * s,
                                      ),
                                    ),
                                    SizedBox(height: 6 * s),
                                    Text(
                                      'Locations: $count',
                                      style: TextStyle(
                                        fontFamily: 'ClashGrotesk',
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF6B7280),
                                        fontSize: 12.5 * s,
                                      ),
                                    ),
                                    if (names.isNotEmpty) ...[
                                      SizedBox(height: 6 * s),
                                      Text(
                                        names.join(', '),
                                        style: TextStyle(
                                          fontFamily: 'ClashGrotesk',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5 * s,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                ),

                SizedBox(height: 10 * s),
                const Divider(),
                SizedBox(height: 10 * s),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Supervisor activity (visits)',
                    style: TextStyle(
                      fontFamily: 'ClashGrotesk',
                      fontWeight: FontWeight.w900,
                      fontSize: 14 * s,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                SizedBox(height: 10 * s),

                // ✅ Live visits stream (UPDATED: shelfCondition + stockQty + displayScore, NO image)
                Flexible(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: Fb.db
                        .collection('journeyPlans')
                        .doc(planId)
                        .collection('visits')
                        .orderBy('createdAt', descending: true)
                        .limit(200)
                        .snapshots(),
                    builder: (ctx, snap) {
                      if (snap.hasError) {
                        return Container(
                          padding: EdgeInsets.all(12 * s),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Failed to load visits: ${snap.error}',
                            style: TextStyle(
                              fontFamily: 'ClashGrotesk',
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5 * s,
                              color: const Color(0xFF991B1B),
                            ),
                          ),
                        );
                      }

                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allDocs = snap.data!.docs;

                      // ✅ NO-INDEX filtering
                      final docs = allDocs.where((d) {
                        final m = d.data();
                        return (m['supervisorId'] ?? '').toString() == supId;
                      }).toList(growable: false);

                      if (docs.isEmpty) {
                        return Container(
                          padding: EdgeInsets.all(12 * s),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F7FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'No visits submitted yet.',
                            style: TextStyle(
                              fontFamily: 'ClashGrotesk',
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5 * s,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        );
                      }

                      String _fmtTs(Timestamp? t) {
                        if (t == null) return '--';
                        final dt = t.toDate();
                        return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
                      }

                      int _durationMin(Timestamp? a, Timestamp? b) {
                        if (a == null || b == null) return 0;
                        return b.toDate().difference(a.toDate()).inMinutes;
                      }

                      int? _asInt(dynamic v) {
                        if (v is int) return v;
                        if (v is num) return v.toInt();
                        if (v is String) return int.tryParse(v.trim());
                        return null;
                      }

                      return ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8 * s),
                        itemBuilder: (_, i) {
                          final d = docs[i].data();

                          final stopName = (d['stopName'] ?? '--').toString();
                          final dayKey = (d['dayKey'] ?? '--').toString();
                          final comment = (d['comment'] ?? '').toString();
                          final checkIn = d['checkIn'] as Timestamp?;
                          final checkOut = d['checkOut'] as Timestamp?;
                          final duration = _durationMin(checkIn, checkOut);

                          final formAny = d['form'];
                          final form = (formAny is Map)
                              ? Map<String, dynamic>.from(formAny)
                              : <String, dynamic>{};

                          // ✅ NEW fields
                          final shelfCondition = (form['shelfCondition'] ?? '').toString();
                          final stockQty = _asInt(form['stockQty']);
                          final displayScore = _asInt(form['displayScore']);

                          final hasAnyChip = shelfCondition.trim().isNotEmpty ||
                              stockQty != null ||
                              displayScore != null;

                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F7FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Theme(
                              data: Theme.of(ctx).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                tilePadding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 2 * s),
                                childrenPadding: EdgeInsets.fromLTRB(12 * s, 0, 12 * s, 12 * s),
                                title: Text(
                                  stopName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'ClashGrotesk',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13.5 * s,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                subtitle: Text(
                                  'Day: $dayKey • In: ${_fmtTs(checkIn)} • Out: ${_fmtTs(checkOut)}'
                                  '${duration > 0 ? ' • $duration min' : ''}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'ClashGrotesk',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5 * s,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                                children: [
                                  if (hasAnyChip) ...[
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if (shelfCondition.trim().isNotEmpty)
                                          _visitChip('Shelf: $shelfCondition'),
                                        if (stockQty != null) _visitChip('Stock Qty: $stockQty'),
                                        if (displayScore != null) _visitChip('Display: $displayScore/10'),
                                      ],
                                    ),
                                  ],

                                  if (comment.trim().isNotEmpty) ...[
                                    SizedBox(height: 10 * s),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Comment',
                                        style: TextStyle(
                                          fontFamily: 'ClashGrotesk',
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12.5 * s,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 6 * s),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        comment,
                                        style: TextStyle(
                                          fontFamily: 'ClashGrotesk',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5 * s,
                                          color: const Color(0xFF374151),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                SizedBox(height: 10 * s),
                SizedBox(
                  width: double.infinity,
                  height: 46 * s,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14 * s)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontFamily: 'ClashGrotesk',
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5 * s,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String k, String v, double s) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6 * s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105 * s,
            child: Text(
              '$k:',
              style: TextStyle(
                fontFamily: 'ClashGrotesk',
                fontWeight: FontWeight.w800,
                fontSize: 12.5 * s,
                color: const Color(0xFF111827),
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: TextStyle(
                fontFamily: 'ClashGrotesk',
                fontWeight: FontWeight.w700,
                fontSize: 12.5 * s,
                color: const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _visitChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'ClashGrotesk',
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
          color: Color(0xFF111827),
        ),
      ),
    );
  }

  // ================= CREATE / SAVE PLAN (UPSERT) =================

  Future<void> _createPlan() async {
    setState(() => _error = null);

    if (_selectedSupervisorId == null) {
      setState(() => _error = 'Select supervisor');
      return;
    }

    final days = _daysInRange(_startDate, _endDate);
    if (days.isEmpty) {
      setState(() => _error = 'Invalid date range');
      return;
    }

    final hasAny = days.any((d) => (_dayToLocationIds[_dayKey(d)]?.isNotEmpty ?? false));
    if (!hasAny) {
      setState(() => _error = 'Select at least one location in at least one day');
      return;
    }

    final allSelectedIds = <String>{};
    for (final d in days) {
      allSelectedIds.addAll(_dayToLocationIds[_dayKey(d)] ?? const <String>{});
    }

    final locationById = {for (final l in _locations) l.id: l};
    final missing = allSelectedIds.where((id) => !locationById.containsKey(id)).toList();
    if (missing.isNotEmpty) {
      setState(() => _error = 'Some selected locations not found. Tap refresh.');
      return;
    }

    setState(() => _saving = true);

    try {
      final Map<String, List<String>> daysMap = {};
      for (final d in days) {
        final k = _dayKey(d);
        final ids = (_dayToLocationIds[k] ?? <String>{}).toList()..sort();
        daysMap[k] = ids;
      }

      final locationsSnapshot = <String, dynamic>{
        for (final id in allSelectedIds)
          id: {
            'id': id,
            'name': locationById[id]!.name,
            'lat': locationById[id]!.lat,
            'lng': locationById[id]!.lng,
            'radiusMeters': locationById[id]!.radiusMeters,
          }
      };

      await _upsertPlanForSupervisor(
        supervisorId: _selectedSupervisorId!,
        periodType: _periodType,
        startDate: _startDate,
        endDate: _endDate,
        daysMap: daysMap,
        locationsSnapshot: locationsSnapshot,
      );

      if (!mounted) return;

      if (_periodType == 'weekly') {
        _lastWeeklyDaysMap = daysMap;
        _lastWeeklySupervisorId = _selectedSupervisorId;
        _lastWeeklyStartDate = DateTime(_startDate.year, _startDate.month, _startDate.day);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Weekly plan saved'),
            action: SnackBarAction(
              label: 'COPY TO MONTH',
              onPressed: () => _createMonthlyFromLastWeekly(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan saved')),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _createMonthlyFromLastWeekly() async {
    if (_lastWeeklyDaysMap == null || _lastWeeklySupervisorId == null || _lastWeeklyStartDate == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final start = DateTime(_lastWeeklyStartDate!.year, _lastWeeklyStartDate!.month, _lastWeeklyStartDate!.day);
      final end = start.add(const Duration(days: 29));
      final daysMap = _repeatWeekPatternTo30Days(start: start, weeklyDaysMap: _lastWeeklyDaysMap!);

      final locationById = {for (final l in _locations) l.id: l};
      final allSelectedIds = <String>{};
      for (final v in daysMap.values) {
        allSelectedIds.addAll(v);
      }

      final locationsSnapshot = <String, dynamic>{
        for (final id in allSelectedIds)
          if (locationById.containsKey(id))
            id: {
              'id': id,
              'name': locationById[id]!.name,
              'lat': locationById[id]!.lat,
              'lng': locationById[id]!.lng,
              'radiusMeters': locationById[id]!.radiusMeters,
            }
      };

      _monthlyPrefilledFromWeekly = true;

      await _upsertPlanForSupervisor(
        supervisorId: _lastWeeklySupervisorId!,
        periodType: 'monthly',
        startDate: start,
        endDate: end,
        daysMap: daysMap,
        locationsSnapshot: locationsSnapshot,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Monthly plan created from weekly plan')),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDeletePlan(String planId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Delete plan?',
          style: TextStyle(fontFamily: 'ClashGrotesk', fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'This will delete the plan. Continue?',
          style: TextStyle(fontFamily: 'ClashGrotesk'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'ClashGrotesk')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(fontFamily: 'ClashGrotesk')),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await jrepo.FbJourneyPlanRepo.deletePlan(planId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan deleted')),
      );

      if (_editingPlanId == planId) {
        setState(() {
          _editingPlanId = null;
          _editingSupervisorId = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  // ================= UI HELPERS =================

  Widget _cardShell({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap, {double s = 1}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 8 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: active
              ? const LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)])
              : null,
          color: active ? null : const Color(0xFFEFF2F8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'ClashGrotesk',
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : const Color(0xFF111827),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _locationCard(FbLocation l, bool checked, double s) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * s),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 9 * s,
            height: 92 * s,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              gradient: LinearGradient(
                colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12 * s),
              onTap: () {
                setState(() {
                  final set = _dayToLocationIds.putIfAbsent(_activeDayKey, () => <String>{});
                  if (checked) {
                    set.remove(l.id);
                  } else {
                    set.add(l.id);
                  }
                });
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(12 * s, 10 * s, 12 * s, 10 * s),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.name,
                            style: TextStyle(
                              fontFamily: 'ClashGrotesk',
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                              fontSize: 15 * s,
                            ),
                          ),
                          SizedBox(height: 6 * s),
                          Text(
                            '(${l.lat.toStringAsFixed(6)}, ${l.lng.toStringAsFixed(6)})',
                            style: TextStyle(
                              fontFamily: 'ClashGrotesk',
                              color: const Color(0xFF6B7280),
                              fontSize: 12.5 * s,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4 * s),
                          Text(
                            'Radius: ${l.radiusMeters.toStringAsFixed(0)} m',
                            style: TextStyle(
                              fontFamily: 'ClashGrotesk',
                              color: const Color(0xFF6B7280),
                              fontSize: 12.5 * s,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10 * s),
                    Container(
                      width: 22 * s,
                      height: 22 * s,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: checked ? const Color(0xFF22C55E) : const Color(0xFFE5E7EB),
                      ),
                      child: Icon(
                        checked ? Icons.check : Icons.circle_outlined,
                        size: 14 * s,
                        color: checked ? Colors.white : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390.0;
    final padBottom = MediaQuery.paddingOf(context).bottom;

    final days = _daysInRange(_startDate, _endDate);
    final activeSet = _dayToLocationIds[_activeDayKey] ?? <String>{};
    final activeDate = _dateFromKey(_activeDayKey);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _listenLocations(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16 * s, 10 * s, 16 * s, 24 * s + padBottom),
            children: [
              SizedBox(height: 12 * s),

              // Supervisor dropdown + edit button
              _cardShell(
                child: StreamBuilder<List<FbSupervisorProfile>>(
                  stream: FbSupervisorRepo.watchSupervisors(),
                  builder: (_, snap) {
                    final items = snap.data ?? const <FbSupervisorProfile>[];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedSupervisorId,
                          decoration: const InputDecoration(
                            labelText: 'Select Supervisor',
                            labelStyle: TextStyle(fontFamily: 'ClashGrotesk', fontWeight: FontWeight.w700),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          items: items
                              .map(
                                (sp) => DropdownMenuItem(
                                  value: sp.uid,
                                  child: Text(
                                    '${sp.email} • ${sp.city}',
                                    style: const TextStyle(fontFamily: 'ClashGrotesk'),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _selectedSupervisorId = v),
                        ),
                        SizedBox(height: 10 * s),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: (_selectedSupervisorId == null || _saving)
                                ? null
                                : () => _loadSupervisorPlanIntoEditor(_selectedSupervisorId!),
                            icon: const Icon(Icons.edit),
                            label: const Text(
                              'Edit this supervisor plan',
                              style: TextStyle(fontFamily: 'ClashGrotesk'),
                            ),
                          ),
                        ),

                        if (_editingPlanId != null && _editingSupervisorId == _selectedSupervisorId) ...[
                          SizedBox(height: 8 * s),
                          Text(
                            'Editing existing plan',
                            style: TextStyle(
                              fontFamily: 'ClashGrotesk',
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5 * s,
                              color: const Color(0xFF7F53FD),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),

              SizedBox(height: 12 * s),

              // Plan type + start/end
              _cardShell(
                padding: EdgeInsets.all(10 * s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan type',
                      style: TextStyle(
                        fontFamily: 'ClashGrotesk',
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                        fontSize: 13 * s,
                      ),
                    ),
                    SizedBox(height: 10 * s),

                    Wrap(
                      spacing: 10 * s,
                      runSpacing: 10 * s,
                      children: [
                        _chip('Weekly', _periodType == 'weekly', () {
                          setState(() {
                            _periodType = 'weekly';
                            _monthlyPrefilledFromWeekly = false;
                            _recalcEndDate();
                            _ensureDays();
                          });
                        }, s: s),
                        _chip('Monthly (30 days)', _periodType == 'monthly', () {
                          setState(() {
                            final wasWeekly = _periodType == 'weekly';

                            _periodType = 'monthly';
                            _recalcEndDate();
                            _ensureDays();

                            if (wasWeekly) {
                              _applyWeeklyPatternToMonthly();
                            }
                          });
                        }, s: s),
                        OutlinedButton.icon(
                          onPressed: _pickStartDate,
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            'Start: ${_fullDate(_startDate)}',
                            style: const TextStyle(fontFamily: 'ClashGrotesk'),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 10 * s),
                    Text(
                      'End: ${_fullDate(_endDate)}',
                      style: TextStyle(
                        fontFamily: 'ClashGrotesk',
                        color: const Color(0xFF6B7280),
                        fontSize: 12.5 * s,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12 * s),

              // Day selector + copy day
              _cardShell(
                padding: EdgeInsets.all(10 * s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select day (plan per-day)',
                      style: TextStyle(
                        fontFamily: 'ClashGrotesk',
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        fontSize: 14.5 * s,
                      ),
                    ),
                    SizedBox(height: 10 * s),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(days.length, (i) {
                          final d = days[i];
                          final k = _dayKey(d);
                          return _dayChip(
                            d,
                            k == _activeDayKey,
                            () => setState(() => _activeDayKey = k),
                            s,
                          );
                        }),
                      ),
                    ),

                    SizedBox(height: 10 * s),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 10 * s),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F7FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        activeDate == null
                            ? 'Selected day: --'
                            : 'Selected day: ${_weekdayShort(activeDate)} • ${_fullDate(activeDate)}',
                        style: TextStyle(
                          fontFamily: 'ClashGrotesk',
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5 * s,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),

                    SizedBox(height: 10 * s),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _copyActiveDayToAllDays,
                            icon: const Icon(Icons.copy),
                            label: const Text(
                              'Copy this day → all days',
                              style: TextStyle(fontFamily: 'ClashGrotesk'),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8 * s),
                    Text(
                      'Locations selected for this day: ${activeSet.length}',
                      style: TextStyle(
                        fontFamily: 'ClashGrotesk',
                        color: const Color(0xFF6B7280),
                        fontSize: 12.5 * s,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12 * s),

              // Locations header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select locations (for selected day)',
                      style: TextStyle(
                        fontFamily: 'ClashGrotesk',
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        fontSize: 16 * s,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Reload locations',
                    onPressed: _listenLocations,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              SizedBox(height: 8 * s),

              // Locations list
              if (_loadingLocations)
                Padding(
                  padding: EdgeInsets.only(top: 30 * s, bottom: 10 * s),
                  child: const Center(child: CircularProgressIndicator()),
                )
              else if (_locationError != null)
                _cardShell(
                  child: Text(
                    'Locations error:\n$_locationError',
                    style: const TextStyle(
                      fontFamily: 'ClashGrotesk',
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else if (_locations.isEmpty)
                _cardShell(
                  child: const Text(
                    'No locations found',
                    style: TextStyle(
                      fontFamily: 'ClashGrotesk',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                ..._locations.map((l) {
                  final checked = (_dayToLocationIds[_activeDayKey] ?? <String>{}).contains(l.id);
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12 * s),
                    child: _locationCard(l, checked, s),
                  );
                }),

              if (_error != null) ...[
                SizedBox(height: 6 * s),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontFamily: 'ClashGrotesk',
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],

              SizedBox(height: 12 * s),

              // Save/Create button (upsert)
              SizedBox(
                width: double.infinity,
                height: 50 * s,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _createPlan,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14 * s),
                    ),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save, color: Colors.white),
                  label: Text(
                    _saving ? 'Saving...' : 'Save Journey Plan',
                    style: TextStyle(
                      fontFamily: 'ClashGrotesk',
                      fontWeight: FontWeight.w900,
                      fontSize: 14 * s,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 18 * s),
              const Divider(),
              SizedBox(height: 8 * s),

              Text(
                'Existing plans (latest 30)',
                style: TextStyle(
                  fontFamily: 'ClashGrotesk',
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  fontSize: 16 * s,
                ),
              ),
              SizedBox(height: 10 * s),

              SizedBox(
                height: 300 * s,
                child: _cardShell(
                  padding: EdgeInsets.zero,
                  child: StreamBuilder<List<FbSupervisorProfile>>(
                    stream: FbSupervisorRepo.watchSupervisors(),
                    builder: (context, supSnap) {
                      final supList = supSnap.data ?? const <FbSupervisorProfile>[];
                      final supMap = {for (final sp in supList) sp.uid: sp};

                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: Fb.db
                            .collection('journeyPlans')
                            .orderBy('createdAt', descending: true)
                            .limit(30)
                            .snapshots(),
                        builder: (context, snap) {
                          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

                          final docs = snap.data!.docs;
                          if (docs.isEmpty) {
                            return const Center(
                              child: Text('No plans found.', style: TextStyle(fontFamily: 'ClashGrotesk')),
                            );
                          }

                          int selectedDaysCount(Map<String, dynamic> data) {
                            final days = data['days'];
                            if (days is Map) {
                              int c = 0;
                              days.forEach((_, v) {
                                if (v is List && v.isNotEmpty) c++;
                              });
                              return c;
                            }
                            return (data['selectedDaysCount'] as int?) ?? 0;
                          }

                          return ListView.separated(
                            itemCount: docs.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final d = docs[i];
                              final data = d.data();

                              final supId = (data['supervisorId'] ?? '').toString();
                              final type = (data['periodType'] ?? '').toString();

                              final start = (data['startDate'] as Timestamp?)?.toDate();
                              final end = (data['endDate'] as Timestamp?)?.toDate();

                              final sup = supMap[supId];
                              final supLabel = sup == null ? supId : '${sup.email} • ${sup.city}';

                              final totalDays = (data['daysCount'] as int?) ?? 0;
                              final plannedDays = selectedDaysCount(data);

                              return ListTile(
                                dense: true,
                                onTap: () => _openPlanDetails(planId: d.id, data: data, supMap: supMap),
                                title: Text(
                                  'Supervisor: $supLabel',
                                  style: const TextStyle(
                                    fontFamily: 'ClashGrotesk',
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                subtitle: Text(
                                  '${type.toUpperCase()} • '
                                  '${start == null ? '--' : _fullDate(start)} → ${end == null ? '--' : _fullDate(end)}\n'
                                  'Planned days: $plannedDays / ${totalDays == 0 ? '--' : totalDays}\n'
                                  'Tap to view details',
                                  style: const TextStyle(
                                    fontFamily: 'ClashGrotesk',
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w600,
                                    height: 1.25,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit',
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _loadSupervisorPlanIntoEditor(supId),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _confirmDeletePlan(d.id),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
