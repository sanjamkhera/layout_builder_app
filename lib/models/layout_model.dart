import 'package:equatable/equatable.dart';
import 'widget_model.dart';

/// Immutable model representing a complete layout for a single tab.
///
/// Contains the tab's metadata and all widgets positioned on its canvas.
/// Implements [Equatable] for value-based equality and provides JSON
/// serialization for Firestore persistence.
class LayoutModel extends Equatable {
  /// Unique identifier for this layout/tab.
  final String tabId;

  /// Display name for this layout/tab.
  final String tabName;

  /// List of all widgets positioned on this layout's canvas.
  final List<WidgetModel> widgets;

  /// Timestamp when the layout was last updated.
  final DateTime? lastUpdated;

  const LayoutModel({
    required this.tabId,
    required this.tabName,
    required this.widgets,
    this.lastUpdated,
  });

  /// Creates a copy of this layout with optionally updated fields.
  ///
  /// Returns a new [LayoutModel] instance with the same values as this one,
  /// except for the fields explicitly provided. Unspecified fields retain
  /// their current values.
  LayoutModel copyWith({
    String? tabId,
    String? tabName,
    List<WidgetModel>? widgets,
    DateTime? lastUpdated,
  }) {
    return LayoutModel(
      tabId: tabId ?? this.tabId,
      tabName: tabName ?? this.tabName,
      widgets: widgets ?? this.widgets,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Converts this layout to a JSON map for Firestore persistence.
  ///
  /// Serializes all fields, including converting widgets to JSON and
  /// formatting the last updated timestamp as ISO 8601.
  Map<String, dynamic> toJson() {
    return {
      'tabId': tabId,
      'tabName': tabName,
      'widgets': widgets.map((widget) => widget.toJson()).toList(),
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  /// Creates a [LayoutModel] from a JSON map loaded from Firestore.
  ///
  /// Deserializes all fields, including parsing widgets from JSON and
  /// converting the ISO 8601 timestamp back to [DateTime].
  factory LayoutModel.fromJson(Map<String, dynamic> json) {
    return LayoutModel(
      tabId: json['tabId'] as String,
      tabName: json['tabName'] as String,
      widgets: (json['widgets'] as List<dynamic>)
          .map((widgetJson) =>
              WidgetModel.fromJson(widgetJson as Map<String, dynamic>))
          .toList(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [tabId, tabName, widgets, lastUpdated];
}
