import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unipal_api/unipal_api.dart';

import '../labels.dart';
import '../session.dart';
import '../widgets/async_view.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  String? _stage;
  final _view = GlobalKey<AsyncViewState<List<Lead>>>();

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final company = session.company!;
    if (!company.can('crm.view')) return const Center(child: Text('ليست لديك صلاحية على العملاء في هذه الشركة.'));

    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              for (final stage in [null, ...leadStages])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(stage == null ? 'الكل' : stageLabels[stage]!),
                    selected: _stage == stage,
                    onSelected: (_) {
                      setState(() => _stage = stage);
                      _view.currentState?.reload();
                    },
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: AsyncView<List<Lead>>(
            key: _view,
            load: () => session.guard((api) => api.leads(company.slug, stage: _stage)),
            builder: (context, leads, _) {
              if (leads.isEmpty) {
                return ListView(
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('لا يوجد عملاء محتملون هنا.')),
                    ),
                  ],
                );
              }
              final today = DateUtils.dateOnly(DateTime.now());
              return ListView.separated(
                itemCount: leads.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final l = leads[i];
                  final due = l.nextFollowUpOn != null && !l.nextFollowUpOn!.isAfter(today);
                  return ListTile(
                    onTap: () => context.go('/leads/${l.id}'),
                    title: Text(l.contactName),
                    subtitle: Text(
                      [
                        l.organizationName,
                        stageLabels[l.stage],
                        sourceLabels[l.source],
                      ].whereType<String>().join(' · '),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatAed(l.proposalValue), textDirection: TextDirection.ltr),
                        Text(
                          formatDate(l.nextFollowUpOn),
                          style: TextStyle(
                            color: due ? Theme.of(context).colorScheme.error : null,
                            fontWeight: due ? FontWeight.w600 : null,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
