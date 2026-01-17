import 'package:flutter_test/flutter_test.dart';
import 'package:layout_builder_app/models/widget_model.dart';

void main() {
  group('WidgetModel', () {
    test('should create a widget with all properties', () {
      const widget = WidgetModel(
        id: 'widget1',
        type: 'A',
        x: 100.0,
        y: 200.0,
        width: 150.0,
        height: 150.0,
      );

      expect(widget.id, 'widget1');
      expect(widget.type, 'A');
      expect(widget.x, 100.0);
      expect(widget.y, 200.0);
      expect(widget.width, 150.0);
      expect(widget.height, 150.0);
    });

    test('copyWith should create a new widget with updated values', () {
      const original = WidgetModel(
        id: 'widget1',
        type: 'A',
        x: 100.0,
        y: 200.0,
        width: 150.0,
        height: 150.0,
      );

      final updated = original.copyWith(
        x: 300.0,
        y: 400.0,
        width: 200.0,
      );

      expect(updated.id, 'widget1');
      expect(updated.type, 'A');
      expect(updated.x, 300.0);
      expect(updated.y, 400.0);
      expect(updated.width, 200.0);
      expect(updated.height, 150.0); // Unchanged
    });

    test('copyWith should preserve original values when no parameters provided', () {
      const original = WidgetModel(
        id: 'widget1',
        type: 'A',
        x: 100.0,
        y: 200.0,
        width: 150.0,
        height: 150.0,
      );

      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.type, original.type);
      expect(copy.x, original.x);
      expect(copy.y, original.y);
      expect(copy.width, original.width);
      expect(copy.height, original.height);
    });

    test('toJson should convert widget to JSON', () {
      const widget = WidgetModel(
        id: 'widget1',
        type: 'A',
        x: 100.0,
        y: 200.0,
        width: 150.0,
        height: 150.0,
      );

      final json = widget.toJson();

      expect(json['id'], 'widget1');
      expect(json['type'], 'A');
      expect(json['x'], 100.0);
      expect(json['y'], 200.0);
      expect(json['width'], 150.0);
      expect(json['height'], 150.0);
    });

    test('fromJson should create widget from JSON', () {
      final json = {
        'id': 'widget1',
        'type': 'A',
        'x': 100.0,
        'y': 200.0,
        'width': 150.0,
        'height': 150.0,
      };

      final widget = WidgetModel.fromJson(json);

      expect(widget.id, 'widget1');
      expect(widget.type, 'A');
      expect(widget.x, 100.0);
      expect(widget.y, 200.0);
      expect(widget.width, 150.0);
      expect(widget.height, 150.0);
    });

    test('fromJson should handle integer values and convert to double', () {
      final json = {
        'id': 'widget1',
        'type': 'A',
        'x': 100, // Integer
        'y': 200, // Integer
        'width': 150, // Integer
        'height': 150, // Integer
      };

      final widget = WidgetModel.fromJson(json);

      expect(widget.x, 100.0);
      expect(widget.y, 200.0);
      expect(widget.width, 150.0);
      expect(widget.height, 150.0);
    });

    test('toJson and fromJson should be reversible', () {
      const original = WidgetModel(
        id: 'widget1',
        type: 'B',
        x: 250.5,
        y: 350.75,
        width: 125.25,
        height: 175.5,
      );

      final json = original.toJson();
      final restored = WidgetModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.type, original.type);
      expect(restored.x, original.x);
      expect(restored.y, original.y);
      expect(restored.width, original.width);
      expect(restored.height, original.height);
    });

    test('equality should work correctly', () {
      const widget1 = WidgetModel(
        id: 'widget1',
        type: 'A',
        x: 100.0,
        y: 200.0,
        width: 150.0,
        height: 150.0,
      );

      const widget2 = WidgetModel(
        id: 'widget1',
        type: 'A',
        x: 100.0,
        y: 200.0,
        width: 150.0,
        height: 150.0,
      );

      const widget3 = WidgetModel(
        id: 'widget2',
        type: 'A',
        x: 100.0,
        y: 200.0,
        width: 150.0,
        height: 150.0,
      );

      expect(widget1 == widget2, true);
      expect(widget1 == widget3, false);
      expect(widget1.hashCode == widget2.hashCode, true);
    });
  });
}
