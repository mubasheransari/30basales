import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';
import 'package:new_amst_flutter/Admin/location_management_tab.dart';
import 'package:new_amst_flutter/Admin/supervisor_management_tab.dart';
import 'package:intl/intl.dart';
import 'package:new_amst_flutter/Model/products_data.dart';
import 'package:new_amst_flutter/Screens/auth_screen.dart';
import 'journey_plans_tab.dart';

Future<bool> showAdminLogoutDialog(BuildContext context) async {
  final res = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _AdminLogoutDialog(),
  );
  return res ?? false;
}

class _AdminLogoutDialog extends StatelessWidget {
  const _AdminLogoutDialog();

  static const _grad = LinearGradient(
    colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                gradient: _grad,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Logout",
              style: TextStyle(
                fontFamily: 'ClashGrotesk',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Are you sure you want to logout from Admin panel?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'ClashGrotesk',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _DialogOutlineBtn(
                    text: "CANCEL",
                    onTap: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DialogGradientBtn(
                    text: "LOGOUT",
                    onTap: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogGradientBtn extends StatelessWidget {
  const _DialogGradientBtn({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  static const _grad = LinearGradient(
    colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        gradient: _grad,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'ClashGrotesk',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogOutlineBtn extends StatelessWidget {
  const _DialogOutlineBtn({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF7F53FD).withOpacity(0.35),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'ClashGrotesk',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF7F53FD),
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
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
  final v =
      item['sku'] ??
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
    Future<void> _logout() async {
      final ok = await showAdminLogoutDialog(context);
      if (!ok) return;

      try {
        final box = GetStorage();

        // ✅ clear all possible login flags you use
        box.remove('admin_loggedIn');
        box.remove('supervisor_loggedIn');
        box.remove('loggedIn');
        box.remove('block_auth_redirect');
      } catch (_) {}

      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (r) => false,
      );
    }

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
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(12 * s, 0, 12 * s, 10 * s),
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              gradient: _grad,
              borderRadius: BorderRadius.circular(9 * s),
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
                    await _logout(); // ✅ shows popup first
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
                  fontSize: 10
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'ClashGrotesk',
                  fontWeight: FontWeight.w800,
                     fontSize: 10
                //  
                ),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.location_on_outlined),
                    label: ' Locations',
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
                    label: 'Journey',
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


class AttendanceTabBlink extends StatefulWidget {
  const AttendanceTabBlink({super.key});

  @override
  State<AttendanceTabBlink> createState() => _AttendanceTabBlinkState();
}

class _AttendanceTabBlinkState extends State<AttendanceTabBlink> {
  // ========================== Theme (same as your other tabs) ==========================
  static const _bg = Color(0xFFF6F7FA);
  static const _txtDark = Color(0xFF0F172A);
  static const _txtDim = Color(0xFF64748B);

  static const _grad = LinearGradient(
    colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ========================== Blink logic (kept) ==========================
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

  // ========================== UI helpers ==========================
  Widget _cardShell({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _gradIconBox(double s, IconData icon) {
    return Container(
      height: 40 * s,
      width: 40 * s,
      decoration: BoxDecoration(
        gradient: _grad,
        borderRadius: BorderRadius.circular(14 * s),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 8)),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 18 * s),
    );
  }

  Widget _chip(double s, IconData icon, String text,
      {Color? bg, Color? fg, Color? border}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 7 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: bg ?? const Color(0xFFF8FAFC),
        border: Border.all(color: border ?? const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14 * s, color: fg ?? _txtDim),
          SizedBox(width: 6 * s),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'ClashGrotesk',
              fontSize: 11.2 * s,
              fontWeight: FontWeight.w800,
              color: fg ?? _txtDark,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtNum(double v) {
    final s = v.toStringAsFixed(6);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  // ========================== Build ==========================
  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390.0;
    final padBottom = MediaQuery.paddingOf(context).bottom;

    final usersStream = FirebaseFirestore.instance.collection('users').snapshots();
    final attendanceStream = FirebaseFirestore.instance
        .collectionGroup('attendance')
        .limit(300)
        .snapshots();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: usersStream,
          builder: (context, usersSnap) {
            // uid -> name map
            final Map<String, String> uidToName = {};
            if (usersSnap.hasData) {
              for (final d in usersSnap.data!.docs) {
                final name = (d.data()['name'] ?? '').toString().trim();
                if (name.isNotEmpty) uidToName[d.id] = name;
              }
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: attendanceStream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return _ErrorBox(message: snap.error.toString());
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = [...snap.data!.docs];
                docs.sort(
                  (a, b) => _createdAtMillis(b.data()).compareTo(
                    _createdAtMillis(a.data()),
                  ),
                );

                _detectNew(docs);

                // ✅ Top summary + list
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16 * s,
                    12 * s,
                    16 * s,
                    24 * s + padBottom,
                  ),
                  children: [
                    _cardShell(
                      padding: EdgeInsets.all(14 * s),
                      child: Row(
                        children: [
                          _gradIconBox(s, Icons.how_to_reg_rounded),
                          SizedBox(width: 10 * s),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Attendance',
                                  style: TextStyle(
                                    fontFamily: 'ClashGrotesk',
                                    fontSize: 16 * s,
                                    fontWeight: FontWeight.w900,
                                    color: _txtDark,
                                  ),
                                ),
                                SizedBox(height: 4 * s),
                                Text(
                                  'Latest check-ins / check-outs with distance & geo.',
                                  style: TextStyle(
                                    fontFamily: 'ClashGrotesk',
                                    fontSize: 12.2 * s,
                                    fontWeight: FontWeight.w700,
                                    color: _txtDim,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10 * s,
                              vertical: 7 * s,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: const Color(0xFFF1F5F9),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Text(
                              '${docs.length} total',
                              style: TextStyle(
                                fontFamily: 'ClashGrotesk',
                                fontSize: 11.4 * s,
                                fontWeight: FontWeight.w900,
                                color: _txtDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14 * s),

                    if (docs.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 120 * s),
                          child: Text(
                            'No attendance records found.',
                            style: TextStyle(
                              fontFamily: 'ClashGrotesk',
                              fontSize: 13.5 * s,
                              fontWeight: FontWeight.w800,
                              color: _txtDim,
                            ),
                          ),
                        ),
                      )
                    else
                      ...List.generate(docs.length, (i) {
                        final d = docs[i];
                        final data = d.data();

                        final uid = d.reference.parent.parent?.id ?? 'unknown';
                        final userName = uidToName[uid] ?? uid;

                        final action = (data['action'] ?? '').toString().trim();
                        final dist = (data['distanceMeters'] as num?)?.toDouble();
                        final within = (data['withinAllowed'] as bool?) ?? false;
                        final lat = (data['lat'] as num?)?.toDouble();
                        final lng = (data['lng'] as num?)?.toDouble();

                        final timeStr = _fmtTime(data['createdAt']);
                        final shouldBlink = _blink.contains(d.id);

                        final actionSafe = action.isEmpty ? 'action' : action;

                        return Padding(
                          padding: EdgeInsets.only(bottom: 12 * s),
                          child: _BlinkCard(
                            blink: shouldBlink,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18 * s),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x14000000),
                                    blurRadius: 18,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(14 * s),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _gradIconBox(
                                          s,
                                          within
                                              ? Icons.verified_rounded
                                              : Icons.block_rounded,
                                        ),
                                        SizedBox(width: 10 * s),
                                        Expanded(
                                          child: Text(
                                            '$userName • $actionSafe',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'ClashGrotesk',
                                              fontSize: 15.2 * s,
                                              fontWeight: FontWeight.w900,
                                              color: _txtDark,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        _chip(
                                          s,
                                          Icons.access_time_rounded,
                                          timeStr,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12 * s),

                                    Wrap(
                                      spacing: 8 * s,
                                      runSpacing: 8 * s,
                                      children: [
                                        _chip(
                                          s,
                                          Icons.social_distance_rounded,
                                          '${dist?.toStringAsFixed(1) ?? '--'} m',
                                        ),
                                        _chip(
                                          s,
                                          within
                                              ? Icons.check_circle_rounded
                                              : Icons.cancel_rounded,
                                          within ? 'Allowed' : 'Blocked',
                                          bg: within
                                              ? const Color(0xFFECFDF3)
                                              : const Color(0xFFFFF1F2),
                                          fg: within
                                              ? const Color(0xFF027A48)
                                              : const Color(0xFFB42318),
                                          border: within
                                              ? const Color(0xFFABEFC6)
                                              : const Color(0xFFFECACA),
                                        ),
                                        if (lat != null && lng != null)
                                          _chip(
                                            s,
                                            Icons.my_location_rounded,
                                            '${_fmtNum(lat)} , ${_fmtNum(lng)}',
                                          ),
                                      ],
                                    ),

                                    SizedBox(height: 10 * s),

                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12 * s,
                                        vertical: 10 * s,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(16 * s),
                                        border: Border.all(color: const Color(0xFFE5E7EB)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            height: 32 * s,
                                            width: 32 * s,
                                            decoration: BoxDecoration(
                                              gradient: _grad,
                                              borderRadius: BorderRadius.circular(12 * s),
                                            ),
                                            child: Icon(
                                              Icons.info_outline_rounded,
                                              color: Colors.white,
                                              size: 16 * s,
                                            ),
                                          ),
                                          SizedBox(width: 10 * s),
                                          Expanded(
                                            child: Text(
                                              'Time: $timeStr\n'
                                              'Distance: ${dist?.toStringAsFixed(1) ?? '--'} m (${within ? 'Allowed' : 'Blocked'})\n'
                                              'Lat/Lng: ${lat?.toStringAsFixed(6) ?? '--'}, ${lng?.toStringAsFixed(6) ?? '--'}',
                                              style: TextStyle(
                                                fontFamily: 'ClashGrotesk',
                                                color: const Color(0xFF334155),
                                                height: 1.25,
                                                fontSize: 12.3 * s,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ============================ ATTENDANCE TAB (BLINK) =============================

// class AttendanceTabBlink extends StatefulWidget {
//   const AttendanceTabBlink({super.key});

//   @override
//   State<AttendanceTabBlink> createState() => _AttendanceTabBlinkState();
// }

// class _AttendanceTabBlinkState extends State<AttendanceTabBlink> {
//   final Set<String> _known = {};
//   final Set<String> _blink = {};

//   void _detectNew(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
//     final currentIds = docs.map((d) => d.id).toSet();

//     if (_known.isEmpty) {
//       _known.addAll(currentIds);
//       return;
//     }

//     final newOnes = currentIds.difference(_known);
//     if (newOnes.isNotEmpty) {
//       _blink.addAll(newOnes);
//       _known.addAll(newOnes);

//       Future.delayed(const Duration(milliseconds: 800), () {
//         if (!mounted) return;
//         setState(() => _blink.removeAll(newOnes));
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final s = MediaQuery.sizeOf(context).width / 390.0;

//     final usersStream = FirebaseFirestore.instance
//         .collection('users')
//         .snapshots();
//     final attendanceStream = FirebaseFirestore.instance
//         .collectionGroup('attendance')
//         .limit(300)
//         .snapshots();

//     return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//       stream: usersStream,
//       builder: (context, usersSnap) {
//         final Map<String, String> uidToName = {};
//         if (usersSnap.hasData) {
//           for (final d in usersSnap.data!.docs) {
//             final name = (d.data()['name'] ?? '').toString();
//             if (name.isNotEmpty) uidToName[d.id] = name;
//           }
//         }

//         return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//           stream: attendanceStream,
//           builder: (context, snap) {
//             if (snap.hasError) return _ErrorBox(message: snap.error.toString());
//             if (!snap.hasData)
//               return const Center(child: CircularProgressIndicator());

//             final docs = [...snap.data!.docs];
//             docs.sort(
//               (a, b) => _createdAtMillis(
//                 b.data(),
//               ).compareTo(_createdAtMillis(a.data())),
//             );

//             _detectNew(docs);

//             if (docs.isEmpty) {
//               return const Center(
//                 child: Text(
//                   'No attendance records found.',
//                   style: TextStyle(
//                     fontFamily: 'ClashGrotesk',
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//               );
//             }

//             return ListView.separated(
//               padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 18 * s),
//               itemCount: docs.length,
//               separatorBuilder: (_, __) => SizedBox(height: 10 * s),
//               itemBuilder: (context, i) {
//                 final d = docs[i];
//                 final data = d.data();

//                 final uid = d.reference.parent.parent?.id ?? 'unknown';
//                 final userName = uidToName[uid] ?? uid;

//                 final action = (data['action'] ?? '').toString();
//                 final dist = (data['distanceMeters'] as num?)?.toDouble();
//                 final within = (data['withinAllowed'] as bool?) ?? false;
//                 final lat = (data['lat'] as num?)?.toDouble();
//                 final lng = (data['lng'] as num?)?.toDouble();

//                 final timeStr = _fmtTime(data['createdAt']);
//                 final shouldBlink = _blink.contains(d.id);

//                 return _BlinkCard(
//                   blink: shouldBlink,
//                   child: Padding(
//                     padding: EdgeInsets.fromLTRB(
//                       12 * s,
//                       10 * s,
//                       12 * s,
//                       10 * s,
//                     ),
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // left gradient spine
//                         Container(
//                           width: 9 * s,
//                           height: 92 * s,
//                           decoration: const BoxDecoration(
//                             borderRadius: BorderRadius.only(
//                               topLeft: Radius.circular(12),
//                               bottomLeft: Radius.circular(12),
//                             ),
//                             gradient: LinearGradient(
//                               colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
//                               begin: Alignment.topCenter,
//                               end: Alignment.bottomCenter,
//                             ),
//                           ),
//                         ),
//                         SizedBox(width: 10 * s),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 '$userName • $action',
//                                 style: TextStyle(
//                                   fontFamily: 'ClashGrotesk',
//                                   fontWeight: FontWeight.w900,
//                                   color: const Color(0xFF0F172A),
//                                   fontSize: 14.5 * s,
//                                 ),
//                               ),
//                               SizedBox(height: 6 * s),
//                               Text(
//                                 'Time: $timeStr\n'
//                                 'Distance: ${dist?.toStringAsFixed(1) ?? '--'} m (${within ? 'Allowed' : 'Blocked'})\n'
//                                 'Lat/Lng: ${lat?.toStringAsFixed(6) ?? '--'}, ${lng?.toStringAsFixed(6) ?? '--'}',
//                                 style: TextStyle(
//                                   fontFamily: 'ClashGrotesk',
//                                   color: const Color(0xFF374151),
//                                   height: 1.25,
//                                   fontSize: 12.5 * s,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             );
//           },
//         );
//       },
//     );
//   }
// }


class SalesTabBlink extends StatefulWidget {
  const SalesTabBlink({super.key});

  @override
  State<SalesTabBlink> createState() => _SalesTabBlinkState();
}

class _SalesTabBlinkState extends State<SalesTabBlink> {
  final Set<String> _known = {};
  final Set<String> _blink = {};

  // ---- per_kg_ltr lookup caches ----
  late final Map<String, double> _perKgById;
  late final Map<String, double> _perKgByNameBrand;

  static const LinearGradient _kGrad = LinearGradient(
    colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void initState() {
    super.initState();
    _buildPerKgLookups();
  }

  void _buildPerKgLookups() {
    final byId = <String, double>{};
    final byNameBrand = <String, double>{};

    for (final p in kTeaProducts) {
      final id = (p['id'] ?? '').toString().trim();
      final name = (p['name'] ?? p['item_name'] ?? '').toString().trim();
      final brand = (p['brand'] ?? '').toString().trim();
      final per = _toDouble(p['per_kg_ltr']);
      if (per <= 0) continue;

      if (id.isNotEmpty) byId[id] = per;
      if (name.isNotEmpty || brand.isNotEmpty) {
        byNameBrand['$name|$brand'] = per;
      }
    }

    _perKgById = byId;
    _perKgByNameBrand = byNameBrand;
  }

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

      Future.delayed(const Duration(milliseconds: 850), () {
        if (!mounted) return;
        setState(() => _blink.removeAll(newOnes));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390.0;

    final usersStream = FirebaseFirestore.instance.collection('users').snapshots();
    final salesStream =
        FirebaseFirestore.instance.collectionGroup('sales').limit(300).snapshots();

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
            if (snap.hasError) return _ErrorBoxModern(message: snap.error.toString());
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = [...snap.data!.docs];
            docs.sort(
              (a, b) => _createdAtMillis(b.data()).compareTo(_createdAtMillis(a.data())),
            );

            _detectNew(docs);

            if (docs.isEmpty) {
              return _EmptyModern(
                scale: s,
                title: 'No sales found',
                subtitle: 'Sales will appear here once orders start coming in.',
                icon: Icons.shopping_cart_outlined,
              );
            }

            return ListView.separated(
              padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 18 * s),
              itemCount: docs.length,
              separatorBuilder: (_, __) => SizedBox(height: 12 * s),
              itemBuilder: (context, i) {
                final d = docs[i];
                final data = d.data();

                final uid = d.reference.parent.parent?.id ?? 'unknown';
                final userName = uidToName[uid] ?? uid;

                final timeStr = _fmtTime(data['createdAt']);
                final items = _extractOrderItems(data);

                final skuCount = items.length;
                final totalQty = items.fold<int>(0, (sum, it) => sum + _qtyOf(it));
                final totalWeight = _calcOrderTotalWeight(items);

                final shouldBlink = _blink.contains(d.id);

                return _ModernBlinkCard(
                  blink: shouldBlink,
                  scale: s,
                  child: _SaleExpandableCard(
                    scale: s,
                    gradient: _kGrad,
                    userName: userName,
                    timeStr: timeStr,
                    skuCount: skuCount,
                    totalQty: totalQty,
                    totalWeight: totalWeight,
                    items: items,
                    itemBuilder: (item) {
                      final name = _nameOf(item);
                      final sku = _skuOf(item);
                      final qty = _qtyOf(item);
                      final w = _calcItemWeight(item);

                      return _SaleItemTile(
                        scale: s,
                        gradient: _kGrad,
                        name: name,
                        sku: sku,
                        qty: qty,
                        weight: w,
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ------------------ Weight helpers ------------------

  double _calcOrderTotalWeight(List<Map<String, dynamic>> items) {
    double sum = 0.0;
    for (final it in items) {
      sum += _calcItemWeight(it);
    }
    return sum;
  }

  double _calcItemWeight(Map<String, dynamic> item) {
    final qty = _qtyOf(item);
    if (qty <= 0) return 0.0;

    final id = (item['itemId'] ?? item['skuId'] ?? item['id'] ?? '')
        .toString()
        .trim();
    final name = _nameOf(item).trim();
    final brand = (item['brand'] ?? '').toString().trim();

    final perKg = _resolvePerKg(itemId: id, name: name, brand: brand);
    if (perKg <= 0) return 0.0;

    return perKg * qty;
  }

  double _resolvePerKg({
    required String itemId,
    required String name,
    required String brand,
  }) {
    if (itemId.isNotEmpty && _perKgById.containsKey(itemId)) {
      return _perKgById[itemId]!;
    }
    return _perKgByNameBrand['$name|$brand'] ?? 0.0;
  }

  // ------------------ Existing helpers (keep yours if already in file) ------------------

  int _createdAtMillis(Map<String, dynamic> data) {
    final v = data['createdAt'];
    if (v is Timestamp) return v.millisecondsSinceEpoch;
    if (v is DateTime) return v.millisecondsSinceEpoch;
    if (v is int) return v;
    if (v is String) return DateTime.tryParse(v)?.millisecondsSinceEpoch ?? 0;
    return 0;
  }

  String _fmtTime(dynamic createdAt) {
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (createdAt is String) {
      final dt = DateTime.tryParse(createdAt);
      if (dt != null) {
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }
    return '--';
  }

  List<Map<String, dynamic>> _extractOrderItems(Map<String, dynamic> data) {
    final v = data['items'] ?? data['lines'] ?? data['orderItems'];
    if (v is List) {
      return v.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return const [];
  }

  String _nameOf(Map<String, dynamic> item) {
    return (item['name'] ?? item['productName'] ?? item['item_name'] ?? '').toString();
  }

  String _skuOf(Map<String, dynamic> item) {
    return (item['sku'] ?? item['skuCode'] ?? item['code'] ?? '').toString();
  }

  int _qtyOf(Map<String, dynamic> item) {
    final v = item['qty'] ?? item['quantity'] ?? item['q'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? 0;
    return 0;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim()) ?? 0.0;
    return 0.0;
  }
}

// ======================= Modern UI Widgets =======================

class _ModernBlinkCard extends StatelessWidget {
  const _ModernBlinkCard({
    required this.blink,
    required this.child,
    required this.scale,
  });

  final bool blink;
  final Widget child;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18 * scale),
        color: Colors.white,
        border: Border.all(
          color: blink ? const Color(0xFF0AA2FF) : const Color(0xFFE5E7EB),
          width: blink ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(blink ? 0.10 : 0.06),
            blurRadius: blink ? 20 : 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18 * scale),
        child: child,
      ),
    );
  }
}

class _SaleExpandableCard extends StatelessWidget {
  const _SaleExpandableCard({
    required this.scale,
    required this.gradient,
    required this.userName,
    required this.timeStr,
    required this.skuCount,
    required this.totalQty,
    required this.totalWeight,
    required this.items,
    required this.itemBuilder,
  });

  final double scale;
  final LinearGradient gradient;
  final String userName;
  final String timeStr;
  final int skuCount;
  final int totalQty;
  final double totalWeight;
  final List<Map<String, dynamic>> items;
  final Widget Function(Map<String, dynamic>) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.fromLTRB(14 * scale, 12 * scale, 14 * scale, 12 * scale),
        childrenPadding: EdgeInsets.fromLTRB(14 * scale, 0, 14 * scale, 14 * scale),
        collapsedIconColor: const Color(0xFF475569),
        iconColor: const Color(0xFF475569),

        title: Row(
          children: [
            _GradIcon(scale: scale, gradient: gradient, icon: Icons.receipt_long_rounded),
            SizedBox(width: 10 * scale),
            Expanded(
              child: Text(
                '$userName • Sale',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'ClashGrotesk',
                  fontSize: 14.8 * scale,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            SizedBox(width: 8 * scale),
            _Pill(
              scale: scale,
              text: timeStr,
              icon: Icons.access_time_rounded,
            ),
          ],
        ),

        subtitle: Padding(
          padding: EdgeInsets.only(top: 10 * scale),
          child: Wrap(
            spacing: 8 * scale,
            runSpacing: 8 * scale,
            children: [
              _MetricChip(scale: scale, label: 'SKUs', value: '$skuCount', icon: Icons.category_outlined),
              _MetricChip(scale: scale, label: 'Qty', value: '$totalQty', icon: Icons.shopping_bag_outlined),
              _MetricChip(
                scale: scale,
                label: 'Weight',
                value: '${totalWeight.toStringAsFixed(2)} KG',
                icon: Icons.scale_outlined,
              ),
            ],
          ),
        ),

        children: items.isEmpty
            ? [
                Padding(
                  padding: EdgeInsets.only(top: 10 * scale),
                  child: _EmptyInline(scale: scale),
                ),
              ]
            : [
                SizedBox(height: 10 * scale),
                ...items.map((it) => Padding(
                      padding: EdgeInsets.only(top: 10 * scale),
                      child: itemBuilder(it),
                    )),
              ],
      ),
    );
  }
}

class _SaleItemTile extends StatelessWidget {
  const _SaleItemTile({
    required this.scale,
    required this.gradient,
    required this.name,
    required this.sku,
    required this.qty,
    required this.weight,
  });

  final double scale;
  final LinearGradient gradient;
  final String name;
  final String sku;
  final int qty;
  final double weight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GradIcon(scale: scale, gradient: gradient, icon: Icons.shopping_bag_rounded, size: 18),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : '—',
                  style: TextStyle(
                    fontFamily: 'ClashGrotesk',
                    fontSize: 13.5 * scale,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                if (sku.trim().isNotEmpty) ...[
                  SizedBox(height: 2 * scale),
                  Text(
                    sku,
                    style: TextStyle(
                      fontFamily: 'ClashGrotesk',
                      fontSize: 11.5 * scale,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
                SizedBox(height: 8 * scale),
                Wrap(
                  spacing: 8 * scale,
                  runSpacing: 8 * scale,
                  children: [
                    _MiniChip(scale: scale, label: 'Qty', value: '$qty'),
                    if (weight > 0) _MiniChip(scale: scale, label: 'Weight', value: '${weight.toStringAsFixed(2)} KG'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradIcon extends StatelessWidget {
  const _GradIcon({
    required this.scale,
    required this.gradient,
    required this.icon,
    this.size = 20,
  });

  final double scale;
  final LinearGradient gradient;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38 * scale,
      width: 38 * scale,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14 * scale),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 8)),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * scale),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.scale,
    required this.text,
    required this.icon,
  });

  final double scale;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 7 * scale),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14 * scale, color: const Color(0xFF64748B)),
          SizedBox(width: 6 * scale),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'ClashGrotesk',
              fontSize: 11.2 * scale,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.scale,
    required this.label,
    required this.value,
    required this.icon,
  });

  final double scale;
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 8 * scale),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFF1F5F9),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15 * scale, color: const Color(0xFF475569)),
          SizedBox(width: 7 * scale),
          Text(
            '$label:',
            style: TextStyle(
              fontFamily: 'ClashGrotesk',
              fontSize: 11.2 * scale,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF64748B),
            ),
          ),
          SizedBox(width: 6 * scale),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'ClashGrotesk',
              fontSize: 11.8 * scale,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.scale,
    required this.label,
    required this.value,
  });

  final double scale;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontFamily: 'ClashGrotesk',
          fontSize: 11 * scale,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  const _EmptyInline({required this.scale});
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14 * scale),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18 * scale, color: const Color(0xFF64748B)),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Text(
              'No items found in this order.',
              style: TextStyle(
                fontFamily: 'ClashGrotesk',
                fontWeight: FontWeight.w800,
                fontSize: 12.5 * scale,
                color: const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyModern extends StatelessWidget {
  const _EmptyModern({
    required this.scale,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final double scale;
  final String title;
  final String subtitle;
  final IconData icon;

  static const LinearGradient _kGrad = LinearGradient(
    colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(16 * scale),
        padding: EdgeInsets.all(18 * scale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18 * scale),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 10)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 56 * scale,
              width: 56 * scale,
              decoration: BoxDecoration(
                gradient: _kGrad,
                borderRadius: BorderRadius.circular(18 * scale),
              ),
              child: Icon(icon, color: Colors.white, size: 28 * scale),
            ),
            SizedBox(height: 12 * scale),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'ClashGrotesk',
                fontSize: 16 * scale,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 6 * scale),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'ClashGrotesk',
                fontSize: 12.5 * scale,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBoxModern extends StatelessWidget {
  const _ErrorBoxModern({required this.message});
  final String message;

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
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }
}


// class SalesTabBlink extends StatefulWidget {
//   const SalesTabBlink({super.key});

//   @override
//   State<SalesTabBlink> createState() => _SalesTabBlinkState();
// }

// class _SalesTabBlinkState extends State<SalesTabBlink> {
//   final Set<String> _known = {};
//   final Set<String> _blink = {};

//   // ---- per_kg_ltr lookup caches ----
//   late final Map<String, double> _perKgById;
//   late final Map<String, double> _perKgByNameBrand;

//   @override
//   void initState() {
//     super.initState();
//     _buildPerKgLookups();
//   }

//   void _buildPerKgLookups() {
//     final byId = <String, double>{};
//     final byNameBrand = <String, double>{};

//     for (final p in kTeaProducts) {
//       final id = (p['id'] ?? '').toString().trim();
//       final name = (p['name'] ?? p['item_name'] ?? '').toString().trim();
//       final brand = (p['brand'] ?? '').toString().trim();
//       final per = _toDouble(p['per_kg_ltr']);
//       if (per <= 0) continue;

//       if (id.isNotEmpty) byId[id] = per;
//       if (name.isNotEmpty || brand.isNotEmpty) {
//         byNameBrand['$name|$brand'] = per;
//       }
//     }

//     _perKgById = byId;
//     _perKgByNameBrand = byNameBrand;
//   }

//   void _detectNew(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
//     final currentIds = docs.map((d) => d.id).toSet();

//     if (_known.isEmpty) {
//       _known.addAll(currentIds);
//       return;
//     }

//     final newOnes = currentIds.difference(_known);
//     if (newOnes.isNotEmpty) {
//       _blink.addAll(newOnes);
//       _known.addAll(newOnes);

//       Future.delayed(const Duration(milliseconds: 800), () {
//         if (!mounted) return;
//         setState(() => _blink.removeAll(newOnes));
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final s = MediaQuery.sizeOf(context).width / 390.0;

//     final usersStream = FirebaseFirestore.instance.collection('users').snapshots();
//     final salesStream = FirebaseFirestore.instance.collectionGroup('sales').limit(300).snapshots();

//     return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//       stream: usersStream,
//       builder: (context, usersSnap) {
//         final Map<String, String> uidToName = {};
//         if (usersSnap.hasData) {
//           for (final d in usersSnap.data!.docs) {
//             final name = (d.data()['name'] ?? '').toString();
//             if (name.isNotEmpty) uidToName[d.id] = name;
//           }
//         }

//         return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//           stream: salesStream,
//           builder: (context, snap) {
//             if (snap.hasError) return _ErrorBox(message: snap.error.toString());
//             if (!snap.hasData) return const Center(child: CircularProgressIndicator());

//             final docs = [...snap.data!.docs];
//             docs.sort(
//               (a, b) => _createdAtMillis(b.data()).compareTo(_createdAtMillis(a.data())),
//             );

//             _detectNew(docs);

//             if (docs.isEmpty) {
//               return const Center(
//                 child: Text(
//                   'No sales records found.',
//                   style: TextStyle(
//                     fontFamily: 'ClashGrotesk',
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//               );
//             }

//             return ListView.separated(
//               padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 18 * s),
//               itemCount: docs.length,
//               separatorBuilder: (_, __) => SizedBox(height: 10 * s),
//               itemBuilder: (context, i) {
//                 final d = docs[i];
//                 final data = d.data();

//                 final uid = d.reference.parent.parent?.id ?? 'unknown';
//                 final userName = uidToName[uid] ?? uid;

//                 final timeStr = _fmtTime(data['createdAt']);
//                 final total = (data['total'] ?? data['grandTotal'] ?? data['amount']);

//                 final items = _extractOrderItems(data);
//                 final skuCount = items.length;
//                 final totalQty = items.fold<int>(0, (sum, it) => sum + _qtyOf(it));

//                 // ✅ Compute weights
//                 final double totalWeight = _calcOrderTotalWeight(items);

//                 final shouldBlink = _blink.contains(d.id);

//                 return _BlinkCard(
//                   blink: shouldBlink,
//                   child: Theme(
//                     data: Theme.of(context).copyWith(
//                       dividerColor: Colors.transparent,
//                       splashColor: Colors.transparent,
//                       highlightColor: Colors.transparent,
//                     ),
//                     child: ExpansionTile(
//                       tilePadding: EdgeInsets.fromLTRB(12 * s, 10 * s, 12 * s, 10 * s),
//                       childrenPadding: EdgeInsets.fromLTRB(12 * s, 0, 12 * s, 12 * s),
//                       title: Row(
//                         children: [
//                           // left gradient spine
//                           Container(
//                             width: 9 * s,
//                             height: 44 * s,
//                             decoration: const BoxDecoration(
//                               borderRadius: BorderRadius.only(
//                                 topLeft: Radius.circular(12),
//                                 bottomLeft: Radius.circular(12),
//                               ),
//                               gradient: LinearGradient(
//                                 colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
//                                 begin: Alignment.topCenter,
//                                 end: Alignment.bottomCenter,
//                               ),
//                             ),
//                           ),
//                           SizedBox(width: 10 * s),
//                           Expanded(
//                             child: Text(
//                               '$userName • Sale',
//                               style: TextStyle(
//                                 fontFamily: 'ClashGrotesk',
//                                 fontWeight: FontWeight.w900,
//                                 color: const Color(0xFF0F172A),
//                                 fontSize: 14.5 * s,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       subtitle: Padding(
//                         padding: EdgeInsets.only(left: (9 + 10) * s),
//                         child: Text(
//                           'Time: $timeStr\n'
//                           'SKUs: $skuCount  •  Qty: $totalQty  •  Weight: ${totalWeight.toStringAsFixed(2)} KG\n',
//                           // 'Total: ${total ?? '--'}',
//                           style: TextStyle(
//                             fontFamily: 'ClashGrotesk',
//                             color: const Color(0xFF374151),
//                             height: 1.25,
//                             fontSize: 12.5 * s,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                       children: items.isEmpty
//                           ? [
//                               const Padding(
//                                 padding: EdgeInsets.only(top: 8),
//                                 child: Text(
//                                   'No items found in this order.',
//                                   style: TextStyle(
//                                     fontFamily: 'ClashGrotesk',
//                                     fontSize: 13,
//                                     fontWeight: FontWeight.w700,
//                                   ),
//                                 ),
//                               ),
//                             ]
//                           : items.map((item) {
//                               final name = _nameOf(item);
//                               final sku = _skuOf(item);
//                               final qty = _qtyOf(item);

//                               // ✅ per item weight
//                               final w = _calcItemWeight(item);

//                               return Padding(
//                                 padding: EdgeInsets.only(top: 10 * s),
//                                 child: Container(
//                                   padding: EdgeInsets.all(12 * s),
//                                   decoration: BoxDecoration(
//                                     color: const Color(0xFFF3F4F6),
//                                     borderRadius: BorderRadius.circular(14 * s),
//                                   ),
//                                   child: Row(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       const Icon(
//                                         Icons.shopping_bag_outlined,
//                                         size: 16,
//                                         color: Color(0xFF0AA2FF),
//                                       ),
//                                       SizedBox(width: 8 * s),
//                                       Expanded(
//                                         child: Text(
//                                           '${name.isNotEmpty ? name : '—'}'
//                                           '${sku.isNotEmpty ? " ($sku)" : ""}\n'
//                                           'Qty: $qty'
//                                           '${w > 0 ? "  •  Weight: ${w.toStringAsFixed(2)} KG" : ""}',
//                                           style: TextStyle(
//                                             fontFamily: 'ClashGrotesk',
//                                             fontSize: 13 * s,
//                                             height: 1.3,
//                                             fontWeight: FontWeight.w700,
//                                             color: const Color(0xFF111827),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             }).toList(),
//                     ),
//                   ),
//                 );
//               },
//             );
//           },
//         );
//       },
//     );
//   }

//   // ------------------ Weight helpers ------------------

//   double _calcOrderTotalWeight(List<Map<String, dynamic>> items) {
//     double sum = 0.0;
//     for (final it in items) {
//       sum += _calcItemWeight(it);
//     }
//     return sum;
//   }

//   double _calcItemWeight(Map<String, dynamic> item) {
//     final qty = _qtyOf(item);
//     if (qty <= 0) return 0.0;

//     final id = (item['itemId'] ?? item['skuId'] ?? item['id'] ?? '').toString().trim();
//     final name = _nameOf(item).trim();
//     final brand = (item['brand'] ?? '').toString().trim();

//     final perKg = _resolvePerKg(itemId: id, name: name, brand: brand);
//     if (perKg <= 0) return 0.0;

//     return perKg * qty;
//   }

//   double _resolvePerKg({required String itemId, required String name, required String brand}) {
//     if (itemId.isNotEmpty && _perKgById.containsKey(itemId)) {
//       return _perKgById[itemId]!;
//     }
//     return _perKgByNameBrand['$name|$brand'] ?? 0.0;
//   }

//   // ------------------ Existing helpers you already have ------------------
//   // Keep your existing versions if they already exist in the file.
//   // I’m including safe fallbacks here so this file compiles.

//   int _createdAtMillis(Map<String, dynamic> data) {
//     final v = data['createdAt'];
//     if (v is Timestamp) return v.millisecondsSinceEpoch;
//     if (v is DateTime) return v.millisecondsSinceEpoch;
//     if (v is int) return v;
//     if (v is String) return DateTime.tryParse(v)?.millisecondsSinceEpoch ?? 0;
//     return 0;
//   }

//   String _fmtTime(dynamic createdAt) {
//     if (createdAt is Timestamp) {
//       final dt = createdAt.toDate();
//       return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
//           '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
//     }
//     if (createdAt is String) {
//       final dt = DateTime.tryParse(createdAt);
//       if (dt != null) {
//         return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
//             '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
//       }
//     }
//     return '--';
//   }

//   List<Map<String, dynamic>> _extractOrderItems(Map<String, dynamic> data) {
//     final v = data['items'] ?? data['lines'] ?? data['orderItems'];
//     if (v is List) {
//       return v.map((e) => Map<String, dynamic>.from(e as Map)).toList();
//     }
//     return const [];
//   }

//   String _nameOf(Map<String, dynamic> item) {
//     return (item['name'] ?? item['productName'] ?? item['item_name'] ?? '').toString();
//   }

//   String _skuOf(Map<String, dynamic> item) {
//     return (item['sku'] ?? item['skuCode'] ?? item['code'] ?? '').toString();
//   }

//   int _qtyOf(Map<String, dynamic> item) {
//     final v = item['qty'] ?? item['quantity'] ?? item['q'];
//     if (v is int) return v;
//     if (v is num) return v.toInt();
//     if (v is String) return int.tryParse(v.trim()) ?? 0;
//     return 0;
//   }

//   double _toDouble(dynamic v) {
//     if (v == null) return 0.0;
//     if (v is num) return v.toDouble();
//     if (v is String) return double.tryParse(v.trim()) ?? 0.0;
//     return 0.0;
//   }
// }

// ------------------ Your existing widgets ------------------
// Keep your current implementations if already defined elsewhere.

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(
          fontFamily: 'ClashGrotesk',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BlinkCard extends StatelessWidget {
  final bool blink;
  final Widget child;

  const _BlinkCard({required this.blink, required this.child});

  @override
  Widget build(BuildContext context) {
    // If you already have blinking animation logic, keep it.
    // This fallback just returns the child.
    return child;
  }
}

/*
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

    final usersStream = FirebaseFirestore.instance
        .collection('users')
        .snapshots();
    final salesStream = FirebaseFirestore.instance
        .collectionGroup('sales')
        .limit(300)
        .snapshots();

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
            if (!snap.hasData)
              return const Center(child: CircularProgressIndicator());

            final docs = [...snap.data!.docs];
            docs.sort(
              (a, b) => _createdAtMillis(
                b.data(),
              ).compareTo(_createdAtMillis(a.data())),
            );

            _detectNew(docs);

            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'No sales records found.',
                  style: TextStyle(
                    fontFamily: 'ClashGrotesk',
                    fontWeight: FontWeight.w800,
                  ),
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
                final total =
                    (data['total'] ?? data['grandTotal'] ?? data['amount']);

                final items = _extractOrderItems(data);
                final skuCount = items.length;
                final totalQty = items.fold<int>(
                  0,
                  (sum, it) => sum + _qtyOf(it),
                );

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
                      tilePadding: EdgeInsets.fromLTRB(
                        12 * s,
                        10 * s,
                        12 * s,
                        10 * s,
                      ),
                      childrenPadding: EdgeInsets.fromLTRB(
                        12 * s,
                        0,
                        12 * s,
                        12 * s,
                      ),
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
                              ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
}*/


// class _BlinkCard extends StatelessWidget {
//   final bool blink;
//   final Widget child;
//   const _BlinkCard({required this.blink, required this.child});

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       decoration: BoxDecoration(
//         color: blink ? const Color(0xFFE8F7FF) : Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: const [
//           BoxShadow(
//             color: Color(0x12000000),
//             blurRadius: 10,
//             offset: Offset(0, 6),
//           ),
//         ],
//         border: Border.all(
//           color: blink ? const Color(0xFF0AA2FF) : Colors.transparent,
//           width: blink ? 1 : 0,
//         ),
//       ),
//       child: ClipRRect(borderRadius: BorderRadius.circular(14), child: child),
//     );
//   }
// }

// class _ErrorBox extends StatelessWidget {
//   final String message;
//   const _ErrorBox({required this.message});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Text(
//           'Error:\n$message',
//           textAlign: TextAlign.center,
//           style: const TextStyle(
//             fontFamily: 'ClashGrotesk',
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),
//     );
//   }
// }
