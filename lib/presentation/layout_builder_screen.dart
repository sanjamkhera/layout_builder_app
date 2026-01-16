import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/layout_bloc.dart';
import '../bloc/layout_events.dart';
import '../bloc/layout_state.dart';
import '../repository/layout_repository.dart';
import '../models/widget_model.dart';

/// Main layout builder screen
/// 
/// Contains:
/// - Widget palette (left side)
/// - Canvas (center) - where widgets are placed
/// - BLoC integration for state management
class LayoutBuilderScreen extends StatelessWidget {
  const LayoutBuilderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide LayoutBloc to the widget tree
    return BlocProvider(
      create: (context) => LayoutBloc(
        repository: LayoutRepository(),
      )..add(const LoadLayoutsEvent()), // Load layouts when screen opens
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Layout Builder'),
          backgroundColor: Colors.blue,
        ),
        body: const Row(
          children: [
            // Widget Palette (left side)
            WidgetPalette(),
            // Canvas (right side - takes remaining space)
            Expanded(
              child: CanvasWidget(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget Palette - Side menu with draggable widgets (A, B, C, D)
class WidgetPalette extends StatelessWidget {
  const WidgetPalette({super.key});

  // Available widget types
  static const List<String> widgetTypes = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Widgets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(),
          // List of draggable widgets
          Expanded(
            child: ListView.builder(
              itemCount: widgetTypes.length,
              itemBuilder: (context, index) {
                final widgetType = widgetTypes[index];
                return _DraggableWidgetItem(widgetType: widgetType);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual draggable widget item in palette
class _DraggableWidgetItem extends StatelessWidget {
  final String widgetType;

  const _DraggableWidgetItem({required this.widgetType});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Draggable<String>(
        data: widgetType, // Data to pass when dragged
        onDragEnd: (details) {
          print('🔄 Drag ended for: $widgetType');
        },
        feedback: Material(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
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
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(8),
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
  }
}

/// Canvas Widget - Where widgets are placed and rendered
class CanvasWidget extends StatefulWidget {
  const CanvasWidget({super.key});

  @override
  State<CanvasWidget> createState() => _CanvasWidgetState();
}

class _CanvasWidgetState extends State<CanvasWidget> {
  // GlobalKey to reference the canvas container for position calculations
  final GlobalKey _canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LayoutBloc, LayoutState>(
      builder: (context, state) {
        // Show loading indicator while loading
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Show error if any
        if (state.error != null) {
          return Center(
            child: Text(
              'Error: ${state.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        // Get active layout
        final activeLayout = state.activeLayout;

        // If no active layout, show empty canvas
        if (activeLayout == null || activeLayout.widgets.isEmpty) {
          return DragTarget<String>(
            onWillAccept: (data) => true, // Accept any String data
            onAcceptWithDetails: (details) {
              final widgetType = details.data;
              print('✅ Drop accepted: $widgetType');
              
              // Get actual drop position relative to canvas
              final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
              if (renderBox == null) return;
              
              // Get drop position relative to canvas
              final localPosition = renderBox.globalToLocal(details.offset);
              
              // Adjust for widget center (widget is 100x100, so offset by 50)
              final x = localPosition.dx - 50;
              final y = localPosition.dy - 50;

              // Send AddWidgetEvent to BLoC with actual drop position
              context.read<LayoutBloc>().add(
                    AddWidgetEvent(
                      type: widgetType,
                      x: x,
                      y: y,
                    ),
                  );
              print('✅ AddWidgetEvent sent: $widgetType at ($x, $y)');
            },
            builder: (context, candidateData, rejectedData) {
              return Container(
                color: candidateData != null ? Colors.blue.shade50 : Colors.white,
                child: Center(
                  child: Text(
                    candidateData != null 
                        ? 'Drop ${candidateData} here'
                        : 'Drop widgets here',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              );
            },
          );
        }

        // Render canvas with widgets
        return DragTarget<String>(
          onWillAccept: (data) => true, // Accept any String data
          onAcceptWithDetails: (details) {
            final widgetType = details.data;
            print('✅ Drop accepted: $widgetType');
            
            // Get actual drop position relative to canvas
            final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox == null) return;
            
            // Get drop position relative to canvas
            final localPosition = renderBox.globalToLocal(details.offset);
            
            // Adjust for widget center (widget is 100x100, so offset by 50)
            final x = localPosition.dx - 50;
            final y = localPosition.dy - 50;

            // Send AddWidgetEvent to BLoC with actual drop position
            context.read<LayoutBloc>().add(
                  AddWidgetEvent(
                    type: widgetType,
                    x: x,
                    y: y,
                  ),
                );
            print('✅ AddWidgetEvent sent: $widgetType at ($x, $y)');
          },
          builder: (context, candidateData, rejectedData) {
            return Container(
              key: _canvasKey, // Add key to canvas container
              color: Colors.white,
              child: Stack(
                children: [
                  // Render all widgets from active layout
                  ...activeLayout.widgets.map((widget) {
                    return Positioned(
                      left: widget.x,
                      top: widget.y,
                      child: _DraggableCanvasWidget(
                        widget: widget,
                        canvasKey: _canvasKey, // Pass key to widget
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Draggable widget on canvas - allows moving widgets around
class _DraggableCanvasWidget extends StatelessWidget {
  final WidgetModel widget;
  final GlobalKey canvasKey;

  const _DraggableCanvasWidget({
    required this.widget,
    required this.canvasKey,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<WidgetModel>(
      data: widget, // Pass widget data when dragging
      onDragEnd: (details) {
        // Get the canvas container's RenderBox using the GlobalKey
        final canvasRenderBox = canvasKey.currentContext?.findRenderObject() as RenderBox?;
        if (canvasRenderBox == null) {
          print('❌ Could not find canvas RenderBox');
          return;
        }
        
        // Convert global drop position to local canvas coordinates
        final localPosition = canvasRenderBox.globalToLocal(details.offset);
        
        // Adjust for widget center (so widget center aligns with drop position)
        final newX = localPosition.dx - (widget.width / 2);
        final newY = localPosition.dy - (widget.height / 2);
        
        // Ensure position is not negative
        final clampedX = newX < 0 ? 0.0 : newX;
        final clampedY = newY < 0 ? 0.0 : newY;
        
        // Send MoveWidgetEvent to BLoC
        context.read<LayoutBloc>().add(
              MoveWidgetEvent(
                widgetId: widget.id,
                newX: clampedX,
                newY: clampedY,
              ),
            );
        print('🔄 MoveWidgetEvent sent: ${widget.id} to ($clampedX, $clampedY)');
      },
      feedback: Material(
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.7),
            border: Border.all(color: Colors.blue.shade700, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              widget.type,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          border: Border.all(color: Colors.grey, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: DragTarget<WidgetModel>(
        onAcceptWithDetails: (details) {
          // Get drop position relative to canvas
          final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox == null) return;
          
          // Get drop position relative to canvas
          final localPosition = renderBox.globalToLocal(details.offset);
          
          // Adjust for widget center
          final newX = localPosition.dx - (widget.width / 2);
          final newY = localPosition.dy - (widget.height / 2);

          // Send MoveWidgetEvent to BLoC
          context.read<LayoutBloc>().add(
                MoveWidgetEvent(
                  widgetId: widget.id,
                  newX: newX,
                  newY: newY,
                ),
              );
          print('✅ MoveWidgetEvent sent: ${widget.id} to ($newX, $newY)');
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: candidateData != null ? Colors.blue.shade300 : Colors.blue,
              border: Border.all(color: Colors.blue.shade700, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                widget.type,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
