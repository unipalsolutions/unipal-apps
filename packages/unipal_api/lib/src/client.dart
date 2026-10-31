import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

/// An error response from the API. [errors] holds Laravel validation messages per field.
class ApiException implements Exception {
  ApiException(this.status, this.message, [this.errors = const {}]);

  final int status;
  final String message;
  final Map<String, List<String>> errors;

  bool get isUnauthorized => status == 401;

  @override
  String toString() => 'ApiException($status): $message';
}

/// Client for `/v1`. Company-scoped calls take the company slug, like the API's URLs.
class UnipalApi {
  UnipalApi({required String baseUrl, this.token, http.Client? httpClient})
    : _base = baseUrl.replaceAll(RegExp(r'/+$'), ''),
      _http = httpClient ?? http.Client();

  final String _base;
  final http.Client _http;

  /// Sanctum token from [login]. Store it in secure storage, never in plain preferences.
  String? token;

  // ---- auth ----------------------------------------------------------------

  Future<({String token, User user})> login(String email, String password, {required String deviceName}) async {
    final json = await _send('POST', '/auth/token', {'email': email, 'password': password, 'device_name': deviceName});
    token = json['token'] as String;
    return (token: token!, user: User.fromJson(json['user'] as Map<String, dynamic>));
  }

  Future<Me> me() async => Me.fromJson(await _send('GET', '/me'));

  Future<void> logout() async {
    await _send('POST', '/auth/logout');
    token = null;
  }

  // ---- CRM -----------------------------------------------------------------

  Future<Pipeline> pipeline(String company) async =>
      Pipeline.fromJson(await _send('GET', '/companies/$company/pipeline'));

  Future<List<Lead>> leads(String company, {String? stage, String? search}) async {
    final query = Uri(queryParameters: {'stage': ?stage, 'search': ?search}).query;
    final json = await _send('GET', '/companies/$company/leads${query.isEmpty ? '' : '?$query'}');
    return [for (final l in json['data'] as List) Lead.fromJson(l as Map<String, dynamic>)];
  }

  Future<Lead> lead(String company, String id) async =>
      Lead.fromJson((await _send('GET', '/companies/$company/leads/$id'))['data'] as Map<String, dynamic>);

  Future<Lead> updateLead(String company, String id, Map<String, Object?> changes) async =>
      Lead.fromJson((await _send('PATCH', '/companies/$company/leads/$id', changes))['data'] as Map<String, dynamic>);

  Future<void> addActivity(String company, String leadId, {required String type, String? outcome, String? notes}) =>
      _send('POST', '/companies/$company/leads/$leadId/activities', {
        'type': type,
        'outcome': ?outcome,
        'notes': ?notes,
      });

  // ---- projects --------------------------------------------------------------

  Future<List<Task>> tasks(String company, {bool mine = false}) async {
    final json = await _send('GET', '/companies/$company/tasks${mine ? '?mine=1' : ''}');
    return [for (final t in json['data'] as List) Task.fromJson(t as Map<String, dynamic>)];
  }

  Future<void> moveTask(String company, String id, String status) =>
      _send('PATCH', '/companies/$company/tasks/$id', {'status': status});

  // ---- transport ---------------------------------------------------------------

  Future<Map<String, dynamic>> _send(String method, String path, [Map<String, Object?>? body]) async {
    final request = http.Request(method, Uri.parse('$_base/v1$path'))
      ..headers['Accept'] = 'application/json'
      ..headers.addAll({if (token != null) 'Authorization': 'Bearer $token'});
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final response = await http.Response.fromStream(await _http.send(request));
    final json = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 400) {
      final map = json is Map<String, dynamic> ? json : <String, dynamic>{};
      throw ApiException(response.statusCode, map['message'] as String? ?? response.reasonPhrase ?? 'Request failed', {
        for (final e in ((map['errors'] as Map?) ?? const {}).entries)
          e.key as String: [for (final m in e.value as List) m as String],
      });
    }
    return json is Map<String, dynamic> ? json : {'data': json};
  }
}
