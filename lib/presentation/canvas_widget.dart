import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/layout_bloc.dart';
import '../bloc/layout_events.dart';
import '../bloc/layout_state.dart';
import '../models/layout_model.dart';
import 'dot_grid_painter.dart';
import 'zoom_controls.dart';
import 'draggable_canvas_widget.dart';

/// Canvas Widget - Where widgets are placed and rendered
class CanvasWidget extends StatefulWidget {
  const CanvasWidget({super.key});

  @override
  State<CanvasWidget> createState() => _CanvasWidgetState();
}

class _CanvasWidgetState extends State<CanvasWidget> {
  // GlobalKey to reference the canvas container for position calculations
  final GlobalKey _canvasKey = GlobalKey();
  
  // Fixed canvas size (design canvas dimensions)
  static const double _fixedCanvasWidth = 1920.0;
  static const double _fixedCanvasHeight = 1080.0;
  
  // Zoom controller for InteractiveViewer
  final TransformationController _transformationController = TransformationController();
  
  // Min and max zoom levels - allow zooming out enough to see full canvas on small screens
  static const double _minScale = 0.1; // Can zoom out to 10% (allows seeing full canvas on phones)
  static const double _maxScale = 3.0;
  
  // Track if we've initialized the canvas to appear at 1:1 scale (1920x1080)
  bool _hasInitialized = false;
  
  // Track if any widget is being dragged or resized - disable pan when true
  bool _isWidgetInteracting = false;
  
  void _onWidgetInteractionStart() {
    setState(() {
      _isWidgetInteracting = true;
    });
  }
  
  void _onWidgetInteractionEnd() {
    setState(() {
      _isWidgetInteracting = false;
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  // Initialize canvas to appear at 1:1 scale (1920x1080) - only called once on first build
  void _initializeCanvas() {
    if (_hasInitialized) return;
    
    _hasInitialized = true;
    
    // Set canvas to appear at actual size (scale 1.0, no translation)
    // Apply after InteractiveViewer is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _transformationController.value = Matrix4.identity();
      }
    });
  }

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.2).clamp(_minScale, _maxScale);
    
    // Get current transformation
    final currentMatrix = _transformationController.value;
    final currentTranslation = currentMatrix.getTranslation();
    
    // Apply scale and preserve translation (scale translation proportionally)
    _transformationController.value = Matrix4.identity()
      ..scale(newScale)
      ..translate(
        currentTranslation.x * (newScale / currentScale),
        currentTranslation.y * (newScale / currentScale),
      );
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale / 1.2).clamp(_minScale, _maxScale);
    
    // Get current transformation
    final currentMatrix = _transformationController.value;
    final currentTranslation = currentMatrix.getTranslation();
    
    // Apply scale and preserve translation (scale translation proportionally)
    _transformationController.value = Matrix4.identity()
      ..scale(newScale)
      ..translate(
        currentTranslation.x * (newScale / currentScale),
        currentTranslation.y * (newScale / currentScale),
      );
  }

  void _resetZoom() {
    // Reset: show canvas at actual 1920x1080 size (scale 1.0, no translation)
    _transformationController.value = Matrix4.identity();
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
          return _buildEmptyCanvas();
        }

        // Render canvas with widgets
        return _buildCanvasWithWidgets(activeLayout);
      },
    );
  }

  Widget _buildEmptyCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Initialize canvas to appear at 1:1 scale (1920x1080) on first build
        _initializeCanvas();
        
        return Stack(
          children: [
            // Background layer (full viewport)
            Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              color: const Color(0xFFFAFBFC),
            ),
            // Interactive viewer for zoom and pan
            InteractiveViewer(
              transformationController: _transformationController,
              minScale: _minScale,
              maxScale: _maxScale,
              panEnabled: !_isWidgetInteracting, // Disable pan when widgets are being interacted with
              boundaryMargin: const EdgeInsets.all(20),
              child: Container(
                key: _canvasKey,
                width: _fixedCanvasWidth,
                height: _fixedCanvasHeight,
                color: const Color(0xFFFAFBFC),
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  child: DragTarget<String>(
                    onWillAccept: (data) => true,
                    onAcceptWithDetails: (details) {
                      _handleWidgetDrop(details);
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Stack(
                        children: [
                          CustomPaint(
                            painter: DotGridPainter(),
                            size: Size(_fixedCanvasWidth, _fixedCanvasHeight),
                          ),
                          // Show drop hint text when dragging
                          if (candidateData != null)
                            Center(
                              child: Text(
                                'Drop ${candidateData} here',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            // Zoom controls overlay
            Positioned(
              bottom: 16,
              right: 16,
              child: ZoomControls(
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

  Widget _buildCanvasWithWidgets(LayoutModel activeLayout) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Initialize canvas to appear at 1:1 scale (1920x1080) on first build
        _initializeCanvas();
        
        return Stack(
          children: [
            // Background layer (full viewport)
            Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              color: const Color(0xFFFAFBFC),
            ),
            // Interactive viewer for zoom and pan
            InteractiveViewer(
              transformationController: _transformationController,
              minScale: _minScale,
              maxScale: _maxScale,
              panEnabled: !_isWidgetInteracting, // Disable pan when widgets are being interacted with
              boundaryMargin: const EdgeInsets.all(20),
              child: Container(
                key: _canvasKey,
                width: _fixedCanvasWidth,
                height: _fixedCanvasHeight,
                color: const Color(0xFFFAFBFC),
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  child: DragTarget<String>(
                    onWillAccept: (data) => true,
                    onAcceptWithDetails: (details) {
                      _handleWidgetDrop(details);
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Stack(
                        children: [
                          // Grid pattern background
                          CustomPaint(
                            painter: DotGridPainter(),
                            size: Size(_fixedCanvasWidth, _fixedCanvasHeight),
                          ),
                          // Render all widgets from active layout
                          ...activeLayout.widgets.map((widget) {
                            // Offset by 10px to account for Stack padding in DraggableCanvasWidget
                            const stackPadding = 10.0;
                            return Positioned(
                              left: widget.x - stackPadding,
                              top: widget.y - stackPadding,
                              child: DraggableCanvasWidget(
                                widget: widget,
                                canvasKey: _canvasKey,
                                transformationController: _transformationController,
                                onInteractionStart: _onWidgetInteractionStart,
                                onInteractionEnd: _onWidgetInteractionEnd,
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            // Zoom controls overlay
            Positioned(
              bottom: 16,
              right: 16,
              child: ZoomControls(
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

  void _handleWidgetDrop(DragTargetDetails<String> details) {
    final widgetType = details.data;
    print('✅ Drop accepted: $widgetType');
    
    // Get canvas render box
    final RenderBox? canvasRenderBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (canvasRenderBox == null) return;
    
    // Convert global drop position to canvas local coordinates
    // globalToLocal automatically accounts for InteractiveViewer transformation
    final canvasLocalPos = canvasRenderBox.globalToLocal(details.offset);
    
    // Canvas coordinates (already accounts for zoom and pan)
    final x = canvasLocalPos.dx.clamp(0.0, _fixedCanvasWidth - 100); // 100 is widget width
    final y = canvasLocalPos.dy.clamp(0.0, _fixedCanvasHeight - 100); // 100 is widget height

    // Send AddWidgetEvent to BLoC with actual drop position
    context.read<LayoutBloc>().add(
          AddWidgetEvent(
            type: widgetType,
            x: x,
            y: y,
          ),
        );
    print('✅ AddWidgetEvent sent: $widgetType at ($x, $y)');
  }
}
