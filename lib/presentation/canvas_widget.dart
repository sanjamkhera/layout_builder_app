import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/layout_bloc.dart';
import '../bloc/layout_events.dart';
import '../bloc/layout_state.dart';
import '../models/layout_model.dart';
import 'dot_grid_painter.dart';
import 'zoom_controls.dart';
import 'draggable_canvas_widget.dart';

/// Canvas widget for placing and rendering draggable widgets.
///
/// Provides a fixed-size design canvas (1920x1080) with zoom and pan
/// capabilities. Supports dropping widgets from the palette and displays
/// all widgets from the active layout. Panning is disabled while widgets
/// are being dragged or resized to prevent interference.
class CanvasWidget extends StatefulWidget {
  const CanvasWidget({super.key});

  @override
  State<CanvasWidget> createState() => _CanvasWidgetState();
}

class _CanvasWidgetState extends State<CanvasWidget> {
  final GlobalKey _canvasKey = GlobalKey();
  static const double _fixedCanvasWidth = 1920.0;
  static const double _fixedCanvasHeight = 1080.0;
  final TransformationController _transformationController =
      TransformationController();
  static const double _minScale = 1.0;
  static const double _maxScale = 3.0;
  bool _hasInitialized = false;
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

  /// Initializes the canvas to display at 1:1 scale on first build.
  void _initializeCanvas() {
    if (_hasInitialized) return;
    _hasInitialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _transformationController.value = Matrix4.identity();
      }
    });
  }

  /// Zooms in by 20%, preserving the current translation.
  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.2).clamp(_minScale, _maxScale);
    final currentMatrix = _transformationController.value;
    final currentTranslation = currentMatrix.getTranslation();

    _transformationController.value = Matrix4.identity()
      ..scale(newScale)
      ..translate(
        currentTranslation.x * (newScale / currentScale),
        currentTranslation.y * (newScale / currentScale),
      );
  }

  /// Zooms out by 20%, preserving the current translation.
  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale / 1.2).clamp(_minScale, _maxScale);
    final currentMatrix = _transformationController.value;
    final currentTranslation = currentMatrix.getTranslation();

    _transformationController.value = Matrix4.identity()
      ..scale(newScale)
      ..translate(
        currentTranslation.x * (newScale / currentScale),
        currentTranslation.y * (newScale / currentScale),
      );
  }

  /// Resets zoom and pan to show canvas at 1:1 scale with no translation.
  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LayoutBloc, LayoutState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state.error != null) {
          return Center(
            child: Text(
              'Error: ${state.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final activeLayout = state.activeLayout;
        if (activeLayout == null || activeLayout.widgets.isEmpty) {
          return _buildEmptyCanvas();
        }

        return _buildCanvasWithWidgets(activeLayout);
      },
    );
  }

  /// Builds an empty canvas with drop target functionality.
  Widget _buildEmptyCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        _initializeCanvas();

        return Stack(
          children: [
            Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              color: const Color(0xFFFAFBFC),
            ),
            InteractiveViewer(
              constrained: false,
              transformationController: _transformationController,
              minScale: _minScale,
              maxScale: _maxScale,
              panEnabled: !_isWidgetInteracting,
              child: Container(
                key: _canvasKey,
                width: _fixedCanvasWidth,
                height: _fixedCanvasHeight,
                color: const Color(0xFFFAFBFC),
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  child: DragTarget<String>(
                    onWillAccept: (data) => true,
                    onAcceptWithDetails: _handleWidgetDrop,
                    builder: (context, candidateData, rejectedData) {
                      return Stack(
                        children: [
                          CustomPaint(
                            painter: DotGridPainter(),
                            size: Size(_fixedCanvasWidth, _fixedCanvasHeight),
                          ),
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

  /// Builds the canvas with widgets from the active layout.
  Widget _buildCanvasWithWidgets(LayoutModel activeLayout) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _initializeCanvas();

        return Stack(
          children: [
            Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              color: const Color(0xFFFAFBFC),
            ),
            InteractiveViewer(
              constrained: false,
              transformationController: _transformationController,
              minScale: _minScale,
              maxScale: _maxScale,
              panEnabled: !_isWidgetInteracting,
              child: Container(
                key: _canvasKey,
                width: _fixedCanvasWidth,
                height: _fixedCanvasHeight,
                color: const Color(0xFFFAFBFC),
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  child: DragTarget<String>(
                    onWillAccept: (data) => true,
                    onAcceptWithDetails: _handleWidgetDrop,
                    builder: (context, candidateData, rejectedData) {
                      return Stack(
                        children: [
                          CustomPaint(
                            painter: DotGridPainter(),
                            size: Size(_fixedCanvasWidth, _fixedCanvasHeight),
                          ),
                          ...activeLayout.widgets.map((widget) {
                            const stackPadding = 10.0;
                            return Positioned(
                              left: widget.x - stackPadding,
                              top: widget.y - stackPadding,
                              child: DraggableCanvasWidget(
                                widget: widget,
                                canvasKey: _canvasKey,
                                transformationController:
                                    _transformationController,
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

  /// Handles widget drop events, converting global coordinates to canvas-local
  /// coordinates and dispatching an [AddWidgetEvent] to the BLoC.
  void _handleWidgetDrop(DragTargetDetails<String> details) {
    final widgetType = details.data;
    final RenderBox? canvasRenderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (canvasRenderBox == null) return;

    final canvasLocalPos = canvasRenderBox.globalToLocal(details.offset);

    const defaultWidgetWidth = 100.0;
    const defaultWidgetHeight = 100.0;
    final maxX = _fixedCanvasWidth - defaultWidgetWidth;
    final maxY = _fixedCanvasHeight - defaultWidgetHeight;

    final x = canvasLocalPos.dx.clamp(0.0, maxX);
    final y = canvasLocalPos.dy.clamp(0.0, maxY);

    context.read<LayoutBloc>().add(
          AddWidgetEvent(
            type: widgetType,
            x: x,
            y: y,
          ),
        );
  }
}
