import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/layout_bloc.dart';
import '../bloc/layout_events.dart';
import '../bloc/layout_state.dart';

/// Tab control widget for displaying and managing layout tabs.
///
/// Displays a horizontal scrollable list of tabs with an inline add button.
/// Supports tab switching, renaming (via long press), and deletion (with
/// confirmation). All operations dispatch events to [LayoutBloc] for state
/// management and persistence.
class TabsControl extends StatelessWidget {
  const TabsControl({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LayoutBloc, LayoutState>(
      builder: (context, state) {
        final tabs = state.layouts.values.toList();
        final activeTabId = state.activeTabId;

        return Container(
          height: 48,
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            border: Border(
              bottom: BorderSide(
                color: Color(0xFF334155),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: tabs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == tabs.length) {
                      return _AddTabButton(
                        onTap: () {
                          final newTabId =
                              'tab${DateTime.now().millisecondsSinceEpoch}';
                          final newTabName = 'Tab ${tabs.length + 1}';

                          context.read<LayoutBloc>().add(
                                CreateTabEvent(
                                  tabId: newTabId,
                                  tabName: newTabName,
                                ),
                              );
                        },
                      );
                    }

                    final tab = tabs[index];
                    final isActive = tab.tabId == activeTabId;

                    return _TabItem(
                      tabId: tab.tabId,
                      tabName: tab.tabName,
                      isActive: isActive,
                      onTap: () {
                        context.read<LayoutBloc>().add(
                              SwitchTabEvent(tabId: tab.tabId),
                            );
                      },
                      onDelete: () {
                        _showDeleteConfirmation(context, tab.tabId, tab.tabName);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Shows a confirmation dialog before deleting a tab.
  void _showDeleteConfirmation(
      BuildContext context, String tabId, String tabName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Tab'),
        content: Text(
            'Are you sure you want to delete "$tabName"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<LayoutBloc>().add(
                    DeleteTabEvent(tabId: tabId),
                  );
              Navigator.of(dialogContext).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Individual tab item widget with rename and delete functionality.
///
/// Displays a tab with visual indication of active state. Supports tap to
/// switch, long press to rename, and delete via close button. Delete button
/// is wrapped in [GestureDetector] to prevent triggering parent tap events.
class _TabItem extends StatelessWidget {
  final String tabId;
  final String tabName;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TabItem({
    required this.tabId,
    required this.tabName,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: () {
        _showRenameDialog(context);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF0F172A)
              : const Color(0xFF334155),
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(
                  color: const Color(0xFF60A5FA),
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tabName,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: isActive ? Colors.white70 : Colors.white54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a dialog for renaming the tab.
  void _showRenameDialog(BuildContext context) {
    final textController = TextEditingController(text: tabName);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename Tab'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Tab Name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              context.read<LayoutBloc>().add(
                    RenameTabEvent(
                      tabId: tabId,
                      newName: value.trim(),
                    ),
                  );
              Navigator.of(dialogContext).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newName = textController.text.trim();
              if (newName.isNotEmpty) {
                context.read<LayoutBloc>().add(
                      RenameTabEvent(
                        tabId: tabId,
                        newName: newName,
                      ),
                    );
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}

/// Circular button for adding new tabs.
class _AddTabButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddTabButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
      child: Material(
        color: Colors.grey[300],
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: const Icon(
              Icons.add,
              color: Colors.black,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
