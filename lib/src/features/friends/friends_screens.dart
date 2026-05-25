part of '../../../main.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({
    super.key,
    required this.repository,
    required this.currentUser,
    required this.onOpenChat,
    required this.onOpenRequests,
  });

  final ChatRepository repository;
  final AppUser currentUser;
  final ValueChanged<Conversation> onOpenChat;
  final VoidCallback onOpenRequests;

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchController = TextEditingController();
  String? _openingChatUserId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openChat(AppUser friend) async {
    if (_openingChatUserId != null) return;
    setState(() => _openingChatUserId = friend.id);
    try {
      final conversation = await widget.repository.openConversation(
        currentUser: widget.currentUser,
        peer: friend,
      );
      if (!mounted) return;
      widget.onOpenChat(conversation);
    } on Object catch (error) {
      if (!mounted) return;
      showAppSnack(context, friendlyFirebaseError(error));
    } finally {
      if (mounted) setState(() => _openingChatUserId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeaderBar(
            title: 'Friends',
            action: IconButton(
              tooltip: 'Friend requests',
              onPressed: widget.onOpenRequests,
              icon: const Icon(Icons.person_add_alt_1_rounded),
            ),
          ),
          const SizedBox(height: 14),
          SearchBox(
            controller: _searchController,
            hintText: 'Search friends...',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: widget.repository.watchFriends(widget.currentUser.id),
              initialData: sampleFriends(),
              builder: (context, snapshot) {
                final query = _searchController.text.trim().toLowerCase();
                final friends = (snapshot.data ?? sampleFriends()).where((
                  friend,
                ) {
                  return query.isEmpty ||
                      friend.displayName.toLowerCase().contains(query) ||
                      friend.email.toLowerCase().contains(query);
                }).toList();

                return ListView.separated(
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    final opening = _openingChatUserId == friend.id;
                    return UserCard(
                      user: friend,
                      trailing: IconButton(
                        tooltip: 'Message',
                        onPressed: opening ? null : () => _openChat(friend),
                        icon: opening
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.chat_bubble_outline_rounded),
                      ),
                      onTap: opening ? null : () => _openChat(friend),
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemCount: friends.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FindPeopleScreen extends StatefulWidget {
  const FindPeopleScreen({
    super.key,
    required this.repository,
    required this.currentUser,
    required this.onOpenChat,
  });

  final ChatRepository repository;
  final AppUser currentUser;
  final ValueChanged<Conversation> onOpenChat;

  @override
  State<FindPeopleScreen> createState() => _FindPeopleScreenState();
}

class _FindPeopleScreenState extends State<FindPeopleScreen> {
  final _searchController = TextEditingController();
  final _emailConnectController = TextEditingController();
  final Set<String> _requested = <String>{};
  bool _connectingByEmail = false;

  @override
  void dispose() {
    _searchController.dispose();
    _emailConnectController.dispose();
    super.dispose();
  }

  Future<void> _startChatByEmail() async {
    final email = _emailConnectController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      showAppSnack(context, 'Enter a valid email address.');
      return;
    }
    if (email.toLowerCase() == widget.currentUser.email.toLowerCase()) {
      showAppSnack(context, 'Enter another user email.');
      return;
    }

    setState(() => _connectingByEmail = true);
    try {
      final conversation = await widget.repository.openConversationByEmail(
        currentUser: widget.currentUser,
        email: email,
      );
      if (!mounted) return;
      _emailConnectController.clear();
      widget.onOpenChat(conversation);
    } on Object catch (error) {
      if (!mounted) return;
      showAppSnack(context, friendlyFirebaseError(error));
    } finally {
      if (mounted) setState(() => _connectingByEmail = false);
    }
  }

  Future<void> _addFriend(AppUser user) async {
    setState(() => _requested.add(user.id));
    try {
      await widget.repository.sendFriendRequest(widget.currentUser, user);
      if (!mounted) return;
      showAppSnack(context, 'Friend request sent to ${user.displayName}.');
    } on Object catch (error) {
      setState(() => _requested.remove(user.id));
      if (!mounted) return;
      showAppSnack(context, friendlyFirebaseError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HeaderBar(title: 'Find People'),
          const SizedBox(height: 14),
          SearchBox(
            controller: _searchController,
            hintText: 'Search users...',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          EmailConnectPanel(
            controller: _emailConnectController,
            loading: _connectingByEmail,
            onSubmit: _startChatByEmail,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: widget.repository.watchFindPeople(widget.currentUser.id),
              initialData: samplePeople(),
              builder: (context, snapshot) {
                final query = _searchController.text.trim().toLowerCase();
                final people = (snapshot.data ?? samplePeople()).where((user) {
                  return query.isEmpty ||
                      user.displayName.toLowerCase().contains(query) ||
                      user.email.toLowerCase().contains(query);
                }).toList();

                return ListView.separated(
                  itemBuilder: (context, index) {
                    final user = people[index];
                    final requested = _requested.contains(user.id);
                    return UserCard(
                      user: user,
                      trailing: FilledButton.icon(
                        onPressed: requested ? null : () => _addFriend(user),
                        icon: Icon(
                          requested
                              ? Icons.check_rounded
                              : Icons.person_add_alt_1_rounded,
                        ),
                        label: Text(requested ? 'Added' : 'Add Friend'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.softPurple,
                          disabledForegroundColor: AppColors.primary,
                          minimumSize: const Size(114, 38),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemCount: people.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EmailConnectPanel extends StatelessWidget {
  const EmailConnectPanel({
    super.key,
    required this.controller,
    required this.loading,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Start chat by email',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !loading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSubmit(),
                  decoration: const InputDecoration(
                    hintText: 'friend@email.com',
                    prefixIcon: Icon(Icons.alternate_email_rounded, size: 19),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                tooltip: 'Start chat',
                onPressed: loading ? null : onSubmit,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: tint(AppColors.primary, 0.58),
                  fixedSize: const Size(46, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.chat_bubble_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({
    super.key,
    required this.repository,
    required this.currentUser,
    required this.onOpenChat,
  });

  final ChatRepository repository;
  final AppUser currentUser;
  final ValueChanged<Conversation> onOpenChat;

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  bool _showReceived = true;

  Future<void> _update(FriendRequest request, RequestStatus status) async {
    final conversation = await widget.repository.updateFriendRequest(
      request: request,
      status: status,
      currentUser: widget.currentUser,
    );
    if (!mounted) return;
    final label = status == RequestStatus.accepted ? 'accepted' : 'declined';
    showAppSnack(context, 'Friend request $label.');
    if (conversation != null) {
      widget.onOpenChat(conversation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Friend Requests'),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            children: [
              SegmentedToggle(
                leftLabel: 'Received',
                rightLabel: 'Sent',
                leftSelected: _showReceived,
                onChanged: (received) =>
                    setState(() => _showReceived = received),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<FriendRequest>>(
                  stream: widget.repository.watchFriendRequests(
                    widget.currentUser.id,
                    sent: !_showReceived,
                  ),
                  initialData: sampleRequests(sentByMe: !_showReceived),
                  builder: (context, snapshot) {
                    final requests =
                        snapshot.data ??
                        sampleRequests(sentByMe: !_showReceived);
                    return ListView.separated(
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        return FriendRequestCard(
                          request: request,
                          showActions:
                              _showReceived &&
                              request.status == RequestStatus.pending,
                          onAccept: () =>
                              _update(request, RequestStatus.accepted),
                          onDecline: () =>
                              _update(request, RequestStatus.declined),
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemCount: requests.length,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FriendRequestCard extends StatelessWidget {
  const FriendRequestCard({
    super.key,
    required this.request,
    required this.showActions,
    required this.onAccept,
    required this.onDecline,
  });

  final FriendRequest request;
  final bool showActions;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AvatarCircle(user: request.user),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.user.displayName,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      request.user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                shortTime(request.createdAt),
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDecline,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: BorderSide(color: tint(AppColors.danger, 0.35)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Accept'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: StatusBadge(status: request.status),
            ),
          ],
        ],
      ),
    );
  }
}
