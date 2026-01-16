import 'package:equatable/equatable.dart';
import 'widget_model.dart';

/// Model representing a complete layout (one tab)
/// 
/// Example: "Home Page" layout with widgets [A, B, C]
class LayoutModel extends Equatable {
  /// Unique ID for this layout/tab
  final String tabId;

  /// Display name for this layout/tab
  final String tabName;

  /// List of all widgets on this layout's canvas
  final List<WidgetModel> widgets;

  /// Timestamp when layout was last updated
  final DateTime? lastUpdated;

  const LayoutModel({
    required this.tabId,
    required this.tabName,
    required this.widgets,
    this.lastUpdated,
  });

  /// Create a copy with updated values (for immutable updates)
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

  /// Convert layout to JSON (for saving to Firestore)
  Map<String, dynamic> toJson() {
    return {
      'tabId': tabId,
      'tabName': tabName,
      'widgets': widgets.map((widget) => widget.toJson()).toList(),
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  /// Create layout from JSON (for loading from Firestore)
  factory LayoutModel.fromJson(Map<String, dynamic> json) {
    return LayoutModel(
      tabId: json['tabId'] as String,
      tabName: json['tabName'] as String,
      widgets: (json['widgets'] as List<dynamic>)
          .map((widgetJson) => WidgetModel.fromJson(widgetJson as Map<String, dynamic>))
          .toList(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [tabId, tabName, widgets, lastUpdated];
}
