import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_builder_app/bloc/layout_bloc.dart';
import 'package:layout_builder_app/bloc/layout_events.dart';
import 'package:layout_builder_app/bloc/layout_state.dart';
import 'package:layout_builder_app/models/layout_model.dart';
import 'package:layout_builder_app/models/widget_model.dart';
import 'package:layout_builder_app/repository/layout_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'layout_bloc_test.mocks.dart';

@GenerateMocks([LayoutRepository])
void main() {
  late MockLayoutRepository mockRepository;

  setUp(() {
    mockRepository = MockLayoutRepository();
  });

  group('LayoutBloc', () {
    test('initial state should be LayoutState.initial()', () {
      final bloc = LayoutBloc(repository: mockRepository);
      expect(bloc.state, equals(LayoutState.initial()));
    });

    group('LoadLayoutsEvent', () {
      blocTest<LayoutBloc, LayoutState>(
        'emits loading state then loads layouts successfully',
        build: () {
          when(mockRepository.fetchLayouts()).thenAnswer(
            (_) async => {
              'tab1': LayoutModel(
                tabId: 'tab1',
                tabName: 'Tab 1',
                widgets: [],
              ),
            },
          );
          when(mockRepository.saveLayout(any)).thenAnswer((_) async => {});
          return LayoutBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(const LoadLayoutsEvent()),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          LayoutState(
            layouts: {},
            activeTabId: 'tab1',
            isLoading: true,
          ),
          LayoutState(
            layouts: {
              'tab1': LayoutModel(
                tabId: 'tab1',
                tabName: 'Tab 1',
                widgets: [],
              ),
            },
            activeTabId: 'tab1',
            isLoading: false,
          ),
        ],
      );

      blocTest<LayoutBloc, LayoutState>(
        'creates default tab when no layouts exist',
        build: () {
          when(mockRepository.fetchLayouts()).thenAnswer((_) async => {});
          when(mockRepository.saveLayout(any)).thenAnswer((_) async => {});
          return LayoutBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(const LoadLayoutsEvent()),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          LayoutState(
            layouts: {},
            activeTabId: 'tab1',
            isLoading: true,
          ),
          predicate<LayoutState>((state) {
            return state.layouts.isNotEmpty &&
                state.activeTabId.isNotEmpty &&
                !state.isLoading;
          }),
        ],
      );

      blocTest<LayoutBloc, LayoutState>(
        'emits error state when fetch fails',
        build: () {
          when(mockRepository.fetchLayouts()).thenThrow(
            Exception('Failed to fetch'),
          );
          return LayoutBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(const LoadLayoutsEvent()),
        expect: () => [
          LayoutState(
            layouts: {},
            activeTabId: 'tab1',
            isLoading: true,
          ),
          LayoutState(
            layouts: {},
            activeTabId: 'tab1',
            isLoading: false,
            error: 'Failed to load layouts: Exception: Failed to fetch',
          ),
        ],
      );
    });

    group('AddWidgetEvent', () {
      final initialLayout = LayoutModel(
        tabId: 'tab1',
        tabName: 'Tab 1',
        widgets: [],
      );

      blocTest<LayoutBloc, LayoutState>(
        'adds widget to active layout',
        build: () {
          when(mockRepository.saveLayout(any)).thenAnswer((_) async => {});
          final bloc = LayoutBloc(repository: mockRepository);
          bloc.emit(LayoutState(
            layouts: {'tab1': initialLayout},
            activeTabId: 'tab1',
          ));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const AddWidgetEvent(
            type: 'A',
            x: 100.0,
            y: 200.0,
          ),
        ),
        expect: () => [
          predicate<LayoutState>((state) {
            final layout = state.layouts['tab1'];
            return layout != null && layout.widgets.length == 1;
          }),
        ],
        verify: (_) {
          verify(mockRepository.saveLayout(any)).called(1);
        },
      );

      blocTest<LayoutBloc, LayoutState>(
        'creates layout if active layout does not exist',
        build: () {
          when(mockRepository.saveLayout(any)).thenAnswer((_) async => {});
          final bloc = LayoutBloc(repository: mockRepository);
          bloc.emit(LayoutState(
            layouts: {},
            activeTabId: 'tab1',
          ));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const AddWidgetEvent(
            type: 'B',
            x: 300.0,
            y: 400.0,
          ),
        ),
        expect: () => [
          predicate<LayoutState>((state) {
            final layout = state.layouts['tab1'];
            return layout != null &&
                layout.widgets.length == 1 &&
                layout.widgets[0].type == 'B';
          }),
        ],
      );
    });

    group('MoveWidgetEvent', () {
      final layoutWithWidget = LayoutModel(
        tabId: 'tab1',
        tabName: 'Tab 1',
        widgets: [
          const WidgetModel(
            id: 'widget1',
            type: 'A',
            x: 100.0,
            y: 200.0,
            width: 150.0,
            height: 150.0,
          ),
        ],
      );

      blocTest<LayoutBloc, LayoutState>(
        'moves widget to new position',
        build: () {
          when(mockRepository.saveLayout(any)).thenAnswer((_) async => {});
          final bloc = LayoutBloc(repository: mockRepository);
          bloc.emit(LayoutState(
            layouts: {'tab1': layoutWithWidget},
            activeTabId: 'tab1',
          ));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const MoveWidgetEvent(
            widgetId: 'widget1',
            newX: 300.0,
            newY: 400.0,
          ),
        ),
        expect: () => [
          predicate<LayoutState>((state) {
            final widget = state.layouts['tab1']?.widgets.firstWhere(
              (w) => w.id == 'widget1',
            );
            return widget != null &&
                widget.x == 300.0 &&
                widget.y == 400.0;
          }),
        ],
      );
    });

    group('ResizeWidgetEvent', () {
      final layoutWithWidget = LayoutModel(
        tabId: 'tab1',
        tabName: 'Tab 1',
        widgets: [
          const WidgetModel(
            id: 'widget1',
            type: 'A',
            x: 100.0,
            y: 200.0,
            width: 150.0,
            height: 150.0,
          ),
        ],
      );

      blocTest<LayoutBloc, LayoutState>(
        'resizes widget',
        build: () {
          when(mockRepository.saveLayout(any)).thenAnswer((_) async => {});
          final bloc = LayoutBloc(repository: mockRepository);
          bloc.emit(LayoutState(
            layouts: {'tab1': layoutWithWidget},
            activeTabId: 'tab1',
          ));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const ResizeWidgetEvent(
            widgetId: 'widget1',
            newWidth: 200.0,
            newHeight: 250.0,
          ),
        ),
        expect: () => [
          predicate<LayoutState>((state) {
            final widget = state.layouts['tab1']?.widgets.firstWhere(
              (w) => w.id == 'widget1',
            );
            return widget != null &&
                widget.width == 200.0 &&
                widget.height == 250.0;
          }),
        ],
      );
    });

    group('DeleteWidgetEvent', () {
      final layoutWithWidget = LayoutModel(
        tabId: 'tab1',
        tabName: 'Tab 1',
        widgets: [
          const WidgetModel(
            id: 'widget1',
            type: 'A',
            x: 100.0,
            y: 200.0,
            width: 150.0,
            height: 150.0,
          ),
          const WidgetModel(
            id: 'widget2',
            type: 'B',
            x: 300.0,
            y: 400.0,
            width: 200.0,
            height: 200.0,
          ),
        ],
      );

      blocTest<LayoutBloc, LayoutState>(
        'deletes widget from layout',
        build: () {
          when(mockRepository.saveLayout(any)).thenAnswer((_) async => {});
          final bloc = LayoutBloc(repository: mockRepository);
          bloc.emit(LayoutState(
            layouts: {'tab1': layoutWithWidget},
            activeTabId: 'tab1',
          ));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const DeleteWidgetEvent(widgetId: 'widget1'),
        ),
        expect: () => [
          predicate<LayoutState>((state) {
            final layout = state.layouts['tab1'];
            return layout != null &&
                layout.widgets.length == 1 &&
                layout.widgets[0].id == 'widget2';
          }),
        ],
      );
    });

    group('CreateTabEvent', () {
      blocTest<LayoutBloc, LayoutState>(
        'creates new tab and sets it as active',
        build: () {
          when(mockRepository.saveLayout(any)).thenAnswer((_) async => {});
          return LayoutBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(
          const CreateTabEvent(
            tabId: 'tab2',
            tabName: 'New Tab',
          ),
        ),
        expect: () => [
          predicate<LayoutState>((state) {
            return state.layouts.containsKey('tab2') &&
                state.activeTabId == 'tab2' &&
                state.layouts['tab2']!.tabName == 'New Tab';
          }),
        ],
      );
    });

    group('SwitchTabEvent', () {
      final layout1 = LayoutModel(
        tabId: 'tab1',
        tabName: 'Tab 1',
        widgets: [],
      );
      final layout2 = LayoutModel(
        tabId: 'tab2',
        tabName: 'Tab 2',
        widgets: [],
      );

      blocTest<LayoutBloc, LayoutState>(
        'switches to existing tab',
        build: () {
          final bloc = LayoutBloc(repository: mockRepository);
          bloc.emit(LayoutState(
            layouts: {
              'tab1': layout1,
              'tab2': layout2,
            },
            activeTabId: 'tab1',
          ));
          return bloc;
        },
        act: (bloc) => bloc.add(const SwitchTabEvent(tabId: 'tab2')),
        expect: () => [
          LayoutState(
            layouts: {
              'tab1': layout1,
              'tab2': layout2,
            },
            activeTabId: 'tab2',
          ),
        ],
      );

      blocTest<LayoutBloc, LayoutState>(
        'does not switch if tab does not exist',
        build: () {
          final bloc = LayoutBloc(repository: mockRepository);
          bloc.emit(LayoutState(
            layouts: {'tab1': layout1},
            activeTabId: 'tab1',
          ));
          return bloc;
        },
        act: (bloc) => bloc.add(const SwitchTabEvent(tabId: 'tab999')),
        expect: () => [],
      );
    });

    group('RenameTabEvent', () {
      final layout = LayoutModel(
        tabId: 'tab1',
        tabName: 'Old Name',
        widgets: [],
      );

      blocTest<LayoutBloc, LayoutState>(
        'renames tab',
        build: () {
          when(mockRepository.saveLayout(any)).thenAnswer((_) async => {});
          final bloc = LayoutBloc(repository: mockRepository);
          bloc.emit(LayoutState(
            layouts: {'tab1': layout},
            activeTabId: 'tab1',
          ));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const RenameTabEvent(
            tabId: 'tab1',
            newName: 'New Name',
          ),
        ),
        expect: () => [
          predicate<LayoutState>((state) {
            return state.layouts['tab1']?.tabName == 'New Name';
          }),
        ],
      );
    });

    group('DeleteTabEvent', () {
      final layout1 = LayoutModel(
        tabId: 'tab1',
        tabName: 'Tab 1',
        widgets: [],
      );
      final layout2 = LayoutModel(
        tabId: 'tab2',
        tabName: 'Tab 2',
        widgets: [],
      );

      blocTest<LayoutBloc, LayoutState>(
        'deletes tab and switches to another if deleting active tab',
        build: () {
          when(mockRepository.deleteTab(any)).thenAnswer((_) async => {});
          when(mockRepository.saveAllLayouts(any)).thenAnswer((_) async => {});
          final bloc = LayoutBloc(repository: mockRepository);
          bloc.emit(LayoutState(
            layouts: {
              'tab1': layout1,
              'tab2': layout2,
            },
            activeTabId: 'tab1',
          ));
          return bloc;
        },
        act: (bloc) => bloc.add(const DeleteTabEvent(tabId: 'tab1')),
        expect: () => [
          predicate<LayoutState>((state) {
            return !state.layouts.containsKey('tab1') &&
                state.layouts.containsKey('tab2') &&
                state.activeTabId == 'tab2';
          }),
        ],
      );

      blocTest<LayoutBloc, LayoutState>(
        'does not delete if it is the only tab',
        build: () {
          final bloc = LayoutBloc(repository: mockRepository);
          bloc.emit(LayoutState(
            layouts: {'tab1': layout1},
            activeTabId: 'tab1',
          ));
          return bloc;
        },
        act: (bloc) => bloc.add(const DeleteTabEvent(tabId: 'tab1')),
        expect: () => [],
      );
    });

    group('SaveLayoutEvent', () {
      final layout = LayoutModel(
        tabId: 'tab1',
        tabName: 'Tab 1',
        widgets: [],
      );

      blocTest<LayoutBloc, LayoutState>(
        'saves active layout to repository',
        build: () {
          when(mockRepository.saveLayout(any)).thenAnswer((_) async => {});
          final bloc = LayoutBloc(repository: mockRepository);
          bloc.emit(LayoutState(
            layouts: {'tab1': layout},
            activeTabId: 'tab1',
          ));
          return bloc;
        },
        act: (bloc) => bloc.add(const SaveLayoutEvent()),
        expect: () => [],
        verify: (_) {
          verify(mockRepository.saveLayout(any)).called(1);
        },
      );

      blocTest<LayoutBloc, LayoutState>(
        'does not save if no active layout',
        build: () {
          final bloc = LayoutBloc(repository: mockRepository);
          bloc.emit(LayoutState(
            layouts: {},
            activeTabId: 'tab1',
          ));
          return bloc;
        },
        act: (bloc) => bloc.add(const SaveLayoutEvent()),
        expect: () => [],
        verify: (_) {
          verifyNever(mockRepository.saveLayout(any));
        },
      );
    });
  });
}
