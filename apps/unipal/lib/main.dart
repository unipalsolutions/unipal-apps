import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = SessionController();
  await session.restore();
  runApp(UnipalApp(session: session));
}
