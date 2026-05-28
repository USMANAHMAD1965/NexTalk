part of '../../../main.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({
    super.key,
    required this.repository,
    required this.currentUser,
    required this.onOpenChat,
    required this.onOpenFindPeople,
    required this.onOpenNotifications,
  });

  final ChatRepository repository;
  final AppUser currentUser;
  final ValueChanged<Conversation> onOpenChat;
  final VoidCallback onOpenFindPeople;
  final VoidCallback onOpenNotifications;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _searchController = TextEditingController();
  int _filterIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Conversation> _filter(List<Conversation> items) {
    final query = _searchController.text.trim().toLowerCase();
    Iterable<Conversation> filtered = items;
    if (_filterIndex == 1) {
      filtered = filtered.where((item) => item.unreadCount > 0);
    } else if (_filterIndex == 2) {
      filtered = filtered.where(
        (item) => DateTime.now().difference(item.updatedAt).inDays < 1,
      );
    } else if (_filterIndex == 3) {
      filtered = filtered.where((item) => item.peer.online);
    }
    if (query.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.peer.displayName.toLowerCase().contains(query) ||
            item.lastMessage.toLowerCase().contains(query);
      });
    }
    return filtered.toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeaderBar(
            title: 'Messages',
            action: IconButton(
              tooltip: 'Notifications',
              onPressed: widget.onOpenNotifications,
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          const SizedBox(height: 14),
          SearchBox(
            controller: _searchController,
            hintText: 'Search conversations...',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          FilterPills(
            selectedIndex: _filterIndex,
            labels: const ['All', 'Unread', 'Recent', 'Active'],
            onChanged: (index) => setState(() => _filterIndex = index),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: StreamBuilder<List<Conversation>>(
              stream: widget.repository.watchConversations(
                widget.currentUser.id,
              ),
              initialData: sampleConversations(),
              builder: (context, snapshot) {
                final conversations = _filter(
                  snapshot.data ?? sampleConversations(),
                );
                if (conversations.isEmpty) {
                  return EmptyConversations(
                    onFindPeople: widget.onOpenFindPeople,
                    onNewChat: widget.onOpenFindPeople,
                  );
                }
                return Stack(
                  children: [
                    ListView.separated(
                      padding: const EdgeInsets.only(bottom: 86),
                      itemBuilder: (context, index) {
                        final conversation = conversations[index];
                        return ConversationTile(
                          conversation: conversation,
                          onTap: () => widget.onOpenChat(conversation),
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemCount: conversations.length,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 16,
                      child: FloatingActionButton.extended(
                        onPressed: widget.onOpenFindPeople,
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        icon: const Icon(Icons.add_comment_rounded),
                        label: const Text('New Chat'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyConversations extends StatelessWidget {
  const EmptyConversations({
    super.key,
    required this.onFindPeople,
    required this.onNewChat,
  });

  final VoidCallback onFindPeople;
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.softPurple,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.primary,
                size: 38,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No conversations yet',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect with friends and start meaningful conversations',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Find People',
              icon: Icons.person_search_rounded,
              onPressed: onFindPeople,
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: 'View Friends',
              icon: Icons.people_alt_outlined,
              onPressed: onNewChat,
            ),
          ],
        ),
      ),
    );
  }
}

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  final Conversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              AvatarCircle(user: conversation.peer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.peer.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          shortTime(conversation.updatedAt),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (conversation.unreadCount > 0)
                          Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${conversation.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
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
}

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
      if (!widget.repository.firebaseEnabled ||
          widget.conversation.id.startsWith('demo')) {
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

    if (!widget.repository.firebaseEnabled ||
        widget.conversation.id.startsWith('demo')) {
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

  void _openVoiceCall() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VoiceCallScreen(
          currentUser: widget.currentUser,
          peer: widget.conversation.peer,
          callId: widget.conversation.id,
        ),
      ),
    );
  }

  void _openVideoCall() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoCallScreen(
          currentUser: widget.currentUser,
          peer: widget.conversation.peer,
          callId: '${widget.conversation.id}-video',
        ),
      ),
    );
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
        mediaTitle: 'Product demo.mp4',
        caption: 'Trimmed video ready for upload',
        createdAt: now,
        status: MessageStatus.sending,
      ),
      MessageType.document => ChatMessage(
        id: 'local-doc-${now.microsecondsSinceEpoch}',
        senderId: widget.currentUser.id,
        text: 'Architecture Notes.pdf',
        type: MessageType.document,
        mediaTitle: 'Architecture Notes.pdf',
        caption: 'Offline queue, E2EE, media CDN, and analytics checklist.',
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
                  showAppSnack(
                    context,
                    'Notifications muted for this demo chat.',
                  );
                },
              ),
              _SheetAction(Icons.wallpaper_rounded, 'Wallpaper', () {
                Navigator.pop(context);
                showAppSnack(
                  context,
                  'Wallpaper controls can connect to user settings.',
                );
              }),
              _SheetAction(Icons.ios_share_rounded, 'Export chat', () {
                Navigator.pop(context);
                showAppSnack(
                  context,
                  'Export queued with encrypted media references.',
                );
              }),
              _SheetAction(Icons.delete_sweep_outlined, 'Clear chat', () {
                Navigator.pop(context);
                showAppSnack(
                  context,
                  'Clear chat action requires confirmation in production.',
                );
              }, destructive: true),
              _SheetAction(Icons.block_rounded, 'Block user', () {
                Navigator.pop(context);
                showAppSnack(context, 'Block/report workflow placeholder.');
              }, destructive: true),
              _SheetAction(Icons.flag_outlined, 'Report user', () {
                Navigator.pop(context);
                showAppSnack(context, 'Report submitted to moderation queue.');
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
                showAppSnack(context, 'Message copied.');
              }),
              _SheetAction(Icons.star_border_rounded, 'Star message', () {
                Navigator.pop(context);
                showAppSnack(context, 'Message starred.');
              }),
              _SheetAction(Icons.push_pin_outlined, 'Pin message', () {
                Navigator.pop(context);
                showAppSnack(context, 'Message pinned.');
              }),
              _SheetAction(Icons.forward_rounded, 'Forward', () {
                Navigator.pop(context);
                showAppSnack(
                  context,
                  'Forward picker supports multiple chats.',
                );
              }),
              _SheetAction(Icons.translate_rounded, 'Translate', () {
                Navigator.pop(context);
                showAppSnack(context, 'Translation module placeholder.');
              }),
              _SheetAction(Icons.share_outlined, 'Share', () {
                Navigator.pop(context);
                showAppSnack(context, 'System share action placeholder.');
              }),
              _SheetAction(Icons.delete_outline_rounded, 'Delete for me', () {
                Navigator.pop(context);
                showAppSnack(context, 'Deleted locally in demo mode.');
              }, destructive: true),
              if (isMe)
                _SheetAction(
                  Icons.delete_forever_outlined,
                  'Delete for everyone',
                  () {
                    Navigator.pop(context);
                    showAppSnack(
                      context,
                      'Delete for everyone requires server sync.',
                    );
                  },
                  destructive: true,
                ),
            ],
          ),
        );
      },
    );
  }

  void _react(ChatMessage message, String emoji) {
    setState(() {
      final index = _localMessages.indexWhere((item) => item.id == message.id);
      if (index != -1) {
        final current = _localMessages[index];
        final reactions = Map<String, int>.from(current.reactions);
        reactions[emoji] = (reactions[emoji] ?? 0) + 1;
        _localMessages[index] = ChatMessage(
          id: current.id,
          senderId: current.senderId,
          text: current.text,
          createdAt: current.createdAt,
          type: current.type,
          status: current.status,
          audioUrl: current.audioUrl,
          audioDuration: current.audioDuration,
          storagePath: current.storagePath,
          mediaUrl: current.mediaUrl,
          mediaTitle: current.mediaTitle,
          caption: current.caption,
          replyToText: current.replyToText,
          replyToSender: current.replyToSender,
          reactions: reactions,
          forwarded: current.forwarded,
          starred: current.starred,
          pinned: current.pinned,
          ephemeral: current.ephemeral,
          viewOnce: current.viewOnce,
          pollOptions: current.pollOptions,
        );
      }
    });
    widget.repository.reactToMessage(
      conversationId: widget.conversation.id,
      messageId: message.id,
      emoji: emoji,
    );
  }

  String get _presenceText {
    return switch (_presence) {
      PresenceState.typing => 'Typing...',
      PresenceState.recording => 'Recording audio...',
      PresenceState.online =>
        widget.conversation.peer.online ? 'Online' : 'Last seen recently',
      PresenceState.offline => 'Offline',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: const BackButton(),
        titleSpacing: 0,
        title: _searching
            ? TextField(
                controller: _chatSearchController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search in chat',
                  prefixIcon: Icon(Icons.search_rounded),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                ),
              )
            : Row(
                children: [
                  AvatarCircle(user: widget.conversation.peer, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.conversation.peer.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _presenceText,
                          style: TextStyle(
                            color:
                                _presence == PresenceState.online &&
                                    widget.conversation.peer.online
                                ? AppColors.accent
                                : AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        actions: [
          if (_searching)
            IconButton(
              tooltip: 'Close search',
              onPressed: () => setState(() {
                _searching = false;
                _chatSearchController.clear();
              }),
              icon: const Icon(Icons.close_rounded),
            )
          else ...[
            IconButton(
              tooltip: 'Video call',
              onPressed: _openVideoCall,
              icon: const Icon(Icons.videocam_outlined),
            ),
            IconButton(
              tooltip: 'Voice call',
              onPressed: _openVoiceCall,
              icon: const Icon(Icons.call_rounded),
            ),
            IconButton(
              tooltip: 'Chat menu',
              onPressed: _openChatMenu,
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (_searching && _chatSearchController.text.isNotEmpty)
            SearchResultBar(query: _chatSearchController.text),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: widget.repository.watchMessages(widget.conversation.id),
              initialData: sampleMessages(),
              builder: (context, snapshot) {
                final messages = [
                  ...(snapshot.data ?? sampleMessages()),
                  ..._localMessages,
                ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
                final query = _chatSearchController.text.trim().toLowerCase();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == widget.currentUser.id;
                    final highlighted =
                        query.isNotEmpty &&
                        ('${message.text} ${message.mediaTitle ?? ''} ${message.caption ?? ''}')
                            .toLowerCase()
                            .contains(query);
                    final showTime =
                        index == 0 ||
                        messages[index].createdAt
                                .difference(messages[index - 1].createdAt)
                                .inMinutes >
                            8;
                    return Column(
                      children: [
                        if (showTime)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              clockTime(message.createdAt),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: GestureDetector(
                            onHorizontalDragEnd: (_) =>
                                setState(() => _replyingTo = message),
                            onLongPress: () =>
                                _showMessageActions(message, isMe),
                            child: MessageBubble(
                              message: message,
                              isMe: isMe,
                              highlighted: highlighted,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Attach',
                    onPressed: _isRecording
                        ? null
                        : () => setState(
                            () => _showAttachments = !_showAttachments,
                          ),
                    icon: Icon(
                      _showAttachments
                          ? Icons.close_rounded
                          : Icons.add_rounded,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_replyingTo != null)
                          ReplyComposerPreview(
                            message: _replyingTo!,
                            peerName: widget.conversation.peer.displayName,
                            currentUserId: widget.currentUser.id,
                            onClose: () => setState(() => _replyingTo = null),
                          ),
                        if (_showAttachments)
                          AttachmentPanel(onPick: _addLocalRichMessage),
                        _isRecording
                            ? RecordingWaveform(
                                duration: _recordDuration,
                                levels: _recordingLevels,
                              )
                            : TextField(
                                controller: _messageController,
                                minLines: 1,
                                maxLines: 4,
                                textInputAction: TextInputAction.send,
                                onChanged: (value) => setState(
                                  () => _presence = value.trim().isEmpty
                                      ? PresenceState.online
                                      : PresenceState.typing,
                                ),
                                onSubmitted: (_) => _send(),
                                decoration: const InputDecoration(
                                  hintText: 'Message',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 11,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.emoji_emotions_outlined,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onLongPressStart: (_) => _startVoiceRecording(),
                    onLongPressEnd: (_) => _stopVoiceRecording(send: true),
                    onLongPressCancel: () => _stopVoiceRecording(send: false),
                    onTap: () => showAppSnack(
                      context,
                      'Hold the mic to record a voice message.',
                    ),
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _isRecording
                              ? AppColors.danger
                              : AppColors.softPurple,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _isUploadingVoice
                            ? const Padding(
                                padding: EdgeInsets.all(13),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _isRecording
                                    ? Icons.stop_rounded
                                    : Icons.mic_rounded,
                                color: _isRecording
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    tooltip: 'Send',
                    onPressed: _sending || _isRecording ? null : _send,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.softPurple,
                      foregroundColor: AppColors.primary,
                    ),
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
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

class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({
    super.key,
    required this.currentUser,
    required this.peer,
    required this.callId,
  });

  final AppUser currentUser;
  final AppUser peer;
  final String callId;

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({
    super.key,
    required this.currentUser,
    required this.peer,
    required this.callId,
  });

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

  @override
  Widget build(BuildContext context) {
    if (ZegoSettings.isConfigured) {
      return ZegoUIKitPrebuiltCall(
        appID: ZegoSettings.appId,
        appSign: ZegoSettings.appSign,
        userID: widget.currentUser.id,
        userName: widget.currentUser.displayName,
        callID: widget.callId,
        config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
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
                onPressed: () => Navigator.pop(context),
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
                    onTap: () => Navigator.pop(context),
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

  @override
  Widget build(BuildContext context) {
    if (ZegoSettings.isConfigured) {
      return ZegoUIKitPrebuiltCall(
        appID: ZegoSettings.appId,
        appSign: ZegoSettings.appSign,
        userID: widget.currentUser.id,
        userName: widget.currentUser.displayName,
        callID: widget.callId,
        config: ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
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
                      onPressed: () => Navigator.of(context).pop(),
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
                      onTap: () => Navigator.of(context).pop(),
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
        ? AppColors.primary
        : Colors.white;
    final foreground = isMe && !highlighted ? Colors.white : AppColors.ink;
    final muted = isMe && !highlighted
        ? tint(Colors.white, 0.76)
        : AppColors.muted;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.76,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(8),
            topRight: const Radius.circular(8),
            bottomLeft: Radius.circular(isMe ? 8 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 8),
          ),
          border: isMe && !highlighted
              ? null
              : Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  color: isMe && !highlighted
                      ? tint(Colors.white, 0.14)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(7),
                  border: Border(
                    left: BorderSide(
                      color: isMe && !highlighted
                          ? Colors.white
                          : AppColors.primary,
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.replyToSender ?? 'Reply',
                      style: TextStyle(
                        color: isMe && !highlighted
                            ? Colors.white
                            : AppColors.primary,
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
            MessageContent(
              message: message,
              foreground: foreground,
              muted: muted,
            ),
            const SizedBox(height: 6),
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
                          color: isMe && !highlighted
                              ? tint(Colors.white, 0.16)
                              : AppColors.surface,
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
        style: TextStyle(color: foreground, fontSize: 13, height: 1.35),
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
  const SearchResultBar({super.key, required this.query});

  final String query;

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
          const Icon(Icons.manage_search_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Searching "$query"',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Previous result',
            onPressed: () {},
            icon: const Icon(Icons.keyboard_arrow_up_rounded),
          ),
          IconButton(
            tooltip: 'Next result',
            onPressed: () {},
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sender,
                  style: const TextStyle(
                    color: AppColors.primary,
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
      _AttachmentItem(Icons.photo_camera_outlined, 'Camera', MessageType.image),
      _AttachmentItem(
        Icons.photo_library_outlined,
        'Gallery',
        MessageType.image,
      ),
      _AttachmentItem(Icons.videocam_outlined, 'Video', MessageType.video),
      _AttachmentItem(
        Icons.insert_drive_file_outlined,
        'Document',
        MessageType.document,
      ),
      _AttachmentItem(
        Icons.location_on_outlined,
        'Location',
        MessageType.location,
      ),
      _AttachmentItem(
        Icons.contact_phone_outlined,
        'Contact',
        MessageType.contact,
      ),
      _AttachmentItem(Icons.poll_outlined, 'Poll', MessageType.poll),
      _AttachmentItem(Icons.audio_file_outlined, 'Audio', MessageType.audio),
    ];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in items)
            Tooltip(
              message: item.label,
              child: InkWell(
                onTap: () => onPick(item.type),
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 70,
                  height: 62,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, color: AppColors.primary, size: 22),
                      const SizedBox(height: 5),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttachmentItem {
  const _AttachmentItem(this.icon, this.label, this.type);

  final IconData icon;
  final String label;
  final MessageType type;
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
        MessageStatus.read => AppColors.accent,
        MessageStatus.failed => AppColors.danger,
        _ => AppColors.muted,
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
            color: tint(foreground, 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: foreground, size: 22),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
            color: tint(foreground, 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: foreground, size: 38),
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
              color: foreground,
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
            backgroundColor: tint(foreground, 0.12),
            color: foreground,
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
    final bubbleColor = widget.isMe ? AppColors.primary : Colors.white;
    final foreground = widget.isMe ? Colors.white : AppColors.ink;
    final muted = widget.isMe ? tint(Colors.white, 0.72) : AppColors.muted;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.76,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(8),
            topRight: const Radius.circular(8),
            bottomLeft: Radius.circular(widget.isMe ? 8 : 2),
            bottomRight: Radius.circular(widget.isMe ? 2 : 8),
          ),
          border: widget.isMe ? null : Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) {
                final playing = snapshot.data?.playing ?? false;
                return IconButton(
                  tooltip: playing
                      ? 'Pause voice message'
                      : 'Play voice message',
                  onPressed: _togglePlayback,
                  style: IconButton.styleFrom(
                    backgroundColor: widget.isMe
                        ? tint(Colors.white, 0.16)
                        : AppColors.softPurple,
                    foregroundColor: widget.isMe
                        ? Colors.white
                        : AppColors.primary,
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
                fontSize: 12,
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
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: tint(AppColors.danger, 0.08),
        border: Border.all(color: tint(AppColors.danger, 0.22)),
        borderRadius: BorderRadius.circular(8),
      ),
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
            width: 3,
            height: 6 + (28 * level),
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
      ..strokeWidth = 3;
    const bars = 22;
    final gap = size.width / bars;
    for (var i = 0; i < bars; i++) {
      final value = 0.25 + (math.sin(i * 0.85) + 1) * 0.34;
      final height = math.max(5.0, size.height * value);
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
