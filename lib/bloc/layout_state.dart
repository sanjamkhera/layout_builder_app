import 'package:equatable/equatable.dart';
import '../models/layout_model.dart';

/// Immutable state class representing the current state of the layout builder.
///
/// Contains all layouts indexed by tab ID, the currently active tab,
/// loading status, and any error messages. Implements [Equatable] for
/// efficient state change detection in BLoC.
class LayoutState extends Equatable {
  /// Map of all layouts indexed by tab ID.
  final Map<String, LayoutModel> layouts;

  /// ID of the currently active tab.
  final String activeTabId;

  /// Whether an async operation (fetch/save) is in progress.
  final bool isLoading;

  /// Error message, or null if no error has occurred.
  final String? error;

  const LayoutState({
    required this.layouts,
    required this.activeTabId,
    this.isLoading = false,
    this.error,
  });

  /// Returns the active layout for the current tab, or null if not found.
  LayoutModel? get activeLayout => layouts[activeTabId];

  /// Creates an initial empty state with no layouts and a default active tab ID.
  factory LayoutState.initial() {
    return const LayoutState(
      layouts: {},
      activeTabId: 'tab1',
    );
  }

  /// Creates a copy of this state with optionally updated fields.
  ///
  /// Returns a new [LayoutState] instance with the same values as this one,
  /// except for the fields explicitly provided. Unspecified fields retain
  /// their current values.
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
