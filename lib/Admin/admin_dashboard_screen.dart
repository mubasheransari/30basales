import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';
import 'package:new_amst_flutter/Admin/location_management_tab.dart';
import 'package:new_amst_flutter/Admin/supervisor_management_tab.dart';
import 'package:intl/intl.dart';
import 'package:new_amst_flutter/Screens/auth_screen.dart';
import 'journey_plans_tab.dart';




int _createdAtMillis(Map<String, dynamic> data) {
  final v = data['createdAt'];
  if (v is Timestamp) return v.millisecondsSinceEpoch;
  if (v is DateTime) return v.millisecondsSinceEpoch;
  if (v is int) return v;
  if (v is String) return DateTime.tryParse(v)?.millisecondsSinceEpoch ?? 0;
  return 0;
}

/// ✅ Safe time formatter
String _fmtTime(dynamic createdAt) {
  if (createdAt is Timestamp) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toDate());
  }
  if (createdAt is String) {
    final dt = DateTime.tryParse(createdAt);
    if (dt != null) return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }
  return '--';
}

/// ✅ Extract items list from many possible firestore keys (NO hardcoding values)
List<Map<String, dynamic>> _extractOrderItems(Map<String, dynamic> data) {
  final raw = data['items'] ?? data['lines'] ?? data['products'] ?? [];
  if (raw is List) {
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  return const [];
}

/// ✅ Extract qty safely
int _qtyOf(Map<String, dynamic> item) {
  final v = item['qty'] ?? item['quantity'] ?? item['q'] ?? 0;
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// ✅ Extract product name safely
String _nameOf(Map<String, dynamic> item) {
  final v = item['name'] ?? item['title'] ?? item['productName'] ?? '';
  return (v ?? '').toString();
}

/// ✅ Extract SKU safely
String _skuOf(Map<String, dynamic> item) {
  final v = item['sku'] ??
      item['skuNo'] ??
      item['number'] ??
      item['code'] ??
      item['skuNumber'] ??
      '';
  return (v ?? '').toString();
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _index = 0;

  static const _bg = Color(0xFFF6F7FA);

  static const _grad = LinearGradient(
    colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const _titles = [
    'Locations',
    'Supervisor',
    'Attendance',
    'Sales',
    'Journey Plan',
    'Logout',
  ];

  Future<void> _logout() async {
    try {
      final box = GetStorage();
      box.remove('supervisor_loggedIn');
      box.remove('admin_loggedIn');
    } catch (_) {}

    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390.0;
    final title = _titles[_index];

    final Widget body = switch (_index) {
      0 => const LocationManagementTab(),
      1 => const SupervisorManagementTab(),
      2 => const AttendanceTabBlink(),
      3 => const SalesTabBlink(),
      4 => const JourneyPlansManagementTab(),
      5 => const SizedBox.shrink(),
      _ => const LocationManagementTab(),
    };

    return Scaffold(
      backgroundColor: _bg,

      // ✅ Clean gradient header (same style vibe as your Attendance screen)
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(64 * s),
        child: SafeArea(
          bottom: false,
          child: Container(
            margin: EdgeInsets.fromLTRB(12 * s, 10 * s, 12 * s, 8 * s),
            padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s),
            decoration: BoxDecoration(
              gradient: _grad,
              borderRadius: BorderRadius.circular(16 * s),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 16,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
            //   const Icon(Icons.admin_panel_settings, color: Colors.white),
                SizedBox(width: 10 * s),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'ClashGrotesk',
                      fontSize: 18 * s,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                // if (_index != 5)
                //   InkWell(
                //     borderRadius: BorderRadius.circular(14),
                //     onTap: _logout,
                //     child: Container(
                //       padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
                //       decoration: BoxDecoration(
                //         color: Colors.white.withOpacity(0.18),
                //         borderRadius: BorderRadius.circular(14),
                //         border: Border.all(color: Colors.white.withOpacity(0.22)),
                //       ),
                //       child: Row(
                //         children: [
                //           Icon(Icons.logout, color: Colors.white, size: 18 * s),
                //           SizedBox(width: 6 * s),
                //           Text(
                //             'Logout',
                //             style: TextStyle(
                //               fontFamily: 'ClashGrotesk',
                //               fontWeight: FontWeight.w900,
                //               color: Colors.white,
                //               fontSize: 12.5 * s,
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ),
              ],
            ),
          ),
        ),
      ),

      body: body,

      // ✅ Modern pill-like bottom nav holder
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(12 * s, 0, 12 * s, 10 * s),
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              gradient: _grad,
              borderRadius: BorderRadius.circular(18 * s),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: _index,
                onTap: (i) async {
                  if (i == 5) {
                    await _logout();
                    return;
                  }
                  setState(() => _index = i);
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white70,
                selectedLabelStyle: const TextStyle(
                  fontFamily: 'ClashGrotesk',
                  fontWeight: FontWeight.w900,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'ClashGrotesk',
                  fontWeight: FontWeight.w800,
                ),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.location_on_outlined),
                    label: 'Locations',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.supervisor_account_outlined),
                    label: 'Supervisor',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.access_time),
                    label: 'Attendance',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.shopping_cart_outlined),
                    label: 'Sales',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.map_outlined),
                    label: 'Journey Plan',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.logout),
                    label: 'Logout',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================ ATTENDANCE TAB (BLINK) =============================

