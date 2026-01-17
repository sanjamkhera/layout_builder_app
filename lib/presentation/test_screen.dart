import 'package:flutter/material.dart';
import '../models/widget_model.dart';
import '../models/layout_model.dart';
import '../repository/layout_repository.dart';

/// Test screen for verifying Firestore connection and repository functionality.
///
/// Provides UI for testing save and load operations with the [LayoutRepository].
/// Displays operation status and results, with timeout handling for network
/// operations. Useful for debugging Firestore connectivity and security rules.
class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final LayoutRepository _repository = LayoutRepository();
  String _status = 'Ready to test';
  bool _isLoading = false;

  /// Saves a test layout to Firestore.
  ///
  /// Creates a test widget and layout, then attempts to save via the repository.
  /// Handles timeouts and errors, displaying appropriate status messages.
  Future<void> _testSave() async {
    setState(() {
      _isLoading = true;
      _status = 'Saving to Firestore...';
    });

    try {
      final testWidget = WidgetModel(
        id: 'test_widget_1',
        type: 'A',
        x: 100.0,
        y: 200.0,
        width: 150.0,
        height: 150.0,
      );

      final testLayout = LayoutModel(
        tabId: 'test_tab_1',
        tabName: 'Test Layout',
        widgets: [testWidget],
      );

      await _repository.saveLayout(testLayout).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
              'Timeout: Firestore took too long. Check security rules!');
        },
      );

      setState(() {
        _status = 'Saved successfully!\n'
            'Tab: ${testLayout.tabName}\n'
            'Widgets: ${testLayout.widgets.length}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error saving: $e\n\n'
            'Common issue: Firestore security rules\n'
            'Go to Firebase Console → Firestore → Rules\n'
            'Set rules to allow read/write for testing';
        _isLoading = false;
      });
    }
  }

  /// Loads layouts from Firestore.
  ///
  /// Fetches all layouts via the repository and displays their details.
  /// Handles empty results and errors with appropriate status messages.
  Future<void> _testLoad() async {
    setState(() {
      _isLoading = true;
      _status = 'Loading from Firestore...';
    });

    try {
      final layouts = await _repository.fetchLayouts().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
              'Timeout: Firestore took too long. Check security rules!');
        },
      );

      if (layouts.isEmpty) {
        setState(() {
          _status = 'No layouts found in Firestore\n'
              'Try saving first!';
          _isLoading = false;
        });
        return;
      }

      final buffer = StringBuffer();
      buffer.writeln('Loaded ${layouts.length} layout(s):\n');
      layouts.forEach((tabId, layout) {
        buffer.writeln('Tab: ${layout.tabName}');
        buffer.writeln('Widgets: ${layout.widgets.length}');
        buffer.writeln('---');
      });

      setState(() {
        _status = buffer.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error loading: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _testSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'Test Save to Firestore',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testLoad,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'Test Load from Firestore',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            const Card(
              color: Colors.amber,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Click "Test Save" to save a test layout'),
                    Text('2. Click "Test Load" to load it back'),
                    Text('3. Check Firebase Console to see the data'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
