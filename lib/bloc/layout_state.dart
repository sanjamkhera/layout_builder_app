import 'package:equatable/equatable.dart';
import '../models/layout_model.dart';

/// State class representing the current state of the layout builder
class LayoutState extends Equatable {
  /// Map of all layouts: key = tabId, value = LayoutModel
  final Map<String, LayoutModel> layouts;

  /// Currently active tab ID
  final String activeTabId;

  /// Loading state (true when fetching/saving)
  final bool isLoading;

  /// Error message (null if no error)
  final String? error;

  const LayoutState({
    required this.layouts,
    required this.activeTabId,
    this.isLoading = false,
    this.error,
  });

  /// Get the active layout (current tab's layout)
  LayoutModel? get activeLayout => layouts[activeTabId];

  /// Create initial/empty state
  factory LayoutState.initial() {
    return const LayoutState(
      layouts: {},
      activeTabId: 'tab1',
    );
  }

  /// Copy with method for immutable updates
  LayoutState copyWith({
    Map<String, LayoutModel>? layouts,
    String? activeTabId,
    bool? isLoading,
    String? error,
  }) {
    return LayoutState(
      layouts: layouts ?? this.layouts,
      activeTabId: activeTabId ?? this.activeTabId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [layouts, activeTabId, isLoading, error];
}
