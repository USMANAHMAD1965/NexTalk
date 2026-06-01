part of '../app.dart';

class ChatApp extends StatefulWidget {
  const ChatApp({super.key, required this.repository});

  final ChatRepository repository;

  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  AppUser? _currentUser;
  bool _checkingSession = true;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _restoreSession();
    if (widget.repository.firebaseEnabled) {
      _foregroundMessageSub = FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        final title = notification?.title ?? 'New notification';
        final body = notification?.body ?? 'Open NexTalk for details.';
        _messengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('$title\n$body'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  Future<void> _restoreSession() async {
    final user = await widget.repository.currentUser();
    if (user != null) {
      await widget.repository.cleanupExpiredCallRequests();
      unawaited(widget.repository.registerNotificationToken(user.id));
    }
    if (!mounted) return;
    setState(() {
      _currentUser = user;
      _checkingSession = false;
    });
  }

  void _handleAuthenticated(AppUser user) {
    unawaited(widget.repository.registerNotificationToken(user.id));
    setState(() => _currentUser = user);
  }

  Future<void> _signOut() async {
    await widget.repository.signOut();
    if (!mounted) return;
    setState(() => _currentUser = null);
  }

  @override
  void dispose() {
    _foregroundMessageSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NexTalk',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      theme: buildTheme(),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: _buildHome(),
      ),
    );
  }

  Widget _buildHome() {
    if (_checkingSession) {
      return const SplashScreen();
    }

    if (_currentUser == null) {
      return SignInScreen(
        repository: widget.repository,
        onAuthenticated: _handleAuthenticated,
      );
    }

    return Stack(
      children: [
        ChatListScreen(
          repository: widget.repository,
          currentUser: _currentUser!,
          onSignOut: _signOut,
        ),
        StreamBuilder<List<CallRequest>>(
          stream: widget.repository.watchIncomingCallRequests(_currentUser!.id),
          initialData: const <CallRequest>[],
          builder: (context, snapshot) {
            final calls = snapshot.data ?? <CallRequest>[];
            if (calls.isEmpty) return const SizedBox.shrink();
            final request = calls.first;
            final caller = AppUser(
              id: request.callerId,
              displayName: request.callerName,
              email: request.callerEmail,
              initial: request.callerInitial,
              online: request.callerOnline,
              phoneNumber: request.callerPhoneNumber,
            );
            return IncomingCallOverlay(
              request: request,
              caller: caller,
              onAccept: () async {
                final navigator = Navigator.of(context);
                await widget.repository.acceptCallRequest(request.callId);
                if (!mounted) return;
                navigator.push(
                  MaterialPageRoute<void>(
                    builder: (_) => request.type == 'video'
                        ? VideoCallScreen(
                            repository: widget.repository,
                            currentUser: _currentUser!,
                            peer: caller,
                            callId: request.callId,
                          )
                        : VoiceCallScreen(
                            repository: widget.repository,
                            currentUser: _currentUser!,
                            peer: caller,
                            callId: request.callId,
                          ),
                  ),
                );
              },
              onDecline: () async {
                await widget.repository.rejectCallRequest(request.callId);
              },
            );
          },
        ),
      ],
    );
  }
}
