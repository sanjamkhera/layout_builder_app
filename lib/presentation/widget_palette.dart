import 'package:flutter/material.dart';
import 'widget_colors.dart';

/// Widget palette displaying draggable widget types.
///
/// Provides a collection of draggable widgets (A, B, C, D) that can be
/// dragged onto the canvas. Supports both horizontal and vertical layouts
/// for responsive design. Horizontal layout is used on small screens,
/// vertical layout is used as a sidebar on larger screens.
class WidgetPalette extends StatelessWidget {
  final bool isHorizontal;

  const WidgetPalette({
    super.key,
    this.isHorizontal = false,
  });

  static const List<String> widgetTypes = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
      ),
      child: isHorizontal
          ? _buildHorizontalLayout(context)
          : _buildVerticalLayout(context),
    );
  }

  /// Builds a horizontal scrollable layout for small screens.
  Widget _buildHorizontalLayout(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: widgetTypes.length,
        itemBuilder: (context, index) {
          final widgetType = widgetTypes[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _DraggableWidgetItem(
              widgetType: widgetType,
              size: 80,
            ),
          );
        },
      ),
    );
  }

  /// Builds a vertical scrollable layout for sidebar display.
  Widget _buildVerticalLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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

/// Individual draggable widget item in the palette.
///
/// Displays a colored square widget that can be dragged onto the canvas.
/// Size is either fixed (for horizontal layout) or calculated as 60% of
/// the container width (for vertical layout). Provides visual feedback
/// during drag operations with elevated shadow and placeholder state.
class _DraggableWidgetItem extends StatelessWidget {
  final String widgetType;
  final double? size;

  const _DraggableWidgetItem({
    required this.widgetType,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final widgetSize = size ?? constraints.maxWidth * 0.6;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Draggable<String>(
            data: widgetType,
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
