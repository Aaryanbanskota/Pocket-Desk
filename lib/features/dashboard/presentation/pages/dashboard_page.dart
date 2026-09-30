import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/services/app_update_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../providers/dashboard_layout_provider.dart';
import '../widgets/app_hamburger_drawer.dart';
import '../widgets/calendar_mini_widget.dart';
import '../widgets/notes_widget.dart';
import '../widgets/pinned_widgets.dart';
import '../widgets/quick_actions.dart';
import '../widgets/statistics_widget.dart';
import '../widgets/swipeable_weather_widget.dart';
import '../widgets/tasks_widget.dart';
import '../widgets/today_schedule_widget.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateService.checkForUpdates(context);
    });
  }

  Widget _buildWidgetByKey(String key) {
    switch (key) {
      case 'weather':
        return const SwipeableWeatherWidget();
      case 'quick_actions':
        return const QuickActions();
      case 'schedule':
        return const TodayScheduleWidget();
      case 'calendar':
        return const CalendarMiniWidget();
      case 'tasks':
        return const TasksWidget();
      case 'notes':
        return const NotesWidget();
      case 'statistics':
        return const StatisticsWidget();
      case 'pinned':
        return const PinnedWidgets();
      default:
        return const SizedBox();
    }
  }

  String _getWidgetTitle(String key) {
    switch (key) {
      case 'weather':
        return 'Weather & Storage Widget';
      case 'quick_actions':
        return 'Quick Actions Bar';
      case 'schedule':
        return 'Today Schedule';
      case 'calendar':
        return 'Mini Calendar';
      case 'tasks':
        return 'Tasks Card';
      case 'notes':
        return 'Notes Card';
      case 'statistics':
        return 'Statistics Card';
      case 'pinned':
        return 'Pinned Shortcuts';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authNotifierProvider).valueOrNull;
    final user = authState is AuthAuthenticated ? authState.user : null;

    final layoutState = ref.watch(dashboardLayoutProvider);
    final layoutNotifier = ref.read(dashboardLayoutProvider.notifier);

    return Scaffold(
      drawer: const AppHamburgerDrawer(),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PocketDesk',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
              ),
            ),
            Text(
              DateTimeUtils.toFullDate(DateTime.now()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              layoutState.isEditing ? Icons.check_circle_rounded : Icons.grid_view_rounded,
              color: layoutState.isEditing ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            tooltip: layoutState.isEditing ? 'Done Reordering' : 'Rearrange Dashboard Widgets',
            onPressed: () => layoutNotifier.toggleEditMode(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.settings),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildWelcomeHeader(theme, user?.displayName ?? user?.username ?? 'User'),
                  ),
                  if (layoutState.isEditing)
                    TextButton.icon(
                      onPressed: () => layoutNotifier.resetLayout(),
                      icon: const Icon(Icons.restart_alt_rounded, size: 18),
                      label: const Text('Reset'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              if (layoutState.isEditing)
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.touch_app_rounded, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Drag handles to reorder any widget anywhere. Tap switch to show or hide widgets.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (layoutState.isEditing)
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: layoutState.widgetOrder.length,
                  onReorder: (oldIndex, newIndex) => layoutNotifier.reorderWidgets(oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final key = layoutState.widgetOrder[index];
                    final isHidden = layoutState.hiddenWidgets.contains(key);

                    return Card(
                      key: ValueKey(key),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 0,
                      color: isHidden
                          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                          : colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            ReorderableDragStartListener(
                              index: index,
                              child: Icon(Icons.drag_indicator_rounded, color: colorScheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _getWidgetTitle(key),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isHidden ? Colors.grey : colorScheme.onSurface,
                                  decoration: isHidden ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            Switch(
                              value: !isHidden,
                              onChanged: (_) => layoutNotifier.toggleWidgetVisibility(key),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              else
                Column(
                  children: layoutState.widgetOrder
                      .where((key) => !layoutState.hiddenWidgets.contains(key))
                      .map((key) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                            child: _buildWidgetByKey(key),
                          ))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(ThemeData theme, String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, $name',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'Here is your productivity overview for today.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
