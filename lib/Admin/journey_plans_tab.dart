import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Firebase/firebase_services.dart'
    show Fb, FbLocation, FbLocationRepo, FbSupervisorRepo, FbSupervisorProfile;

import 'package:new_amst_flutter/Firebase/fb_journey_plan_repo.dart' as jrepo;



class JourneyPlansManagementTab extends StatefulWidget {
  const JourneyPlansManagementTab({super.key});

  @override
  State<JourneyPlansManagementTab> createState() => _JourneyPlansManagementTabState();
}

/// Backwards compatibility
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

  // keep last created weekly plan data for "Copy to Month" action
  Map<String, List<String>>? _lastWeeklyDaysMap;
  String? _lastWeeklySupervisorId;
  DateTime? _lastWeeklyStartDate;

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

  String _fullDate(DateTime dt) => _dayKey(dt);

  // ================= LABEL HELPERS =================

  static const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  String _weekdayShort(DateTime d) => _wd[(d.weekday - 1).clamp(0, 6)];

  // chip shows DayName + Day# + selectedCount
  Widget _dayChip(DateTime date, bool active, VoidCallback onTap, double s, int dayNumber) {
    final k = _dayKey(date);
    final selectedCount = _dayToLocationIds[k]?.length ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: 8 * s),
        padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 9 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: active
              ? const LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)])
              : null,
          color: active ? null : const Color(0xFFEFF2F8),
          border: Border.all(
            color: selectedCount > 0 && !active ? const Color(0xFF7F53FD).withOpacity(0.35) : Colors.transparent,
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
            SizedBox(width: 8 * s),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 3 * s),
              decoration: BoxDecoration(
                color: active ? Colors.white.withOpacity(0.18) : Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$dayNumber',
                style: TextStyle(
                  fontFamily: 'ClashGrotesk',
                  fontWeight: FontWeight.w900,
                  color: active ? Colors.white : const Color(0xFF7F53FD),
                  fontSize: 11 * s,
                ),
              ),
            ),
            SizedBox(width: 8 * s),
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
      final now = Timestamp.now();

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

      final planRef = await Fb.db.collection('journeyPlans').add({
        'supervisorId': _lastWeeklySupervisorId,
        'periodType': 'monthly',
        'startDate': Timestamp.fromDate(start),
        'endDate': Timestamp.fromDate(end),
        'createdAt': now,
        'days': daysMap,
        'locationsSnapshot': locationsSnapshot,
        'daysCount': 30,
        'selectedDaysCount': daysMap.entries.where((e) => e.value.isNotEmpty).length,
        'copiedFrom': 'weekly',
      });

      final batch = Fb.db.batch();
      for (final entry in daysMap.entries) {
        batch.set(planRef.collection('days').doc(entry.key), {
          'date': entry.key,
          'locationIds': entry.value,
          'updatedAt': now,
        });
      }
      await batch.commit();

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
      (locationsSnapshotAny is Map<String, dynamic>)
          ? locationsSnapshotAny
          : <String, dynamic>{};

  final keys = daysMap.keys.toList()..sort((a, b) => a.compareTo(b));

  // small helper chips (same style family)
  Widget infoChip(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: const Color(0xFF6B7280)),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'ClashGrotesk',
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  // Day card like your location card (gradient spine)
  Widget dayCard({
    required String title,
    required String subtitle,
    required List<String> names,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 9,
            height: names.isEmpty ? 78 : 102,
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'ClashGrotesk',
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'ClashGrotesk',
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                      fontSize: 12.5,
                      height: 1.2,
                    ),
                  ),
                  if (names.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: names.map((n) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F7FA),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            n,
                            style: const TextStyle(
                              fontFamily: 'ClashGrotesk',
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  await showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.35),
    builder: (ctx) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FA),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header (gradient)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  gradient: LinearGradient(
                    colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Plan Details',
                        style: TextStyle(
                          fontFamily: 'ClashGrotesk',
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top white card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Supervisor',
                              style: TextStyle(
                                fontFamily: 'ClashGrotesk',
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              supLabel,
                              style: const TextStyle(
                                fontFamily: 'ClashGrotesk',
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                fontSize: 14.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                infoChip(type.toUpperCase(),
                                    icon: Icons.event_note),
                                infoChip(
                                  start == null ? 'Start: --' : 'Start: ${_fullDate(start)}',
                                  icon: Icons.play_arrow_rounded,
                                ),
                                infoChip(
                                  end == null ? 'End: --' : 'End: ${_fullDate(end)}',
                                  icon: Icons.stop_rounded,
                                ),
                                infoChip(
                                  'Planned: $plannedDays / ${keys.length}',
                                  icon: Icons.check_circle_outline,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'Day wise breakdown',
                        style: TextStyle(
                          fontFamily: 'ClashGrotesk',
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (keys.isEmpty)
                        const Text(
                          'No day data found in this plan.',
                          style: TextStyle(
                            fontFamily: 'ClashGrotesk',
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B7280),
                          ),
                        )
                      else
                        ...keys.map((k) {
                          final dt = _dateFromKey(k);
                          final dayName = dt == null ? '--' : _weekdayShort(dt);

                          final v = daysMap[k];
                          final ids = (v is List)
                              ? v.map((e) => e.toString()).toList()
                              : <String>[];

                          final names = <String>[];
                          for (final id in ids) {
                            final item = locationsSnapshot[id];
                            if (item is Map && item['name'] != null) {
                              names.add(item['name'].toString());
                            }
                          }

                          final title = '$dayName • $k';
                          final subtitle = 'Locations: ${ids.length}';

                          return dayCard(
                            title: title,
                            subtitle: subtitle,
                            names: names,
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),

              // Bottom actions
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontFamily: 'ClashGrotesk',
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontSize: 14,
                      ),
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
      final now = Timestamp.now();

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

      final planRef = await Fb.db.collection('journeyPlans').add({
        'supervisorId': _selectedSupervisorId,
        'periodType': _periodType,
        'startDate': Timestamp.fromDate(DateTime(_startDate.year, _startDate.month, _startDate.day)),
        'endDate': Timestamp.fromDate(DateTime(_endDate.year, _endDate.month, _endDate.day)),
        'createdAt': now,
        'days': daysMap,
        'locationsSnapshot': locationsSnapshot,
        'daysCount': days.length,
        'selectedDaysCount': daysMap.entries.where((e) => e.value.isNotEmpty).length,
      });

      final batch = Fb.db.batch();
      for (final entry in daysMap.entries) {
        batch.set(planRef.collection('days').doc(entry.key), {
          'date': entry.key,
          'locationIds': entry.value,
          'updatedAt': now,
        });
      }
      await batch.commit();

      if (!mounted) return;

      if (_periodType == 'weekly') {
        _lastWeeklyDaysMap = daysMap;
        _lastWeeklySupervisorId = _selectedSupervisorId;
        _lastWeeklyStartDate = DateTime(_startDate.year, _startDate.month, _startDate.day);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Weekly plan created'),
            action: SnackBarAction(
              label: 'COPY TO MONTH',
              onPressed: () => _createMonthlyFromLastWeekly(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journey plan created')),
        );
      }

      setState(() {
        for (final k in daysMap.keys) {
          _dayToLocationIds[k]?.clear();
        }
      });
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
          'This will delete the plan, its stops and visits. Continue?',
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
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
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
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
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

              // Supervisor dropdown
              _cardShell(
                child: StreamBuilder<List<FbSupervisorProfile>>(
  stream: FbSupervisorRepo.watchSupervisors(),
  builder: (_, snap) {
    final items = snap.data ?? const <FbSupervisorProfile>[];
    return DropdownButtonFormField<String>(
      value: _selectedSupervisorId,
      decoration: const InputDecoration(
        labelText: 'Select Supervisor',
        labelStyle: TextStyle(fontFamily: 'ClashGrotesk',fontWeight: FontWeight.w700),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero, // optional (removes extra padding)
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
    );
  },
)

              ),

              SizedBox(height: 12 * s),

              // Plan type + date
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
                    Row(
                      children: [
                        _chip('Weekly', _periodType == 'weekly', () {
                          setState(() {
                            _periodType = 'weekly';
                            _recalcEndDate();
                            _ensureDays();
                          });
                        }, s: s),
                        SizedBox(width: 10 * s),
                        _chip('Monthly (30 days)', _periodType == 'monthly', () {
                          setState(() {
                            _periodType = 'monthly';
                            _recalcEndDate();
                            _ensureDays();
                          });
                        }, s: s),
                        // const Spacer(),
                        // OutlinedButton.icon(
                        //   onPressed: _pickStartDate,
                        //   icon: const Icon(Icons.date_range),
                        //   label: Text(
                        //     'Start: ${_fullDate(_startDate)}',
                        //     style: const TextStyle(fontFamily: 'ClashGrotesk'),
                        //   ),
                        // ),
                      ],
                    ),
                    SizedBox(height: 10 * s),
                    Text(
                      'End date: ${_fullDate(_endDate)}',
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

              // Day selector + copy day action
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
                            i + 1,
                          );
                        }),
                      ),
                    ),

                    // ✅ show complete date for selected day
                    SizedBox(height: 10 * s),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
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
                        ),
                      ],
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

              // Create button
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
                      : const Icon(Icons.add, color: Colors.white),
                  label: Text(
                    _saving ? 'Creating...' : 'Create Journey Plan',
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
                height: 270 * s,
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
                          if (snap.hasError) {
                            return Center(child: Text('Error: ${snap.error}'));
                          }
                          if (!snap.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final docs = snap.data!.docs;
                          if (docs.isEmpty) {
                            return const Center(
                              child: Text(
                                'No plans found.',
                                style: TextStyle(fontFamily: 'ClashGrotesk'),
                              ),
                            );
                          }

                          String short(DateTime? dt) => dt == null ? '--' : _fullDate(dt);

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
                                onTap: () => _openPlanDetails(
                                  planId: d.id,
                                  data: data,
                                  supMap: supMap,
                                ),
                                title: Text(
                                  'Supervisor: $supLabel',
                                  style: const TextStyle(
                                    fontFamily: 'ClashGrotesk',
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                subtitle: Text(
                                  '${type.toUpperCase()} • ${short(start)} → ${short(end)}\n'
                                  'Planned days: $plannedDays / ${totalDays == 0 ? '--' : totalDays}\n'
                                  'Tap to view details',
                                  style: const TextStyle(
                                    fontFamily: 'ClashGrotesk',
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w600,
                                    height: 1.25,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _confirmDeletePlan(d.id),
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
