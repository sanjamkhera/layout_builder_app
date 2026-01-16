# Flutter Drag & Drop Layout Builder (Canvas + Tabs + Firestore)

A responsive layout builder built with Flutter, BLoC state management, and Firebase Firestore. Users can visually design screens by dragging and dropping predefined widgets (A, B, C, D, etc.) into a canvas, resize them dynamically, and manage multiple layouts using tabs.

## 🎯 Project Overview

Build a **screen designer** where users can:
- Drag predefined widgets (A/B/C/D/...) from a palette
- Drop them into **one canvas** (one panel)
- Move + resize them
- Use **tabs** for multiple layouts
- Save/load layouts as **JSON** in **Firebase Firestore**

Each layout is stored as JSON in Firestore. When the user revisits, the saved layout is fetched and rendered exactly as it was left. Any updates are synced back to Firestore.

---

## 📁 Project Structure

```
lib/
├── bloc/
│   ├── layout_bloc.dart      # BLoC that manages layout state
│   ├── layout_events.dart     # All user actions (Add, Move, Resize, etc.)
│   └── layout_state.dart      # Current app state (layouts, activeTab, etc.)
├── models/
│   ├── widget_model.dart      # Single widget data (id, type, position, size)
│   └── layout_model.dart       # Complete layout data (tabId, widgets list)
├── repository/
│   └── layout_repository.dart # Firestore operations (save/load)
├── presentation/
│   └── test_screen.dart       # Test screen for Firestore sync
├── firebase_options.dart      # Firebase configuration
└── main.dart                  # App entry point
```

---

## ✅ Progress Status

### PART 1: Project Setup & Architecture ✅ **COMPLETED**

**Goal:** Create a scalable and maintainable foundation

**Completed:**
- ✅ Added dependencies: `flutter_bloc`, `firebase_core`, `cloud_firestore`, `equatable`
- ✅ Configured Firebase for Flutter
- ✅ Generated `firebase_options.dart` via FlutterFire CLI
- ✅ Initialized Firebase in `main.dart`
- ✅ Created folder structure:
  - `lib/presentation/`
  - `lib/bloc/`
  - `lib/models/`
  - `lib/repository/`
- ✅ Created base BLoC architecture (LayoutBloc, Events, State)

**Deliverables:**
- ✅ Firebase connected project
- ✅ Base BLoC architecture

---

### PART 2: Layout Data Model & Firestore Integration ✅ **COMPLETED**

**Goal:** Define how layouts are stored and retrieved

**Completed:**
- ✅ Created `WidgetModel` with:
  - id, type, position (x, y), size (width, height)
  - JSON serialization (`toJson()`, `fromJson()`)
- ✅ Created `LayoutModel` with:
  - tabId, tabName, widgets list
  - JSON serialization (`toJson()`, `fromJson()`)
- ✅ Created Firestore repository:
  - `fetchLayouts()` - loads all layouts from Firestore
  - `saveLayout()` - saves a layout to Firestore
  - `saveAllLayouts()` - saves multiple layouts at once
- ✅ Created test screen to verify Firestore sync
- ⚠️ Initial load on screen open (will be implemented in Part 3 with UI)

**Deliverables:**
- ✅ Fully working Firestore sync
- ✅ Layout persistence (data survives app restarts)

**Test Results:**
- ✅ Can save layouts to Firestore
- ✅ Can load layouts from Firestore
- ✅ JSON serialization/deserialization working
- ✅ Data persists in cloud storage

---

### PART 3: Canvas & Drag-Drop System ✅ **COMPLETED**

**Goal:** Enable widget placement

**Completed:**
- ✅ Created single canvas widget (`CanvasWidget`)
- ✅ Widget palette side menu with draggable widgets (A, B, C, D)
- ✅ Drag source from palette (`Draggable<String>`)
- ✅ Drop target on canvas (`DragTarget<String>`)
- ✅ Captures actual drop position (not just center)
- ✅ Widgets are draggable on canvas (can be moved around)
- ✅ BLoC integration (sends AddWidgetEvent and MoveWidgetEvent)
- ✅ Initial load on screen open (LoadLayoutsEvent)

**Deliverables:**
- ✅ Widgets can be added via drag & drop
- ✅ All widgets rendered in one panel
- ✅ Widgets can be moved around on canvas

---

### PART 4: Resize & Layout Interaction ✅ **COMPLETED**

**Goal:** Allow user to resize and manipulate widgets

