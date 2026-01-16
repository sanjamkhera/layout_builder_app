import 'package:flutter/material.dart';

/// Color scheme helper for widget types
class WidgetColors {
  // Modern color palette for each widget type
  static const Map<String, Color> typeColors = {
    'A': Color(0xFF6366F1), // Indigo
    'B': Color(0xFF10B981), // Emerald
    'C': Color(0xFFF59E0B), // Amber
    'D': Color(0xFFEF4444), // Red
  };

  // Darker shade for borders
  static const Map<String, Color> borderColors = {
    'A': Color(0xFF4F46E5), // Darker Indigo
    'B': Color(0xFF059669), // Darker Emerald
    'C': Color(0xFFD97706), // Darker Amber
    'D': Color(0xFFDC2626), // Darker Red
  };

  // Get color for widget type, default to indigo if not found
  static Color getColor(String type) {
    return typeColors[type] ?? const Color(0xFF6366F1);
  }

  // Get border color for widget type
  static Color getBorderColor(String type) {
    return borderColors[type] ?? const Color(0xFF4F46E5);
  }
}
