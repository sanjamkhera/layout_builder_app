import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'presentation/layout_builder_screen.dart';

/// Application entry point.
///
/// Initializes Firebase and authenticates the user anonymously to establish
/// a persistent user identity for data storage. The authentication state is
/// restored from local storage when available to prevent creating duplicate
/// anonymous users on app restart.
///
/// If Firebase initialization or authentication fails, the app will still
/// launch but user-specific features may be unavailable.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    await _ensureAuthenticatedUser();
  } catch (e) {
    // Log error but continue app initialization
    // User-specific features will be unavailable if auth fails
  }
  
  runApp(const MyApp());
}

/// Ensures an authenticated anonymous user exists for the current session.
///
/// Attempts to restore an existing authentication state from local storage
/// (critical for web platform where localStorage restoration is asynchronous).
/// If no existing user is found, creates a new anonymous user.
///
/// The authentication state restoration process:
/// 1. Waits for the initial auth state emission from [authStateChanges]
/// 2. If no user is found, waits for potential async restoration (web)
/// 3. Falls back to creating a new anonymous user if none exists
Future<void> _ensureAuthenticatedUser() async {
  final auth = FirebaseAuth.instance;
  User? currentUser;
  
  try {
    // Wait for initial auth state restoration (especially important on web)
    currentUser = await auth.authStateChanges()
        .first
        .timeout(
          const Duration(seconds: 3),
          onTimeout: () => auth.currentUser,
        )
        .catchError((_) => auth.currentUser);
    
    // Additional wait for async restoration on web platforms
    if (currentUser == null) {
      await Future.delayed(const Duration(milliseconds: 1500));
      currentUser = auth.currentUser;
      
      if (currentUser == null) {
        currentUser = await auth.authStateChanges()
            .where((user) => user != null)
            .timeout(const Duration(seconds: 2))
            .first
            .catchError((_) => null);
      }
    }
  } catch (e) {
    // Fallback to direct currentUser check
    await Future.delayed(const Duration(milliseconds: 500));
    currentUser = auth.currentUser;
  }
  
  // Create anonymous user if none exists
  if (currentUser == null) {
    await auth.signInAnonymously();
  }
}

/// Root application widget.
///
/// Configures the Material app theme and sets [LayoutBuilderScreen] as the
/// initial route.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Layout Builder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LayoutBuilderScreen(),
    );
  }
}
