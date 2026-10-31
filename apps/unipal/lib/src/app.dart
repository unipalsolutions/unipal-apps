import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:unipal_brand/unipal_brand.dart';

import 'screens/dashboard_screen.dart';
import 'screens/lead_screen.dart';
import 'screens/leads_screen.dart';
import 'screens/login_screen.dart';
import 'screens/shell.dart';
import 'screens/tasks_screen.dart';
import 'session.dart';

class UnipalApp extends StatefulWidget {
  const UnipalApp({super.key, required this.session});

  final SessionController session;

  @override
  State<UnipalApp> createState() => _UnipalAppState();
}

class _UnipalAppState extends State<UnipalApp> {
  late final GoRouter _router = GoRouter(
    refreshListenable: widget.session,
    redirect: (context, state) {
      final atLogin = state.matchedLocation == '/login';
      if (!widget.session.signedIn) return atLogin ? null : '/login';
      return atLogin ? '/' : null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      ShellRoute(
        builder: (_, state, child) => Shell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
          GoRoute(path: '/tasks', builder: (_, _) => const TasksScreen()),
          GoRoute(
            path: '/leads',
            builder: (_, _) => const LeadsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => LeadScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      session: widget.session,
      child: ListenableBuilder(
        listenable: widget.session,
        builder: (context, _) {
          // The selected company decides the accent, exactly like data-brand on the web.
          final brand = UnipalBrand.values.asNameMap()[widget.session.company?.slug] ?? UnipalBrand.group;
          return MaterialApp.router(
            title: 'UniPal',
            debugShowCheckedModeBanner: false,
            theme: UnipalTheme.light(brand),
            darkTheme: UnipalTheme.dark(brand),
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
