import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:unipal_api/unipal_api.dart';

void main() {
  test('login stores the token and sends it on later calls', () async {
    final seen = <http.Request>[];
    final api = UnipalApi(
      baseUrl: 'https://api.test/',
      httpClient: MockClient((request) async {
        seen.add(request);
        if (request.url.path == '/v1/auth/token') {
          return http.Response(
            jsonEncode({
              'token': 't0k',
              'user': {'id': 'u1', 'name': 'Nour', 'email': 'n@u.g'},
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'user': {'id': 'u1', 'name': 'Nour', 'email': 'n@u.g'},
            'companies': [
              {
                'id': 'c1',
                'slug': 'tax',
                'name': 'UniPal Tax',
                'name_ar': 'يونيبال للضرائب',
                'is_parent': false,
                'role': 'manager',
                'abilities': ['crm.view'],
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final login = await api.login('n@u.g', 'pw', deviceName: 'test');
    final me = await api.me();

    expect(login.token, 't0k');
    expect(seen.last.headers['Authorization'], 'Bearer t0k');
    expect(seen.last.url.toString(), 'https://api.test/v1/me');
    expect(me.companies.single.slug, 'tax');
    expect(me.companies.single.can('crm.view'), isTrue);
    expect(me.companies.single.can('crm.manage'), isFalse);
  });

  test('validation errors become an ApiException with field messages', () async {
    final api = UnipalApi(
      baseUrl: 'https://api.test',
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': 'Invalid',
            'errors': {
              'email': ['These credentials do not match our records.'],
            },
          }),
          422,
        ),
      ),
    );

    expect(
      () => api.login('x@y.z', 'bad', deviceName: 'test'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.status, 'status', 422)
            .having((e) => e.errors['email']?.single, 'email error', contains('credentials')),
      ),
    );
  });

  test('parses leads with decimal values sent as strings', () {
    final lead = Lead.fromJson({
      'id': 'l1',
      'reference': 'TAX-0001',
      'stage': 'proposal_sent',
      'source': 'website',
      'contact_name': 'Omar',
      'probability': 50,
      'proposal_value': '15000.00',
      'weighted_value': '7500.00',
      'next_follow_up_on': '2026-11-02',
    });

    expect(lead.proposalValue, 15000);
    expect(lead.weightedValue, 7500);
    expect(lead.nextFollowUpOn, DateTime(2026, 11, 2));
  });
}
