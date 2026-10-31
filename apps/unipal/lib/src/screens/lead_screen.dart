import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unipal_api/unipal_api.dart';
import 'package:url_launcher/url_launcher.dart';

import '../labels.dart';
import '../session.dart';
import '../widgets/async_view.dart';

class LeadScreen extends StatelessWidget {
  const LeadScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final company = session.company!;
    final canManage = company.can('crm.manage');

    return AsyncView<Lead>(
      load: () => session.guard((api) => api.lead(company.slug, id)),
      builder: (context, lead, reload) {
        final text = Theme.of(context).textTheme;
        final muted = Theme.of(context).colorScheme.onSurfaceVariant;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => context.go('/leads'),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('العملاء'),
              ),
            ),
            Text(lead.contactName, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            Text('${lead.reference} · ${stageLabels[lead.stage]}', style: text.bodyMedium?.copyWith(color: muted)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                if (lead.phone case final phone?)
                  ActionChip(
                    avatar: const Icon(Icons.call, size: 18),
                    label: Text(phone, textDirection: TextDirection.ltr),
                    onPressed: () => launchUrl(Uri(scheme: 'tel', path: phone)),
                  ),
                if (lead.email case final email?)
                  ActionChip(
                    avatar: const Icon(Icons.mail_outline, size: 18),
                    label: Text(email),
                    onPressed: () => launchUrl(Uri(scheme: 'mailto', path: email)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Fact('الشركة', lead.organizationName ?? '—'),
                    _Fact('المصدر', sourceLabels[lead.source] ?? lead.source),
                    _Fact('قيمة العرض', formatAed(lead.proposalValue)),
                    _Fact('الاحتمال', '${lead.probability}%'),
                    _Fact('المتابعة القادمة', formatDate(lead.nextFollowUpOn)),
                    _Fact('المسؤول', lead.owner?.name ?? '—'),
                    if (lead.message case final message?) ...[const SizedBox(height: 8), Text(message)],
                  ],
                ),
              ),
            ),
            if (canManage) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: lead.stage,
                decoration: const InputDecoration(labelText: 'المرحلة'),
                items: [
                  // Lost and paused need a reason; set those from the hub until the app has the form.
                  for (final s in leadStages.where((s) => s != 'lost' && s != 'paused' || s == lead.stage))
                    DropdownMenuItem(value: s, child: Text(stageLabels[s]!)),
                ],
                onChanged: (stage) async {
                  if (stage == null || stage == lead.stage) return;
                  await session.guard((api) => api.updateLead(company.slug, lead.id, {'stage': stage}));
                  await reload();
                },
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  if (await _logActivity(context, session, company.slug, lead.id)) await reload();
                },
                icon: const Icon(Icons.add_comment_outlined),
                label: const Text('تسجيل تواصل'),
              ),
            ],
            const SizedBox(height: 24),
            Text('سجل التواصل', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            if (lead.activities.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('لا يوجد تواصل مسجّل بعد.')),
            for (final a in lead.activities)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(activityLabels[a.type] ?? a.type),
                subtitle: Text([formatDate(a.occurredAt), a.user?.name, a.notes].whereType<String>().join(' · ')),
              ),
          ],
        );
      },
    );
  }

  static Future<bool> _logActivity(
    BuildContext context,
    SessionController session,
    String company,
    String leadId,
  ) async {
    var type = 'call';
    final notes = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('تسجيل تواصل'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: type,
                items: [for (final e in activityLabels.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: (v) => setState(() => type = v ?? type),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'ملاحظات'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
          ],
        ),
      ),
    );
    if (saved != true) return false;
    await session.guard(
      (api) =>
          api.addActivity(company, leadId, type: type, notes: notes.text.trim().isEmpty ? null : notes.text.trim()),
    );
    return true;
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
