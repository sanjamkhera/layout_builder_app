# Data Flow Diagram - Layout Builder App

## 🚀 Complete Flow: App Start → User Drags Widget → Saves to Firestore

---

## 📍 STEP 1: App Initialization (main.dart)

### **File:** `lib/main.dart`

#### **main() function**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase Anonymous Authentication
  await FirebaseAuth.instance.signInAnonymously();
  
  runApp(const MyApp());
}
```
**What happens:**
1. Initializes Flutter binding
2. Connects to Firebase
3. Signs in user anonymously (creates unique user ID)
4. Starts the app

---

#### **MyApp widget**
```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const LayoutBuilderScreen(),
    );
  }
}
```
**What happens:**
- Creates MaterialApp
- Sets `LayoutBuilderScreen` as home screen

---

## 📍 STEP 2: Layout Builder Screen Setup (layout_builder_screen.dart)

### **File:** `lib/presentation/layout_builder_screen.dart`

#### **LayoutBuilderScreen widget**
```dart
class LayoutBuilderScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LayoutBloc(
        repository: LayoutRepository(),
      )..add(const LoadLayoutsEvent()),  // Immediately load layouts
      child: Scaffold(
        appBar: AppBar(...),  // Top navigation with "Layout Builder" title
        body: Column(
          children: [
            const TabsControl(),  // Tab management UI
            if (isSmallScreen) WidgetPalette(isHorizontal: true),
            Expanded(
              child: Row(
                children: [
                  if (!isSmallScreen) WidgetPalette(isHorizontal: false),
                  Expanded(child: CanvasWidget()),  // Main canvas
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```
**What happens:**
1. Creates BlocProvider (makes BLoC available to child widgets)
2. Creates LayoutBloc with LayoutRepository
3. Immediately sends `LoadLayoutsEvent()` to load saved layouts
4. Builds Scaffold with:
   - AppBar (top navigation)
   - TabsControl (tab management)
   - WidgetPalette (draggable widgets A, B, C, D)
   - CanvasWidget (where widgets are placed)

**Screen Structure:**
```
LayoutBuilderScreen
├── AppBar ("Layout Builder" title)
├── TabsControl (tab management bar)
└── Body
    ├── WidgetPalette (A, B, C, D widgets)
    └── CanvasWidget (1920x1080 fixed canvas with zoom/pan)
```

---

## 📍 STEP 3: BLoC Loads Layouts (layout_bloc.dart)

### **File:** `lib/bloc/layout_bloc.dart`

#### **BLoC Constructor**
```dart
LayoutBloc({required this.repository}) : super(LayoutState.initial()) {
  on<LoadLayoutsEvent>(_onLoadLayouts);
  on<AddWidgetEvent>(_onAddWidget);
  on<MoveWidgetEvent>(_onMoveWidget);
  on<ResizeWidgetEvent>(_onResizeWidget);
  on<DeleteWidgetEvent>(_onDeleteWidget);
  on<SwitchTabEvent>(_onSwitchTab);
  on<CreateTabEvent>(_onCreateTab);
  on<DeleteTabEvent>(_onDeleteTab);
  on<RenameTabEvent>(_onRenameTab);
  on<SaveLayoutEvent>(_onSaveLayout);
}
```
**What happens:**
- Registers all event handlers
- Initial state: `LayoutState.initial()` (empty layouts, default activeTabId)

---

#### **_onLoadLayouts Method**
```dart
Future<void> _onLoadLayouts(LoadLayoutsEvent event, Emitter<LayoutState> emit) {
  emit(state.copyWith(isLoading: true, error: null));
  
  try {
    final layouts = await repository.fetchLayouts();
    
    // If no layouts exist, create a default tab
    if (layouts.isEmpty) {
      final defaultTabId = 'tab${DateTime.now().millisecondsSinceEpoch}';
      final defaultTabName = 'Tab 1';
      final defaultLayout = LayoutModel(
        tabId: defaultTabId,
        tabName: defaultTabName,
        widgets: [],
      );
      
      emit(state.copyWith(
        layouts: {defaultTabId: defaultLayout},
        activeTabId: defaultTabId,
        isLoading: false,
      ));
      
      // Auto-save the default layout
      add(const SaveLayoutEvent());
    } else {
      // Set first layout as active if activeTabId doesn't exist
      String activeTabId = state.activeTabId;
      if (!layouts.containsKey(activeTabId)) {
        activeTabId = layouts.keys.first;
      }
      
      emit(state.copyWith(
        layouts: layouts,
        activeTabId: activeTabId,
        isLoading: false,
      ));
    }
  } catch (e) {
    emit(state.copyWith(
      isLoading: false,
      error: 'Failed to load layouts: $e',
    ));
  }
}
```
**What happens:**
1. Sets loading state
2. Calls `repository.fetchLayouts()`
3. **If no layouts:** Creates default tab automatically
4. **If layouts exist:** Sets first layout as active if needed
5. Emits state with loaded layouts
6. UI rebuilds with loaded data

---

## 📍 STEP 4: Repository Loads from Firestore (layout_repository.dart)

### **File:** `lib/repository/layout_repository.dart`

#### **fetchLayouts Method**
```dart
Future<Map<String, LayoutModel>> fetchLayouts() async {
  final userId = _getUserId();  // Gets unique user ID from Firebase Auth
  final docRef = _firestore.collection('layouts').doc(userId);
  
  final docSnapshot = await docRef.get();
  
  if (!docSnapshot.exists) {
    return {};  // No layouts saved yet
  }
  
  final data = docSnapshot.data();
  final Map<String, LayoutModel> layouts = {};
  
  data.forEach((tabId, layoutJson) {
    if (layoutJson is Map<String, dynamic>) {
      layouts[tabId] = LayoutModel.fromJson(layoutJson);
    }
  });
  
  return layouts;
}
```
**What happens:**
1. Gets current user's unique ID from Firebase Auth
2. Reads Firestore document: `layouts/{userId}`
3. Converts JSON → LayoutModel using `fromJson()`
4. Returns map of layouts: `{tabId: LayoutModel, ...}`

**Firestore Structure:**
```
layouts/
  └── {userId}/     # User's document
      ├── tab1: {tabId, tabName, widgets: [...]}
      ├── tab2: {tabId, tabName, widgets: [...]}
      └── tab3: {tabId, tabName, widgets: [...]}
```

---

## 📍 STEP 5: UI Renders - Tabs & Canvas (layout_builder_screen.dart)

### **TabsControl Widget**
```dart
class TabsControl extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LayoutBloc, LayoutState>(
      builder: (context, state) {
        final tabs = state.layouts.values.toList();
        final activeTabId = state.activeTabId;
        
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            if (index == tabs.length) {
              return _AddTabButton(...);  // + button for new tabs
            }
            return _TabItem(
              tab: tabs[index],
              isActive: tabs[index].tabId == activeTabId,
              onTap: () => context.read<LayoutBloc>().add(
                SwitchTabEvent(tabId: tabs[index].tabId)
              ),
            );
          },
        );
      },
    );
  }
}
```
**What happens:**
- Displays all tabs from state
- Highlights active tab
- Allows switching tabs (dispatches `SwitchTabEvent`)
- Shows "+" button to create new tabs
- Allows deleting/renaming tabs

---

### **CanvasWidget**
```dart
class CanvasWidget extends StatefulWidget {
  static const double _fixedCanvasWidth = 1920.0;
  static const double _fixedCanvasHeight = 1080.0;
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LayoutBloc, LayoutState>(
      builder: (context, state) {
        final activeLayout = state.activeLayout;
        
        return InteractiveViewer(
          transformationController: _transformationController,
          minScale: 1.0,  // Can't zoom out beyond 1:1
          maxScale: 3.0,  // Can zoom in up to 3x
          child: Container(
            width: _fixedCanvasWidth,
            height: _fixedCanvasHeight,
            child: DragTarget<String>(
              onAcceptWithDetails: (details) {
                _handleWidgetDrop(details);
              },
              builder: (context, candidateData, rejectedData) {
                return Stack(
                  children: [
                    DotGridPainter(),  // Grid background
                    // Render widgets from activeLayout
                    ...activeLayout.widgets.map((widget) {
                      return DraggableCanvasWidget(widget: widget);
                    }),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
```
**What happens:**
- Listens to BLoC state changes
- Displays active layout's widgets
- Fixed 1920x1080 canvas size
- Supports zoom (1x to 3x) and pan
- Accepts dropped widgets from palette

---

### **WidgetPalette**
```dart
class WidgetPalette extends StatelessWidget {
  static const List<String> widgetTypes = ['A', 'B', 'C', 'D'];
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        return _DraggableWidgetItem(
          widgetType: widgetTypes[index],
        );
      },
    );
  }
}

class _DraggableWidgetItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: widgetType,  // "A", "B", "C", or "D"
      // Visual styling...
    );
  }
}
```
**What happens:**
- Creates 4 draggable widgets (A, B, C, D)
- `data: widgetType` = what gets passed when dropped

---

## 📍 STEP 6: User Drags Widget from Palette

### **Flow:**
```
User clicks widget "A" in palette
    ↓
widget_palette.dart:94
Draggable<String> starts drag
    ↓
User drags over canvas
    ↓
canvas_widget.dart:252
DragTarget.onWillAccept("A") → returns true
    ↓
Canvas shows "Drop A here" hint
    ↓
User drops widget at position (x, y)
    ↓
canvas_widget.dart:253
DragTarget.onAcceptWithDetails() called with drop position
```

---

## 📍 STEP 7: Drop Accepted → Event Sent (canvas_widget.dart)

### **File:** `lib/presentation/canvas_widget.dart`

#### **_handleWidgetDrop Method**
```dart
void _handleWidgetDrop(DragTargetDetails<String> details) {
  final widgetType = details.data;  // "A", "B", "C", or "D"
  
  // Get canvas render box
  final RenderBox? canvasRenderBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
  if (canvasRenderBox == null) return;
  
  // Convert global drop position to canvas local coordinates
  // globalToLocal automatically accounts for InteractiveViewer transformation (zoom + pan)
  final canvasLocalPos = canvasRenderBox.globalToLocal(details.offset);
  
  // Clamp to fixed canvas bounds (1920x1080)
  const defaultWidgetWidth = 100.0;
  const defaultWidgetHeight = 100.0;
  final maxX = _fixedCanvasWidth - defaultWidgetWidth;
  final maxY = _fixedCanvasHeight - defaultWidgetHeight;
  
  final x = canvasLocalPos.dx.clamp(0.0, maxX);
  final y = canvasLocalPos.dy.clamp(0.0, maxY);

  // Send AddWidgetEvent to BLoC with actual drop position
  context.read<LayoutBloc>().add(
    AddWidgetEvent(
      type: widgetType,
      x: x,  // Actual drop X position
      y: y,  // Actual drop Y position
    ),
  );
}
```
**What happens:**
1. Gets actual drop position from `details.offset`
2. Converts global position to canvas local coordinates (accounts for zoom/pan)
3. Clamps position to canvas bounds (0 to maxX/Y)
4. Sends `AddWidgetEvent` with actual drop position

**Key improvement:** Now captures actual drop position, not just center!

---

## 📍 STEP 8: BLoC Processes Event (layout_bloc.dart)

### **File:** `lib/bloc/layout_bloc.dart`

#### **_onAddWidget Method**
```dart
Future<void> _onAddWidget(AddWidgetEvent event, Emitter<LayoutState> emit) {
  // Get active layout (current tab)
  var activeLayout = state.activeLayout;
  if (activeLayout == null) {
    // Create layout if it doesn't exist
    activeLayout = LayoutModel(
      tabId: state.activeTabId,
      tabName: 'Layout ${state.activeTabId}',
      widgets: [],
    );
  }
  
  // Create WidgetModel with actual drop position
  final newWidget = WidgetModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    type: event.type,  // "A", "B", "C", or "D"
    x: event.x,        // Actual drop X
    y: event.y,        // Actual drop Y
    width: 100,
    height: 100,
  );
  
  // Add widget to active layout
  final updatedWidgets = [...activeLayout.widgets, newWidget];
  final updatedLayout = activeLayout.copyWith(widgets: updatedWidgets);
  
  // Update state
  final updatedLayouts = Map<String, LayoutModel>.from(state.layouts);
  updatedLayouts[state.activeTabId] = updatedLayout;
  
  // Emit new state (UI rebuilds)
  emit(state.copyWith(layouts: updatedLayouts));
  
  // Auto-save after adding widget
  add(const SaveLayoutEvent());
}
```
**What happens:**
1. Gets active layout (current tab)
2. Creates WidgetModel with actual drop position
3. Adds widget to active layout
4. Updates state
5. Emits new state (UI rebuilds - widget appears on canvas)
6. Triggers auto-save

---

## 📍 STEP 9: UI Rebuilds - Widget Appears on Canvas

### **CanvasWidget Rebuilds**
```dart
BlocBuilder<LayoutBloc, LayoutState>(
  builder: (context, state) {
    final activeLayout = state.activeLayout;
    
    return Stack(
      children: [
        // Render all widgets from active layout
        ...activeLayout.widgets.map((widget) {
          return Positioned(
            left: widget.x,      // From WidgetModel
            top: widget.y,       // From WidgetModel
            child: DraggableCanvasWidget(
              widget: widget,  // Can be moved and resized
            ),
          );
        }),
      ],
    );
  },
)
```
**What happens:**
- BLoC emits new state
- BlocBuilder detects change
- Rebuilds canvas
- New widget appears at drop position

---

## 📍 STEP 10: Auto-Save Triggered (layout_bloc.dart)

### **_onSaveLayout Method**
```dart
Future<void> _onSaveLayout(SaveLayoutEvent event, Emitter<LayoutState> emit) {
  final activeLayout = state.activeLayout;
  if (activeLayout == null) return;
  
  try {
    await repository.saveLayout(activeLayout);
  } catch (e) {
    emit(state.copyWith(error: 'Failed to save layout: $e'));
  }
}
```
**What happens:**
- Gets active layout (current tab)
- Calls repository to save to Firestore
- Auto-save happens after: add, move, resize, delete widget, create tab, delete tab, rename tab

---

## 📍 STEP 11: Repository Saves to Firestore (layout_repository.dart)

### **saveLayout Method**
```dart
Future<void> saveLayout(LayoutModel layout) async {
  final userId = _getUserId();  // Gets unique user ID
  final docRef = _firestore.collection('layouts').doc(userId);
  
  // Convert LayoutModel to JSON
  final layoutJson = layout.toJson();
  
  // Save to Firestore with merge: true (preserves other tabs)
  await docRef.set(
    {layout.tabId: layoutJson},
    SetOptions(merge: true),
  );
}
```
**What happens:**
1. Gets Firestore document reference for user
2. Converts LayoutModel to JSON
3. Saves to Firestore with merge (preserves other tabs)

---

## 📍 STEP 12: JSON Conversion (models)

### **LayoutModel.toJson()**
```dart
Map<String, dynamic> toJson() {
  return {
    'tabId': tabId,
    'tabName': tabName,
    'widgets': widgets.map((widget) => widget.toJson()).toList(),
    'lastUpdated': lastUpdated?.toIso8601String(),
  };
}
```

### **WidgetModel.toJson()**
```dart
Map<String, dynamic> toJson() {
  return {
    'id': id,
    'type': type,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };
}
```

**Final JSON structure in Firestore:**
```json
{
  "tab1": {
    "tabId": "tab1",
    "tabName": "Tab 1",
    "widgets": [
      {
        "id": "1234567890",
        "type": "A",
        "x": 450.0,
        "y": 320.0,
        "width": 100.0,
        "height": 100.0
      }
    ]
  },
  "tab2": {
    "tabId": "tab2",
    "tabName": "Tab 2",
    "widgets": [...]
  }
}
```

---

## 🔄 Tab Management Flow

### **Creating a Tab**
```
User clicks "+" button in TabsControl
    ↓
TabsControl dispatches CreateTabEvent(tabId, tabName)
    ↓
BLoC._onCreateTab() creates new LayoutModel
    ↓
State updated with new tab, set as active
    ↓
Auto-save: SaveLayoutEvent → Repository → Firestore
```

### **Switching Tabs**
```
User clicks tab in TabsControl
    ↓
TabsControl dispatches SwitchTabEvent(tabId)
    ↓
BLoC._onSwitchTab() updates activeTabId
    ↓
State emitted with new activeTabId
    ↓
CanvasWidget rebuilds → shows new active layout's widgets
```

### **Deleting a Tab**
```
User clicks "X" on tab
    ↓
TabsControl shows confirmation dialog
    ↓
User confirms → dispatches DeleteTabEvent(tabId)
    ↓
BLoC._onDeleteTab() removes tab from layouts
    ↓
If deleting active tab → switches to another tab
    ↓
Repository.deleteTab() removes from Firestore
```

### **Renaming a Tab**
```
User long-presses tab
    ↓
TabsControl shows rename dialog
    ↓
User enters new name → dispatches RenameTabEvent(tabId, newName)
    ↓
BLoC._onRenameTab() updates tabName in LayoutModel
    ↓
Auto-save: SaveLayoutEvent → Repository → Firestore
```

---

## 🔄 Widget Manipulation Flow

### **Moving a Widget**
```
User drags widget on canvas
    ↓
DraggableCanvasWidget._onPanUpdate()
    ↓
Converts global position to canvas coordinates (accounts for zoom/pan)
    ↓
Clamps to canvas bounds (0 to maxX/Y)
    ↓
Dispatches MoveWidgetEvent(widgetId, newX, newY)
    ↓
BLoC._onMoveWidget() updates widget position
    ↓
State emitted → UI rebuilds (real-time preview)
    ↓
Auto-save: SaveLayoutEvent → Repository → Firestore
```

### **Resizing a Widget**
```
User drags resize handle
    ↓
ResizeHandle detects drag
    ↓
Converts position, maintains min size (50px)
    ↓
Dispatches ResizeWidgetEvent(widgetId, newWidth, newHeight)
    ↓
BLoC._onResizeWidget() updates widget size
    ↓
State emitted → UI rebuilds (real-time preview)
    ↓
Auto-save: SaveLayoutEvent → Repository → Firestore
```

---

## 🔄 Complete Method Call Chain

```
1. main.dart:main()
   ↓
2. Firebase.initializeApp() + signInAnonymously()
   ↓
3. runApp(MyApp())
   ↓
4. MaterialApp(home: LayoutBuilderScreen())
   ↓
5. layout_builder_screen.dart:BlocProvider
   create: LayoutBloc(repository: LayoutRepository())
   ..add(LoadLayoutsEvent())
   ↓
6. layout_bloc.dart:_onLoadLayouts()
   ↓
7. layout_repository.dart:fetchLayouts()
   → Firestore: layouts/{userId}.get()
   ↓
8. layout_model.dart:LayoutModel.fromJson()
   ↓
9. layout_bloc.dart:emit(state.copyWith(layouts: layouts))
   ↓
10. layout_builder_screen.dart:BlocBuilder rebuilds
    → TabsControl shows tabs
    → CanvasWidget shows active layout
   ↓
11. User drags widget "A" from palette
   ↓
12. canvas_widget.dart:DragTarget.onAcceptWithDetails()
   ↓
13. canvas_widget.dart:_handleWidgetDrop()
    → Converts drop position to canvas coordinates
    → Clamps to bounds
   ↓
14. layout_builder_screen.dart:context.read<LayoutBloc>().add(
    AddWidgetEvent(type: "A", x: 450.0, y: 320.0)
   )
   ↓
15. layout_bloc.dart:_onAddWidget()
    → Creates WidgetModel
    → Updates LayoutModel
    → Emits state
    → add(SaveLayoutEvent())
   ↓
16. canvas_widget.dart:BlocBuilder rebuilds
    → Widget appears on canvas at drop position
   ↓
17. layout_bloc.dart:_onSaveLayout()
   ↓
18. layout_repository.dart:saveLayout()
   ↓
19. layout_model.dart:layout.toJson()
   ↓
20. widget_model.dart:widget.toJson()
   ↓
21. layout_repository.dart:docRef.set({tabId: layoutJson})
   ↓
22. FIRESTORE: Data saved ✅
```

---

## 📊 Data Flow Summary

### **App Start:**
```
main.dart → Firebase.init + Auth → MyApp → LayoutBuilderScreen
    ↓
BlocProvider → LayoutBloc → LoadLayoutsEvent
    ↓
Repository.fetchLayouts() → Firestore
    ↓
LayoutModel.fromJson() → State → UI renders (TabsControl + CanvasWidget)
```

### **User Drags Widget:**
```
Palette Draggable → Canvas DragTarget.onAcceptWithDetails()
    ↓
_handleWidgetDrop() → Convert position → AddWidgetEvent
    ↓
BLoC._onAddWidget() → WidgetModel → LayoutModel → State
    ↓
UI rebuilds → Widget appears on canvas
    ↓
SaveLayoutEvent → Repository.saveLayout() → Firestore
```

### **User Moves/Resizes Widget:**
```
DraggableCanvasWidget drag → Convert position → MoveWidgetEvent/ResizeWidgetEvent
    ↓
BLoC updates widget → State → UI rebuilds (real-time preview)
    ↓
SaveLayoutEvent → Repository → Firestore
```

### **Tab Operations:**
```
TabsControl UI action → Event (Create/Switch/Delete/Rename)
    ↓
BLoC handler → Update state → UI rebuilds
    ↓
SaveLayoutEvent → Repository → Firestore
```

---

## 🎯 Key Files & Their Roles

| File | Role | Key Methods |
|------|------|-------------|
| `main.dart` | App entry point | `main()`, Firebase init, Anonymous Auth |
| `layout_builder_screen.dart` | Main UI | `LayoutBuilderScreen`, `TabsControl` integration |
| `tabs_control.dart` | Tab management UI | Tab display, create, switch, delete, rename |
| `canvas_widget.dart` | Canvas area | Widget rendering, drop handling, zoom/pan |
| `draggable_canvas_widget.dart` | Individual widget | Move, resize handlers |
| `widget_palette.dart` | Palette UI | Draggable widgets (A, B, C, D) |
| `layout_bloc.dart` | State management | All event handlers (`_onAddWidget`, `_onMoveWidget`, etc.) |
| `layout_repository.dart` | Data access | `fetchLayouts()`, `saveLayout()`, `deleteTab()` |
| `layout_model.dart` | Data model | `toJson()`, `fromJson()` |
| `widget_model.dart` | Data model | `toJson()`, `fromJson()` |

---

## 🔍 Where Each Action Happens

### **App Initialization:**
- `main.dart` - Firebase init, Anonymous Auth
- `main.dart` - Sets LayoutBuilderScreen as home
- `layout_builder_screen.dart` - Creates BLoC, loads layouts

### **Loading Layouts:**
- `layout_bloc.dart:_onLoadLayouts()` - Handles LoadLayoutsEvent
- `layout_bloc.dart` - Creates default tab if no layouts exist
- `layout_repository.dart:fetchLayouts()` - Fetches from Firestore
- `layout_model.dart:fromJson()` - Converts JSON to LayoutModel

### **Tab Management:**
- `tabs_control.dart` - Tab UI, creates/dispatches tab events
- `layout_bloc.dart:_onCreateTab()` - Creates new tab
- `layout_bloc.dart:_onSwitchTab()` - Switches active tab
- `layout_bloc.dart:_onDeleteTab()` - Deletes tab
- `layout_bloc.dart:_onRenameTab()` - Renames tab

### **User Drags Widget:**
- `widget_palette.dart` - Draggable widget in palette
- `canvas_widget.dart:_handleWidgetDrop()` - Handles drop, converts position
- `canvas_widget.dart` - Sends AddWidgetEvent with actual drop position

### **Adding Widget:**
- `layout_builder_screen.dart` - Sends AddWidgetEvent
- `layout_bloc.dart:_onAddWidget()` - Creates WidgetModel, updates state
- `canvas_widget.dart` - Renders widgets from state

### **Moving Widget:**
- `draggable_canvas_widget.dart:_onPanUpdate()` - Handles drag
- `layout_bloc.dart:_onMoveWidget()` - Updates widget position
- Auto-save triggered

### **Resizing Widget:**
- `resize_handle.dart` - Handles resize drag
- `layout_bloc.dart:_onResizeWidget()` - Updates widget size
- Auto-save triggered

### **Saving:**
- `layout_bloc.dart` - All handlers auto-trigger SaveLayoutEvent
- `layout_bloc.dart:_onSaveLayout()` - Handles save
- `layout_repository.dart:saveLayout()` - Saves to Firestore
- `layout_model.dart:toJson()` - Converts to JSON
- `widget_model.dart:toJson()` - Converts to JSON

---

## 💡 Key Features

### **Multi-Tab Support:**
- Multiple layouts per user (each tab = separate layout)
- Switch between tabs to see different layouts
- Create, delete, rename tabs
- All tabs persisted in Firestore

### **Fixed Canvas Size:**
- Canvas is always 1920x1080 (fixed dimensions)
- Widgets can't be placed outside bounds
- Zoom (1x to 3x) and pan for navigation

### **Real-time Preview:**
- Widget moves/resizes update state immediately
- UI rebuilds in real-time during drag
- Changes auto-saved after interaction ends

### **Auto-Save:**
- All operations trigger auto-save (add, move, resize, delete widget, tab operations)
- No manual save button needed
- Uses Firestore merge to preserve other tabs

### **User Isolation:**
- Each device gets unique user ID via Anonymous Auth
- User ID persists across app restarts
- Complete data isolation between users/devices

---

## 🎨 UI Components

### **AppBar:**
- Title: "Layout Builder" (bold, italic, left-aligned)
- Dark slate background

### **TabsControl:**
- Horizontal scrollable list of tabs
- Active tab highlighted
- "+" button (circular, gray background, black icon) to create tabs
- "X" button on each tab to delete (with confirmation)
- Long press to rename

### **WidgetPalette:**
- Sidebar (desktop) or top bar (mobile)
- 4 draggable widgets: A, B, C, D
- Color-coded by type

### **CanvasWidget:**
- Fixed 1920x1080 size
- Dot grid background
- Zoom controls (bottom-right)
- InteractiveViewer for zoom/pan
- DragTarget for dropping widgets

---

## 📝 Notes

- **Canvas Size:** Fixed at 1920x1080 pixels (Full HD)
- **Widget Bounds:** Widgets clamped to canvas bounds automatically
- **Zoom Range:** 1.0x (actual size) to 3.0x (3x zoom)
- **Min Widget Size:** 50x50 pixels
- **Auto-Save:** All changes automatically saved to Firestore
- **User Identification:** Firebase Anonymous Authentication
- **Data Structure:** `layouts/{userId}/{tabId}` in Firestore

---

**Last Updated:** Part 5 Complete (Multi-Tab Layout Management)
