import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Firebase/firebase_services.dart'
    show Fb, FbLocation, FbLocationRepo, FbSupervisorRepo, FbSupervisorProfile;

import 'package:new_amst_flutter/Firebase/fb_journey_plan_repo.dart' as jrepo;

class JourneyPlansManagementTab extends StatefulWidget {
  const JourneyPlansManagementTab({super.key});

  @override
  State<JourneyPlansManagementTab> createState() =>
      _JourneyPlansManagementTabState();
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

  final Set<String> _selectedLocationIds = {};
  final List<FbLocation> _locations = [];

  bool _loadingLocations = true;
  bool _saving = false;

  String? _error;
  String? _locationError;

  StreamSubscription<List<FbLocation>>? _locationSub;

  @override
  void initState() {
    super.initState();
    _recalcEndDate();
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

  // ================= DATE =================

  void _recalcEndDate() {
    if (_periodType == 'weekly') {
      _endDate = DateTime(_startDate.year, _startDate.month, _startDate.day)
          .add(const Duration(days: 6));
    } else {
      final nextMonth = DateTime(_startDate.year, _startDate.month + 1, 1);
      _endDate = nextMonth.subtract(const Duration(days: 1));
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
    });
  }

  // ================= CREATE PLAN =================

  Future<void> _createPlan() async {
    setState(() => _error = null);

    if (_selectedSupervisorId == null) {
      setState(() => _error = 'Select supervisor');
      return;
    }

    if (_selectedLocationIds.isEmpty) {
      setState(() => _error = 'Select at least one location');
      return;
    }

    final selected = _locations
        .where((l) => _selectedLocationIds.contains(l.id))
        .toList(growable: false);

    if (selected.isEmpty) {
      setState(() => _error = 'Selected locations not found. Tap refresh.');
      return;
    }

    setState(() => _saving = true);

    try {
      await jrepo.FbJourneyPlanRepo.createJourneyPlan(
        supervisorId: _selectedSupervisorId!,
        periodType: _periodType,
        startDate: _startDate,
        endDate: _endDate,
        stops: selected,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Journey plan created')),
      );

      setState(() => _selectedLocationIds.clear());
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
          style:
              TextStyle(fontFamily: 'ClashGrotesk', fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'This will delete the plan, its stops and visits. Continue?',
          style: TextStyle(fontFamily: 'ClashGrotesk'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(fontFamily: 'ClashGrotesk')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(fontFamily: 'ClashGrotesk')),
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

  String _shortDate(DateTime dt) => dt.toIso8601String().substring(0, 10);

  Widget _cardShell({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(12),
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

  // Chips like Attendance screen
  Widget _chip(String label, bool active, VoidCallback onTap, {double s = 1}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 8 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: active
              ? const LinearGradient(
                  colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
                )
              : null,
          color: active ? null : const Color(0xFFEFF2F8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'ClashGrotesk',
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : const Color(0xFF111827),
            fontSize: 13 * s,
          ),
        ),
      ),
    );
  }

  // Location card like attendance card (left gradient spine)
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
                  if (checked) {
                    _selectedLocationIds.remove(l.id);
                  } else {
                    _selectedLocationIds.add(l.id);
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
                        color: checked
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFE5E7EB),
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

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _listenLocations(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16 * s, 10 * s, 16 * s, 24 * s + padBottom),
            children: [
              // Text(
              //   'Journey Plans',
              //   style: TextStyle(
              //     fontFamily: 'ClashGrotesk',
              //     fontSize: 20 * s,
              //     fontWeight: FontWeight.w900,
              //     color: const Color(0xFF0F172A),
              //   ),
              // ),
              SizedBox(height: 12 * s),

              // Supervisor card
              _cardShell(
                child: StreamBuilder<List<FbSupervisorProfile>>(
                  stream: FbSupervisorRepo.watchSupervisors(),
                  builder: (_, snap) {
                    final items = snap.data ?? const <FbSupervisorProfile>[];
                    return DropdownButtonFormField<String>(
                      value: _selectedSupervisorId,
                      decoration: const InputDecoration(
                        labelText: 'Supervisor',
                        border: OutlineInputBorder(),
                      ),
                      items: items
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.uid,
                              child: Text(
                                '${s.name} (${s.city})',
                                style: const TextStyle(fontFamily: 'ClashGrotesk'),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedSupervisorId = v),
                    );
                  },
                ),
              ),

              SizedBox(height: 12 * s),

              // Plan type (chips) + date card
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _chip('Weekly', _periodType == 'weekly', () {
                          setState(() {
                            _periodType = 'weekly';
                            _recalcEndDate();
                          });
                        }, s: s),
                        _chip('Monthly', _periodType == 'monthly', () {
                          setState(() {
                            _periodType = 'monthly';
                            _recalcEndDate();
                          });
                        }, s: s),
                        OutlinedButton.icon(
                          onPressed: _pickStartDate,
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            _shortDate(_startDate),
                            style: const TextStyle(fontFamily: 'ClashGrotesk'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10 * s),
                    Text(
                      'End date auto: ${_shortDate(_endDate)}',
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

              SizedBox(height: 12 * s),

              // Locations header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select locations',
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
                  final checked = _selectedLocationIds.contains(l.id);
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

              // Create button (same clean look)
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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

              // Existing plans list (bounded height inside ListView)
              SizedBox(
                height: 240 * s,
                child: _cardShell(
                  padding: EdgeInsets.zero,
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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

                      String short(DateTime? dt) =>
                          dt == null ? '--' : dt.toIso8601String().substring(0, 10);

                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final d = docs[i];
                          final data = d.data();

                          final supId = (data['supervisorId'] ?? '').toString();
                          final type = (data['periodType'] ?? '').toString();

                          final start =
                              (data['startDate'] as Timestamp?)?.toDate() ??
                                  (data['startAt'] as Timestamp?)?.toDate();
                          final end = (data['endDate'] as Timestamp?)?.toDate() ??
                              (data['endAt'] as Timestamp?)?.toDate();

                          return ListTile(
                            dense: true,
                            title: Text(
                              'Supervisor: $supId',
                              style: const TextStyle(
                                fontFamily: 'ClashGrotesk',
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            subtitle: Text(
                              '${type.toUpperCase()} • ${short(start)} → ${short(end)}',
                              style: const TextStyle(
                                fontFamily: 'ClashGrotesk',
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
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
