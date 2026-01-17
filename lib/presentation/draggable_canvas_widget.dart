import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/layout_bloc.dart';
import '../bloc/layout_events.dart';
import '../models/widget_model.dart';
import 'widget_colors.dart';
import 'resize_handle.dart';

/// Draggable widget displayed on the canvas.
///
/// Supports dragging and resizing via 8 resize handles (4 corners + 4 edges).
/// Automatically disables canvas panning during drag/resize operations to
/// prevent gesture conflicts. Widgets are constrained to the canvas bounds
/// (1920x1080) and positions are updated in real-time during drag operations.
class DraggableCanvasWidget extends StatefulWidget {
  final WidgetModel widget;
  final GlobalKey canvasKey;
  final TransformationController transformationController;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;

  const DraggableCanvasWidget({
    super.key,
    required this.widget,
    required this.canvasKey,
    required this.transformationController,
    this.onInteractionStart,
    this.onInteractionEnd,
  });

  @override
  State<DraggableCanvasWidget> createState() => _DraggableCanvasWidgetState();
}

class _DraggableCanvasWidgetState extends State<DraggableCanvasWidget> {
  bool _isDragging = false;
  bool _isResizing = false;
  Offset? _lastDragPosition;
  Offset? _dragOffset;

  /// Checks if a point is within any resize handle area.
  ///
  /// Handles can extend beyond widget bounds, so this accounts for the
  /// overflow area when detecting handle interactions.
  bool _isPointOnHandle(Offset localPoint) {
    const handleSize = 10.0;
    const handleHitArea = handleSize * 2;
    final w = widget.widget.width;
    final h = widget.widget.height;

    final handles = [
      Offset(0, 0),
      Offset(w, 0),
      Offset(0, h),
      Offset(w, h),
      Offset(w / 2, 0),
      Offset(w, h / 2),
      Offset(w / 2, h),
      Offset(0, h / 2),
    ];

    for (final handlePos in handles) {
      final handleRect = Rect.fromCenter(
        center: handlePos,
        width: handleHitArea,
        height: handleHitArea,
      );
      if (handleRect.contains(localPoint)) {
        return true;
      }
    }
    return false;
  }

  /// Handles the start of a drag gesture.
  ///
  /// Calculates the drag offset from the widget's top-left corner and
  /// prevents dragging if the pointer is on a resize handle.
  void _onPanStart(DragStartDetails details) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPoint = renderBox.globalToLocal(details.globalPosition);
    if (_isPointOnHandle(localPoint)) {
      return;
    }

    final canvasRenderBox =
        widget.canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (canvasRenderBox == null) return;

    final canvasLocalPos = canvasRenderBox.globalToLocal(details.globalPosition);
    final dragOffsetX = canvasLocalPos.dx - widget.widget.x;
    final dragOffsetY = canvasLocalPos.dy - widget.widget.y;

    setState(() {
      _isDragging = true;
      _lastDragPosition = details.globalPosition;
      _dragOffset = Offset(dragOffsetX, dragOffsetY);
    });

