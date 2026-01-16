import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/layout_bloc.dart';
import '../bloc/layout_events.dart';
import '../bloc/layout_state.dart';
import '../repository/layout_repository.dart';
import '../models/widget_model.dart';

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

/// Main layout builder screen
/// 
/// Contains:
/// - Widget palette (left side or drawer)
/// - Canvas (center) - where widgets are placed
/// - BLoC integration for state management
class LayoutBuilderScreen extends StatefulWidget {
  const LayoutBuilderScreen({super.key});

  @override
  State<LayoutBuilderScreen> createState() => _LayoutBuilderScreenState();
}

class _LayoutBuilderScreenState extends State<LayoutBuilderScreen> {
  // Drawer state management
  bool _isDrawerPinned = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Breakpoint for switching between sidebar and drawer (768px is typical tablet breakpoint)
  static const double _breakpoint = 768.0;

  void _toggleDrawer() {
    if (_scaffoldKey.currentState!.isDrawerOpen) {
      _scaffoldKey.currentState!.closeDrawer();
    } else {
      _scaffoldKey.currentState!.openDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < _breakpoint;

    // Provide LayoutBloc to the widget tree
    return BlocProvider(
      create: (context) => LayoutBloc(
        repository: LayoutRepository(),
      )..add(const LoadLayoutsEvent()), // Load layouts when screen opens
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('Layout Builder'),
          backgroundColor: const Color(0xFF1E293B), // Modern dark slate
          foregroundColor: Colors.white,
          elevation: 0,
          leading: isSmallScreen
              ? IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: _toggleDrawer,
                  tooltip: 'Open widget palette',
                )
              : null,
        ),
        drawer: isSmallScreen
            ? Drawer(
                width: screenWidth * 0.7, // 70% of screen width
                child: Column(
                  children: [
                    // Drawer header with pin button
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E293B),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Widgets',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              _isDrawerPinned ? Icons.push_pin : Icons.push_pin_outlined,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _isDrawerPinned = !_isDrawerPinned;
                              });
                            },
                            tooltip: _isDrawerPinned ? 'Unpin drawer' : 'Pin drawer',
                          ),
                        ],
                      ),
                    ),
                    // Widget palette content
                    const Expanded(
                      child: WidgetPalette(),
                    ),
                  ],
                ),
              )
            : null,
        drawerEnableOpenDragGesture: !_isDrawerPinned,
        onDrawerChanged: (isOpened) {
          // When drawer is closed and not pinned, ensure it stays closed
          if (!isOpened && !_isDrawerPinned) {
            setState(() {});
          }
        },
        body: Row(
          children: [
            // Widget Palette (sidebar for large screens)
            if (!isSmallScreen)
              SizedBox(
                width: screenWidth * 0.15, // 15% of screen width
                child: const WidgetPalette(),
              ),
            // Canvas (takes remaining space)
            const Expanded(
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
      width: double.infinity, // Takes full width of parent (sidebar or drawer)
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9), // Cool slate gray
      ),
      child: Column(
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use 60% of container width, maintaining square aspect ratio
        final widgetSize = constraints.maxWidth * 0.6;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Draggable<String>(
            data: widgetType, // Data to pass when dragged
            onDragEnd: (details) {
              print('🔄 Drag ended for: $widgetType');
            },
            feedback: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: widgetSize,
                height: widgetSize,
            decoration: BoxDecoration(
              color: WidgetColors.getColor(widgetType),
              borderRadius: BorderRadius.circular(12),
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
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Container(
              width: widgetSize,
              height: widgetSize,
              decoration: BoxDecoration(
                color: WidgetColors.getColor(widgetType),
                borderRadius: BorderRadius.circular(12),
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

/// Canvas Widget - Where widgets are placed and rendered
class CanvasWidget extends StatefulWidget {
  const CanvasWidget({super.key});

  @override
  State<CanvasWidget> createState() => _CanvasWidgetState();
}

class _CanvasWidgetState extends State<CanvasWidget> {
  // GlobalKey to reference the canvas container for position calculations
  final GlobalKey _canvasKey = GlobalKey();
  
  // Zoom controller for InteractiveViewer
  final TransformationController _transformationController = TransformationController();
  
  // Min and max zoom levels
  static const double _minScale = 0.5;
  static const double _maxScale = 3.0;
  static const double _initialScale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformationController.value = Matrix4.identity()..scale(_initialScale);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.2).clamp(_minScale, _maxScale);
    _transformationController.value = Matrix4.identity()..scale(newScale);
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale / 1.2).clamp(_minScale, _maxScale);
    _transformationController.value = Matrix4.identity()..scale(newScale);
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity()..scale(_initialScale);
  }

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
          return Stack(
            children: [
              // Fixed background layer (doesn't zoom) - like Figma
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    color: const Color(0xFFFAFBFC),
                    child: CustomPaint(
                      painter: _DotGridPainter(),
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                    ),
                  );
                },
              ),
              // Interactive viewer for zoom and pan (only widgets layer)
              InteractiveViewer(
                transformationController: _transformationController,
                minScale: _minScale,
                maxScale: _maxScale,
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(100),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Make widgets canvas much larger to cover panned area
                    final screenSize = MediaQuery.of(context).size;
                    final canvasWidth = screenSize.width * 10;
                    final canvasHeight = screenSize.height * 10;
                    
                    return DragTarget<String>(
                      onWillAccept: (data) => true,
                      onAcceptWithDetails: (details) {
                        final widgetType = details.data;
                        print('✅ Drop accepted: $widgetType');
                        
                        // Get actual drop position relative to canvas
                        final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                        if (renderBox == null) return;
                        
                        // Get drop position relative to canvas (accounting for zoom)
                        final localPosition = renderBox.globalToLocal(details.offset);
                        final scale = _transformationController.value.getMaxScaleOnAxis();
                        
                        // Adjust for widget center and zoom
                        final x = (localPosition.dx / scale) - 50;
                        final y = (localPosition.dy / scale) - 50;

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
                          width: canvasWidth,
                          height: canvasHeight,
                          color: Colors.transparent, // Transparent so background shows through
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
                  },
                ),
              ),
              // Zoom controls overlay
              Positioned(
                bottom: 16,
                right: 16,
                child: _ZoomControls(
                  onZoomIn: _zoomIn,
                  onZoomOut: _zoomOut,
                  onReset: _resetZoom,
                ),
              ),
            ],
          );
        }

        // Render canvas with widgets
        return Stack(
          children: [
            // Fixed background layer (doesn't zoom) - like Figma
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  color: const Color(0xFFFAFBFC),
                  child: CustomPaint(
                    painter: _DotGridPainter(),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                );
              },
            ),
            // Interactive viewer for zoom and pan (only widgets layer)
            InteractiveViewer(
              transformationController: _transformationController,
              minScale: _minScale,
              maxScale: _maxScale,
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(100),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Make widgets canvas much larger to cover panned area
                  final screenSize = MediaQuery.of(context).size;
                  final canvasWidth = screenSize.width * 10;
                  final canvasHeight = screenSize.height * 10;
                  
                  return DragTarget<String>(
                    onWillAccept: (data) => true,
                    onAcceptWithDetails: (details) {
                      final widgetType = details.data;
                      print('✅ Drop accepted: $widgetType');
                      
                      // Get actual drop position relative to canvas
                      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                      if (renderBox == null) return;
                      
                      // Get drop position relative to canvas (accounting for zoom)
                      final localPosition = renderBox.globalToLocal(details.offset);
                      final scale = _transformationController.value.getMaxScaleOnAxis();
                      
                      // Adjust for widget center and zoom
                      final x = (localPosition.dx / scale) - 50;
                      final y = (localPosition.dy / scale) - 50;

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
                        key: _canvasKey,
                        width: canvasWidth,
                        height: canvasHeight,
                        color: Colors.transparent, // Transparent so background shows through
                        child: Stack(
                          children: [
                            // Render all widgets from active layout
                            ...activeLayout.widgets.map((widget) {
                              return Positioned(
                                left: widget.x,
                                top: widget.y,
                                child: _DraggableCanvasWidget(
                                  widget: widget,
                                  canvasKey: _canvasKey,
                                  transformationController: _transformationController,
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Zoom controls overlay
            Positioned(
              bottom: 16,
              right: 16,
              child: _ZoomControls(
                onZoomIn: _zoomIn,
                onZoomOut: _zoomOut,
                onReset: _resetZoom,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Draggable widget on canvas - allows moving widgets around
class _DraggableCanvasWidget extends StatelessWidget {
  final WidgetModel widget;
  final GlobalKey canvasKey;
  final TransformationController transformationController;

  const _DraggableCanvasWidget({
    required this.widget,
    required this.canvasKey,
    required this.transformationController,
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
        
        // Get current zoom scale
        final scale = transformationController.value.getMaxScaleOnAxis();
        
        // Adjust for widget center and zoom (divide by scale to get actual canvas coordinates)
        final newX = (localPosition.dx / scale) - (widget.width / 2);
        final newY = (localPosition.dy / scale) - (widget.height / 2);
        
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
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: WidgetColors.getColor(widget.type).withOpacity(0.8),
            border: Border.all(
              color: WidgetColors.getBorderColor(widget.type),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
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
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey[400]!, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: DragTarget<WidgetModel>(
        onAcceptWithDetails: (details) {
          // Get drop position relative to canvas
          final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox == null) return;
          
          // Get drop position relative to canvas
          final localPosition = renderBox.globalToLocal(details.offset);
          
          // Get current zoom scale
          final scale = transformationController.value.getMaxScaleOnAxis();
          
          // Adjust for widget center and zoom (divide by scale to get actual canvas coordinates)
          final newX = (localPosition.dx / scale) - (widget.width / 2);
          final newY = (localPosition.dy / scale) - (widget.height / 2);

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
          final widgetColor = WidgetColors.getColor(widget.type);
          final borderColor = WidgetColors.getBorderColor(widget.type);
          
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: candidateData != null 
                  ? widgetColor.withOpacity(0.7) 
                  : widgetColor,
              border: Border.all(
                color: borderColor,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: widgetColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
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

/// Zoom controls widget
class _ZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  const _ZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: onZoomIn,
            tooltip: 'Zoom in',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: onZoomOut,
            tooltip: 'Zoom out',
          ),
          const Divider(height: 1),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            onPressed: onReset,
            tooltip: 'Reset zoom',
          ),
        ],
      ),
    );
  }
}

/// Custom painter that draws a dot grid pattern on the canvas
class _DotGridPainter extends CustomPainter {
  // Grid spacing (distance between dots)
  static const double _gridSpacing = 20.0;
  
  // Dot radius
  static const double _dotRadius = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0).withOpacity(0.6) // Modern subtle gray
      ..style = PaintingStyle.fill;

    // Draw dots in a grid pattern
    for (double x = 0; x < size.width; x += _gridSpacing) {
      for (double y = 0; y < size.height; y += _gridSpacing) {
        canvas.drawCircle(Offset(x, y), _dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
