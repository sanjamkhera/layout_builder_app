# Data Flow Diagram - Starting from main.dart

## 🚀 Complete Flow: App Start → User Drags Widget → Saves to Firestore

---

## 📍 STEP 1: App Initialization (main.dart)

### **File:** `lib/main.dart`

#### **Line 6-17: main() function**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Line 7
  await Firebase.initializeApp(                // Line 9
    options: DefaultFirebaseOptions.currentPlatform,  // Line 10
  );
  runApp(const MyApp());                      // Line 16
}
```
**What happens:**
1. Initializes Flutter binding
2. Connects to Firebase
3. Starts the app

---

#### **Line 19-47: MyApp widget**
```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const LayoutBuilderScreen(),  // Line 45
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

#### **Line 14-42: LayoutBuilderScreen widget**
```dart
class LayoutBuilderScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(  // Line 20
      create: (context) => LayoutBloc(  // Line 21
        repository: LayoutRepository(),  // Line 22
      )..add(const LoadLayoutsEvent()),  // Line 23
      child: Scaffold(...),
    );
  }
}
```
**What happens:**
1. **Line 20:** Creates BlocProvider (makes BLoC available to child widgets)
2. **Line 21-22:** Creates LayoutBloc with LayoutRepository
3. **Line 23:** Immediately sends `LoadLayoutsEvent()` to load saved layouts
4. **Line 24-40:** Builds Scaffold with palette + canvas

**Data flow:**
```
LayoutBuilderScreen
    ↓
BlocProvider creates LayoutBloc
    ↓
LayoutBloc receives LoadLayoutsEvent
    ↓
BLoC calls repository.fetchLayouts()
    ↓
Repository loads from Firestore
    ↓
BLoC emits state with loaded layouts
```

---

## 📍 STEP 3: BLoC Loads Layouts (layout_bloc.dart)

### **File:** `lib/bloc/layout_bloc.dart`

#### **Line 12-22: BLoC Constructor**
```dart
LayoutBloc({required this.repository}) : super(LayoutState.initial()) {
  on<LoadLayoutsEvent>(_onLoadLayouts);  // Line 14 - Registers handler
  on<AddWidgetEvent>(_onAddWidget);      // Line 15
  on<SaveLayoutEvent>(_onSaveLayout);    // Line 21
}
```
**What happens:**
- Registers event handlers
- Initial state: `LayoutState.initial()` (empty layouts, activeTabId: "tab1")

---

#### **Line 24-43: _onLoadLayouts Method**
```dart
Future<void> _onLoadLayouts(LoadLayoutsEvent event, Emitter<LayoutState> emit) {
  emit(state.copyWith(isLoading: true, error: null));  // Line 29
  
  try {
    final layouts = await repository.fetchLayouts();  // Line 32
    emit(state.copyWith(                              // Line 33
      layouts: layouts,
      isLoading: false,
    ));
  } catch (e) {
    emit(state.copyWith(                              // Line 38
      isLoading: false,
      error: 'Failed to load layouts: $e',
    ));
  }
}
```
**What happens:**
1. Sets loading state
2. Calls `repository.fetchLayouts()`
3. Emits state with loaded layouts
4. UI rebuilds with loaded data

---

## 📍 STEP 4: Repository Loads from Firestore (layout_repository.dart)

### **File:** `lib/repository/layout_repository.dart`

#### **Line 31-71: fetchLayouts Method**
```dart
Future<Map<String, LayoutModel>> fetchLayouts() async {
  final userId = _getUserId();  // Line 36 - Gets "user1"
  final docRef = _firestore.collection('layouts').doc(userId);  // Line 37
  
  final docSnapshot = await docRef.get();  // Line 40
  
  if (!docSnapshot.exists) {
    return {};  // Line 45 - No layouts saved yet
  }
  
  final data = docSnapshot.data();  // Line 49
  final Map<String, LayoutModel> layouts = {};
  
  data.forEach((tabId, layoutJson) {  // Line 59
    if (layoutJson is Map<String, dynamic>) {
      layouts[tabId] = LayoutModel.fromJson(layoutJson);  // Line 62
    }
  });
  
  return layouts;  // Line 66
}
```
**What happens:**
1. Gets Firestore document for user
2. Reads JSON data
3. Converts JSON → LayoutModel using `fromJson()`
4. Returns map of layouts

**Data transformation:**
```
Firestore JSON → LayoutModel.fromJson() → LayoutModel object
```

---

## 📍 STEP 5: UI Renders (layout_builder_screen.dart)

### **File:** `lib/presentation/layout_builder_screen.dart`

#### **Line 29-37: Body Layout**
```dart
body: const Row(
  children: [
    WidgetPalette(),        // Line 32 - Left side
    Expanded(
      child: CanvasWidget(), // Line 35 - Right side
    ),
  ],
)
```
**What happens:**
- Creates row with palette (left) and canvas (right)

