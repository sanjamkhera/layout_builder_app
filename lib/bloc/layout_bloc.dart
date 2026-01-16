import 'package:flutter_bloc/flutter_bloc.dart';
import 'layout_events.dart';
import 'layout_state.dart';
import '../models/widget_model.dart';
import '../models/layout_model.dart';
import '../repository/layout_repository.dart';

/// BLoC that manages layout state and handles all layout-related events
class LayoutBloc extends Bloc<LayoutEvent, LayoutState> {
  final LayoutRepository repository;

  LayoutBloc({required this.repository}) : super(LayoutState.initial()) {
    // Register event handlers
    on<LoadLayoutsEvent>(_onLoadLayouts);
    on<AddWidgetEvent>(_onAddWidget);
    on<MoveWidgetEvent>(_onMoveWidget);
    on<ResizeWidgetEvent>(_onResizeWidget);
    on<DeleteWidgetEvent>(_onDeleteWidget);
    on<SwitchTabEvent>(_onSwitchTab);
    on<CreateTabEvent>(_onCreateTab);
    on<SaveLayoutEvent>(_onSaveLayout);
  }

  /// Load all layouts from Firestore
  Future<void> _onLoadLayouts(
    LoadLayoutsEvent event,
    Emitter<LayoutState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final layouts = await repository.fetchLayouts();
      emit(state.copyWith(
        layouts: layouts,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load layouts: $e',
      ));
    }
  }

  /// Add a new widget to the active layout
  Future<void> _onAddWidget(
    AddWidgetEvent event,
    Emitter<LayoutState> emit,
  ) async {
    final activeLayout = state.activeLayout;
    if (activeLayout == null) return;

    final newWidget = WidgetModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: event.type,
      x: event.x,
      y: event.y,
      width: 100, // Default width
      height: 100, // Default height
    );

    final updatedWidgets = [...activeLayout.widgets, newWidget];
    final updatedLayout = activeLayout.copyWith(widgets: updatedWidgets);

    final updatedLayouts = Map<String, LayoutModel>.from(state.layouts);
    updatedLayouts[state.activeTabId] = updatedLayout;

    emit(state.copyWith(layouts: updatedLayouts));

    // Auto-save after adding widget
    add(const SaveLayoutEvent());
  }

  /// Move a widget on the canvas
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

    // Auto-save after moving widget
    add(const SaveLayoutEvent());
  }

  /// Resize a widget
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

    // Auto-save after resizing widget
    add(const SaveLayoutEvent());
  }

  /// Delete a widget from canvas
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

    // Auto-save after deleting widget
    add(const SaveLayoutEvent());
  }

  /// Switch to a different tab
  Future<void> _onSwitchTab(
    SwitchTabEvent event,
    Emitter<LayoutState> emit,
  ) async {
    if (state.layouts.containsKey(event.tabId)) {
      emit(state.copyWith(activeTabId: event.tabId));
    }
  }

  /// Create a new tab/layout
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

    // Save the new layout
    add(const SaveLayoutEvent());
  }

  /// Save current layout to Firestore
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
