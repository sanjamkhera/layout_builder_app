import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/layout_model.dart';

/// Repository for Firestore operations on layout data.
///
/// Acts as the data access layer between the BLoC and Firestore, handling
/// all database operations for layouts. Stores layouts in a user-scoped
/// document structure where each user has a document containing their
/// collection of layout tabs.
class LayoutRepository {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'layouts';

  LayoutRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Returns the current authenticated user's unique ID.
  ///
  /// Throws an exception if no user is authenticated.
  String _getUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception(
        'User not authenticated. Please ensure anonymous authentication is enabled.',
      );
    }
    return user.uid;
  }

  /// Fetches all layouts for the current user from Firestore.
  ///
  /// Returns a map of tab IDs to [LayoutModel] instances. Returns an empty
  /// map if no layouts exist for the user.
  ///
  /// Throws an exception if the fetch operation fails.
  Future<Map<String, LayoutModel>> fetchLayouts() async {
    try {
      final userId = _getUserId();
      final docRef = _firestore.collection(_collectionName).doc(userId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        return {};
      }

      final data = docSnapshot.data();
      if (data == null) {
        return {};
      }

      final Map<String, LayoutModel> layouts = {};
      data.forEach((tabId, layoutJson) {
        if (layoutJson is Map<String, dynamic>) {
          layouts[tabId] = LayoutModel.fromJson(layoutJson);
        }
      });

      return layouts;
    } catch (e) {
      throw Exception('Failed to fetch layouts: $e');
    }
  }

  /// Saves a layout to Firestore.
  ///
  /// Updates the user's document with the provided layout, merging with
  /// existing data to preserve other tabs. Uses the layout's [tabId] as
  /// the field key in the document.
  ///
  /// Throws an exception if the save operation fails.
  Future<void> saveLayout(LayoutModel layout) async {
    try {
      final userId = _getUserId();
      final docRef = _firestore.collection(_collectionName).doc(userId);
      final layoutJson = layout.toJson();

      await docRef.set(
        {layout.tabId: layoutJson},
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Failed to save layout: $e');
    }
  }

  /// Saves all layouts in a single Firestore operation.
  ///
  /// Useful for batch updates or initial synchronization. Merges with
  /// existing data in the user's document.
  ///
  /// Throws an exception if the save operation fails.
  Future<void> saveAllLayouts(Map<String, LayoutModel> layouts) async {
    try {
      final userId = _getUserId();
      final docRef = _firestore.collection(_collectionName).doc(userId);

      final Map<String, dynamic> layoutsJson = {};
      layouts.forEach((tabId, layout) {
        layoutsJson[tabId] = layout.toJson();
      });

      await docRef.set(layoutsJson, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save all layouts: $e');
    }
  }

  /// Deletes a tab/layout from Firestore.
  ///
  /// Removes the specified tab field from the user's document using
  /// [FieldValue.delete()].
  ///
  /// Throws an exception if the delete operation fails.
  Future<void> deleteTab(String tabId) async {
    try {
      final userId = _getUserId();
      final docRef = _firestore.collection(_collectionName).doc(userId);

      await docRef.update({
        tabId: FieldValue.delete(),
      });
    } catch (e) {
      throw Exception('Failed to delete tab: $e');
    }
  }
}
