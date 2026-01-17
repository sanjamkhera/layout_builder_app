import 'package:equatable/equatable.dart';
import '../models/widget_model.dart';

/// Base class for all layout-related events.
///
/// All events extend [Equatable] for value-based equality comparison,
/// enabling efficient state change detection in BLoC.
abstract class LayoutEvent extends Equatable {
  const LayoutEvent();

  @override
  List<Object?> get props => [];
}

/// Event to add a new widget to the active layout at specified coordinates.
class AddWidgetEvent extends LayoutEvent {
  final String type;
  final double x;
  final double y;

  const AddWidgetEvent({
    required this.type,
    required this.x,
    required this.y,
  });

  @override
  List<Object?> get props => [type, x, y];
}

/// Event to move a widget to a new position on the canvas.
class MoveWidgetEvent extends LayoutEvent {
  final String widgetId;
  final double newX;
  final double newY;

  const MoveWidgetEvent({
    required this.widgetId,
    required this.newX,
    required this.newY,
  });

  @override
  List<Object?> get props => [widgetId, newX, newY];
}

/// Event to resize a widget to new dimensions.
class ResizeWidgetEvent extends LayoutEvent {
  final String widgetId;
  final double newWidth;
  final double newHeight;

  const ResizeWidgetEvent({
    required this.widgetId,
    required this.newWidth,
    required this.newHeight,
  });

  @override
  List<Object?> get props => [widgetId, newWidth, newHeight];
}

/// Event to delete a widget from the active layout.
class DeleteWidgetEvent extends LayoutEvent {
  final String widgetId;

  const DeleteWidgetEvent({required this.widgetId});

  @override
  List<Object?> get props => [widgetId];
}

/// Event to load all layouts from Firestore.
///
/// Typically dispatched on app initialization or when refreshing layout data.
class LoadLayoutsEvent extends LayoutEvent {
  const LoadLayoutsEvent();
}

/// Event to save the current active layout to Firestore.
///
/// Automatically dispatched after widget modifications and tab operations
/// to persist changes.
class SaveLayoutEvent extends LayoutEvent {
  const SaveLayoutEvent();
}

/// Event to switch the active tab to a different layout.
class SwitchTabEvent extends LayoutEvent {
  final String tabId;

  const SwitchTabEvent({required this.tabId});

  @override
  List<Object?> get props => [tabId];
}

/// Event to create a new tab/layout with the specified ID and name.
class CreateTabEvent extends LayoutEvent {
  final String tabId;
  final String tabName;

  const CreateTabEvent({
    required this.tabId,
    required this.tabName,
  });

  @override
  List<Object?> get props => [tabId, tabName];
}

/// Event to delete a tab/layout from state and Firestore.
class DeleteTabEvent extends LayoutEvent {
  final String tabId;

  const DeleteTabEvent({required this.tabId});

  @override
  List<Object?> get props => [tabId];
}

/// Event to rename a tab/layout with a new name.
class RenameTabEvent extends LayoutEvent {
  final String tabId;
  final String newName;

  const RenameTabEvent({
    required this.tabId,
    required this.newName,
  });

  @override
  List<Object?> get props => [tabId, newName];
}