---

#### **Line 45-83: WidgetPalette**
```dart
class WidgetPalette extends StatelessWidget {
  static const List<String> widgetTypes = ['A', 'B', 'C', 'D'];  // Line 49
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(  // Line 72
      itemBuilder: (context, index) {
        return _DraggableWidgetItem(widgetType: widgetTypes[index]);  // Line 76
      },
    );
  }
}
```
**What happens:**
- Creates list of 4 draggable widgets (A, B, C, D)

---

#### **Line 87-147: _DraggableWidgetItem**
```dart
class _DraggableWidgetItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Draggable<String>(  // Line 96
      data: widgetType,  // Line 97 - "A", "B", "C", or "D"
      // ... visual styling
    );
  }
}
```
**What happens:**
- Creates draggable widget
- `data: widgetType` = what gets passed when dropped

---

#### **Line 150-267: CanvasWidget**
```dart
class CanvasWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LayoutBloc, LayoutState>(  // Line 155
      builder: (context, state) {
        final activeLayout = state.activeLayout;  // Line 175
        
        return DragTarget<String>(  // Line 222
          onAccept: (widgetType) {  // Line 224
            // Handle drop
          },
        );
      },
    );
  }
}
```
**What happens:**
- Listens to BLoC state changes
- Shows loading/error/empty states
- Renders widgets from state
- Accepts dropped widgets

---

## 📍 STEP 6: User Drags Widget

### **Flow:**
```
User clicks widget "A" in palette
    ↓
layout_builder_screen.dart:96
Draggable<String> starts drag
    ↓
User drags over canvas
    ↓
layout_builder_screen.dart:223
DragTarget.onWillAccept("A") → returns true
    ↓
Canvas highlights (visual feedback)
    ↓
User drops widget
    ↓
layout_builder_screen.dart:224
DragTarget.onAccept("A") called
```

---

## 📍 STEP 7: Drop Accepted → Event Sent (layout_builder_screen.dart)

### **File:** `lib/presentation/layout_builder_screen.dart`

#### **Line 224-240: onAccept Handler**
```dart
onAccept: (widgetType) {  // widgetType = "A"
  print('✅ Drop accepted: $widgetType');  // Line 225
  
  final RenderBox? renderBox = context.findRenderObject() as RenderBox?;  // Line 227
  if (renderBox == null) return;
  
  final size = renderBox.size;  // Line 230
  
  // Send AddWidgetEvent to BLoC
  context.read<LayoutBloc>().add(  // Line 233
    AddWidgetEvent(
      type: widgetType,              // "A"
      x: size.width / 2 - 50,       // Line 238 - Center X
      y: size.height / 2 - 50,      // Line 239 - Center Y
    ),
  );
}
```
**What happens:**
1. Gets canvas size
2. Calculates drop position (currently center)
3. Sends `AddWidgetEvent` to BLoC

**Data created:**
```dart
AddWidgetEvent(type: "A", x: 400.0, y: 300.0)
```

---

## 📍 STEP 8: BLoC Processes Event (layout_bloc.dart)

### **File:** `lib/bloc/layout_bloc.dart`

#### **Line 46-85: _onAddWidget Method**
```dart
Future<void> _onAddWidget(AddWidgetEvent event, Emitter<LayoutState> emit) {
  print('🎯 BLoC: AddWidgetEvent received');  // Line 50
  
  // Line 53-61: Create layout if doesn't exist
  var activeLayout = state.activeLayout;
  if (activeLayout == null) {
    activeLayout = LayoutModel(
      tabId: state.activeTabId,  // "tab1"
      tabName: 'Layout tab1',
      widgets: [],
    );
  }
  
  // Line 63-70: Create WidgetModel
  final newWidget = WidgetModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),  // "1234567890"
    type: event.type,  // "A"
    x: event.x,        // 400.0
    y: event.y,        // 300.0
    width: 100,
    height: 100,
  );
  
  // Line 74-75: Update LayoutModel
  final updatedWidgets = [...activeLayout.widgets, newWidget];
  final updatedLayout = activeLayout.copyWith(widgets: updatedWidgets);
  
  // Line 77-78: Update state
  final updatedLayouts = Map<String, LayoutModel>.from(state.layouts);
  updatedLayouts[state.activeTabId] = updatedLayout;
  
  // Line 81: Emit new state
  emit(state.copyWith(layouts: updatedLayouts));
  
  // Line 84: Trigger save
  add(const SaveLayoutEvent());
}
```
**What happens:**
1. Creates WidgetModel from event
2. Adds widget to LayoutModel
3. Updates state
4. Emits new state (UI rebuilds)
5. Triggers save

**Data transformations:**
```
AddWidgetEvent → WidgetModel → LayoutModel → LayoutState
```

---