    widget.onInteractionStart?.call();
  }

  /// Updates widget position during drag, clamping to canvas bounds.
  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging || _dragOffset == null) return;

    _lastDragPosition = details.globalPosition;
    final canvasRenderBox =
        widget.canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (canvasRenderBox == null) return;

    final canvasLocalPos = canvasRenderBox.globalToLocal(details.globalPosition);
    final newX = canvasLocalPos.dx - _dragOffset!.dx;
    final newY = canvasLocalPos.dy - _dragOffset!.dy;

    const fixedCanvasWidth = 1920.0;
    const fixedCanvasHeight = 1080.0;
    final maxX = fixedCanvasWidth - widget.widget.width;
    final maxY = fixedCanvasHeight - widget.widget.height;

    final clampedX = newX.clamp(0.0, maxX);
    final clampedY = newY.clamp(0.0, maxY);

    if (mounted) {
      context.read<LayoutBloc>().add(
            MoveWidgetEvent(
              widgetId: widget.widget.id,
              newX: clampedX,
              newY: clampedY,
            ),
          );
    }
  }

  /// Handles the end of a drag gesture, cleaning up drag state.
  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging || _lastDragPosition == null) {
      setState(() {
        _isDragging = false;
        _lastDragPosition = null;
        _dragOffset = null;
      });
      return;
    }

    setState(() {
      _isDragging = false;
      _lastDragPosition = null;
      _dragOffset = null;
    });

    widget.onInteractionEnd?.call();
  }

  /// Handles drag cancellation, cleaning up drag state.
  void _onPanCancel() {
    setState(() {
      _isDragging = false;
      _lastDragPosition = null;
      _dragOffset = null;
    });

    widget.onInteractionEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {},
      behavior: _isDragging || _isResizing
          ? HitTestBehavior.opaque
          : HitTestBehavior.translucent,
      child: GestureDetector(
        onPanStart: _isResizing ? null : _onPanStart,
        onPanUpdate: _isResizing ? null : _onPanUpdate,
        onPanEnd: _isResizing ? null : _onPanEnd,
        onPanCancel: _isResizing ? null : _onPanCancel,
        behavior: _isDragging || _isResizing
            ? HitTestBehavior.opaque
            : HitTestBehavior.deferToChild,
        child: SizedBox(
          width: widget.widget.width + 20,
          height: widget.widget.height + 20,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  width: widget.widget.width,
                  height: widget.widget.height,
                  decoration: BoxDecoration(
                    color: _isDragging
                        ? WidgetColors.getColor(widget.widget.type)
                            .withOpacity(0.8)
                        : WidgetColors.getColor(widget.widget.type),
                    border: Border.all(
                      color: WidgetColors.getBorderColor(widget.widget.type),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.zero,
                    boxShadow: [
                      BoxShadow(
                        color: _isDragging
                            ? Colors.black.withOpacity(0.4)
                            : WidgetColors.getColor(widget.widget.type)
                                .withOpacity(0.3),
                        blurRadius: _isDragging ? 8 : 4,
                        offset: _isDragging
                            ? const Offset(0, 4)
                            : const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.widget.type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              ResizeHandle(
              widget: widget.widget,
              canvasKey: widget.canvasKey,
              transformationController: widget.transformationController,
              handleType: ResizeHandleType.topLeft,
              onResizeStart: () {
                setState(() => _isResizing = true);
                widget.onInteractionStart?.call();
              },
              onResizeEnd: () {
                setState(() => _isResizing = false);
                widget.onInteractionEnd?.call();
              },
            ),
            ResizeHandle(
              widget: widget.widget,
              canvasKey: widget.canvasKey,
              transformationController: widget.transformationController,
              handleType: ResizeHandleType.topRight,
              onResizeStart: () {
                setState(() => _isResizing = true);
                widget.onInteractionStart?.call();
              },
              onResizeEnd: () {
                setState(() => _isResizing = false);
                widget.onInteractionEnd?.call();
              },
            ),
            ResizeHandle(
              widget: widget.widget,
              canvasKey: widget.canvasKey,
              transformationController: widget.transformationController,
              handleType: ResizeHandleType.bottomLeft,
              onResizeStart: () {
                setState(() => _isResizing = true);
                widget.onInteractionStart?.call();
              },
              onResizeEnd: () {
                setState(() => _isResizing = false);
                widget.onInteractionEnd?.call();
              },
            ),
            ResizeHandle(
              widget: widget.widget,
              canvasKey: widget.canvasKey,
              transformationController: widget.transformationController,
              handleType: ResizeHandleType.bottomRight,
              onResizeStart: () {
                setState(() => _isResizing = true);
                widget.onInteractionStart?.call();
              },
              onResizeEnd: () {
                setState(() => _isResizing = false);
                widget.onInteractionEnd?.call();
              },
            ),
            ResizeHandle(
              widget: widget.widget,
              canvasKey: widget.canvasKey,
              transformationController: widget.transformationController,
              handleType: ResizeHandleType.top,
              onResizeStart: () {
                setState(() => _isResizing = true);
                widget.onInteractionStart?.call();
              },
              onResizeEnd: () {
                setState(() => _isResizing = false);
                widget.onInteractionEnd?.call();
              },
            ),
            ResizeHandle(
              widget: widget.widget,
              canvasKey: widget.canvasKey,
              transformationController: widget.transformationController,
              handleType: ResizeHandleType.right,
              onResizeStart: () {
                setState(() => _isResizing = true);
                widget.onInteractionStart?.call();
              },
              onResizeEnd: () {
                setState(() => _isResizing = false);
                widget.onInteractionEnd?.call();
              },
            ),
            ResizeHandle(
              widget: widget.widget,
              canvasKey: widget.canvasKey,
              transformationController: widget.transformationController,
              handleType: ResizeHandleType.bottom,
              onResizeStart: () {
                setState(() => _isResizing = true);
                widget.onInteractionStart?.call();
              },
              onResizeEnd: () {
                setState(() => _isResizing = false);
                widget.onInteractionEnd?.call();
              },
            ),
            ResizeHandle(
              widget: widget.widget,
              canvasKey: widget.canvasKey,
              transformationController: widget.transformationController,
              handleType: ResizeHandleType.left,
              onResizeStart: () {
                setState(() => _isResizing = true);
                widget.onInteractionStart?.call();
              },
              onResizeEnd: () {
                setState(() => _isResizing = false);
                widget.onInteractionEnd?.call();
              },
            ),
          ],
        ),
        ),
      ),
    );
  }
}
