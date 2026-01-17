import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/layout_bloc.dart';
import '../bloc/layout_events.dart';
import '../models/widget_model.dart';

/// Types of resize handles positioned on widget corners and edges.
enum ResizeHandleType {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  top,
  right,
  bottom,
  left,
}

/// Resize handle widget for resizing canvas widgets by dragging.
///
/// Implements delta-based resize calculations that store initial widget state
/// and compute new dimensions based on drag deltas. Handles enforce minimum size
/// constraints (50px) and clamp to canvas bounds (1920x1080). Corner handles
/// modify both dimensions and position, while edge handles modify one dimension
/// and may adjust position. Blocks InteractiveViewer pan/zoom during resize
/// operations to prevent gesture conflicts.
class ResizeHandle extends StatefulWidget {
  final WidgetModel widget;
  final GlobalKey canvasKey;
  final TransformationController transformationController;
  final ResizeHandleType handleType;
  final VoidCallback onResizeStart;
  final VoidCallback onResizeEnd;

  const ResizeHandle({
    super.key,
    required this.widget,
    required this.canvasKey,
    required this.transformationController,
    required this.handleType,
    required this.onResizeStart,
    required this.onResizeEnd,
  });

  @override
  State<ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<ResizeHandle> {
  static const double _handleSize = 10.0;
  static const double _minSize = 50.0;

  Offset? _startPanPosition;
  double? _startWidgetX;
  double? _startWidgetY;
  double? _startWidgetWidth;
  double? _startWidgetHeight;

  @override
  void dispose() {
    _startPanPosition = null;
    _startWidgetX = null;
    _startWidgetY = null;
    _startWidgetWidth = null;
    _startWidgetHeight = null;
    super.dispose();
  }

  /// Converts global screen coordinates to canvas-local coordinates.
  ///
  /// Accounts for InteractiveViewer zoom and pan transformations by using
  /// [RenderBox.globalToLocal], which automatically applies the transformation
  /// matrix.
  Offset _globalToCanvas(Offset globalPosition) {
    final canvasRenderBox =
        widget.canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (canvasRenderBox == null) return Offset.zero;
    return canvasRenderBox.globalToLocal(globalPosition);
  }

  /// Returns the handle position relative to the widget's top-left corner.
  Offset _getHandlePosition() {
    final w = widget.widget.width;
    final h = widget.widget.height;

    switch (widget.handleType) {
      case ResizeHandleType.topLeft:
        return const Offset(0, 0);
      case ResizeHandleType.topRight:
        return Offset(w, 0);
      case ResizeHandleType.bottomLeft:
        return Offset(0, h);
      case ResizeHandleType.bottomRight:
        return Offset(w, h);
      case ResizeHandleType.top:
        return Offset(w / 2, 0);
      case ResizeHandleType.right:
        return Offset(w, h / 2);
      case ResizeHandleType.bottom:
        return Offset(w / 2, h);
      case ResizeHandleType.left:
        return Offset(0, h / 2);
    }
  }

  /// Returns the appropriate mouse cursor for the handle type.
  SystemMouseCursor _getCursor() {
    switch (widget.handleType) {
      case ResizeHandleType.topLeft:
      case ResizeHandleType.bottomRight:
        return SystemMouseCursors.resizeUpLeftDownRight;
      case ResizeHandleType.topRight:
      case ResizeHandleType.bottomLeft:
        return SystemMouseCursors.resizeUpRightDownLeft;
      case ResizeHandleType.top:
      case ResizeHandleType.bottom:
        return SystemMouseCursors.resizeUpDown;
      case ResizeHandleType.left:
      case ResizeHandleType.right:
        return SystemMouseCursors.resizeLeftRight;
    }
  }

  /// Stores initial widget state when resize begins.
  void _onPanStart(Offset globalPosition) {
    _startPanPosition = _globalToCanvas(globalPosition);
    _startWidgetX = widget.widget.x;
    _startWidgetY = widget.widget.y;
    _startWidgetWidth = widget.widget.width;
    _startWidgetHeight = widget.widget.height;
  }

  /// Calculates new widget dimensions and position based on drag delta.
  ///
  /// Applies handle-specific resize logic: corner handles modify both dimensions
  /// and position, edge handles modify one dimension and may adjust position.
  /// Enforces minimum size constraints and canvas bounds, adjusting position
  /// when necessary to maintain constraints. Dispatches [ResizeWidgetEvent] and
  /// [MoveWidgetEvent] to the BLoC for state updates.
  void _onPanUpdate(Offset globalPosition) {
    if (!mounted) return;

    if (_startPanPosition == null ||
        _startWidgetX == null ||
        _startWidgetY == null ||
        _startWidgetWidth == null ||
        _startWidgetHeight == null) {
      return;
    }

    final currentCanvasPos = _globalToCanvas(globalPosition);
    final deltaX = currentCanvasPos.dx - _startPanPosition!.dx;
    final deltaY = currentCanvasPos.dy - _startPanPosition!.dy;

    double newWidth = _startWidgetWidth!;
    double newHeight = _startWidgetHeight!;
    double newX = _startWidgetX!;
    double newY = _startWidgetY!;

    switch (widget.handleType) {
      case ResizeHandleType.topLeft:
        newWidth = _startWidgetWidth! - deltaX;
        newHeight = _startWidgetHeight! - deltaY;
        newX = _startWidgetX! + deltaX;
        newY = _startWidgetY! + deltaY;
        break;
      case ResizeHandleType.topRight:
        newWidth = _startWidgetWidth! + deltaX;
        newHeight = _startWidgetHeight! - deltaY;
        newY = _startWidgetY! + deltaY;
        break;
      case ResizeHandleType.bottomLeft:
        newWidth = _startWidgetWidth! - deltaX;
        newHeight = _startWidgetHeight! + deltaY;
        newX = _startWidgetX! + deltaX;
        break;
      case ResizeHandleType.bottomRight:
        newWidth = _startWidgetWidth! + deltaX;
        newHeight = _startWidgetHeight! + deltaY;
        break;
      case ResizeHandleType.top:
        newHeight = _startWidgetHeight! - deltaY;
        newY = _startWidgetY! + deltaY;
        break;
      case ResizeHandleType.right:
        newWidth = _startWidgetWidth! + deltaX;
        break;
      case ResizeHandleType.bottom:
        newHeight = _startWidgetHeight! + deltaY;
        break;
      case ResizeHandleType.left:
        newWidth = _startWidgetWidth! - deltaX;
        newX = _startWidgetX! + deltaX;
        break;
    }

    if (newWidth < _minSize) {
      newWidth = _minSize;
      if (widget.handleType == ResizeHandleType.topLeft ||
          widget.handleType == ResizeHandleType.bottomLeft ||
          widget.handleType == ResizeHandleType.left) {
        newX = _startWidgetX! + (_startWidgetWidth! - _minSize);
      }
    }

    if (newHeight < _minSize) {
      newHeight = _minSize;
      if (widget.handleType == ResizeHandleType.topLeft ||
          widget.handleType == ResizeHandleType.topRight ||
          widget.handleType == ResizeHandleType.top) {
        newY = _startWidgetY! + (_startWidgetHeight! - _minSize);
      }
    }

    const fixedCanvasWidth = 1920.0;
    const fixedCanvasHeight = 1080.0;

    newX = newX < 0 ? 0 : newX;
    newY = newY < 0 ? 0 : newY;

    if (newX + newWidth > fixedCanvasWidth) {
      newWidth = fixedCanvasWidth - newX;
      if (newWidth < _minSize) {
        newWidth = _minSize;
        newX = fixedCanvasWidth - _minSize;
      }
    }

    if (newY + newHeight > fixedCanvasHeight) {
      newHeight = fixedCanvasHeight - newY;
      if (newHeight < _minSize) {
        newHeight = _minSize;
        newY = fixedCanvasHeight - _minSize;
      }
    }

    newWidth = newWidth.clamp(_minSize, fixedCanvasWidth - newX);
    newHeight = newHeight.clamp(_minSize, fixedCanvasHeight - newY);

    if (!mounted) return;

    context.read<LayoutBloc>().add(
          ResizeWidgetEvent(
            widgetId: widget.widget.id,
            newWidth: newWidth,
            newHeight: newHeight,
          ),
        );

    if (newX != widget.widget.x || newY != widget.widget.y) {
      if (!mounted) return;
      context.read<LayoutBloc>().add(
            MoveWidgetEvent(
              widgetId: widget.widget.id,
              newX: newX,
              newY: newY,
            ),
          );
    }
  }

  /// Cleans up resize state when drag ends.
  void _onPanEnd() {
    _startPanPosition = null;
    _startWidgetX = null;
    _startWidgetY = null;
    _startWidgetWidth = null;
    _startWidgetHeight = null;
  }

  @override
  Widget build(BuildContext context) {
    final position = _getHandlePosition();
    final hitAreaSize = _handleSize * 2;
    const stackPadding = 10.0;

    return Positioned(
      left: position.dx - (hitAreaSize / 2) + stackPadding,
      top: position.dy - (hitAreaSize / 2) + stackPadding,
      child: Listener(
        onPointerDown: (_) {},
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(
          cursor: _getCursor(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              widget.onResizeStart();
              _onPanStart(details.globalPosition);
            },
            onPanUpdate: (details) {
              if (mounted) {
                _onPanUpdate(details.globalPosition);
              }
            },
            onPanEnd: (_) {
              if (mounted) {
                _onPanEnd();
                widget.onResizeEnd();
              }
            },
            onPanCancel: () {
              if (mounted) {
                _onPanEnd();
                widget.onResizeEnd();
              }
            },
            child: Container(
              width: hitAreaSize,
              height: hitAreaSize,
              color: Colors.transparent,
              alignment: Alignment.center,
              child: Container(
                width: _handleSize,
                height: _handleSize,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
