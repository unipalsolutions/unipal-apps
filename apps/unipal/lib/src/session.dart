import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:unipal_api/unipal_api.dart';

import 'config.dart';

/// Signed-in state: the API token (kept in the platform keychain), the user, their companies,
/// and the company the app is showing. Screens read it through [SessionScope].
class SessionController extends ChangeNotifier {
  SessionController({UnipalApi? api, FlutterSecureStorage? storage})
    : api = api ?? UnipalApi(baseUrl: apiUrl),
      // The macOS build is not signed with a team yet, so it cannot use the data-protection keychain
      // (that needs the Keychain Sharing entitlement). The login keychain works without it.
      _storage = storage ?? const FlutterSecureStorage(mOptions: MacOsOptions(usesDataProtectionKeychain: false));

  static const _tokenKey = 'unipal.token';
  static const _companyKey = 'unipal.company';

  final UnipalApi api;
  final FlutterSecureStorage _storage;

  Me? _me;
  Company? _company;

  User? get user => _me?.user;
  List<Company> get companies => _me?.companies ?? const [];
  Company? get company => _company;
  bool get signedIn => _me != null;

  /// Picks up a saved token at startup. A token the API no longer accepts is discarded.
  Future<void> restore() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return;
    api.token = token;
    try {
      await _load(preferred: await _storage.read(key: _companyKey));
    } on ApiException catch (e) {
      if (e.isUnauthorized) await _clear();
    } catch (_) {
      // Offline at startup: keep the token and show the sign-in screen's retry.
    }
  }

  Future<void> login(String email, String password) async {
    final result = await api.login(email, password, deviceName: _deviceName());
    await _storage.write(key: _tokenKey, value: result.token);
    await _load();
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } catch (_) {
      // Signing out locally must work even when the API is unreachable.
    }
    await _clear();
  }

  Future<void> selectCompany(Company company) async {
    _company = company;
    await _storage.write(key: _companyKey, value: company.slug);
    notifyListeners();
  }

  /// Runs an API call and signs out if the token was revoked or expired.
  Future<T> guard<T>(Future<T> Function(UnipalApi api) call) async {
    try {
      return await call(api);
    } on ApiException catch (e) {
      if (e.isUnauthorized) await _clear();
      rethrow;
    }
  }

  Future<void> _load({String? preferred}) async {
    _me = await api.me();
    _company = companies.where((c) => c.slug == preferred).firstOrNull ?? companies.firstOrNull;
    notifyListeners();
  }

  Future<void> _clear() async {
    api.token = null;
    _me = null;
    _company = null;
    await _storage.delete(key: _tokenKey);
    notifyListeners();
  }

  static String _deviceName() {
    if (kIsWeb) return 'web';
    return 'unipal-${Platform.operatingSystem}';
  }
}

class SessionScope extends InheritedNotifier<SessionController> {
  const SessionScope({super.key, required SessionController session, required super.child}) : super(notifier: session);

  static SessionController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessionScope>()!.notifier!;
}
