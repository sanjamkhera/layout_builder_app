import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/layout_bloc.dart';
import '../bloc/layout_events.dart';
import '../repository/layout_repository.dart';
import 'widget_palette.dart';
import 'canvas_widget.dart';
import 'tabs_control.dart';

/// Main layout builder screen - Entry point for the layout builder application
/// 
/// RENDERING FLOW:
/// 1. This widget builds first (entry point from main.dart -> MaterialApp)
/// 2. BlocProvider creates and injects LayoutBloc into widget tree
/// 3. Scaffold establishes the app structure (AppBar + Body)
/// 4. Body contains responsive layout: Column -> Row -> CanvasWidget
/// 5. CanvasWidget receives constraints from Expanded widget
/// 
/// WIDGET HIERARCHY:
/// LayoutBuilderScreen
/// └─ BlocProvider (provides LayoutBloc to entire subtree)
///    └─ Scaffold
///       ├─ AppBar (top navigation bar)
///       └─ Column (body)
///          ├─ WidgetPalette (conditional - only on small screens at top)
///          └─ Expanded
///             └─ Row (horizontal layout for large screens)
///                ├─ SizedBox (WidgetPalette - sidebar, 15% width)
///                └─ Expanded (CanvasWidget - takes remaining space)
/// 
/// RESPONSIVE BEHAVIOR:
/// - Small screens (< 768px): Palette shown at top horizontally
/// - Large screens (>= 768px): Palette shown as sidebar (15% width)
/// 
/// CONSTRAINT FLOW (CRITICAL FOR CANVAS SIZING):
/// - MediaQuery gives full screen width (e.g., 1440px on desktop)
/// - Scaffold body gets available space minus AppBar height
/// - Column receives available height
/// - Expanded (inside Column) takes remaining vertical space
/// - Row receives width = screen width, height = Expanded height
/// - SizedBox (sidebar) takes: width = screenWidth * 0.15 (e.g., 216px)
/// - Expanded (CanvasWidget) receives remaining width (e.g., 1224px)
/// - CanvasWidget's LayoutBuilder gets: maxWidth=1224px, maxHeight=~780px
/// 
/// POTENTIAL ISSUES:
/// - screenWidth * 0.15 is calculated BEFORE Row layout, which may cause
///   constraint timing issues if Row hasn't computed its final size yet
/// - CanvasWidget receives constraints from Expanded, which depend on
///   the SizedBox width calculation - this creates a dependency chain
/// - First build may have constraints that change as parent layout settles

class LayoutBuilderScreen extends StatefulWidget {
  const LayoutBuilderScreen({super.key});

  @override
  State<LayoutBuilderScreen> createState() => _LayoutBuilderScreenState();
}

class _LayoutBuilderScreenState extends State<LayoutBuilderScreen> {
  /// Responsive breakpoint for switching between mobile and desktop layouts
  /// 
  /// Below 768px: Mobile layout (palette at top)
  /// 768px and above: Desktop layout (palette as sidebar)
  /// 
  /// This breakpoint is chosen because:
  /// - 768px is typical tablet width in landscape
  /// - iPads and most tablets are 768px wide
  /// - Provides good separation between phone and tablet/desktop experiences
  static const double _breakpoint = 768.0;

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // STEP 1: Get screen dimensions and determine layout mode
    // ============================================================
    // MediaQuery provides the full screen dimensions from the device
    // This is the ACTUAL screen width, not constrained by parent widgets
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Determine if we're on a small screen (mobile) or large screen (tablet/desktop)
    // This affects how the palette is displayed (top vs sidebar)
    final isSmallScreen = screenWidth < _breakpoint;

    // ============================================================
    // STEP 2: Set up BLoC (Business Logic Component) for state management
    // ============================================================
    // BlocProvider wraps the entire widget tree and provides LayoutBloc
    // This makes LayoutBloc available to all child widgets via context.read<LayoutBloc>()
    //
    // LayoutBloc manages:
    // - Loading/saving layouts from Firestore
    // - Managing active layout state
    // - Handling widget add/move/resize/delete events
    //
    // The cascade operator (..) immediately dispatches LoadLayoutsEvent
    // This triggers loading of saved layouts when the screen first appears
    return BlocProvider(
      create: (context) => LayoutBloc(
        repository: LayoutRepository(), // Repository handles Firestore operations
      )..add(const LoadLayoutsEvent()), // Immediately load layouts from database
      
      // ============================================================
      // STEP 3: Build the main UI structure (Scaffold)
      // ============================================================
      child: Scaffold(
          // Top navigation bar - always visible
          appBar: AppBar(
            title: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Layout Builder',
                style: TextStyle(
                  fontFamily: 'Roboto', // Better font
                  fontSize: 20,
                  fontWeight: FontWeight.bold, // Bold text
                  fontStyle: FontStyle.italic, // Italic text
                  letterSpacing: 0.5,
                ),
              ),
            ),
            backgroundColor: const Color(0xFF1E293B), // Modern dark slate color
            foregroundColor: Colors.white, // White text/icons on dark background
            elevation: 0, // No shadow for flat design
            centerTitle: false, // Left-justified title
          ),
          
          // Main body content - contains tabs, palette, and canvas
          body: Column(
            children: [
              // Tabs control - shows all tabs and allows creation/switching
              const TabsControl(),
              
              // ============================================================
              // STEP 4A: Widget Palette for SMALL SCREENS (Mobile layout)
              // ============================================================
            // This only renders on screens < 768px wide
            // Displayed horizontally at the top of the screen
            // Takes only the space it needs (not Expanded)
            if (isSmallScreen)
              const WidgetPalette(isHorizontal: true),
            
            // ============================================================
            // STEP 4B: Main content area (takes remaining vertical space)
            // ============================================================
            // 
            // SIMPLIFIED APPROACH:
            // Use Expanded to fill vertical space, but use LayoutBuilder inside
            // to get actual constraints and calculate widths directly
            // This eliminates the constraint dependency chain and timing issues
            Expanded(
              child: LayoutBuilder(
                // LayoutBuilder gives us ACTUAL constraints from Expanded
                // These are the real dimensions available for Row layout
                builder: (context, constraints) {
                  // Get actual available width and height from constraints
                  final availableWidth = constraints.maxWidth;
                  final availableHeight = constraints.maxHeight;
                  
                  // Calculate sidebar width from ACTUAL constraints (not MediaQuery)
                  // This ensures we use the real Row width, not screen width
                  final sidebarWidth = !isSmallScreen ? availableWidth * 0.15 : 0.0;
                  final canvasWidth = availableWidth - sidebarWidth;
                  
                  return Row(
                    children: [
                      // Sidebar (only on large screens)
                      if (!isSmallScreen)
                        SizedBox(
                          width: sidebarWidth, // Calculated from actual Row constraints
                          child: const WidgetPalette(isHorizontal: false),
                        ),
                      // Canvas - uses calculated width directly, no Expanded needed
                      SizedBox(
                        width: canvasWidth, // Direct width calculation, no constraint dependency
                        height: availableHeight, // Direct height from constraints
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
