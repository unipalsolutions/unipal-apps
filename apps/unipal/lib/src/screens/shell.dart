import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../session.dart';
import '../widgets/mark.dart';

const _destinations = [
  (path: '/', label: 'الرئيسية', icon: Icons.space_dashboard_outlined),
  (path: '/tasks', label: 'المهام', icon: Icons.view_kanban_outlined),
  (path: '/leads', label: 'العملاء', icon: Icons.people_alt_outlined),
];

/// Navigation that adapts to the screen: a bottom bar on phones, a side rail on tablets and desktop.
class Shell extends StatelessWidget {
  const Shell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  int get _index {
    final i = _destinations.lastIndexWhere((d) => d.path == '/' ? location == '/' : location.startsWith(d.path));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 840;
    void go(int i) => context.go(_destinations[i].path);

    final appBar = AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!wide) ...[const Mark(size: 28), const SizedBox(width: 10)],
          if (session.companies.length > 1)
            DropdownButtonHideUnderline(
              child: DropdownButton(
                value: session.company?.slug,
                items: [for (final c in session.companies) DropdownMenuItem(value: c.slug, child: Text(c.nameAr))],
                onChanged: (slug) => session.selectCompany(session.companies.firstWhere((c) => c.slug == slug)),
              ),
            )
          else
            Text(session.company?.nameAr ?? ''),
        ],
      ),
      actions: [
        PopupMenuButton<void>(
          tooltip: session.user?.name,
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
            child: Text((session.user?.name ?? '?').characters.first),
          ),
          itemBuilder: (_) => [
            PopupMenuItem(enabled: false, child: Text(session.user?.email ?? '')),
            PopupMenuItem(onTap: session.logout, child: const Text('تسجيل الخروج')),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );

    // Each company gets its own subtree so screens reload when the company changes.
    final body = KeyedSubtree(key: ValueKey(session.company?.slug), child: child);

    if (!wide) {
      return Scaffold(
        appBar: appBar,
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: go,
          destinations: [for (final d in _destinations) NavigationDestination(icon: Icon(d.icon), label: d.label)],
        ),
      );
    }
    return Scaffold(
      appBar: appBar,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: go,
            labelType: NavigationRailLabelType.all,
            leading: const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Mark(size: 36)),
            destinations: [
              for (final d in _destinations) NavigationRailDestination(icon: Icon(d.icon), label: Text(d.label)),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}
