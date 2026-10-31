import 'package:flutter/material.dart';
import 'package:unipal_api/unipal_api.dart';

import '../labels.dart';
import '../session.dart';
import '../widgets/async_view.dart';

/// The company task board as tabs (one per column) so it works on a phone; move a task from its menu.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool _mine = false;
  final _view = GlobalKey<AsyncViewState<List<Task>>>();

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final company = session.company!;
    final canManage = company.can('projects.manage');

    return DefaultTabController(
      length: taskStatuses.length,
      initialIndex: taskStatuses.indexOf('doing'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('مهامي فقط'),
                  selected: _mine,
                  onSelected: (v) {
                    setState(() => _mine = v);
                    _view.currentState?.reload();
                  },
                ),
              ],
            ),
          ),
          TabBar(isScrollable: true, tabs: [for (final s in taskStatuses) Tab(text: statusLabels[s])]),
          Expanded(
            child: AsyncView<List<Task>>(
              key: _view,
              load: () => session.guard((api) => api.tasks(company.slug, mine: _mine)),
              builder: (context, tasks, reload) => TabBarView(
                children: [
                  for (final status in taskStatuses)
                    _Column(
                      tasks: tasks.where((t) => t.status == status).toList(),
                      canManage: canManage,
                      onMove: (task, to) async {
                        try {
                          await session.guard((api) => api.moveTask(company.slug, task.id, to));
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(const SnackBar(content: Text('تعذّر نقل المهمة.')));
                          }
                        }
                        await reload();
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({required this.tasks, required this.canManage, required this.onMove});

  final List<Task> tasks;
  final bool canManage;
  final Future<void> Function(Task task, String status) onMove;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('لا مهام هنا.')),
          ),
        ],
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final t = tasks[i];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: ListTile(
            leading: Container(width: 4, height: 36, color: t.priority == 'high' ? scheme.error : scheme.secondary),
            title: Text(t.title),
            subtitle: Text(
              [
                t.projectName,
                t.assignee?.name,
                if (t.dueOn != null) formatDate(t.dueOn),
              ].whereType<String>().join(' · '),
            ),
            trailing: canManage
                ? PopupMenuButton<String>(
                    tooltip: 'نقل إلى',
                    icon: const Icon(Icons.swap_horiz),
                    onSelected: (to) => onMove(t, to),
                    itemBuilder: (_) => [
                      for (final s in taskStatuses)
                        if (s != t.status) PopupMenuItem(value: s, child: Text(statusLabels[s]!)),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }
}