## 📍 STEP 9: UI Rebuilds (layout_builder_screen.dart)

### **File:** `lib/presentation/layout_builder_screen.dart`

#### **Line 155: BlocBuilder Rebuilds**
```dart
BlocBuilder<LayoutBloc, LayoutState>(
  builder: (context, state) {
    // This rebuilds when state changes
    final activeLayout = state.activeLayout;  // Line 175
    // ... render widgets
  },
)
```
**What happens:**
- BLoC emits new state
- BlocBuilder detects change
- Rebuilds UI

---

#### **Line 234-258: Render Widgets**
```dart
...activeLayout.widgets.map((widget) {  // Line 234
  return Positioned(
    left: widget.x,      // Line 236 - From WidgetModel
    top: widget.y,       // Line 237 - From WidgetModel
    child: Container(
      width: widget.width,   // Line 239 - From WidgetModel
      height: widget.height, // Line 240 - From WidgetModel
      child: Text(widget.type), // Line 248 - From WidgetModel
    ),
  );
})
```
**What happens:**
- Maps each WidgetModel to a Positioned widget
- Uses WidgetModel properties (x, y, width, height, type)
- Widget appears on canvas

---

## 📍 STEP 10: Auto-Save Triggered (layout_bloc.dart)

### **File:** `lib/bloc/layout_bloc.dart`

#### **Line 84: SaveLayoutEvent Triggered**
```dart
add(const SaveLayoutEvent());  // Line 84
```
**What happens:**
- After adding widget, automatically triggers save

---

#### **Line 183-195: _onSaveLayout Method**
```dart
Future<void> _onSaveLayout(SaveLayoutEvent event, Emitter<LayoutState> emit) {
  final activeLayout = state.activeLayout;  // Line 187
  if (activeLayout == null) return;
  
  try {
    await repository.saveLayout(activeLayout);  // Line 191
  } catch (e) {
    emit(state.copyWith(error: 'Failed to save layout: $e'));  // Line 193
  }
}
```
**What happens:**
- Gets active layout
- Calls repository to save

---

## 📍 STEP 11: Repository Saves to Firestore (layout_repository.dart)

### **File:** `lib/repository/layout_repository.dart`

#### **Line 77-97: saveLayout Method**
```dart
Future<void> saveLayout(LayoutModel layout) async {
  final userId = _getUserId();  // Line 80 - "user1"
  final docRef = _firestore.collection('layouts').doc(userId);  // Line 81
  
  final layoutJson = layout.toJson();  // Line 84 - Converts to JSON
  
  await docRef.set(  // Line 89
    {layout.tabId: layoutJson},
    SetOptions(merge: true),
  );
}
```
**What happens:**
1. Gets Firestore document reference
2. Converts LayoutModel to JSON
3. Saves to Firestore

---

## 📍 STEP 12: JSON Conversion (layout_model.dart & widget_model.dart)

### **File:** `lib/models/layout_model.dart`

#### **Line 42-49: toJson Method**
```dart
Map<String, dynamic> toJson() {
  return {
    'tabId': tabId,
    'tabName': tabName,
    'widgets': widgets.map((widget) => widget.toJson()).toList(),  // Line 47
    'lastUpdated': lastUpdated?.toIso8601String(),
  };
}
```
**What happens:**
- Converts LayoutModel to JSON
- Calls `widget.toJson()` for each widget

---

### **File:** `lib/models/widget_model.dart`

#### **Line 53-62: toJson Method**
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
**What happens:**
- Converts WidgetModel to JSON

**Final JSON structure:**
```json
{
  "tab1": {
    "tabId": "tab1",
    "tabName": "Layout tab1",
    "widgets": [
      {
        "id": "1234567890",
        "type": "A",
        "x": 400.0,
        "y": 300.0,
        "width": 100.0,
        "height": 100.0
      }
    ]
  }
}
```

---

## 🔄 Complete Method Call Chain

