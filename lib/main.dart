import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_file/cross_file.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import 'firebase_options.dart';

part 'src/core/firebase_bootstrap.dart';
part 'src/core/theme.dart';
part 'src/app/chat_app.dart';
part 'src/models/models.dart';
part 'src/services/chat_repository.dart';
part 'src/core/utils.dart';
part 'src/demo/sample_data.dart';
part 'src/features/auth/auth_screens.dart';
part 'src/features/home/home_shell.dart';
part 'src/features/chat/chat_screens.dart';
part 'src/features/friends/friends_screens.dart';
part 'src/features/notifications/notifications_screens.dart';
part 'src/features/profile/profile_screens.dart';
part 'src/shared/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseEnabled = await FirebaseBootstrap.initialize();
  runApp(ChatApp(repository: ChatRepository(firebaseEnabled: firebaseEnabled)));
}
