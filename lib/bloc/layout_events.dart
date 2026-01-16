import 'package:equatable/equatable.dart';
import '../models/widget_model.dart';

/// Base class for all layout events
abstract class LayoutEvent extends Equatable {
  const LayoutEvent();

  @override
  List<Object?> get props => [];
}

/// Event: Add a new widget to the canvas
class AddWidgetEvent extends LayoutEvent {
  final String type; // Widget type: "A", "B", "C", "D", etc.
  final double x; // X position on canvas
  final double y; // Y position on canvas

  const AddWidgetEvent({
    required this.type,
    required this.x,
    required this.y,
  });

  @override
  List<Object?> get props => [type, x, y];
}

/// Event: Move a widget on the canvas
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

/// Event: Resize a widget
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

/// Event: Delete a widget from canvas
class DeleteWidgetEvent extends LayoutEvent {
  final String widgetId;

  const DeleteWidgetEvent({required this.widgetId});

  @override
  List<Object?> get props => [widgetId];
}

/// Event: Load layouts from Firestore
class LoadLayoutsEvent extends LayoutEvent {
  const LoadLayoutsEvent();
}

/// Event: Save current layout to Firestore
class SaveLayoutEvent extends LayoutEvent {
  const SaveLayoutEvent();
}

/// Event: Switch to a different tab/layout
class SwitchTabEvent extends LayoutEvent {
  final String tabId;

  const SwitchTabEvent({required this.tabId});

  @override
  List<Object?> get props => [tabId];
}

/// Event: Create a new tab/layout
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