```
1. main.dart:16
   runApp(MyApp())
   ↓
2. main.dart:45
   MaterialApp(home: LayoutBuilderScreen())
   ↓
3. layout_builder_screen.dart:20
   BlocProvider(create: LayoutBloc(...))
   ↓
4. layout_builder_screen.dart:23
   LayoutBloc()..add(LoadLayoutsEvent())
   ↓
5. layout_bloc.dart:14
   on<LoadLayoutsEvent>(_onLoadLayouts)
   ↓
6. layout_bloc.dart:32
   repository.fetchLayouts()
   ↓
7. layout_repository.dart:40
   docRef.get() → Firestore
   ↓
8. layout_repository.dart:62
   LayoutModel.fromJson(layoutJson)
   ↓
9. layout_bloc.dart:33
   emit(state.copyWith(layouts: layouts))
   ↓
10. layout_builder_screen.dart:155
    BlocBuilder rebuilds
    ↓
11. User drags widget "A"
    ↓
12. layout_builder_screen.dart:224
    DragTarget.onAccept("A")
    ↓
13. layout_builder_screen.dart:233
    LayoutBloc.add(AddWidgetEvent(type: "A", x: 400, y: 300))
    ↓
14. layout_bloc.dart:15
    on<AddWidgetEvent>(_onAddWidget)
    ↓
15. layout_bloc.dart:63
    WidgetModel(id: "...", type: "A", x: 400, y: 300, ...)
    ↓
16. layout_bloc.dart:74
    activeLayout.copyWith(widgets: [...oldWidgets, newWidget])
    ↓
17. layout_bloc.dart:81
    emit(state.copyWith(layouts: updatedLayouts))
    ↓
18. layout_builder_screen.dart:155
    BlocBuilder rebuilds
    ↓
19. layout_builder_screen.dart:234
    activeLayout.widgets.map((widget) => render widget)
    ↓
20. layout_bloc.dart:84
    add(SaveLayoutEvent())
    ↓
21. layout_bloc.dart:21
    on<SaveLayoutEvent>(_onSaveLayout)
    ↓
22. layout_bloc.dart:191
    repository.saveLayout(activeLayout)
    ↓
23. layout_repository.dart:84
    layout.toJson()
    ↓
24. layout_model.dart:47
    widgets.map((widget) => widget.toJson())
    ↓
25. widget_model.dart:53
    widget.toJson() → Returns JSON
    ↓
26. layout_repository.dart:89
    docRef.set({tabId: layoutJson})
    ↓
27. FIRESTORE
    Data saved ✅
```

---

## 📊 Data Flow Summary

### **App Start:**
```
main.dart → MyApp → LayoutBuilderScreen → BlocProvider → LayoutBloc
    ↓
LoadLayoutsEvent → repository.fetchLayouts() → Firestore
    ↓
LayoutModel.fromJson() → State → UI renders
```

### **User Drags Widget:**
```
Palette Draggable → Canvas DragTarget.onAccept()
    ↓
AddWidgetEvent → BLoC._onAddWidget()
    ↓
WidgetModel created → LayoutModel updated → State emitted
    ↓
UI rebuilds → Widget appears on canvas
    ↓
SaveLayoutEvent → repository.saveLayout()
    ↓
LayoutModel.toJson() → WidgetModel.toJson() → Firestore
```

---

## 🎯 Key Files & Their Roles

| File | Role | Key Methods |
|------|------|-------------|
| `main.dart` | App entry point | `main()`, `MyApp.build()` |
| `layout_builder_screen.dart` | UI layer | `LayoutBuilderScreen`, `WidgetPalette`, `CanvasWidget` |
| `layout_bloc.dart` | State management | `_onLoadLayouts()`, `_onAddWidget()`, `_onSaveLayout()` |
| `layout_repository.dart` | Data access | `fetchLayouts()`, `saveLayout()` |
| `layout_model.dart` | Data model | `toJson()`, `fromJson()` |
| `widget_model.dart` | Data model | `toJson()`, `fromJson()` |

---

## 🔍 Where Each Action Happens

### **App Initialization:**
- `main.dart:6-17` - App starts, Firebase initializes
- `main.dart:45` - Sets LayoutBuilderScreen as home

### **Screen Setup:**
- `layout_builder_screen.dart:20-23` - Creates BLoC, loads layouts
- `layout_builder_screen.dart:29-37` - Creates palette + canvas layout

### **Loading Layouts:**
- `layout_bloc.dart:24-43` - Handles LoadLayoutsEvent
- `layout_repository.dart:31-71` - Fetches from Firestore
- `layout_model.dart:52-64` - Converts JSON to LayoutModel

### **User Drags Widget:**
- `layout_builder_screen.dart:96` - Draggable widget in palette
- `layout_builder_screen.dart:224` - DragTarget accepts drop

### **Adding Widget:**
- `layout_builder_screen.dart:233` - Sends AddWidgetEvent
- `layout_bloc.dart:46-85` - Creates WidgetModel, updates state
- `layout_builder_screen.dart:234` - Renders widgets

### **Saving:**
- `layout_bloc.dart:84` - Triggers SaveLayoutEvent
- `layout_bloc.dart:183-195` - Handles save
- `layout_repository.dart:77-97` - Saves to Firestore
- `layout_model.dart:42-49` - Converts to JSON
- `widget_model.dart:53-62` - Converts to JSON

---

## 💡 Current Issue: Widgets All in Center

**Problem Location:** `layout_builder_screen.dart:238-239`
```dart
x: size.width / 2 - 50,   // Always center X
y: size.height / 2 - 50,  // Always center Y
```

**Why:** Not getting actual drop position from drag details

**Solution:** Need to capture drop position from `DragTarget.onAccept` parameters
