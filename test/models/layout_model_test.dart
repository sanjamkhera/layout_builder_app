import 'package:flutter_test/flutter_test.dart';
import 'package:layout_builder_app/models/layout_model.dart';
import 'package:layout_builder_app/models/widget_model.dart';

void main() {
  group('LayoutModel', () {
    test('should create a layout with all properties', () {
      const layout = LayoutModel(
        tabId: 'tab1',
        tabName: 'Home Page',
        widgets: [],
      );

      expect(layout.tabId, 'tab1');
      expect(layout.tabName, 'Home Page');
      expect(layout.widgets, []);
      expect(layout.lastUpdated, null);
    });

    test('should create a layout with widgets', () {
      final widgets = [
        const WidgetModel(
          id: 'widget1',
          type: 'A',
          x: 100.0,
          y: 200.0,
          width: 150.0,
          height: 150.0,
        ),
        const WidgetModel(
          id: 'widget2',
          type: 'B',
          x: 300.0,
          y: 400.0,
          width: 200.0,
          height: 200.0,
        ),
      ];

      final layout = LayoutModel(
        tabId: 'tab1',
        tabName: 'Home Page',
        widgets: widgets,
      );

      expect(layout.widgets.length, 2);
      expect(layout.widgets[0].type, 'A');
      expect(layout.widgets[1].type, 'B');
    });

    test('copyWith should create a new layout with updated values', () {
      const original = LayoutModel(
        tabId: 'tab1',
        tabName: 'Home Page',
        widgets: [],
      );

      final updated = original.copyWith(
        tabName: 'Updated Page',
        widgets: [
          const WidgetModel(
            id: 'widget1',
            type: 'A',
            x: 100.0,
            y: 200.0,
            width: 150.0,
            height: 150.0,
          ),
        ],
      );

      expect(updated.tabId, 'tab1'); // Unchanged
      expect(updated.tabName, 'Updated Page');
      expect(updated.widgets.length, 1);
    });

    test('toJson should convert layout to JSON', () {
      final layout = LayoutModel(
        tabId: 'tab1',
        tabName: 'Home Page',
        widgets: [
          const WidgetModel(
            id: 'widget1',
            type: 'A',
            x: 100.0,
            y: 200.0,
            width: 150.0,
            height: 150.0,
          ),
        ],
      );

      final json = layout.toJson();

      expect(json['tabId'], 'tab1');
      expect(json['tabName'], 'Home Page');
      expect(json['widgets'], isA<List>());
      expect(json['widgets'].length, 1);
      expect(json['lastUpdated'], null);
    });

    test('toJson should include lastUpdated when present', () {
      final lastUpdated = DateTime(2024, 1, 1, 12, 0, 0);
      final layout = LayoutModel(
        tabId: 'tab1',
        tabName: 'Home Page',
        widgets: [],
        lastUpdated: lastUpdated,
      );

      final json = layout.toJson();

      expect(json['lastUpdated'], lastUpdated.toIso8601String());
    });

    test('fromJson should create layout from JSON', () {
      final json = {
        'tabId': 'tab1',
        'tabName': 'Home Page',
        'widgets': [
          {
            'id': 'widget1',
            'type': 'A',
            'x': 100.0,
            'y': 200.0,
            'width': 150.0,
            'height': 150.0,
          },
        ],
      };

      final layout = LayoutModel.fromJson(json);

      expect(layout.tabId, 'tab1');
      expect(layout.tabName, 'Home Page');
      expect(layout.widgets.length, 1);
      expect(layout.widgets[0].type, 'A');
    });

    test('fromJson should handle lastUpdated', () {
      final lastUpdatedStr = '2024-01-01T12:00:00.000Z';
      final json = {
        'tabId': 'tab1',
        'tabName': 'Home Page',
        'widgets': [],
        'lastUpdated': lastUpdatedStr,
      };

      final layout = LayoutModel.fromJson(json);

      expect(layout.lastUpdated, isNotNull);
      expect(layout.lastUpdated!.toIso8601String(), lastUpdatedStr);
    });

    test('toJson and fromJson should be reversible', () {
      final original = LayoutModel(
        tabId: 'tab1',
        tabName: 'Home Page',
        widgets: [
          const WidgetModel(
            id: 'widget1',
            type: 'A',
            x: 100.0,
            y: 200.0,
            width: 150.0,
            height: 150.0,
          ),
        ],
      );

      final json = original.toJson();
      final restored = LayoutModel.fromJson(json);

      expect(restored.tabId, original.tabId);
      expect(restored.tabName, original.tabName);
      expect(restored.widgets.length, original.widgets.length);
      expect(restored.widgets[0].id, original.widgets[0].id);
    });

    test('equality should work correctly', () {
      const layout1 = LayoutModel(
        tabId: 'tab1',
        tabName: 'Home Page',
        widgets: [],
      );

      const layout2 = LayoutModel(
        tabId: 'tab1',
        tabName: 'Home Page',
        widgets: [],
      );

      const layout3 = LayoutModel(
        tabId: 'tab2',
        tabName: 'Home Page',
        widgets: [],
      );

      expect(layout1 == layout2, true);
      expect(layout1 == layout3, false);
      expect(layout1.hashCode == layout2.hashCode, true);
    });
  });
}
