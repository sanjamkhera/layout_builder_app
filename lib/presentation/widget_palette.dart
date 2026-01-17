import 'package:flutter/material.dart';
import 'widget_colors.dart';

/// Widget Palette - Side menu with draggable widgets (A, B, C, D)
class WidgetPalette extends StatelessWidget {
  final bool isHorizontal;
  
  const WidgetPalette({
    super.key,
    this.isHorizontal = false,
  });

  // Available widget types
  static const List<String> widgetTypes = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Takes full width of parent (sidebar or drawer)
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9), // Cool slate gray
      ),
      child: isHorizontal
          ? _buildHorizontalLayout(context)
          : _buildVerticalLayout(context),
    );
  }

  Widget _buildHorizontalLayout(BuildContext context) {
    return Container(
      height: 100, // Fixed height for horizontal palette
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        // Use AlwaysScrollableScrollPhysics to ensure it's always scrollable
        // even when content doesn't overflow (for better UX with many widgets)
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(), // iOS-style bounce effect
        ),
        itemCount: widgetTypes.length,
        itemBuilder: (context, index) {
          final widgetType = widgetTypes[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _DraggableWidgetItem(
              widgetType: widgetType,
              size: 80, // Fixed size for horizontal layout
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerticalLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // List of draggable widgets
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
            itemCount: widgetTypes.length,
            itemBuilder: (context, index) {
              final widgetType = widgetTypes[index];
              return _DraggableWidgetItem(widgetType: widgetType);
            },
          ),
        ),
      ],
    );
  }
}

/// Individual draggable widget item in palette
class _DraggableWidgetItem extends StatelessWidget {
  final String widgetType;
  final double? size; // Optional fixed size for horizontal layout

  const _DraggableWidgetItem({
    required this.widgetType,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use fixed size if provided, otherwise use 60% of container width
        final widgetSize = size ?? constraints.maxWidth * 0.6;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Draggable<String>(
            data: widgetType, // Data to pass when dragged
            onDragEnd: (details) {
              print('🔄 Drag ended for: $widgetType');
            },
            feedback: Material(
              elevation: 8,
              borderRadius: BorderRadius.zero,
              child: Container(
                width: widgetSize,
                height: widgetSize,
                decoration: BoxDecoration(
                  color: WidgetColors.getColor(widgetType),
                  borderRadius: BorderRadius.zero,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widgetType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            childWhenDragging: Container(
              width: widgetSize,
              height: widgetSize,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: Container(
              width: widgetSize,
              height: widgetSize,
              decoration: BoxDecoration(
                color: WidgetColors.getColor(widgetType),
                borderRadius: BorderRadius.zero,
                boxShadow: [
                  BoxShadow(
                    color: WidgetColors.getColor(widgetType).withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widgetType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
