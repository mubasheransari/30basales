import 'package:flutter/material.dart';
import 'package:new_amst_flutter/Screens/home_screen.dart';
import 'package:new_amst_flutter/Screens/profile_screen.dart' show ProfilePage;
import 'package:new_amst_flutter/Screens/tabbar_screen_history.dart';
import '../Widgets/bottom_bar.dart';



import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ for SystemNavigator.pop()

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _visibleTabs = <BottomTab>[
    BottomTab.home,
    BottomTab.reports,
    BottomTab.profile,
  ];

  BottomTab _tab = BottomTab.home;

  final Map<BottomTab, GlobalKey<NavigatorState>> _navKeys = {
    BottomTab.home: GlobalKey<NavigatorState>(),
    BottomTab.reports: GlobalKey<NavigatorState>(),
    BottomTab.profile: GlobalKey<NavigatorState>(),
  };

  int get _stackIndex {
    final i = _visibleTabs.indexOf(_tab);
    return i >= 0 ? i : 0;
  }

  @override
  void initState() {
    super.initState();
    if (!_visibleTabs.contains(_tab)) _tab = BottomTab.home;
  }

  // ✅ Back handling + themed exit dialog
  Future<bool> _onWillPop() async {
    final nav = _navKeys[_visibleTabs[_stackIndex]]!.currentState!;

    // 1) If current tab has pages, pop them
    if (nav.canPop()) {
      nav.pop();
      return false;
    }

    // 2) If not on home tab, switch to home
    if (_tab != BottomTab.home) {
      setState(() => _tab = BottomTab.home);
      return false;
    }

    // 3) On home root → ask to exit
    final ok = await _showExitDialog(context);
    if (ok == true) {
      SystemNavigator.pop(); // ✅ close the app
    }
    return false; // ✅ prevent default system dialog
  }

  void _setTab(BottomTab t) =>
      setState(() => _tab = _visibleTabs.contains(t) ? t : BottomTab.home);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: IndexedStack(
          index: _stackIndex,
          children: [
            _TabNavigator(
              navKey: _navKeys[BottomTab.home]!,
              initial: const HomeScreen(),
            ),
            _TabNavigator(
              navKey: _navKeys[BottomTab.reports]!,
              initial: HistoryTabsScreen(),
            ),
             _TabNavigator(navKey: _navKeys[BottomTab.profile]!, initial: const ProfilePage()),
          ],
        ),
        bottomNavigationBar: BottomBar(
          active: _visibleTabs[_stackIndex],
          onChanged: _setTab,
        ),
      ),
    );
  }

  // ========================== ✅ Themed Exit Dialog ==========================
  Future<bool?> _showExitDialog(BuildContext context) {
    const grad = LinearGradient(
      colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gradient pill header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: grad,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.exit_to_app_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Exit App',
                      style: TextStyle(
                        fontFamily: 'ClashGrotesk',
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'Are you sure you want to close the app?',
                style: TextStyle(
                  fontFamily: 'ClashGrotesk',
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),

              const Text(
                'You can continue anytime from where you left off.',
                style: TextStyle(
                  fontFamily: 'ClashGrotesk',
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4B5563),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogCtx, false),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Stay',
                        style: TextStyle(
                          fontFamily: 'ClashGrotesk',
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogCtx, true),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Exit',
                        style: TextStyle(
                          fontFamily: 'ClashGrotesk',
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabNavigator extends StatelessWidget {
  const _TabNavigator({required this.navKey, required this.initial});
  final GlobalKey<NavigatorState> navKey;
  final Widget initial;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navKey,
      onGenerateRoute: (settings) =>
          MaterialPageRoute(builder: (_) => initial, settings: settings),
    );
  }
}




// class AppShell extends StatefulWidget {
//   const AppShell({super.key});
//   @override
//   State<AppShell> createState() => _AppShellState();
// }

// class _AppShellState extends State<AppShell> {
//   static const _visibleTabs = <BottomTab>[
//     BottomTab.home,
//     BottomTab.reports,
//   // BottomTab.profile,
//   ];

//   BottomTab _tab = BottomTab.home;

//   final Map<BottomTab, GlobalKey<NavigatorState>> _navKeys = {
//     BottomTab.home: GlobalKey<NavigatorState>(),
//     BottomTab.reports: GlobalKey<NavigatorState>(),
//     //BottomTab.profile: GlobalKey<NavigatorState>(),
//   };

//   int get _stackIndex {
//     final i = _visibleTabs.indexOf(_tab);
//     return i >= 0 ? i : 0; // coerce map/about to home
//   }

//   @override
//   void initState() {
//     super.initState();
//     if (!_visibleTabs.contains(_tab)) _tab = BottomTab.home;
//   }

//   Future<bool> _onWillPop() async {
//     final nav = _navKeys[_visibleTabs[_stackIndex]]!.currentState!;
//     if (nav.canPop()) {
//       nav.pop();
//       return false;
//     }
//     if (_tab != BottomTab.home) {
//       setState(() => _tab = BottomTab.home);
//       return false;
//     }
//     return true;
//   }

//   void _setTab(BottomTab t) =>
//       setState(() => _tab = _visibleTabs.contains(t) ? t : BottomTab.home);

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: Scaffold(
//         backgroundColor: const Color(0xFFF7F8FA),
//         body: IndexedStack(
//           index: _stackIndex,
//           children: [
//             _TabNavigator(navKey: _navKeys[BottomTab.home]!,    initial: const HomeScreen()),
//             _TabNavigator(navKey: _navKeys[BottomTab.reports]!, initial: HistoryTabsScreen()), //AttendanceHistoryScreen()),//ReportHistoryScreen()),
//          //   _TabNavigator(navKey: _navKeys[BottomTab.profile]!, initial: const ProfilePage()),
//           ],
//         ),
//         bottomNavigationBar: BottomBar(
//           active: _visibleTabs[_stackIndex],
//           onChanged: _setTab,
//         ),
//       ),
//     );
//   }
// }

// class _TabNavigator extends StatelessWidget {
//   const _TabNavigator({required this.navKey, required this.initial});
//   final GlobalKey<NavigatorState> navKey;
//   final Widget initial;

//   @override
//   Widget build(BuildContext context) {
//     return Navigator(
//       key: navKey, // important: attach the key to Navigator
//       onGenerateRoute: (settings) =>
//           MaterialPageRoute(builder: (_) => initial, settings: settings),
//     );
//   }
// }

