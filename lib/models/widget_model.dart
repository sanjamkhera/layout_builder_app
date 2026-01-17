import 'package:equatable/equatable.dart';

/// Immutable model representing a single widget positioned on the canvas.
///
/// Contains the widget's type identifier, position coordinates, and dimensions.
/// Implements [Equatable] for value-based equality and provides JSON
/// serialization for Firestore persistence.
class WidgetModel extends Equatable {
  /// Unique identifier for this widget instance.
  final String id;

  /// Widget type identifier (e.g., "A", "B", "C", "D").
  final String type;

  /// X coordinate of the widget's left edge on the canvas.
  final double x;

  /// Y coordinate of the widget's top edge on the canvas.
  final double y;

  /// Width of the widget in canvas coordinates.
  final double width;

  /// Height of the widget in canvas coordinates.
  final double height;

  const WidgetModel({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Creates a copy of this widget with optionally updated fields.
  ///
  /// Returns a new [WidgetModel] instance with the same values as this one,
  /// except for the fields explicitly provided. Unspecified fields retain
  /// their current values.
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

  /// Converts this widget to a JSON map for Firestore persistence.
  ///
  /// Serializes all fields as their native JSON-compatible types.
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

  /// Creates a [WidgetModel] from a JSON map loaded from Firestore.
  ///
  /// Deserializes all fields, converting numeric values to doubles to handle
  /// both integer and floating-point JSON numbers.
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
