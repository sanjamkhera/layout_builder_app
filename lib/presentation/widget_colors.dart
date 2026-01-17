import 'package:flutter/material.dart';

/// Color scheme utility for widget types.
///
/// Provides consistent color mapping for different widget types displayed
/// on the canvas. Each widget type has an associated fill color and a darker
/// border color for visual distinction.
class WidgetColors {
  static const Map<String, Color> typeColors = {
    'A': Color(0xFF6366F1), // Indigo
    'B': Color(0xFF10B981), // Emerald
    'C': Color(0xFFF59E0B), // Amber
    'D': Color(0xFFEF4444), // Red
  };

  static const Map<String, Color> borderColors = {
    'A': Color(0xFF4F46E5), // Darker Indigo
    'B': Color(0xFF059669), // Darker Emerald
    'C': Color(0xFFD97706), // Darker Amber
    'D': Color(0xFFDC2626), // Darker Red
  };

  /// Returns the fill color for the given widget type.
  ///
  /// Returns indigo as the default color if the type is not found in the map.
  static Color getColor(String type) {
    return typeColors[type] ?? const Color(0xFF6366F1);
  }

  /// Returns the border color for the given widget type.
  ///
  /// Returns darker indigo as the default color if the type is not found
  /// in the map.
  static Color getBorderColor(String type) {
    return borderColors[type] ?? const Color(0xFF4F46E5);
  }
}
