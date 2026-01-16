import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/layout_bloc.dart';
import '../bloc/layout_events.dart';
import '../models/widget_model.dart';

/// Enum for resize handle types
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

/// Resize handle widget - allows resizing widgets by dragging
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
  static const double _minSize = 50.0; // Minimum widget size
  
  // Store initial state when resize starts for delta-based calculations
  Offset? _startPanPosition; // Initial pan position in canvas coordinates
  double? _startWidgetX;
  double? _startWidgetY;
  double? _startWidgetWidth;
  double? _startWidgetHeight;

  @override
  void dispose() {
    // Clean up any ongoing resize operations
    _startPanPosition = null;
    _startWidgetX = null;
    _startWidgetY = null;
    _startWidgetWidth = null;
    _startWidgetHeight = null;
    super.dispose();
  }

  /// Convert global screen coordinates to canvas coordinates
  /// Accounts for InteractiveViewer zoom transformation
  Offset _globalToCanvas(Offset globalPosition) {
    final canvasRenderBox = widget.canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (canvasRenderBox == null) return Offset.zero;
    
    // Convert global to local canvas coordinates
    // globalToLocal accounts for the InteractiveViewer zoom transformation
    final localPosition = canvasRenderBox.globalToLocal(globalPosition);
    
    return localPosition;
  }

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

  void _onPanStart(Offset globalPosition) {
    // Store initial state for delta-based calculations
    _startPanPosition = _globalToCanvas(globalPosition);
    _startWidgetX = widget.widget.x;
    _startWidgetY = widget.widget.y;
    _startWidgetWidth = widget.widget.width;
    _startWidgetHeight = widget.widget.height;
  }

  void _onPanUpdate(Offset globalPosition) {
    // Check if widget is still mounted
    if (!mounted) return;
    
    // Ensure we have initial state
    if (_startPanPosition == null || 
        _startWidgetX == null || 
        _startWidgetY == null || 
        _startWidgetWidth == null || 
        _startWidgetHeight == null) {
      return;
    }
    
    // Convert current position to canvas coordinates
    final currentCanvasPos = _globalToCanvas(globalPosition);
    
    // Calculate delta from start position
    final deltaX = currentCanvasPos.dx - _startPanPosition!.dx;
    final deltaY = currentCanvasPos.dy - _startPanPosition!.dy;
    
    // Calculate new dimensions based on handle type using deltas
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
    
    // Apply minimum size constraints
    if (newWidth < _minSize) {
      newWidth = _minSize;
      // Adjust position if handle is on the left side
      if (widget.handleType == ResizeHandleType.topLeft || 
          widget.handleType == ResizeHandleType.bottomLeft ||
          widget.handleType == ResizeHandleType.left) {
        newX = _startWidgetX! + (_startWidgetWidth! - _minSize);
      }
    }
    
    if (newHeight < _minSize) {
      newHeight = _minSize;
      // Adjust position if handle is on the top side
      if (widget.handleType == ResizeHandleType.topLeft || 
          widget.handleType == ResizeHandleType.topRight ||
          widget.handleType == ResizeHandleType.top) {
        newY = _startWidgetY! + (_startWidgetHeight! - _minSize);
      }
    }
    
    // Fixed canvas dimensions for bounds checking
    const fixedCanvasWidth = 1920.0;
    const fixedCanvasHeight = 1080.0;
    
    // Ensure non-negative positions
    newX = newX < 0 ? 0 : newX;
    newY = newY < 0 ? 0 : newY;
    
    // Ensure widget doesn't exceed canvas bounds
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
    
    // Clamp width and height to canvas bounds
    newWidth = newWidth.clamp(_minSize, fixedCanvasWidth - newX);
    newHeight = newHeight.clamp(_minSize, fixedCanvasHeight - newY);
    
    // Check mounted again before accessing context
    if (!mounted) return;
    
    // Send ResizeWidgetEvent to BLoC
    context.read<LayoutBloc>().add(
          ResizeWidgetEvent(
            widgetId: widget.widget.id,
            newWidth: newWidth,
            newHeight: newHeight,
          ),
        );
    
    // If position changed (for corner/edge handles that move the widget), send MoveWidgetEvent
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

  void _onPanEnd() {
    // Reset initial state
    _startPanPosition = null;
    _startWidgetX = null;
    _startWidgetY = null;
    _startWidgetWidth = null;
    _startWidgetHeight = null;
  }

  @override
  Widget build(BuildContext context) {
    final position = _getHandlePosition();
    final hitAreaSize = _handleSize * 2; // 20x20 hit area
    
    // Account for the 10px padding added to Stack in DraggableCanvasWidget
    const stackPadding = 10.0;
    
    return Positioned(
      left: position.dx - (hitAreaSize / 2) + stackPadding, // Center hit area, account for Stack padding
      top: position.dy - (hitAreaSize / 2) + stackPadding,  // Center hit area, account for Stack padding
      child: Listener(
        // Listener captures ALL pointer events in this area, even outside widget bounds
        // This ensures the outer white border part captures gestures
        onPointerDown: (event) {
          // Capture pointer to prevent InteractiveViewer from getting it
          // This prevents InteractiveViewer from panning/zooming when resizing
        },
        behavior: HitTestBehavior.opaque, // Critical: ensures full area captures events and blocks InteractiveViewer
        child: MouseRegion(
          // MouseRegion covers the FULL 20x20 hit area so cursor appears everywhere
          cursor: _getCursor(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque, // Ensure full hit area captures gestures
            onPanStart: (details) {
              widget.onResizeStart();
              _onPanStart(details.globalPosition);
            },
            onPanUpdate: (details) {
              if (mounted) {
                _onPanUpdate(details.globalPosition);
              }
            },
            onPanEnd: (details) {
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
              // Larger hit area for easier interaction (20x20)
              // This container MUST be opaque for hit testing to work beyond widget bounds
              width: hitAreaSize,
              height: hitAreaSize,
              color: Colors.transparent, // Transparent but still captures gestures
              alignment: Alignment.center,
              child: Container(
                width: _handleSize,
                height: _handleSize,
                decoration: BoxDecoration(
                  color: Colors.grey[600], // Darker gray fill
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
