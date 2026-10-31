import 'package:flutter/material.dart';
import 'package:unipal_api/unipal_api.dart';

import '../session.dart';
import '../widgets/mark.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await SessionScope.of(context).login(_email.text.trim(), _password.text);
    } on ApiException catch (e) {
      setState(
        () => _error = switch (e.status) {
          422 => 'البريد أو كلمة المرور غير صحيحة.',
          429 => 'محاولات كثيرة. انتظر دقيقة ثم حاول.',
          _ => 'تعذّر تسجيل الدخول. حاول مرة أخرى.',
        },
      );
    } catch (_) {
      setState(() => _error = 'تعذّر الاتصال بالخادم. تحقق من الإنترنت.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(alignment: AlignmentDirectional.centerStart, child: Mark(size: 48)),
                  const SizedBox(height: 24),
                  Text('يونيبال', style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'سجّل الدخول بحساب الشركة.',
                    style: text.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    textDirection: TextDirection.ltr,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(labelText: 'كلمة المرور'),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'جارٍ الدخول…' : 'دخول')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