class AttendanceTabBlink extends StatefulWidget {
  const AttendanceTabBlink({super.key});

  @override
  State<AttendanceTabBlink> createState() => _AttendanceTabBlinkState();
}

class _AttendanceTabBlinkState extends State<AttendanceTabBlink> {
  final Set<String> _known = {};
  final Set<String> _blink = {};

  void _detectNew(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final currentIds = docs.map((d) => d.id).toSet();

    if (_known.isEmpty) {
      _known.addAll(currentIds);
      return;
    }

    final newOnes = currentIds.difference(_known);
    if (newOnes.isNotEmpty) {
      _blink.addAll(newOnes);
      _known.addAll(newOnes);

      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() => _blink.removeAll(newOnes));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390.0;

    final usersStream = FirebaseFirestore.instance.collection('users').snapshots();
    final attendanceStream =
        FirebaseFirestore.instance.collectionGroup('attendance').limit(300).snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: usersStream,
      builder: (context, usersSnap) {
        final Map<String, String> uidToName = {};
        if (usersSnap.hasData) {
          for (final d in usersSnap.data!.docs) {
            final name = (d.data()['name'] ?? '').toString();
            if (name.isNotEmpty) uidToName[d.id] = name;
          }
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: attendanceStream,
          builder: (context, snap) {
            if (snap.hasError) return _ErrorBox(message: snap.error.toString());
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());

            final docs = [...snap.data!.docs];
            docs.sort((a, b) => _createdAtMillis(b.data()).compareTo(_createdAtMillis(a.data())));

            _detectNew(docs);

            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'No attendance records found.',
                  style: TextStyle(fontFamily: 'ClashGrotesk', fontWeight: FontWeight.w800),
                ),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 18 * s),
              itemCount: docs.length,
              separatorBuilder: (_, __) => SizedBox(height: 10 * s),
              itemBuilder: (context, i) {
                final d = docs[i];
                final data = d.data();

                final uid = d.reference.parent.parent?.id ?? 'unknown';
                final userName = uidToName[uid] ?? uid;

                final action = (data['action'] ?? '').toString();
                final dist = (data['distanceMeters'] as num?)?.toDouble();
                final within = (data['withinAllowed'] as bool?) ?? false;
                final lat = (data['lat'] as num?)?.toDouble();
                final lng = (data['lng'] as num?)?.toDouble();

                final timeStr = _fmtTime(data['createdAt']);
                final shouldBlink = _blink.contains(d.id);

                return _BlinkCard(
                  blink: shouldBlink,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12 * s, 10 * s, 12 * s, 10 * s),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // left gradient spine
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
                        SizedBox(width: 10 * s),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$userName • $action',
                                style: TextStyle(
                                  fontFamily: 'ClashGrotesk',
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A),
                                  fontSize: 14.5 * s,
                                ),
                              ),
                              SizedBox(height: 6 * s),
                              Text(
                                'Time: $timeStr\n'
                                'Distance: ${dist?.toStringAsFixed(1) ?? '--'} m (${within ? 'Allowed' : 'Blocked'})\n'
                                'Lat/Lng: ${lat?.toStringAsFixed(6) ?? '--'}, ${lng?.toStringAsFixed(6) ?? '--'}',
                                style: TextStyle(
                                  fontFamily: 'ClashGrotesk',
                                  color: const Color(0xFF374151),
                                  height: 1.25,
                                  fontSize: 12.5 * s,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ============================ SALES TAB (BLINK) =============================

class SalesTabBlink extends StatefulWidget {
  const SalesTabBlink({super.key});

  @override
  State<SalesTabBlink> createState() => _SalesTabBlinkState();
}

class _SalesTabBlinkState extends State<SalesTabBlink> {
  final Set<String> _known = {};
  final Set<String> _blink = {};

  void _detectNew(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final currentIds = docs.map((d) => d.id).toSet();

    if (_known.isEmpty) {
      _known.addAll(currentIds);
      return;
    }

    final newOnes = currentIds.difference(_known);
    if (newOnes.isNotEmpty) {
      _blink.addAll(newOnes);
      _known.addAll(newOnes);

      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() => _blink.removeAll(newOnes));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390.0;

    final usersStream = FirebaseFirestore.instance.collection('users').snapshots();
    final salesStream = FirebaseFirestore.instance.collectionGroup('sales').limit(300).snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: usersStream,
      builder: (context, usersSnap) {
        final Map<String, String> uidToName = {};
        if (usersSnap.hasData) {
          for (final d in usersSnap.data!.docs) {
            final name = (d.data()['name'] ?? '').toString();
            if (name.isNotEmpty) uidToName[d.id] = name;
          }
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: salesStream,
          builder: (context, snap) {
            if (snap.hasError) return _ErrorBox(message: snap.error.toString());
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());

            final docs = [...snap.data!.docs];
            docs.sort((a, b) => _createdAtMillis(b.data()).compareTo(_createdAtMillis(a.data())));

            _detectNew(docs);

            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'No sales records found.',
                  style: TextStyle(fontFamily: 'ClashGrotesk', fontWeight: FontWeight.w800),
                ),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 18 * s),
              itemCount: docs.length,
              separatorBuilder: (_, __) => SizedBox(height: 10 * s),
              itemBuilder: (context, i) {
                final d = docs[i];
                final data = d.data();

                final uid = d.reference.parent.parent?.id ?? 'unknown';
                final userName = uidToName[uid] ?? uid;

                final timeStr = _fmtTime(data['createdAt']);
                final total = (data['total'] ?? data['grandTotal'] ?? data['amount']);

                final items = _extractOrderItems(data);
                final skuCount = items.length;
                final totalQty = items.fold<int>(0, (sum, it) => sum + _qtyOf(it));

                final shouldBlink = _blink.contains(d.id);

                return _BlinkCard(
                  blink: shouldBlink,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.fromLTRB(12 * s, 10 * s, 12 * s, 10 * s),
                      childrenPadding: EdgeInsets.fromLTRB(12 * s, 0, 12 * s, 12 * s),
                      title: Row(
                        children: [
                          // left gradient spine
                          Container(
                            width: 9 * s,
                            height: 44 * s,
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
                          SizedBox(width: 10 * s),
                          Expanded(
                            child: Text(
                              '$userName • Sale',
                              style: TextStyle(
                                fontFamily: 'ClashGrotesk',
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                                fontSize: 14.5 * s,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: EdgeInsets.only(left: (9 + 10) * s),
                        child: Text(
                          'Time: $timeStr\n'
                          'SKUs: $skuCount  •  Qty: $totalQty\n',
                         /// 'Total: ${total ?? '--'}',
                          style: TextStyle(
                            fontFamily: 'ClashGrotesk',
                            color: const Color(0xFF374151),
                            height: 1.25,
                            fontSize: 12.5 * s,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      children: items.isEmpty
                          ? [
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'No items found in this order.',
                                  style: TextStyle(
                                    fontFamily: 'ClashGrotesk',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            ]
                          : items.map((item) {
                              final name = _nameOf(item);
                              final sku = _skuOf(item);
                              final qty = _qtyOf(item);

                              return Padding(
                                padding: EdgeInsets.only(top: 10 * s),
                                child: Container(
                                  padding: EdgeInsets.all(12 * s),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(14 * s),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 16,
                                        color: Color(0xFF0AA2FF),
                                      ),
                                      SizedBox(width: 8 * s),
                                      Expanded(
                                        child: Text(
                                          '${name.isNotEmpty ? name : '—'}'
                                          '${sku.isNotEmpty ? " ($sku)" : ""}\n'
                                          'Qty: $qty',
                                          style: TextStyle(
                                            fontFamily: 'ClashGrotesk',
                                            fontSize: 13 * s,
                                            height: 1.3,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF111827),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ================================ UI =================================

class _BlinkCard extends StatelessWidget {
  final bool blink;
  final Widget child;
  const _BlinkCard({required this.blink, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: blink ? const Color(0xFFE8F7FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: blink ? const Color(0xFF0AA2FF) : Colors.transparent,
          width: blink ? 1 : 0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: child,
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Error:\n$message',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'ClashGrotesk',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

