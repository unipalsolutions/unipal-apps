import 'package:flutter/material.dart';
import 'package:unipal_api/unipal_api.dart';

import '../labels.dart';
import '../session.dart';
import '../widgets/async_view.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final company = session.company!;
    return AsyncView<({Pipeline? pipeline, List<Task> tasks})>(
      load: () => session.guard((api) async {
        final pipeline = company.can('crm.view') ? await api.pipeline(company.slug) : null;
        final tasks = company.can('projects.view') ? await api.tasks(company.slug, mine: true) : <Task>[];
        return (pipeline: pipeline, tasks: tasks);
      }),
      builder: (context, data, _) {
        final open = data.tasks.where((t) => t.status != 'done').toList()
          ..sort((a, b) => (a.dueOn ?? DateTime(9999)).compareTo(b.dueOn ?? DateTime(9999)));
        final text = Theme.of(context).textTheme;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('أهلاً ${session.user!.name}', style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            if (data.pipeline case final p?)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _Stat(label: 'عملاء محتملون مفتوحون', value: '${p.openLeads}'),
                  _Stat(label: 'التوقع المرجّح', value: formatAed(p.weightedForecast)),
                  _Stat(label: 'متابعات مستحقة', value: '${p.followUpsDue}'),
                ],
              ),
            const SizedBox(height: 24),
            Text('مهامي', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (open.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('لا مهام مفتوحة لك.')),
            for (final t in open)
              Card(
                child: ListTile(
                  title: Text(t.title),
                  subtitle: Text([t.projectName, statusLabels[t.status]].whereType<String>().join(' · ')),
                  trailing: Text(formatDate(t.dueOn)),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 6),
              Text(
                value,
                textDirection: TextDirection.ltr,
                style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
