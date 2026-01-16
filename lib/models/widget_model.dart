import 'package:equatable/equatable.dart';

/// Model representing a single widget on the canvas
/// 
/// Example: Widget A at position (100, 200) with size 150x150
class WidgetModel extends Equatable {
  /// Unique ID for this widget
  final String id;

  /// Widget type: "A", "B", "C", "D", etc.
  final String type;

  /// X position on canvas (left edge)
  final double x;

  /// Y position on canvas (top edge)
  final double y;

  /// Width of the widget
  final double width;

  /// Height of the widget
  final double height;

  const WidgetModel({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Create a copy with updated values (for immutable updates)
  WidgetModel copyWith({
    String? id,
    String? type,
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return WidgetModel(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  /// Convert widget to JSON (for saving to Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }

  /// Create widget from JSON (for loading from Firestore)
  factory WidgetModel.fromJson(Map<String, dynamic> json) {
    return WidgetModel(
      id: json['id'] as String,
      type: json['type'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        x,
        y,
        width,
        height,
      ];
}
