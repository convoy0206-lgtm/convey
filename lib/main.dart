import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/landing_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment configurations from .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: Could not load .env file. Using system fallback properties: $e");
  }

  // Initialize Firebase (relies on native config directories setup)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase Initialization Skip: Please drop google-services.json / GoogleService-Info.plist files: $e");
  }

  runApp(
    // ProviderScope is required for Riverpod state storage
    const ProviderScope(
      child: ConvoyApp(),
    ),
  );
}

class ConvoyApp extends ConsumerWidget {
  const ConvoyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return MaterialApp(
      title: 'Convoy',
      debugShowCheckedModeBanner: false,
      
      // Theme Configuration (Premium Dark Space Theme)
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0088FF),
          secondary: Color(0xFF00F0FF),
          surface: Color(0xFF12141C),
          background: Color(0xFF090A0F),
          error: Color(0xFFEF4444),
        ),
        scaffoldBackgroundColor: const Color(0xFF090A0F),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF12141C),
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00F0FF)),
          ),
        ),
      ),
      
      // Main Routing Entrypoint
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const LandingScreen();
          }
          return const LoginScreen();
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, stack) => Scaffold(
          body: Center(
            child: Text('Authentication Error: ${err.toString()}'),
          ),
        ),
      ),
    );
  }
}