**Completed:**
- ✅ Added resize handles (8 handles: 4 corners + 4 edges)
- ✅ Update width & height on drag (real-time resize updates)
- ✅ Maintain minimum size constraints (50px minimum)
- ✅ Update layout state via BLoC (ResizeWidgetEvent + MoveWidgetEvent)
- ✅ Re-render canvas efficiently (BlocBuilder for state-driven updates)

**Deliverables:**
- ✅ Resizable widgets
- ✅ Smooth drag + resize UX

---

### PART 5: Multi-Tab Layout Management & Sync ⏳ **PENDING**

**Goal:** Support multiple layouts

**Tasks:**
- ⏳ Add tab UI
- ⏳ Create new layout tab
- ⏳ Switch active layout
- ⏳ Load layout from Firestore on tab change
- ⏳ Auto-save layout on update
- ⏳ Handle conflicts / overwrite safely

**Deliverables:**
- ⏳ Multiple layouts per user
- ⏳ Persistent layout per tab

---

## 🛠️ Tech Stack

- **Flutter** - UI framework
- **flutter_bloc** - State management
- **equatable** - Value equality for BLoC
- **Firebase Core** - Firebase initialization
- **Cloud Firestore** - Database for layout persistence

---

## 📦 Dependencies

```yaml
dependencies:
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  firebase_core: ^3.6.0
  cloud_firestore: ^5.4.4
```

---

## 🏗️ Architecture Overview

### BLoC Pattern

**Events** (`layout_events.dart`):
- `AddWidgetEvent` - Add widget to canvas
- `MoveWidgetEvent` - Move widget on canvas
- `ResizeWidgetEvent` - Resize widget
- `DeleteWidgetEvent` - Delete widget
- `LoadLayoutsEvent` - Load from Firestore
- `SaveLayoutEvent` - Save to Firestore
- `SwitchTabEvent` - Switch active tab
- `CreateTabEvent` - Create new tab

**State** (`layout_state.dart`):
- `layouts` - Map of all layouts (by tabId)
- `activeTabId` - Currently active tab
- `isLoading` - Loading indicator
- `error` - Error messages

**BLoC** (`layout_bloc.dart`):
- Handles all events
- Updates state
- Calls repository to save/load from Firestore
- Auto-saves after changes

### Data Models

**WidgetModel**:
- Represents a single widget on canvas
- Contains: id, type, position (x, y), size (width, height)
- JSON serializable for Firestore

**LayoutModel**:
- Represents a complete layout (one tab)
- Contains: tabId, tabName, list of widgets
- JSON serializable for Firestore

### Repository Pattern

**LayoutRepository**:
- `fetchLayouts()` - Loads all layouts from Firestore
- `saveLayout()` - Saves a layout to Firestore
- Handles JSON conversion (models ↔ Firestore)

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.10.7+)
- Firebase project set up
- FlutterFire CLI installed

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd layout_builder_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Firebase is already configured via `firebase_options.dart`
   - Ensure Firestore security rules allow read/write (for testing):
     ```javascript
     rules_version = '2';
     service cloud.firestore {
       match /databases/{database}/documents {
         match /{document=**} {
           allow read, write: if true;
         }
       }
     }
     ```

4. **Run the app**
   ```bash
   flutter run -d chrome  # Web
   flutter run -d macos  # macOS
   flutter run -d ios    # iOS
   ```

---

## 🧪 Testing

A test screen is available at `lib/presentation/test_screen.dart` to verify:
- Firebase connection
- Firestore save/load operations
- JSON serialization/deserialization

---

## 📝 Notes

- **Single Canvas**: All widgets exist in one canvas (not stacked layers)
- **Multiple Layouts**: Each tab represents a separate layout
- **Auto-save**: Layouts are automatically saved to Firestore on changes
- **Persistence**: Layouts persist across app restarts via Firestore

---

## 🔄 Data Flow

1. App loads → Fetch layouts from Firestore
2. Active tab layout rendered on canvas
3. User drags/resizes widgets
4. LayoutBloc updates state
5. Updated JSON saved to Firestore
6. On revisit → Layout restored from Firestore

---

## 📚 Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [BLoC Pattern](https://bloclibrary.dev/)
- [Firebase Firestore](https://firebase.google.com/docs/firestore)
- [FlutterFire](https://firebase.flutter.dev/)

---

## 📄 License

This project is part of a learning exercise.
