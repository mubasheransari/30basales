// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:new_amst_flutter/Bloc/auth_bloc.dart';
// import 'package:new_amst_flutter/Data/local_sessions.dart';
// import 'package:new_amst_flutter/Repository/repository.dart';
// import 'package:new_amst_flutter/Screens/app_shell.dart';
// import 'package:new_amst_flutter/Screens/splash_screen.dart';
// import 'package:new_amst_flutter/Supervisor/home_supervisor_screen.dart';

/*

void main() async {
  await GetStorage.init();
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase will auto-pick Android (google-services.json) and iOS (GoogleService-Info.plist)
  // configs. If you're also building for Web, generate firebase_options.dart using
  // `flutterfire configure` and use Firebase.initializeApp(options: ...).
  await Firebase.initializeApp();

  final repo = Repository();
  final authBloc = AuthBloc(repo);

  runApp(
    RepositoryProvider.value(
      value: repo,
      child: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var box =GetStorage();
    final hasSession = LocalSession.readLogin() != null;
    var supervisorLoggedIn =   box.read("supervisor_loggedIn");
    print("SUPERVISOR $supervisorLoggedIn");

    return MaterialApp(
      title: 'BA Program',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),

    //   home: !hasSession && supervisorLoggedIn != "1"
    // ?  SplashScreen()
    // : supervisorLoggedIn == "1"
    //     ? JourneyPlanMapScreen()   
    //     :const  AppShell(),

    
      home: SplashScreen(),

      //home: hasSession  ? const AppShell() : const SplashScreen(),
    );
  }
}


*/
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_amst_flutter/Bloc/auth_bloc.dart';

import 'screens/auth_screen.dart';
import 'screens/splash_screen.dart';

// ✅ import your bloc files (update paths if different)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Firebase.initializeApp();

  // ✅ Android GoogleMap stability: fixes SurfaceProducer/ImageReader crashes on some devices
  AndroidGoogleMapsFlutter.useAndroidViewSurface = true;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // ✅ Provide AuthBloc globally (so AuthScreen, SplashScreen, all routes can access it)
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // not logged in
            if (!snap.hasData) return const AuthScreen();

            // logged in
            return const SplashScreen();
          },
        ),
      ),
    );
  }
}
