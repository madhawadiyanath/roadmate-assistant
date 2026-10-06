import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/firebase_state.dart';
import 'firebase_options.dart';
import 'screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Missing .env should not crash the app (fresh clone / CI).
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // AppEnv falls back to safe defaults.
  }
  // Firebase needs google-services.json / GoogleService-Info.plist from the
  // Firebase console (see FIREBASE_SETUP below). Missing config must not
  // crash the app or widget tests.
  try {
    if (!DefaultFirebaseOptions.isPlaceholder) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      firebaseReady = true;
    } else {
      debugPrint('Running in mock/local mode (placeholder Firebase options).');
      firebaseReady = false;
    }
  } catch (e) {
    debugPrint('Firebase not initialised (add config files): $e');
    firebaseReady = false;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoadMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A2A66),
        ),
      ),
      home: const OnboardingScreen(),
    );
  }
}
