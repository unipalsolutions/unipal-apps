import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:unipal/src/app.dart';
import 'package:unipal/src/session.dart';
import 'package:unipal_api/unipal_api.dart';

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

/// A fake API: one manager of UniPal Tax with one lead and one task.
MockClient _fakeApi() => MockClient((request) async {
  final path = request.url.path;
  if (path == '/v1/auth/token') {
    final body = jsonDecode(request.body) as Map;
    if (body['password'] != 'right') {
      return _json({
        'message': 'Invalid',
        'errors': {
          'email': ['wrong'],
        },
      }, 422);
    }
    return _json({
      'token': 't',
      'user': {'id': 'u1', 'name': 'سارة', 'email': 'sara@unipal.group'},
    });
  }
  if (path == '/v1/me') {
    return _json({
      'user': {'id': 'u1', 'name': 'سارة', 'email': 'sara@unipal.group'},
      'companies': [
        {
          'id': 'c',
          'slug': 'tax',
          'name': 'UniPal Tax',
          'name_ar': 'يونيبال للضرائب',
          'is_parent': false,
          'role': 'manager',
          'abilities': ['crm.view', 'crm.manage', 'projects.view', 'projects.manage'],
        },
      ],
    });
  }
  if (path.endsWith('/pipeline')) {
    return _json({'currency': 'AED', 'stages': [], 'open_leads': 3, 'weighted_forecast': 7500, 'follow_ups_due': 1});
  }
  if (path.endsWith('/tasks')) {
    return _json({
      'data': [
        {
          'id': 't1',
          'title': 'إقرار القيمة المضافة',
          'status': 'doing',
          'priority': 'high',
          'project': {'id': 'p', 'name': 'إقرارات VAT'},
          'due_on': '2026-11-28',
        },
      ],
    });
  }
  return _json({'message': 'Not found'}, 404);
});

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('signs in, then shows the dashboard for the user\'s company', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final session = SessionController(
      api: UnipalApi(baseUrl: 'https://api.test', httpClient: _fakeApi()),
    );
    await tester.pumpWidget(UnipalApp(session: session));
    await tester.pumpAndSettle();

    expect(find.text('سجّل الدخول بحساب الشركة.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'sara@unipal.group');
    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();
    expect(find.text('البريد أو كلمة المرور غير صحيحة.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), 'right');
    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();

    expect(find.text('أهلاً سارة'), findsOneWidget);
    expect(find.text('يونيبال للضرائب'), findsOneWidget);
    expect(find.text('AED 7,500'), findsOneWidget);
    expect(find.text('إقرار القيمة المضافة'), findsOneWidget);
    expect(session.company?.slug, 'tax');
  });
}
