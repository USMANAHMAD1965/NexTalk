part of '../../main.dart';

class ChatApp extends StatefulWidget {
  const ChatApp({super.key, required this.repository, this.showSplash = true});

  final ChatRepository repository;
  final bool showSplash;

  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  AppUser? _currentUser;
  bool _checkingSession = true;
  late bool _showSplash;
  Timer? _splashTimer;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _showSplash = widget.showSplash;
    _restoreSession();
    if (_showSplash) {
      _splashTimer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) {
          setState(() => _showSplash = false);
        }
      });
    }
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
    _splashTimer?.cancel();
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
    if (_showSplash || _checkingSession) {
      return const SplashScreen();
    }

    if (_currentUser == null) {
      return LoginScreen(
        repository: widget.repository,
        onAuthenticated: _handleAuthenticated,
      );
    }

    return HomeShell(
      repository: widget.repository,
      currentUser: _currentUser!,
      onSignOut: _signOut,
    );
  }
}
