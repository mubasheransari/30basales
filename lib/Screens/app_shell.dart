import 'package:flutter/material.dart';
import 'package:new_amst_flutter/Screens/home_screen.dart';
import 'package:new_amst_flutter/Screens/profile_screen.dart' show ProfilePage;
import 'package:new_amst_flutter/Screens/tabbar_screen_history.dart';
import '../Widgets/bottom_bar.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

enum BottomTab { home, reports, profile }

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

  NavigatorState get _currentNav =>
      _navKeys[_visibleTabs[_stackIndex]]!.currentState!;

  @override
  void initState() {
    super.initState();
    if (!_visibleTabs.contains(_tab)) _tab = BottomTab.home;
  }

  void _setTab(BottomTab t) {
    if (!_visibleTabs.contains(t)) return;

    // ✅ tap active tab => pop to root of that tab
    if (_tab == t) {
      final nav = _navKeys[t]!.currentState;
      if (nav != null && nav.canPop()) nav.popUntil((r) => r.isFirst);
      return;
    }

    setState(() => _tab = t);
  }

  Future<bool> _onWillPop() async {
    final nav = _currentNav;

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

    // 3) On home root => show exit dialog
    final ok = await _showExitDialog(context);
    if (ok == true) {
      SystemNavigator.pop();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),

        // ✅ FIX: show real nested navigators (NOT empty)
        body: IndexedStack(
          index: _stackIndex,
          children: [
            _TabNavigator(
              navKey: _navKeys[BottomTab.home]!,
              initial: const HomeScreen(),
            ),
            _TabNavigator(
              navKey: _navKeys[BottomTab.reports]!,
              initial: const HistoryTabsScreen(),
            ),
            _TabNavigator(
              navKey: _navKeys[BottomTab.profile]!,
              initial: const ProfilePage(),
            ),
          ],
        ),

        bottomNavigationBar: _buildBottomBar(context),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final items = const <BottomItem>[
      BottomItem(icon: Icons.home_rounded, label: 'Home'),
      BottomItem(icon: Icons.receipt_long_rounded, label: 'Reports'),
      BottomItem(icon: Icons.person_rounded, label: 'Profile'),
    ];

    return GlassBottomNav(
      currentIndex: _stackIndex,
      items: items,
      onTap: (i) => _setTab(_visibleTabs[i]),
    );
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _ExitAppDialog(),
    );
  }
}

/// ✅ Real tab navigator
class _TabNavigator extends StatelessWidget {
  const _TabNavigator({
    required this.navKey,
    required this.initial,
  });

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

class BottomItem {
  final IconData icon;
  final String label;
  const BottomItem({required this.icon, required this.label});
}

class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.bottomGap = 8, // ✅ THIS is the visible gap from bottom
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomItem> items;

  /// ✅ visible space between nav bar and screen bottom
  final double bottomGap;

  static const LinearGradient _grad = LinearGradient(
    colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final s = w / 390.0;

    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      // ✅ This creates REAL space from bottom (works always)
      padding: EdgeInsets.fromLTRB(14 * s, 0, 14 * s, bottomGap + safeBottom),
      child: SizedBox(
        height: 76 * s,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22 * s),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22 * s),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _grad,
                  border: Border.all(color: Colors.white.withOpacity(.18)),
                ),
                child: Row(
                  children: [
                    for (int i = 0; i < items.length; i++)
                      Expanded(
                        child: _NavItemTile(
                          item: items[i],
                          selected: i == currentIndex,
                          onTap: () => onTap(i),
                          scale: s,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/*
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.extraBottomPadding = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomItem> items;
  final double extraBottomPadding;

static const LinearGradient _grad = LinearGradient(
  colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);


  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final s = w / 390.0;

    return SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(
        14 * s,
        0,
        14 * s,
        (12 * s) + extraBottomPadding,
      ),
      child: Container(
        height: 76 * s,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22 * s),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22 * s),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                gradient: _grad,
                border: Border.all(color: Colors.white.withOpacity(.18)),
              ),
              child: Row(
                children: [
                  for (int i = 0; i < items.length; i++)
                    Expanded(
                      child: _NavItemTile(
                        item: items[i],
                        selected: i == currentIndex,
                        onTap: () => onTap(i),
                        scale: s,
                      ),
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
*/
class _NavItemTile extends StatelessWidget {
  const _NavItemTile({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.scale,
  });

  final BottomItem item;
  final bool selected;
  final VoidCallback onTap;
  final double scale;

static const LinearGradient _grad = LinearGradient(
  colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);


  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white24,
        highlightColor: Colors.transparent,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 9 * scale),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(16 * scale),
              border: selected
                  ? Border.all(color: const Color(0xFF7841BA).withOpacity(.22), width: 1.1)
                  : Border.all(color: Colors.white.withOpacity(.10), width: 1),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 14,
                        offset: Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: selected
                      ? ShaderMask(
                          key: const ValueKey('selectedIcon'),
                          shaderCallback: (rect) => _grad.createShader(rect),
                          child: Icon(item.icon, color: Colors.white, size: 32 * scale),
                        )
                      : Icon(
                          item.icon,
                          key: const ValueKey('normalIcon'),
                          color: Colors.white.withOpacity(.88),
                          size: 22 * scale,
                        ),
                ),
              //  SizedBox(height: 2 * scale),
                Text(
                  item.label,
                  //maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'ClashGrotesk',
                    fontSize: 10.2 * scale,
                    fontWeight: FontWeight.w900,
                    color: selected ? const Color(0xFF0F172A) : Colors.white.withOpacity(.88),
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 6 * scale),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 3 * scale,
                  width: selected ? 22 * scale : 10 * scale,
                  decoration: BoxDecoration(
                    gradient: selected ? _grad : null,
                    color: selected ? null : Colors.white.withOpacity(.22),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Exit dialog
class _ExitAppDialog extends StatelessWidget {
  const _ExitAppDialog();

  static const _grad = LinearGradient(
    colors: [Color(0xFF7841BA), Color(0xFF5C2E91)],
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
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 14,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.exit_to_app_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 12),
            const Text(
              "Exit App",
              style: TextStyle(
                fontFamily: 'ClashGrotesk',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Are you sure you want to close the app?",
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
                    text: "STAY",
                    onTap: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DialogGradientBtn(
                    text: "EXIT",
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
    colors: [Color(0xFF7841BA), Color(0xFF5C2E91)],
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
          BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 8)),
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
          color: const Color(0xFF7841BA).withOpacity(0.35),
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
                color: Color(0xFF7841BA),
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}





/*
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

    final ok = await _showExitDialog(context);
    if (ok == true) {
      SystemNavigator.pop();
    }
    return false; 
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
*/



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

