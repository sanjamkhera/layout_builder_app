import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/layout_model.dart';

/// Repository that handles all Firestore operations for layouts
/// 
/// This is the "middleman" between BLoC and Firestore.
/// BLoC asks repository to save/load, repository talks to Firestore.
class LayoutRepository {
  // Firestore instance (the database connection)
  final FirebaseFirestore _firestore;

  // Collection name in Firestore where we store layouts
  static const String _collectionName = 'layouts';

  // Constructor - creates repository with Firestore connection
  LayoutRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get user ID from Firebase Authentication
  /// 
  /// Returns the current authenticated user's unique ID.
  /// If no user is authenticated, throws an exception.
  String _getUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception(
        'User not authenticated. Please ensure anonymous authentication is enabled.',
      );
    }
    return user.uid; // Unique user ID (e.g., "a7K9mP2xQyZ1...")
  }

  /// Fetch all layouts for the current user from Firestore
  /// 
  /// Returns: Map of tabId -> LayoutModel
  /// Example: { "tab1": LayoutModel(...), "tab2": LayoutModel(...) }
  Future<Map<String, LayoutModel>> fetchLayouts() async {
    try {
      // Get the user's document from Firestore
      // Collection: "layouts"
      // Document ID: userId (e.g., "user1")
      final userId = _getUserId();
      final docRef = _firestore.collection(_collectionName).doc(userId);

      // Get the document snapshot (the data)
      final docSnapshot = await docRef.get();

      // Check if document exists
      if (!docSnapshot.exists) {
        // No layouts saved yet - return empty map
        return {};
      }

      // Get the data from the document
      final data = docSnapshot.data();
      if (data == null) {
        return {};
      }

      // Convert JSON data to LayoutModel objects
      // Data structure: { "tab1": {...}, "tab2": {...} }
      final Map<String, LayoutModel> layouts = {};

      // Loop through each tab in the data
      data.forEach((tabId, layoutJson) {
        if (layoutJson is Map<String, dynamic>) {
          // Convert JSON to LayoutModel using fromJson()
          layouts[tabId] = LayoutModel.fromJson(layoutJson);
        }
      });

      return layouts;
    } catch (e) {
      // If something goes wrong, throw error (BLoC will handle it)
      throw Exception('Failed to fetch layouts: $e');
    }
  }

  /// Save a layout to Firestore
  /// 
  /// Takes a LayoutModel and saves it to Firestore
  /// Updates the user's document with this layout
  Future<void> saveLayout(LayoutModel layout) async {
    try {
      // Get the user's document reference
      final userId = _getUserId();
      final docRef = _firestore.collection(_collectionName).doc(userId);

      // Convert LayoutModel to JSON using toJson()
      final layoutJson = layout.toJson();

      // Update the document
      // Using update() with field path to update just this tab
      // Structure: { "tabId": { layout data } }
      await docRef.set(
        {layout.tabId: layoutJson},
        SetOptions(merge: true), // Merge with existing data (don't overwrite other tabs)
      );
    } catch (e) {
      // If something goes wrong, throw error (BLoC will handle it)
      throw Exception('Failed to save layout: $e');
    }
  }

  /// Save all layouts at once (optional helper method)
  /// 
  /// Useful when you want to save multiple layouts in one operation
  Future<void> saveAllLayouts(Map<String, LayoutModel> layouts) async {
    try {
      final userId = _getUserId();
      final docRef = _firestore.collection(_collectionName).doc(userId);

      // Convert all layouts to JSON
      final Map<String, dynamic> layoutsJson = {};
      layouts.forEach((tabId, layout) {
        layoutsJson[tabId] = layout.toJson();
      });

      // Save all at once
      await docRef.set(layoutsJson, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save all layouts: $e');
    }
  }
}
