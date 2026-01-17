import 'package:flutter_bloc/flutter_bloc.dart';
import 'layout_events.dart';
import 'layout_state.dart';
import '../models/widget_model.dart';
import '../models/layout_model.dart';
import '../repository/layout_repository.dart';

/// Business logic component for managing layout state and operations.
///
/// Handles all layout-related events including widget manipulation (add, move,
/// resize, delete), tab management (create, switch, delete, rename), and
/// persistence operations. Automatically saves changes to Firestore after
/// widget modifications and tab operations.
class LayoutBloc extends Bloc<LayoutEvent, LayoutState> {
  final LayoutRepository repository;

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

  /// Loads all layouts from Firestore and initializes state.
  ///
  /// Creates a default tab if no layouts exist. Sets the first available
  /// layout as active if the current active tab ID is invalid.
  Future<void> _onLoadLayouts(
    LoadLayoutsEvent event,
    Emitter<LayoutState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final layouts = await repository.fetchLayouts();

      if (layouts.isEmpty) {
        final defaultTabId = 'tab${DateTime.now().millisecondsSinceEpoch}';
        final defaultTabName = 'Tab 1';
        final defaultLayout = LayoutModel(
          tabId: defaultTabId,
          tabName: defaultTabName,
          widgets: [],
        );

        final updatedLayouts = {defaultTabId: defaultLayout};

        emit(state.copyWith(
          layouts: updatedLayouts,
          activeTabId: defaultTabId,
          isLoading: false,
        ));

        add(const SaveLayoutEvent());
      } else {
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

  /// Adds a new widget to the active layout.
  ///
  /// Creates a new layout if none exists for the active tab. Widgets are
  /// created with default dimensions (100x100) and positioned at the drop
  /// coordinates. Automatically saves the layout after adding.
  Future<void> _onAddWidget(
    AddWidgetEvent event,
    Emitter<LayoutState> emit,
  ) async {
    var activeLayout = state.activeLayout;
    if (activeLayout == null) {
      activeLayout = LayoutModel(
        tabId: state.activeTabId,
        tabName: 'Layout ${state.activeTabId}',
        widgets: [],
      );
    }

    final newWidget = WidgetModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: event.type,
      x: event.x,
      y: event.y,
      width: 100,
      height: 100,
    );

    final updatedWidgets = [...activeLayout.widgets, newWidget];
    final updatedLayout = activeLayout.copyWith(widgets: updatedWidgets);

    final updatedLayouts = Map<String, LayoutModel>.from(state.layouts);
    updatedLayouts[state.activeTabId] = updatedLayout;

    emit(state.copyWith(layouts: updatedLayouts));
    add(const SaveLayoutEvent());
  }

  /// Moves a widget to a new position on the canvas.
  ///
  /// Updates the widget's x and y coordinates. Automatically saves the
  /// layout after moving.
  Future<void> _onMoveWidget(
    MoveWidgetEvent event,
    Emitter<LayoutState> emit,
  ) async {
    final activeLayout = state.activeLayout;
    if (activeLayout == null) return;

    final updatedWidgets = activeLayout.widgets.map((widget) {
      if (widget.id == event.widgetId) {
        return widget.copyWith(x: event.newX, y: event.newY);
      }
      return widget;
    }).toList();

    final updatedLayout = activeLayout.copyWith(widgets: updatedWidgets);
    final updatedLayouts = Map<String, LayoutModel>.from(state.layouts);
    updatedLayouts[state.activeTabId] = updatedLayout;

    emit(state.copyWith(layouts: updatedLayouts));
    add(const SaveLayoutEvent());
  }

  /// Resizes a widget to new dimensions.
  ///
  /// Updates the widget's width and height. Automatically saves the layout
  /// after resizing.
  Future<void> _onResizeWidget(
    ResizeWidgetEvent event,
    Emitter<LayoutState> emit,
  ) async {
    final activeLayout = state.activeLayout;
    if (activeLayout == null) return;

    final updatedWidgets = activeLayout.widgets.map((widget) {
      if (widget.id == event.widgetId) {
        return widget.copyWith(
          width: event.newWidth,
          height: event.newHeight,
        );
      }
      return widget;
    }).toList();

    final updatedLayout = activeLayout.copyWith(widgets: updatedWidgets);
    final updatedLayouts = Map<String, LayoutModel>.from(state.layouts);
    updatedLayouts[state.activeTabId] = updatedLayout;

    emit(state.copyWith(layouts: updatedLayouts));
    add(const SaveLayoutEvent());
  }

  /// Deletes a widget from the active layout.
  ///
  /// Removes the widget from the layout's widget list. Automatically saves
  /// the layout after deletion.
  Future<void> _onDeleteWidget(
    DeleteWidgetEvent event,
    Emitter<LayoutState> emit,
  ) async {
    final activeLayout = state.activeLayout;
    if (activeLayout == null) return;

    final updatedWidgets = activeLayout.widgets
        .where((widget) => widget.id != event.widgetId)
        .toList();

    final updatedLayout = activeLayout.copyWith(widgets: updatedWidgets);
    final updatedLayouts = Map<String, LayoutModel>.from(state.layouts);
    updatedLayouts[state.activeTabId] = updatedLayout;

    emit(state.copyWith(layouts: updatedLayouts));
    add(const SaveLayoutEvent());
  }

  /// Switches the active tab to the specified tab ID.
  ///
  /// Only switches if the tab exists in the current layouts.
  Future<void> _onSwitchTab(
    SwitchTabEvent event,
    Emitter<LayoutState> emit,
  ) async {
    if (state.layouts.containsKey(event.tabId)) {
      emit(state.copyWith(activeTabId: event.tabId));
    }
  }

  /// Creates a new tab/layout with the specified ID and name.
  ///
  /// Adds the new layout to state and sets it as active. Automatically
  /// saves the new layout to Firestore.
  Future<void> _onCreateTab(
    CreateTabEvent event,
    Emitter<LayoutState> emit,
  ) async {
    final newLayout = LayoutModel(
      tabId: event.tabId,
      tabName: event.tabName,
      widgets: [],
    );

    final updatedLayouts = Map<String, LayoutModel>.from(state.layouts);
    updatedLayouts[event.tabId] = newLayout;

    emit(state.copyWith(
      layouts: updatedLayouts,
      activeTabId: event.tabId,
    ));

    add(const SaveLayoutEvent());
  }

  /// Deletes a tab/layout from state and Firestore.
  ///
  /// Prevents deletion if it's the only remaining tab. If the deleted tab
  /// is active, switches to the first available tab. Deletes from Firestore
  /// and saves all remaining layouts to ensure consistency.
  Future<void> _onDeleteTab(
    DeleteTabEvent event,
    Emitter<LayoutState> emit,
  ) async {
    final updatedLayouts = Map<String, LayoutModel>.from(state.layouts);

    if (updatedLayouts.length <= 1) {
      return;
    }

    updatedLayouts.remove(event.tabId);

    String newActiveTabId = state.activeTabId;
    if (event.tabId == state.activeTabId && updatedLayouts.isNotEmpty) {
      newActiveTabId = updatedLayouts.keys.first;
    }

    emit(state.copyWith(
      layouts: updatedLayouts,
      activeTabId: newActiveTabId,
    ));

    try {
      await repository.deleteTab(event.tabId);
      await repository.saveAllLayouts(updatedLayouts);
    } catch (e) {
      emit(state.copyWith(error: 'Failed to delete tab: $e'));
    }
  }

  /// Renames a tab/layout with a new name.
  ///
  /// Updates the layout's tab name and saves to Firestore.
  Future<void> _onRenameTab(
    RenameTabEvent event,
    Emitter<LayoutState> emit,
  ) async {
    final activeLayout = state.layouts[event.tabId];
    if (activeLayout == null) return;

    final updatedLayout = activeLayout.copyWith(tabName: event.newName);
    final updatedLayouts = Map<String, LayoutModel>.from(state.layouts);
    updatedLayouts[event.tabId] = updatedLayout;

    emit(state.copyWith(layouts: updatedLayouts));
    add(const SaveLayoutEvent());
  }

  /// Saves the current active layout to Firestore.
  ///
  /// Persists the active layout's state. Emits an error state if the save
  /// operation fails.
  Future<void> _onSaveLayout(
    SaveLayoutEvent event,
    Emitter<LayoutState> emit,
  ) async {
    final activeLayout = state.activeLayout;
    if (activeLayout == null) return;

    try {
      await repository.saveLayout(activeLayout);
    } catch (e) {
      emit(state.copyWith(error: 'Failed to save layout: $e'));
    }
  }
}
