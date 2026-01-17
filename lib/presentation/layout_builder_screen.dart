import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/layout_bloc.dart';
import '../bloc/layout_events.dart';
import '../repository/layout_repository.dart';
import 'widget_palette.dart';
import 'canvas_widget.dart';
import 'tabs_control.dart';

/// Main screen for the layout builder application.
///
/// Provides a responsive interface for building and editing widget layouts.
/// The screen adapts its layout based on screen width:
/// - Small screens (< 768px): Widget palette displayed horizontally at the top
/// - Large screens (>= 768px): Widget palette displayed as a sidebar (15% width)
///
/// Uses [LayoutBloc] for state management, which handles loading/saving layouts
/// from Firestore and managing widget operations (add, move, resize, delete).
class LayoutBuilderScreen extends StatefulWidget {
  const LayoutBuilderScreen({super.key});

  @override
  State<LayoutBuilderScreen> createState() => _LayoutBuilderScreenState();
}

class _LayoutBuilderScreenState extends State<LayoutBuilderScreen> {
  /// Responsive breakpoint for switching between mobile and desktop layouts.
  ///
  /// Screens below this width use a mobile layout with the palette at the top.
  /// Screens at or above this width use a desktop layout with a sidebar palette.
  static const double _breakpoint = 768.0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < _breakpoint;

    return BlocProvider(
      create: (context) => LayoutBloc(
        repository: LayoutRepository(),
      )..add(const LoadLayoutsEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Layout Builder',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.5,
              ),
            ),
          ),
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        body: Column(
          children: [
            const TabsControl(),
            if (isSmallScreen) const WidgetPalette(isHorizontal: true),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final availableHeight = constraints.maxHeight;
                  final sidebarWidth =
                      !isSmallScreen ? availableWidth * 0.15 : 0.0;
                  final canvasWidth = availableWidth - sidebarWidth;

                  return Row(
                    children: [
                      if (!isSmallScreen)
                        SizedBox(
                          width: sidebarWidth,
                          child: const WidgetPalette(isHorizontal: false),
                        ),
                      SizedBox(
                        width: canvasWidth,
                        height: availableHeight,
                        child: const CanvasWidget(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
