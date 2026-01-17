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
    
    // Check if user is already signed in
    if (auth.currentUser == null) {
      // Sign in anonymously - creates a unique user ID per device
      final userCredential = await auth.signInAnonymously();
      print('✅ Anonymous user authenticated: ${userCredential.user?.uid}');
    } else {
      print('✅ User already authenticated: ${auth.currentUser?.uid}');
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
