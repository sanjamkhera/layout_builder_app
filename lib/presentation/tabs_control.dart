import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/layout_bloc.dart';
import '../bloc/layout_events.dart';
import '../bloc/layout_state.dart';

/// TabsControl widget - Displays and manages tabs for layouts
/// 
/// BLoC COMPLIANCE:
/// - Uses BlocBuilder to read state (no direct state access)
/// - Dispatches events only (no direct database calls)
/// - All database operations go through BLoC → Repository → Firestore
class TabsControl extends StatelessWidget {
  const TabsControl({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LayoutBloc, LayoutState>(
      builder: (context, state) {
        // Get all tabs from state
        final tabs = state.layouts.values.toList();
        final activeTabId = state.activeTabId;

        return Container(
          height: 48,
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B), // Dark slate to match AppBar
            border: Border(
              bottom: BorderSide(
                color: Color(0xFF334155), // Slightly lighter border
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // List of tabs with "+" button inline
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: tabs.length + 1, // +1 for the add button
                  itemBuilder: (context, index) {
                    // Show add button as the first item (right after tabs)
                    if (index == tabs.length) {
                      return _AddTabButton(
                        onTap: () {
                          // Generate new tab ID
                          final newTabId = 'tab${DateTime.now().millisecondsSinceEpoch}';
                          final newTabName = 'Tab ${tabs.length + 1}';

                          // Dispatch CreateTabEvent - BLoC handles creation and save
                          context.read<LayoutBloc>().add(
                                CreateTabEvent(
                                  tabId: newTabId,
                                  tabName: newTabName,
                                ),
                              );
                        },
                      );
                    }

                    // Regular tab items
                    final tab = tabs[index];
                    final isActive = tab.tabId == activeTabId;

                    return _TabItem(
                      tabId: tab.tabId,
                      tabName: tab.tabName,
                      isActive: isActive,
                      onTap: () {
                        // Dispatch SwitchTabEvent - BLoC handles state update
                        context.read<LayoutBloc>().add(
                              SwitchTabEvent(tabId: tab.tabId),
                            );
                      },
                      onDelete: () {
                        // Show confirmation dialog before deleting
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

  /// Show confirmation dialog before deleting a tab
  void _showDeleteConfirmation(BuildContext context, String tabId, String tabName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Tab'),
        content: Text('Are you sure you want to delete "$tabName"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Dispatch DeleteTabEvent - BLoC handles deletion and save
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

/// Individual tab item widget
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
        // Show rename dialog on long press
        _showRenameDialog(context);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF0F172A) // Darker when active
              : const Color(0xFF334155), // Lighter when inactive
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(
                  color: const Color(0xFF60A5FA), // Blue border when active
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tab name
            Text(
              tabName,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            // Delete button - wrapped in GestureDetector to prevent parent tap
            GestureDetector(
              onTap: () {
                onDelete();
              },
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
              // Dispatch RenameTabEvent - BLoC handles rename and save
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
                // Dispatch RenameTabEvent - BLoC handles rename and save
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

/// Add new tab button
class _AddTabButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddTabButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
      child: Material(
        color: Colors.grey[300], // Subtle gray background
        shape: const CircleBorder(), // Round shape
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 40, // Fixed width for circular button
            height: 40, // Fixed height for circular button
            alignment: Alignment.center,
            child: const Icon(
              Icons.add,
              color: Colors.black, // Black + sign
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
