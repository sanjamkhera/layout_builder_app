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
- ✅ Implemented user identification with Firebase Anonymous Authentication
  - Each device gets unique user ID automatically
  - User ID persists across app restarts
  - Complete data isolation between users/devices
- ✅ Initial load on screen open (implemented in Part 3 with UI)

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

### PART 5: Multi-Tab Layout Management & Sync ✅ **COMPLETED**

**Goal:** Support multiple layouts

**Completed:**
- ✅ Created `TabsControl` widget with full tab UI
  - Displays all tabs with active tab highlighting
  - Horizontal scrollable tab list
  - "+" button to create new tabs
  - Delete button (X) on each tab with confirmation dialog
  - Long press to rename tabs
- ✅ Tab creation (`CreateTabEvent` + handler)
  - Generates unique tab IDs
  - Creates new `LayoutModel` in state
  - Automatically saves to Firestore
  - Creates default tab if no layouts exist on initial load
- ✅ Tab switching (`SwitchTabEvent` + handler)
  - Updates `activeTabId` in state
  - Canvas automatically shows active tab's widgets via `BlocBuilder`
  - All layouts loaded once on initial load (efficient state management)
- ✅ Auto-save on layout changes
  - All tab operations automatically dispatch `SaveLayoutEvent`
  - Tab creation → auto-save
  - Tab deletion → auto-save
  - Tab renaming → auto-save
  - Widget changes → auto-save (from Part 3 & 4)
- ✅ Safe conflict handling
  - Firestore `SetOptions(merge: true)` prevents overwrites
  - Tab deletion uses `FieldValue.delete()` to safely remove from Firestore
- ✅ Additional features:
  - Tab deletion with confirmation dialog (prevents accidental deletion)
  - Tab renaming via long press
  - Prevents deletion of last remaining tab
  - Automatic tab switching when deleting active tab

**Deliverables:**
- ✅ Multiple layouts per user
- ✅ Persistent layout per tab
- ✅ Full tab management UI (create, switch, delete, rename)

---

## 🛠️ Tech Stack

- **Flutter** - UI framework
- **flutter_bloc** - State management
- **equatable** - Value equality for BLoC
- **Firebase Core** - Firebase initialization
- **Firebase Authentication** - User identification (Anonymous Auth)
- **Cloud Firestore** - Database for layout persistence

---

## 📦 Dependencies

```yaml
dependencies:
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
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
- `DeleteTabEvent` - Delete tab (with confirmation)
- `RenameTabEvent` - Rename tab

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
- `fetchLayouts()` - Loads all layouts from Firestore (per user)
- `saveLayout()` - Saves a layout to Firestore (per user)
- `saveAllLayouts()` - Saves multiple layouts at once (per user)
- `deleteTab()` - Deletes a tab from Firestore (per user)
- `_getUserId()` - Gets unique user ID from Firebase Authentication
- Handles JSON conversion (models ↔ Firestore)

### User Identification

**Firebase Anonymous Authentication**:
- Each device automatically gets a unique user ID on app startup
- User ID persists across app restarts (stored locally)
- No UI required - authentication happens automatically in the background
- Each user's layouts are stored in a separate Firestore document: `layouts/{userId}`
- Provides complete data isolation between users/devices

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

3. **Enable Anonymous Authentication in Firebase Console**
   
   Before running the app, you must enable Anonymous Authentication:
   
   1. Go to [Firebase Console](https://console.firebase.google.com/)
   2. Select your project: `layout-builder-app`
   3. Navigate to: **Authentication** → **Sign-in method**
   4. Click on **Anonymous** provider
   5. Enable it and click **Save**
   
   This allows the app to automatically create unique user IDs for each device.

3. **Run the app**
   
   You can run the app on different platforms:
   
   **Web:**
   ```bash
   flutter run -d chrome
   ```
   
   **macOS:**
   ```bash
   flutter run -d macos
   ```
   
   **iOS (requires Xcode installed):**
   ```bash
   # List available iOS devices/simulators
   flutter devices
   
   # Run on iOS simulator
   flutter run -d ios
   
   # Or run on a connected iPhone/iPad
   flutter run -d <device-id>
   ```
   
   **Android (requires Android Studio installed):**
   ```bash
   # List available Android devices/emulators
   flutter devices
   
   # Run on Android emulator or connected device
   flutter run -d android
   
   # Or run on a specific device
   flutter run -d <device-id>
   ```
   
   **Note:** Make sure you have:
   - **Xcode** installed for iOS development (macOS only)
   - **Android Studio** installed with Android SDK for Android development
   - A connected device or running emulator/simulator

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
- **User Identification**: Each device gets a unique user ID via Firebase Anonymous Authentication
- **Data Isolation**: Each user's layouts are stored separately in Firestore (no data sharing between users)

---

## 🔄 Data Flow

1. App loads → Firebase initializes → Anonymous authentication (creates unique user ID)
2. Fetch layouts from Firestore using user ID → `layouts/{userId}`
3. Active tab layout rendered on canvas
4. User drags/resizes widgets
5. LayoutBloc updates state
6. Updated JSON saved to Firestore (under user's document)
7. On revisit → Layout restored from Firestore using same user ID

**Firestore Structure:**
```
layouts/
  ├── {user1-uid}/     # User 1's layouts
  │   ├── tab1: {...}
  │   └── tab2: {...}
  ├── {user2-uid}/     # User 2's layouts
  │   ├── tab1: {...}
  │   └── tab3: {...}
  └── {user3-uid}/     # User 3's layouts
      └── tab1: {...}
```

---

## 📚 Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [BLoC Pattern](https://bloclibrary.dev/)
- [Firebase Firestore](https://firebase.google.com/docs/firestore)
- [FlutterFire](https://firebase.flutter.dev/)

---

## 📄 License

This project is part of a learning exercise.
