import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task_model.dart';
import '../providers/tasks_notifier.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_sheet.dart';

class TasksDashboardView extends ConsumerStatefulWidget {
  const TasksDashboardView({super.key});

  @override
  ConsumerState<TasksDashboardView> createState() => _TasksDashboardViewState();
}

class _TasksDashboardViewState extends ConsumerState<TasksDashboardView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  bool _searching = false;
  List<TaskModel>? _searchResults;

  static const _tabs = [
    (label: 'To Do', status: TaskStatus.todo),
    (label: 'In Progress', status: TaskStatus.inProgress),
    (label: 'Done', status: TaskStatus.done),
    (label: 'Archived', status: TaskStatus.archived),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        ref
            .read(tasksProvider.notifier)
            .setFilter(_tabs[_tabCtrl.index].status);
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _doSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = null);
      return;
    }
    final notifier = ref.read(tasksProvider.notifier);
    final results = await notifier.searchTasks(query);
    setState(() => _searchResults = results);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search tasks…',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: cs.onSurfaceVariant),
                ),
                onChanged: _doSearch,
              )
            : Text(
                'Tasks',
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search_outlined),
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) {
                  _searchCtrl.clear();
                  _searchResults = null;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_outlined),
            onPressed: () => _showSortFilter(context),
          ),
        ],
        bottom: _searching
            ? null
            : TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: _tabs
                    .map((t) => Tab(text: t.label))
                    .toList(),
              ),
      ),
      body: _searching && _searchResults != null
          ? _buildTaskList(
              context, AsyncValue.data(
                TasksState(tasks: _searchResults!),
              ),
            )
          : tasksAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (state) => state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildTaskList(context, tasksAsync),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => TaskFormSheet.show(context),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, AsyncValue<TasksState> tasksAsync) {
    final tasks = tasksAsync.valueOrNull?.tasks ?? [];

    if (tasks.isEmpty) {
      return _EmptyState(
        onAdd: () => TaskFormSheet.show(context),
      );
    }

    // Group by folder if present
    final byFolder = <String, List<TaskModel>>{};
    for (final t in tasks) {
      final key = t.folderName?.isNotEmpty == true ? t.folderName! : '';
      byFolder.putIfAbsent(key, () => []).add(t);
    }

    if (byFolder.length == 1 && byFolder.containsKey('')) {
      return ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: tasks.length,
        itemBuilder: (_, i) => TaskCard(task: tasks[i]),
      );
    }

    // Grouped by folder
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      children: byFolder.entries.map((entry) {
        final folderName = entry.key.isEmpty ? 'Tasks' : entry.key;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Row(
                children: [
                  Icon(
                    entry.key.isEmpty
                        ? Icons.inbox_outlined
                        : Icons.folder_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    folderName,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${entry.value.length})',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            ...entry.value.map((t) => TaskCard(task: t)),
          ],
        );
      }).toList(),
    );
  }

  void _showSortFilter(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => const _SortFilterSheet(),
    );
  }
}

// ─── Sort/filter sheet ───────────────────────────────────────────────────────

class _SortFilterSheet extends StatelessWidget {
  const _SortFilterSheet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter & Sort',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Priority',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            Wrap(
              spacing: 8,
              children: TaskPriority.values.map((p) {
                return ActionChip(
                  label: Text(p.name),
                  onPressed: () => Navigator.pop(context),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text('Due',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            Wrap(
              spacing: 8,
              children: ['Today', 'This Week', 'Overdue', 'No Date'].map((l) {
                return ActionChip(
                  label: Text(l),
                  onPressed: () => Navigator.pop(context),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.task_alt_outlined,
            size: 72,
            color: cs.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks here',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: onAdd,
            child: const Text('Add your first task'),
          ),
        ],
      ),
    );
  }
}
