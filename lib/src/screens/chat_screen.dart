part of '../app.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.repository,
    required this.currentUser,
    required this.conversation,
  });

  final ChatRepository repository;
  final AppUser currentUser;
  final Conversation conversation;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _chatSearchController = TextEditingController();
  final _scrollController = ScrollController();
  final _recorder = AudioRecorder();
  final List<ChatMessage> _localMessages = <ChatMessage>[];
  StreamSubscription<Amplitude>? _amplitudeSub;
  Timer? _recordTimer;
  bool _sending = false;
  bool _isRecording = false;
  bool _isUploadingVoice = false;
  bool _searching = false;
  bool _showAttachments = false;
  PresenceState _presence = PresenceState.online;
  ChatMessage? _replyingTo;
  Duration _recordDuration = Duration.zero;
  List<double> _recordingLevels = List<double>.filled(22, 0.18);

  @override
  void dispose() {
    _messageController.dispose();
    _chatSearchController.dispose();
    _scrollController.dispose();
    _amplitudeSub?.cancel();
    _recordTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    _messageController.clear();

    setState(() {
      _sending = true;
      _presence = PresenceState.online;
      if (!widget.repository.firebaseEnabled) {
        _localMessages.add(
          ChatMessage(
            id: 'local-${DateTime.now().microsecondsSinceEpoch}',
            senderId: widget.currentUser.id,
            text: text,
            createdAt: DateTime.now(),
            status: MessageStatus.sending,
            replyToSender: _replyingTo == null
                ? null
                : (_replyingTo!.senderId == widget.currentUser.id
                      ? 'You'
                      : widget.conversation.peer.displayName),
            replyToText: _replyingTo?.text.isNotEmpty == true
                ? _replyingTo!.text
                : _replyingTo?.mediaTitle,
          ),
        );
      }
      _replyingTo = null;
      _showAttachments = false;
    });

    try {
      await widget.repository.sendMessage(
        conversation: widget.conversation,
        sender: widget.currentUser,
        text: text,
      );
    } on Object catch (error) {
      if (!mounted) return;
      showAppSnack(context, friendlyFirebaseError(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _startVoiceRecording() async {
    if (_isRecording || _isUploadingVoice) return;

    final allowed = await _recorder.hasPermission();
    if (!allowed) {
      if (!mounted) return;
      showAppSnack(context, 'Microphone permission is required.');
      return;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = kIsWeb
        ? 'voice_$timestamp.m4a'
        : '${(await getTemporaryDirectory()).path}/voice_$timestamp.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 44100,
        numChannels: 1,
        echoCancel: true,
        noiseSuppress: true,
      ),
      path: path,
    );

    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 120))
        .listen((amplitude) {
          final normalized = ((amplitude.current + 60) / 60).clamp(0.08, 1.0);
          if (!mounted) return;
          setState(() {
            _recordingLevels = [
              ..._recordingLevels.skip(1),
              normalized.toDouble(),
            ];
          });
        });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _recordDuration += const Duration(seconds: 1));
    });

    setState(() {
      _isRecording = true;
      _presence = PresenceState.recording;
      _recordDuration = Duration.zero;
      _recordingLevels = List<double>.filled(22, 0.18);
    });
  }

  Future<void> _stopVoiceRecording({required bool send}) async {
    if (!_isRecording) return;

    final duration = _recordDuration;
    final path = await _recorder.stop();
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    _recordTimer?.cancel();
    _recordTimer = null;

    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _presence = PresenceState.online;
      _recordDuration = Duration.zero;
    });

    if (!send || path == null) return;
    if (duration.inMilliseconds < 700) {
      showAppSnack(context, 'Hold a little longer to record a voice message.');
      return;
    }

    if (!widget.repository.firebaseEnabled) {
      setState(() {
        _localMessages.add(
          ChatMessage(
            id: 'local-voice-${DateTime.now().microsecondsSinceEpoch}',
            senderId: widget.currentUser.id,
            text: '',
            type: MessageType.voice,
            audioUrl: path,
            audioDuration: duration,
            createdAt: DateTime.now(),
            status: MessageStatus.sending,
          ),
        );
      });
      return;
    }

    setState(() => _isUploadingVoice = true);
    try {
      await widget.repository.sendVoiceMessage(
        conversation: widget.conversation,
        sender: widget.currentUser,
        localAudioPath: path,
        duration: duration,
      );
    } on Object catch (error) {
      if (!mounted) return;
      showAppSnack(context, friendlyFirebaseError(error));
    } finally {
      if (mounted) setState(() => _isUploadingVoice = false);
    }
  }

  Future<void> _openVoiceCall() async {
    final callId = widget.conversation.id;
    try {
      await widget.repository.createCallRequest(
        callId: callId,
        caller: widget.currentUser,
        callee: widget.conversation.peer,
        type: 'voice',
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VoiceCallScreen(
            repository: widget.repository,
            currentUser: widget.currentUser,
            peer: widget.conversation.peer,
            callId: callId,
          ),
        ),
      );
    } on Object catch (error) {
      showAppSnack(context, friendlyFirebaseError(error));
    }
  }

  Future<void> _openVideoCall() async {
    final callId = '${widget.conversation.id}-video';
    try {
      await widget.repository.createCallRequest(
        callId: callId,
        caller: widget.currentUser,
        callee: widget.conversation.peer,
        type: 'video',
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VideoCallScreen(
            repository: widget.repository,
            currentUser: widget.currentUser,
            peer: widget.conversation.peer,
            callId: callId,
          ),
        ),
      );
    } on Object catch (error) {
      showAppSnack(context, friendlyFirebaseError(error));
    }
  }

  void _addLocalRichMessage(MessageType type) {
    final now = DateTime.now();
    final message = switch (type) {
      MessageType.image => ChatMessage(
        id: 'local-image-${now.microsecondsSinceEpoch}',
        senderId: widget.currentUser.id,
        text: '',
        type: MessageType.image,
        mediaTitle: 'Camera image',
        caption: 'Compressed image with caption preview',
        createdAt: now,
        status: MessageStatus.sending,
      ),
      MessageType.video => ChatMessage(
        id: 'local-video-${now.microsecondsSinceEpoch}',
        senderId: widget.currentUser.id,
        text: '',
        type: MessageType.video,
        mediaTitle: 'Shared video',
        caption: 'Video attachment sent.',
        createdAt: now,
        status: MessageStatus.sending,
      ),
      MessageType.document => ChatMessage(
        id: 'local-doc-${now.microsecondsSinceEpoch}',
        senderId: widget.currentUser.id,
        text: 'Document.pdf',
        type: MessageType.document,
        mediaTitle: 'Document.pdf',
        caption: 'Document attachment sent.',
        createdAt: now,
        status: MessageStatus.sending,
      ),
      MessageType.location => ChatMessage(
        id: 'local-location-${now.microsecondsSinceEpoch}',
        senderId: widget.currentUser.id,
        text: '',
        type: MessageType.location,
        mediaTitle: 'Current location',
        caption: 'Live location active for 1 hour',
        createdAt: now,
        status: MessageStatus.sending,
      ),
      MessageType.contact => ChatMessage(
        id: 'local-contact-${now.microsecondsSinceEpoch}',
        senderId: widget.currentUser.id,
        text: '',
        type: MessageType.contact,
        mediaTitle: 'Dear Programmer',
        caption: '+92 300 1234567',
        createdAt: now,
        status: MessageStatus.sending,
      ),
      MessageType.poll => ChatMessage(
        id: 'local-poll-${now.microsecondsSinceEpoch}',
        senderId: widget.currentUser.id,
        text: 'Pick the next rollout priority',
        type: MessageType.poll,
        pollOptions: const [
          PollOption(label: 'Push notifications', votes: 5),
          PollOption(label: 'Group permissions', votes: 3),
          PollOption(label: 'View-once media', votes: 2),
        ],
        createdAt: now,
        status: MessageStatus.sending,
      ),
      _ => ChatMessage(
        id: 'local-media-${now.microsecondsSinceEpoch}',
        senderId: widget.currentUser.id,
        text: 'Shared media',
        type: type,
        createdAt: now,
        status: MessageStatus.sending,
      ),
    };

    setState(() {
      _localMessages.add(message);
      _showAttachments = false;
    });
    widget.repository
        .sendRichMessage(
          conversation: widget.conversation,
          sender: widget.currentUser,
          message: message,
        )
        .catchError((Object error) {
          if (mounted) showAppSnack(context, friendlyFirebaseError(error));
        });
  }

  void _openChatMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            children: [
              _SheetAction(Icons.person_outline_rounded, 'View contact', () {
                Navigator.pop(context);
                _showContactSheet();
              }),
              _SheetAction(Icons.search_rounded, 'Search', () {
                Navigator.pop(context);
                setState(() => _searching = true);
              }),
              _SheetAction(Icons.perm_media_outlined, 'Media, links, docs', () {
                Navigator.pop(context);
                showAppSnack(
                  context,
                  'Media library is ready for backend wiring.',
                );
              }),
              _SheetAction(
                Icons.notifications_off_outlined,
                'Mute notifications',
                () {
                  Navigator.pop(context);
                  showAppSnack(context, 'Notifications muted.');
                },
              ),
              _SheetAction(Icons.wallpaper_rounded, 'Wallpaper', () {
                Navigator.pop(context);
                showAppSnack(
                  context,
                  'Wallpaper controls can connect to user settings.',
                );
              }),
              _SheetAction(Icons.delete_sweep_outlined, 'Clear chat', () {
                Navigator.pop(context);
                showAppSnack(
                  context,
                  'Clear chat action requires confirmation in production.',
                );
              }, destructive: true),
            ],
          ),
        );
      },
    );
  }

  void _showContactSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AvatarCircle(
                user: widget.conversation.peer,
                size: 72,
                fontSize: 26,
              ),
              const SizedBox(height: 12),
              Text(
                widget.conversation.peer.displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.conversation.peer.email,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              const InfoPanel(
                children: [
                  InfoRow(
                    icon: Icons.lock_outline_rounded,
                    label: 'Encryption',
                    value: 'End-to-end encryption ready',
                  ),
                  Divider(height: 22),
                  InfoRow(
                    icon: Icons.timer_outlined,
                    label: 'Privacy',
                    value: 'Disappearing and view-once flags supported',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageActions(ChatMessage message, bool isMe) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final emoji in const [
                      '❤️',
                      '👍',
                      '😂',
                      '😮',
                      '😢',
                      '🙏',
                    ])
                      ActionChip(
                        label: Text(emoji),
                        onPressed: () {
                          Navigator.pop(context);
                          _react(message, emoji);
                        },
                      ),
                  ],
                ),
              ),
              _SheetAction(Icons.reply_rounded, 'Reply', () {
                Navigator.pop(context);
                setState(() => _replyingTo = message);
              }),
              _SheetAction(Icons.copy_rounded, 'Copy', () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.text));
                showAppSnack(context, 'Message copied.');
              }),
              _SheetAction(Icons.star_border_rounded, 'Star message', () {
                Navigator.pop(context);
                showAppSnack(context, 'Message starred.');
              }),
              _SheetAction(Icons.delete_outline_rounded, 'Delete', () {
                Navigator.pop(context);
                showAppSnack(context, 'Delete option triggered.');
              }, destructive: true),
            ],
          ),
        );
      },
    );
  }

  void _react(ChatMessage message, String emoji) {
    widget.repository
        .reactToMessage(
          conversationId: widget.conversation.id,
          messageId: message.id,
          emoji: emoji,
        )
        .catchError((Object error) {
          if (!mounted) return;
          showAppSnack(context, friendlyFirebaseError(error));
        });
  }

  List<ChatMessage> _filterMessages(List<ChatMessage> items) {
    final query = _chatSearchController.text.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items
        .where((item) => item.text.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.conversation.peer.displayName.trim().isNotEmpty
        ? widget.conversation.peer.displayName.trim()[0].toUpperCase()
        : 'C';

    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD), // WhatsApp Background Color
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: InkWell(
          onTap: _showContactSheet,
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF25D366),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (widget.conversation.peer.online)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF075E54),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.conversation.peer.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _presence == PresenceState.recording
                          ? 'recording audio...'
                          : widget.conversation.peer.online
                          ? 'online'
                          : 'last seen recently',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Colors.white),
            onPressed: _openVideoCall,
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined, color: Colors.white),
            onPressed: _openVoiceCall,
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => setState(() => _searching = !_searching),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: _openChatMenu,
          ),
        ],
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF075E54),
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_searching)
              SearchResultBar(
                query: _chatSearchController.text,
                controller: _chatSearchController,
                onChanged: (_) => setState(() {}),
                onClose: () => setState(() {
                  _searching = false;
                  _chatSearchController.clear();
                }),
              ),
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: widget.repository.watchMessages(widget.conversation.id),
                builder: (context, snapshot) {
                  final dbMessages = snapshot.data ?? const <ChatMessage>[];
                  final allMessages = <ChatMessage>[
                    ...dbMessages,
                    ..._localMessages.where(
                      (local) => !dbMessages.any((db) => db.id == local.id),
                    ),
                  ];
                  final filtered = _filterMessages(allMessages);

                  // Keep list auto scrolled to bottom
                  Timer(const Duration(milliseconds: 100), () {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final message = filtered[index];
                      final isMe = message.senderId == widget.currentUser.id;
                      return GestureDetector(
                        onLongPress: () => _showMessageActions(message, isMe),
                        child: Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: MessageBubble(message: message, isMe: isMe),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (_replyingTo != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ReplyComposerPreview(
                  message: _replyingTo!,
                  peerName: widget.conversation.peer.displayName,
                  currentUserId: widget.currentUser.id,
                  onClose: () => setState(() => _replyingTo = null),
                ),
              ),
            if (_showAttachments)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AttachmentPanel(onPick: _addLocalRichMessage),
              ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: const Color(0xFFF0F0F0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.emoji_emotions_outlined,
                      color: Color(0xFF888888),
                    ),
                    onPressed: () {
                      showAppSnack(
                        context,
                        'Emoji Keyboard is ready for native binding.',
                      );
                    },
                  ),
                  Expanded(
                    child: _isRecording
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: RecordingWaveform(
                              duration: _recordDuration,
                              levels: _recordingLevels,
                            ),
                          )
                        : TextField(
                            controller: _messageController,
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Message',
                              hintStyle: TextStyle(color: Color(0xFFAAAAAA)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                  ),
                  if (!_isRecording) ...[
                    IconButton(
                      icon: Icon(
                        _showAttachments ? Icons.close : Icons.attach_file,
                        color: const Color(0xFF888888),
                      ),
                      onPressed: () =>
                          setState(() => _showAttachments = !_showAttachments),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                        color: Color(0xFF888888),
                      ),
                      onPressed: () => _addLocalRichMessage(MessageType.image),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onLongPressStart: (_) => _startVoiceRecording(),
            onLongPressEnd: (_) => _stopVoiceRecording(send: true),
            onTap: _isRecording ? () => _stopVoiceRecording(send: true) : _send,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Color(0xFF25D366),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isRecording
                    ? Icons.mic_rounded
                    : _messageController.text.trim().isEmpty
                    ? Icons.mic_rounded
                    : Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// VoiceCallScreen & VideoCallScreen components using Zego
// -------------------------------------------------------------

class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({
    super.key,
    required this.repository,
    required this.currentUser,
    required this.peer,
    required this.callId,
  });

  final ChatRepository repository;
  final AppUser currentUser;
  final AppUser peer;
  final String callId;

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({
    super.key,
    required this.repository,
    required this.currentUser,
    required this.peer,
    required this.callId,
  });

  final ChatRepository repository;
  final AppUser currentUser;
  final AppUser peer;
  final String callId;

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _muted = false;
  bool _cameraOff = false;
  bool _speaker = true;
  bool _callEnded = false;
  CallRequest? _callRequest;
  StreamSubscription<CallRequest?>? _callRequestSub;

  @override
  void initState() {
    super.initState();
    _callRequestSub = widget.repository.watchCallRequest(widget.callId).listen((
      request,
    ) {
      if (request == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      if (request.isRejected ||
          request.status == 'ended' ||
          (request.status == 'ringing' && !request.isRinging)) {
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }
      setState(() {
        _callRequest = request;
      });
    });
  }

  @override
  void dispose() {
    _callRequestSub?.cancel();
    super.dispose();
  }

  Future<void> _endCall() async {
    if (_callEnded) return;
    _callEnded = true;
    try {
      await widget.repository.endCallRequest(widget.callId);
    } on Object catch (_) {
      // ignore errors
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onDispose() async {
    await _endCall();
  }

  @override
  Widget build(BuildContext context) {
    final request = _callRequest;
    if (request == null || request.status == 'ringing') {
      return Scaffold(
        backgroundColor: AppColors.ink,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: AppColors.ink,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AvatarCircle(user: widget.peer, size: 116, fontSize: 42),
                      const SizedBox(height: 18),
                      Text(
                        widget.peer.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Waiting for the call to be accepted...',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 10,
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: _endCall,
                  color: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 28,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CallControlButton(
                      icon: Icons.call_end_rounded,
                      label: 'Cancel',
                      danger: true,
                      onTap: _endCall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (ZegoSettings.isConfigured) {
      return ZegoUIKitPrebuiltCall(
        appID: ZegoSettings.appId,
        appSign: ZegoSettings.appSign,
        userID: widget.currentUser.id,
        userName: widget.currentUser.displayName,
        callID: widget.callId,
        config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
        events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (event, defaultAction) async {
            await _endCall();
          },
        ),
        onDispose: _onDispose,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                alignment: Alignment.center,
                color: AppColors.ink,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AvatarCircle(user: widget.peer, size: 116, fontSize: 42),
                    const SizedBox(height: 18),
                    Text(
                      widget.peer.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Video call preview. Configure Zego credentials for live WebRTC.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: tint(Colors.white, 0.72)),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 18,
              top: 18,
              child: Container(
                width: 104,
                height: 146,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint(Colors.white, 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tint(Colors.white, 0.22)),
                ),
                child: Icon(
                  _cameraOff
                      ? Icons.videocam_off_rounded
                      : Icons.person_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: 10,
              child: IconButton(
                tooltip: 'Back',
                onPressed: _endCall,
                color: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 28,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CallControlButton(
                    icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    label: _muted ? 'Muted' : 'Mute',
                    active: _muted,
                    onTap: () => setState(() => _muted = !_muted),
                  ),
                  CallControlButton(
                    icon: _cameraOff
                        ? Icons.videocam_off_rounded
                        : Icons.videocam_rounded,
                    label: 'Camera',
                    active: !_cameraOff,
                    onTap: () => setState(() => _cameraOff = !_cameraOff),
                  ),
                  CallControlButton(
                    icon: _speaker
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    label: 'Speaker',
                    active: _speaker,
                    onTap: () => setState(() => _speaker = !_speaker),
                  ),
                  CallControlButton(
                    icon: Icons.call_end_rounded,
                    label: 'End',
                    danger: true,
                    onTap: _endCall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  bool _muted = false;
  bool _speaker = true;
  bool _callEnded = false;
  CallRequest? _callRequest;
  StreamSubscription<CallRequest?>? _callRequestSub;

  @override
  void initState() {
    super.initState();
    _callRequestSub = widget.repository.watchCallRequest(widget.callId).listen((
      request,
    ) {
      if (request == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      if (request.isRejected ||
          request.status == 'ended' ||
          (request.status == 'ringing' && !request.isRinging)) {
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }
      setState(() {
        _callRequest = request;
      });
    });
  }

  @override
  void dispose() {
    _callRequestSub?.cancel();
    super.dispose();
  }

  Future<void> _endCall() async {
    if (_callEnded) return;
    _callEnded = true;
    try {
      await widget.repository.endCallRequest(widget.callId);
    } on Object catch (_) {
      // ignore errors
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onDispose() async {
    await _endCall();
  }

  @override
  Widget build(BuildContext context) {
    final request = _callRequest;
    if (request == null || request.status == 'ringing') {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AvatarCircle(user: widget.peer, size: 116, fontSize: 42),
                      const SizedBox(height: 18),
                      Text(
                        widget.peer.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Waiting for the call to be accepted...',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 10,
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: _endCall,
                    color: Colors.white,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 28,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CallControlButton(
                        icon: Icons.call_end_rounded,
                        label: 'Cancel',
                        danger: true,
                        onTap: _endCall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (ZegoSettings.isConfigured) {
      return ZegoUIKitPrebuiltCall(
        appID: ZegoSettings.appId,
        appSign: ZegoSettings.appSign,
        userID: widget.currentUser.id,
        userName: widget.currentUser.displayName,
        callID: widget.callId,
        config: ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
        events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (event, defaultAction) async {
            await _endCall();
          },
        ),
        onDispose: _onDispose,
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: _endCall,
                      color: Colors.white,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'Voice Call',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const Spacer(),
                AvatarCircle(user: widget.peer, size: 118, fontSize: 42),
                const SizedBox(height: 22),
                Text(
                  widget.peer.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ZegoSettings.isConfigured
                      ? 'Connecting...'
                      : 'Add Zego AppID/AppSign to enable live calls',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: tint(Colors.white, 0.76),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 34),
                const SizedBox(
                  width: 180,
                  height: 54,
                  child: StaticWaveform(color: Colors.white70),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CallControlButton(
                      icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      label: _muted ? 'Muted' : 'Mute',
                      active: _muted,
                      onTap: () => setState(() => _muted = !_muted),
                    ),
                    CallControlButton(
                      icon: _speaker
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      label: 'Speaker',
                      active: _speaker,
                      onTap: () => setState(() => _speaker = !_speaker),
                    ),
                    CallControlButton(
                      icon: Icons.call_end_rounded,
                      label: 'End',
                      danger: true,
                      onTap: _endCall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CallControlButton extends StatelessWidget {
  const CallControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final background = danger
        ? AppColors.danger
        : active
        ? Colors.white
        : tint(Colors.white, 0.16);
    final foreground = danger
        ? Colors.white
        : active
        ? AppColors.primary
        : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: foreground, size: 25),
          ),
        ),
        const SizedBox(height: 9),
        Text(
          label,
          style: TextStyle(
            color: tint(Colors.white, 0.82),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// Message Bubble & Rich Media Components
// -------------------------------------------------------------

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.highlighted = false,
  });

  final ChatMessage message;
  final bool isMe;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.voice) {
      return VoiceMessageBubble(message: message, isMe: isMe);
    }

    final bubbleColor = highlighted
        ? AppColors.warning.withValues(alpha: 0.22)
        : isMe
        ? const Color(0xFFDCF8C6) // WhatsApp Light Green
        : Colors.white;
    final foreground = AppColors.ink;
    final muted = AppColors.muted;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.76,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.forwarded)
              _BubbleMeta(
                icon: Icons.forward_rounded,
                label: 'Forwarded',
                color: muted,
              ),
            if (message.replyToText != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(7),
                  border: const Border(
                    left: BorderSide(color: Color(0xFF075E54), width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.replyToSender ?? 'Reply',
                      style: const TextStyle(
                        color: Color(0xFF075E54),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      message.replyToText!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.topLeft,
              child: MessageContent(
                message: message,
                foreground: foreground,
                muted: muted,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  clockTime(message.createdAt),
                  style: TextStyle(color: muted, fontSize: 10),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  MessageStatusIcon(status: message.status),
                ],
              ],
            ),
            if (message.reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Wrap(
                  spacing: 4,
                  children: [
                    for (final entry in message.reactions.entries)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${entry.key} ${entry.value}',
                          style: TextStyle(color: foreground, fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MessageContent extends StatelessWidget {
  const MessageContent({
    super.key,
    required this.message,
    required this.foreground,
    required this.muted,
  });

  final ChatMessage message;
  final Color foreground;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return switch (message.type) {
      MessageType.text => Text(
        message.text,
        style: TextStyle(color: foreground, fontSize: 14, height: 1.35),
      ),
      MessageType.document => _AttachmentBubbleContent(
        icon: Icons.description_outlined,
        title: message.mediaTitle ?? message.text,
        subtitle: message.caption ?? 'Document',
        foreground: foreground,
        muted: muted,
      ),
      MessageType.image => _MediaPreviewContent(
        icon: Icons.image_outlined,
        title: message.mediaTitle ?? 'Image',
        subtitle: message.caption ?? 'Image preview',
        foreground: foreground,
        muted: muted,
      ),
      MessageType.video => _MediaPreviewContent(
        icon: Icons.play_circle_outline_rounded,
        title: message.mediaTitle ?? 'Video',
        subtitle: message.caption ?? 'Video preview',
        foreground: foreground,
        muted: muted,
      ),
      MessageType.location => _AttachmentBubbleContent(
        icon: Icons.location_on_outlined,
        title: message.mediaTitle ?? 'Location',
        subtitle: message.caption ?? 'Map preview',
        foreground: foreground,
        muted: muted,
      ),
      MessageType.contact => _AttachmentBubbleContent(
        icon: Icons.contact_phone_outlined,
        title: message.mediaTitle ?? 'Contact',
        subtitle: message.caption ?? 'Shared contact',
        foreground: foreground,
        muted: muted,
      ),
      MessageType.poll => PollContent(message: message, foreground: foreground),
      MessageType.audio => _AttachmentBubbleContent(
        icon: Icons.audio_file_outlined,
        title: message.mediaTitle ?? 'Audio',
        subtitle: message.caption ?? 'Audio file',
        foreground: foreground,
        muted: muted,
      ),
      MessageType.gif => _MediaPreviewContent(
        icon: Icons.gif_box_outlined,
        title: 'GIF',
        subtitle: message.caption ?? 'Animated media',
        foreground: foreground,
        muted: muted,
      ),
      MessageType.sticker => _AttachmentBubbleContent(
        icon: Icons.emoji_emotions_outlined,
        title: 'Sticker',
        subtitle: message.caption ?? 'Sticker',
        foreground: foreground,
        muted: muted,
      ),
      MessageType.voice => const SizedBox.shrink(),
    };
  }
}

class PollContent extends StatelessWidget {
  const PollContent({
    super.key,
    required this.message,
    required this.foreground,
  });

  final ChatMessage message;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final totalVotes = message.pollOptions.fold<int>(
      0,
      (total, option) => total + option.votes,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.text,
          style: TextStyle(
            color: foreground,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        for (final option in message.pollOptions) ...[
          _PollOptionBar(
            option: option,
            totalVotes: totalVotes,
            foreground: foreground,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class SearchResultBar extends StatelessWidget {
  const SearchResultBar({
    super.key,
    required this.query,
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  final String query;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          const Icon(Icons.manage_search_rounded, color: Color(0xFF075E54)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: 'Search in conversation...',
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            tooltip: 'Cancel',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class ReplyComposerPreview extends StatelessWidget {
  const ReplyComposerPreview({
    super.key,
    required this.message,
    required this.peerName,
    required this.currentUserId,
    required this.onClose,
  });

  final ChatMessage message;
  final String peerName;
  final String currentUserId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final sender = message.senderId == currentUserId ? 'You' : peerName;
    final text = message.text.isNotEmpty
        ? message.text
        : message.mediaTitle ?? message.type.name;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: Color(0xFF075E54), width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sender,
                  style: const TextStyle(
                    color: Color(0xFF075E54),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cancel reply',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class AttachmentPanel extends StatelessWidget {
  const AttachmentPanel({super.key, required this.onPick});

  final ValueChanged<MessageType> onPick;

  @override
  Widget build(BuildContext context) {
    final items = [
      _AttachmentItem(
        Icons.photo_camera_outlined,
        'Camera',
        MessageType.image,
        const Color(0xFFFF4444),
      ),
      _AttachmentItem(
        Icons.photo_library_outlined,
        'Gallery',
        MessageType.image,
        const Color(0xFFFF6B9D),
      ),
      _AttachmentItem(
        Icons.videocam_outlined,
        'Video',
        MessageType.video,
        const Color(0xFF7B68EE),
      ),
      _AttachmentItem(
        Icons.insert_drive_file_outlined,
        'Document',
        MessageType.document,
        const Color(0xFF9C27B0),
      ),
      _AttachmentItem(
        Icons.location_on_outlined,
        'Location',
        MessageType.location,
        const Color(0xFF4CAF50),
      ),
      _AttachmentItem(
        Icons.contact_phone_outlined,
        'Contact',
        MessageType.contact,
        const Color(0xFF2196F3),
      ),
      _AttachmentItem(
        Icons.poll_outlined,
        'Poll',
        MessageType.poll,
        const Color(0xFF009688),
      ),
      _AttachmentItem(
        Icons.audio_file_outlined,
        'Audio',
        MessageType.audio,
        const Color(0xFFFF9800),
      ),
    ];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceAround,
        children: [
          for (final item in items)
            InkWell(
              onTap: () => onPick(item.type),
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 68,
                height: 72,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttachmentItem {
  const _AttachmentItem(this.icon, this.label, this.type, this.color);

  final IconData icon;
  final String label;
  final MessageType type;
  final Color color;
}

class MessageStatusIcon extends StatelessWidget {
  const MessageStatusIcon({super.key, required this.status});

  final MessageStatus status;

  @override
  Widget build(BuildContext context) {
    return Icon(
      switch (status) {
        MessageStatus.sending => Icons.schedule_rounded,
        MessageStatus.sent => Icons.done_rounded,
        MessageStatus.delivered => Icons.done_all_rounded,
        MessageStatus.read => Icons.done_all_rounded,
        MessageStatus.failed => Icons.error_outline_rounded,
      },
      size: 14,
      color: switch (status) {
        MessageStatus.read => const Color(
          0xFF34B7F1,
        ), // WhatsApp Blue Read Tick
        MessageStatus.failed => AppColors.danger,
        _ => const Color(0xFF888888),
      },
    );
  }
}

class _BubbleMeta extends StatelessWidget {
  const _BubbleMeta({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentBubbleContent extends StatelessWidget {
  const _AttachmentBubbleContent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.foreground,
    required this.muted,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color foreground;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.insert_drive_file,
            color: Color(0xFF075E54),
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MediaPreviewContent extends StatelessWidget {
  const _MediaPreviewContent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.foreground,
    required this.muted,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color foreground;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 210,
          height: 112,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE8E8E8)),
          ),
          child: Icon(icon, color: const Color(0xFF075E54), size: 38),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foreground,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: muted, fontSize: 11),
        ),
      ],
    );
  }
}

class _PollOptionBar extends StatelessWidget {
  const _PollOptionBar({
    required this.option,
    required this.totalVotes,
    required this.foreground,
  });

  final PollOption option;
  final int totalVotes;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final percent = totalVotes == 0 ? 0.0 : option.votes / totalVotes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              option.selectedByMe
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: const Color(0xFF075E54),
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                option.label,
                style: TextStyle(color: foreground, fontSize: 12),
              ),
            ),
            Text(
              '${(percent * 100).round()}%',
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 5,
            value: percent,
            backgroundColor: const Color(0xFFE8E8E8),
            color: const Color(0xFF075E54),
          ),
        ),
      ],
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction(
    this.icon,
    this.label,
    this.onTap, {
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : AppColors.ink;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }
}

class VoiceMessageBubble extends StatefulWidget {
  const VoiceMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  final ChatMessage message;
  final bool isMe;

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final _player = AudioPlayer();
  bool _prepared = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    final url = widget.message.audioUrl;
    if (url == null || url.isEmpty) return;

    if (_player.playing) {
      await _player.pause();
      return;
    }

    if (!_prepared) {
      if (url.startsWith('http')) {
        await _player.setUrl(url);
      } else {
        await _player.setFilePath(url);
      }
      _prepared = true;
    }

    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }
    await _player.play();
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = widget.isMe ? const Color(0xFFDCF8C6) : Colors.white;
    final foreground = AppColors.ink;
    final muted = AppColors.muted;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.76,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(widget.isMe ? 12 : 2),
            bottomRight: Radius.circular(widget.isMe ? 2 : 12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) {
                final playing = snapshot.data?.playing ?? false;
                return IconButton(
                  tooltip: playing ? 'Pause voice' : 'Play voice',
                  onPressed: _togglePlayback,
                  style: IconButton.styleFrom(
                    backgroundColor: widget.isMe
                        ? const Color(0xFFB0F0AD)
                        : const Color(0xFFE8F5E9),
                    foregroundColor: const Color(0xFF075E54),
                    fixedSize: const Size(34, 34),
                    padding: EdgeInsets.zero,
                  ),
                  icon: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 21,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 118,
              height: 28,
              child: StaticWaveform(color: muted),
            ),
            const SizedBox(width: 8),
            Text(
              formatVoiceDuration(widget.message.audioDuration),
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecordingWaveform extends StatelessWidget {
  const RecordingWaveform({
    super.key,
    required this.duration,
    required this.levels,
  });

  final Duration duration;
  final List<double> levels;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          const Icon(Icons.mic_rounded, color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(child: LiveWaveform(levels: levels)),
          const SizedBox(width: 8),
          Text(
            formatVoiceDuration(duration),
            style: const TextStyle(
              color: AppColors.danger,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class LiveWaveform extends StatelessWidget {
  const LiveWaveform({super.key, required this.levels});

  final List<double> levels;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final level in levels)
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 2.5,
            height: 4 + (20 * level),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

class StaticWaveform extends StatelessWidget {
  const StaticWaveform({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _WavePainter(color));
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;
    const bars = 20;
    final gap = size.width / bars;
    for (var i = 0; i < bars; i++) {
      final value = 0.25 + (math.sin(i * 0.85) + 1) * 0.34;
      final height = math.max(4.0, size.height * value);
      final x = i * gap + gap / 2;
      canvas.drawLine(
        Offset(x, (size.height - height) / 2),
        Offset(x, (size.height + height) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
