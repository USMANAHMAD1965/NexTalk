import 'package:flutter/material.dart';

import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseEnabled = await FirebaseBootstrap.initialize();
  runApp(ChatApp(repository: ChatRepository(firebaseEnabled: firebaseEnabled)));
}
