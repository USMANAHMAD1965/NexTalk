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
  final _recorder = AudioRecorder();
  final List<ChatMessage> _localMessages = <ChatMessage>[];
  StreamSubscription<Amplitude>? _amplitudeSub;
  Timer? _recordTimer;
  bool _sending = false;
  bool _isRecording = false;
  bool _isUploadingVoice = false;
  Duration _recordDuration = Duration.zero;
  List<double> _recordingLevels = List<double>.filled(22, 0.18);

  @override
  void dispose() {
    _messageController.dispose();
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
      if (!widget.repository.firebaseEnabled ||
          widget.conversation.id.startsWith('demo')) {
        _localMessages.add(
          ChatMessage(
            id: 'local-${DateTime.now().microsecondsSinceEpoch}',
            senderId: widget.currentUser.id,
            text: text,
            createdAt: DateTime.now(),
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: const BackButton(),
        titleSpacing: 0,
        title: Row(
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
                    widget.conversation.peer.online
                        ? 'Online'
                        : 'Last seen recently',
                    style: TextStyle(
                      color: widget.conversation.peer.online
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
          IconButton(
            tooltip: 'Voice call',
            onPressed: _openVoiceCall,
            icon: const Icon(Icons.call_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: widget.repository.watchMessages(widget.conversation.id),
              initialData: sampleMessages(),
              builder: (context, snapshot) {
                final messages = [
                  ...(snapshot.data ?? sampleMessages()),
                  ..._localMessages,
                ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == widget.currentUser.id;
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
                          child: MessageBubble(message: message, isMe: isMe),
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
                  Expanded(
                    child: _isRecording
                        ? RecordingWaveform(
                            duration: _recordDuration,
                            levels: _recordingLevels,
                          )
                        : TextField(
                            controller: _messageController,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 11,
                              ),
                            ),
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
  const MessageBubble({super.key, required this.message, required this.isMe});

  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.voice) {
      return VoiceMessageBubble(message: message, isMe: isMe);
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.76,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(8),
            topRight: const Radius.circular(8),
            bottomLeft: Radius.circular(isMe ? 8 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 8),
          ),
          border: isMe ? null : Border.all(color: AppColors.line),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isMe ? Colors.white : AppColors.ink,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ),
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
