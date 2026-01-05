import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';
import 'package:new_amst_flutter/Bloc/auth_bloc.dart' show AuthBloc;
import 'package:new_amst_flutter/Screens/auth_screen.dart';
import 'package:new_amst_flutter/Screens/app_shell.dart';
import 'package:new_amst_flutter/Admin/admin_dashboard_screen.dart';
import 'package:new_amst_flutter/Firebase/firebase_services.dart';
import 'package:new_amst_flutter/Widgets/watermarked_widget.dart';
import 'package:new_amst_flutter/Supervisor/home_supervisor_screen.dart' hide AuthScreen;
import 'package:new_amst_flutter/Screens/location_select_screen.dart';



class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // small delay for splash
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;

      // ✅ Warm locations cache early so LocationSelect/Admin screens can render quickly
      // NOTE: if your warmCache reads Firestore and you want it to work without login,
      // make sure your /locations rules allow read for everyone (you already did).
      try {
        await FbLocationRepo.warmCache();
      } catch (_) {
        // ignore cache errors (don't block splash)
      }

      final box = GetStorage();

      // ✅ Firebase session (IMPORTANT: if null => don't call any repo that hits Firestore)
      final user = FirebaseAuth.instance.currentUser;
      final bool hasSession = user != null;

      // 🔹 Read supervisor flag (normalize)
      final supervisorLoggedIn = (box.read("supervisor_loggedIn") ?? "0").toString();
      print("SUPERVISOR $supervisorLoggedIn");

      // 🔹 Get the bloc BEFORE navigation, using the current context
      final authBloc = context.read<AuthBloc>();

      // ✅ Decide target before navigation (builder cannot be async)
      Widget target;

      // -------------------------
      // ✅ NO SESSION
      // -------------------------
      if (!hasSession) {
        // If supervisor flag says logged in but firebase session is missing,
        // treat as not logged in (otherwise you'll get permission denied everywhere)
        if (supervisorLoggedIn == "1") {
          // clean invalid flag so it doesn't loop
          await box.remove("supervisor_loggedIn");
        }
        target = const AuthScreen();
      } else {
        // -------------------------
        // ✅ SESSION EXISTS
        // -------------------------
        try {
          // If you want supervisor to always go to map when flag set:
          if (supervisorLoggedIn == "1") {
            target = JourneyPlanMapScreen();
          } else {
            // Admin check
            final isAdmin = await FbAdminRepo.isAdmin(user!.uid);
            if (isAdmin) {
              target = AdminDashboardScreen();
            } else {
              // Supervisor check
              final isSupervisor = await FbSupervisorRepo.isSupervisor(user.uid);
              if (isSupervisor) {
                target = JourneyPlanMapScreen();
              } else {
                // Normal user flow
                // Ensure the user has selected a location before using attendance.
                final profile = await FbUserRepo.getOrCreateProfile(user: user);

                final locationId = profile.locationId;
                final hasValidGeoPoint =
                    (profile.allowedLat != 0 || profile.allowedLng != 0);

                target = (locationId == null || !hasValidGeoPoint)
                    ? const LocationSelectScreen()
                    : const AppShell();
              }
            }
          }
        } catch (e) {
          // ✅ If rules deny, token expired, or any Firestore error -> go to login safely
          // Also clear supervisor flag to avoid loops
          await box.remove("supervisor_loggedIn");
          target = const AuthScreen();
        }
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: target,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: const [
          // watermark background
          WatermarkTiledSmall(tileScale: 6.0),

          // centered-ish logo
          Positioned(
            top: 240,
            right: 10,
            left: 10,
            child: Center(child: _SplashLogo()),
          ),
        ],
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF0ED2F7), Color(0xFF7F53FD)],
        ).createShader(bounds);
      },
      child: Image.asset(
        'assets/basales.png',
        width: 390,
        height: 290,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}







/*
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  @override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // small delay for splash
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // ✅ Warm locations cache early so LocationSelect/Admin screens can render
    // quickly when the app opens.
    await FbLocationRepo.warmCache();

    final box = GetStorage();

    // ✅ Firebase session
    final user = FirebaseAuth.instance.currentUser;
    final bool hasSession = user != null;

    // 🔹 Read supervisor flag (might be int/bool/string, so normalize)
    final supervisorLoggedIn = box.read("supervisor_loggedIn")?.toString() ?? "0";
    print("SUPERVISOR $supervisorLoggedIn");

    // 🔹 Get the bloc BEFORE navigation, using the current context
    final authBloc = context.read<AuthBloc>();

    // ✅ Decide target before navigation (builder cannot be async)
    Widget target;
    if (!hasSession && supervisorLoggedIn != "1") {
      target = const AuthScreen();
    } else if (supervisorLoggedIn == "1") {
      target = JourneyPlanMapScreen();
    } else {
      final isAdmin = await FbAdminRepo.isAdmin(user!.uid);
      if (isAdmin) {
        target = AdminDashboardScreen();
      } else {
        final isSupervisor = await FbSupervisorRepo.isSupervisor(user.uid);
        if (isSupervisor) {
          target = JourneyPlanMapScreen();
        } else {

        // Ensure the user has selected a location before using attendance.
        final profile = await FbUserRepo.getOrCreateProfile(user: user!);
        final locationId = profile.locationId;
        final hasValidGeoPoint =
            (profile.allowedLat != 0 || profile.allowedLng != 0);

        target = (locationId == null || !hasValidGeoPoint)
            ? const LocationSelectScreen()
            : const AppShell();
        }

      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: target,
        ),
      ),
    );
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: const [
          // watermark background
          WatermarkTiledSmall(tileScale: 6.0),

          // centered-ish logo
          Positioned(
            top: 240,
            right: 10,
            left: 10,
           // left: 58,
            child: Center(child: _SplashLogo()),
          ),
        ],
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
           Color(0xFF0ED2F7), Color(0xFF7F53FD)
          ],
        ).createShader(bounds);
      },
      child:Image.asset(
      'assets/basales.png',
      width: 390,
      height: 290,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    )
    );
  }
}


// class _SplashLogo extends StatelessWidget {
//   const _SplashLogo();

//   static const _logoPath = 'assets/basales.png';

//   @override
//   Widget build(BuildContext context) {
    // return Image.asset(
    
    //   _logoPath,
    //   width: 320,
    //   height: 160,
    //   fit: BoxFit.contain,
    //   filterQuality: FilterQuality.high,
    // );
//   }
// }
*/