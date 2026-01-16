import 'package:flutter/material.dart';

/// Zoom controls widget
class ZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  const ZoomControls({
    super.key,
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
            tooltip: 'Fit to screen',
          ),
        ],
      ),
    );
  }
}
