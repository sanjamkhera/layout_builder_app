import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/layout_bloc.dart';
import '../bloc/layout_events.dart';
import '../models/widget_model.dart';
import 'widget_colors.dart';
import 'resize_handle.dart';

/// Draggable widget on canvas - allows moving widgets around
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
  bool _isResizing = false; // Track if any handle is being resized
  Offset? _lastDragPosition; // Track last drag position
  Offset? _dragOffset; // Track drag offset for preview

  // Check if a point is within any handle area
  // Note: localPoint is relative to the widget, handles can extend beyond widget bounds
  bool _isPointOnHandle(Offset localPoint) {
    const handleSize = 10.0;
    const handleHitArea = handleSize * 2; // 20x20 hit area
    final w = widget.widget.width;
    final h = widget.widget.height;
    
    // Check all 8 handle positions (handles can extend beyond widget bounds)
    final handles = [
      Offset(0, 0), // topLeft
      Offset(w, 0), // topRight
      Offset(0, h), // bottomLeft
      Offset(w, h), // bottomRight
      Offset(w / 2, 0), // top
      Offset(w, h / 2), // right
      Offset(w / 2, h), // bottom
      Offset(0, h / 2), // left
    ];
    
    for (final handlePos in handles) {
      // Create rect that extends beyond widget bounds (handles overflow)
      final handleRect = Rect.fromCenter(
        center: handlePos,
        width: handleHitArea,
        height: handleHitArea,
      );
      // Check if point is in handle area (even if negative or beyond widget bounds)
      if (handleRect.contains(localPoint)) {
        return true;
      }
    }
    return false;
  }

  void _onPanStart(DragStartDetails details) {
    // Check if pointer is on a handle - if so, don't start dragging
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final localPoint = renderBox.globalToLocal(details.globalPosition);
    
    // Don't start drag if on handle (handles are for resizing)
    if (_isPointOnHandle(localPoint)) {
      return;
    }
    
    // Allow dragging from anywhere on the widget (except handles)
    
    // Calculate initial drag offset from widget's top-left corner
    final canvasRenderBox = widget.canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (canvasRenderBox == null) return;
    
    // Convert global position to canvas coordinates
    // globalToLocal already accounts for InteractiveViewer transformation (zoom + pan)
    final canvasLocalPos = canvasRenderBox.globalToLocal(details.globalPosition);
    final canvasX = canvasLocalPos.dx;
    final canvasY = canvasLocalPos.dy;
    
    // Calculate offset from widget's top-left corner (where user clicked)
    final dragOffsetX = canvasX - widget.widget.x;
    final dragOffsetY = canvasY - widget.widget.y;
    
    setState(() {
      _isDragging = true;
      _lastDragPosition = details.globalPosition;
      _dragOffset = Offset(dragOffsetX, dragOffsetY);
    });
    
    // Notify canvas to disable pan
    widget.onInteractionStart?.call();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging || _dragOffset == null) return;
    
    // Track the current position during drag for preview
    _lastDragPosition = details.globalPosition;
    
    // Update drag offset for real-time preview
    final canvasRenderBox = widget.canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (canvasRenderBox == null) return;
    
    // Convert global position to canvas coordinates
    // globalToLocal already accounts for InteractiveViewer transformation (zoom + pan)
    final canvasLocalPos = canvasRenderBox.globalToLocal(details.globalPosition);
    final canvasX = canvasLocalPos.dx;
    final canvasY = canvasLocalPos.dy;
    
    // Calculate new position: cursor position minus the drag offset
    final newX = canvasX - _dragOffset!.dx;
    final newY = canvasY - _dragOffset!.dy;
    
    // Clamp to fixed canvas bounds (1920x1080) - prevent widgets from going past bounds
    const fixedCanvasWidth = 1920.0;
    const fixedCanvasHeight = 1080.0;
    
    // Calculate maximum allowed positions to keep widget within canvas bounds
    final maxX = fixedCanvasWidth - widget.widget.width;
    final maxY = fixedCanvasHeight - widget.widget.height;
    
    // Clamp position to canvas bounds (0 to maxX/Y)
    final clampedX = newX.clamp(0.0, maxX);
    final clampedY = newY.clamp(0.0, maxY);
    
    // Send MoveWidgetEvent for real-time preview
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

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging || _lastDragPosition == null) {
      setState(() {
        _isDragging = false;
        _lastDragPosition = null;
        _dragOffset = null;
      });
      return;
    }
    
    // Position is already updated during pan update, just clean up
    setState(() {
      _isDragging = false;
      _lastDragPosition = null;
      _dragOffset = null;
    });
    
    // Notify canvas to re-enable pan
    widget.onInteractionEnd?.call();
  }

  void _onPanCancel() {
    // Cancel drag and reset to original position if needed
    setState(() {
      _isDragging = false;
      _lastDragPosition = null;
      _dragOffset = null;
    });
    
    // Notify canvas to re-enable pan
    widget.onInteractionEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Capture pointer events when dragging/resizing to prevent InteractiveViewer from handling them
      onPointerDown: (_) {
        // This prevents InteractiveViewer from starting pan gesture
      },
      behavior: _isDragging || _isResizing 
          ? HitTestBehavior.opaque  
          : HitTestBehavior.translucent,
      child: GestureDetector(
        // Only handle gestures when not resizing
        onPanStart: _isResizing ? null : _onPanStart,
        onPanUpdate: _isResizing ? null : _onPanUpdate,
        onPanEnd: _isResizing ? null : _onPanEnd,
        onPanCancel: _isResizing ? null : _onPanCancel,
        // Use opaque to block InteractiveViewer from handling gestures when dragging
        behavior: _isDragging || _isResizing 
            ? HitTestBehavior.opaque  
            : HitTestBehavior.deferToChild,
        child: SizedBox(
        // Expand size to accommodate resize handle overflow (10px padding on all sides)
        width: widget.widget.width + 20, // 10px padding on each side
        height: widget.widget.height + 20, // 10px padding on each side
        child: Stack(
          clipBehavior: Clip.none, // Allow handles to overflow widget bounds
          children: [
            // Main widget container (at 0,0 - Stack padding is just for hit testing)
            Positioned(
              left: 10, // Offset by padding to keep visual position correct
              top: 10,  // Offset by padding to keep visual position correct
              child: Container(
                width: widget.widget.width,
                height: widget.widget.height,
                decoration: BoxDecoration(
                  color: _isDragging 
                      ? WidgetColors.getColor(widget.widget.type).withOpacity(0.8) 
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
                          : WidgetColors.getColor(widget.widget.type).withOpacity(0.3),
                      blurRadius: _isDragging ? 8 : 4,
                      offset: _isDragging ? const Offset(0, 4) : const Offset(0, 2),
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
            // Resize handles (8 handles: 4 corners + 4 edges) - on top so they capture gestures first
            // Handles are positioned relative to widget, but Stack now includes overflow area
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
