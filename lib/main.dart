import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'presentation/layout_builder_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');

    // Sign in anonymously for user identification
    // This creates a unique user ID for each device automatically
    final auth = FirebaseAuth.instance;
    
    // IMPORTANT: Wait for auth state to be restored from local storage (especially on web)
    // On web, Firebase Auth stores the session in localStorage and needs time to restore it
    // This prevents creating a new anonymous user on every app restart
    
    User? currentUser;
    
    // Strategy: Wait for authStateChanges to emit its initial value (restored state)
    // Then check if we got a user or need to create one
    try {
      print('🔍 Checking for existing authenticated user...');
      
      // Listen to authStateChanges - it emits the current auth state immediately
      // and will emit again when auth state changes (including restoration from localStorage)
      // We need to wait for the initial emission which contains the restored state
      final authStateStream = auth.authStateChanges();
      
      // Get the first emission (current/restored auth state)
      // This might be null if no user exists, or a User if one was restored
      currentUser = await authStateStream.first.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('   ⏱️  Timeout waiting for initial auth state');
          return auth.currentUser; // Fallback to currentUser if timeout
        },
      ).catchError((e) {
        print('   ⚠️  Error getting auth state: $e');
        return auth.currentUser; // Fallback on error
      });
      
      // If still null, wait a bit longer as localStorage restoration can be async
      if (currentUser == null) {
        print('   ⏳ No user in initial state, waiting for async restoration...');
        
        // Wait for potential restoration (localStorage on web can take a moment)
        await Future.delayed(const Duration(milliseconds: 1500));
        
        // Check currentUser again after delay
        currentUser = auth.currentUser;
        
        // If still null, listen to authStateChanges for any user restoration
        if (currentUser == null) {
          try {
            currentUser = await auth.authStateChanges()
                .where((user) => user != null)
                .timeout(const Duration(seconds: 2))
                .first
                .catchError((_) => null);
          } catch (e) {
            // Timeout or error - no user restored
            currentUser = null;
          }
        }
      }
      
      if (currentUser != null) {
        print('   ✓ Found user: ${currentUser!.uid}');
      } else {
        print('   ✗ No existing user found - will create new anonymous user');
      }
    } catch (e) {
      // Fallback: check currentUser directly
      print('⚠️  Exception during auth state check: $e');
      await Future.delayed(const Duration(milliseconds: 500));
      currentUser = auth.currentUser;
      if (currentUser != null) {
        print('   ✓ Found user in fallback check: ${currentUser!.uid}');
      }
    }
    
    // Check if user is already signed in
    if (currentUser == null) {
      // Sign in anonymously - creates a unique user ID per device
      final userCredential = await auth.signInAnonymously();
      final userId = userCredential.user?.uid ?? 'unknown';
      print('✅ Anonymous user authenticated: $userId');
      print('   📍 New user created - this ID will persist across app restarts');
      print('   📍 Firestore path: layouts/$userId');
    } else {
      final userId = currentUser.uid;
      print('✅ User already authenticated: $userId');
      print('   📍 Using existing user ID (restored from previous session)');
      print('   📍 Firestore path: layouts/$userId');
    }
  } catch (e) {
    print('❌ Firebase initialization/authentication error: $e');
    // Check if it's the configuration-not-found error (usually means Anonymous Auth isn't enabled)
    if (e.toString().contains('configuration-not-found')) {
      print('');
      print('⚠️  SOLUTION REQUIRED: Enable Anonymous Authentication in Firebase Console');
      print('   This error occurs because Anonymous Authentication is not enabled.');
      print('');
      print('   Steps to fix:');
      print('   1. Go to: https://console.firebase.google.com/');
      print('   2. Select project: layout-builder-app');
      print('   3. Navigate to: Authentication → Sign-in method');
      print('   4. Click on "Anonymous" provider');
      print('   5. Enable it (toggle switch)');
      print('   6. Click "Save"');
      print('   7. Restart the app');
      print('');
      print('   Note: The app will continue to run, but user identification will not work');
      print('   until Anonymous Authentication is enabled.');
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LayoutBuilderScreen(),
    );
  }
}
