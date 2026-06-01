part of '../app.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.repository,
    required this.currentUser,
  });

  final ChatRepository repository;
  final AppUser currentUser;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  IconData _iconFor(AppNotification notification) {
    if (notification.accepted) {
      return Icons.check_circle;
    } else if (notification.title.toLowerCase().contains('request') ||
        notification.body.toLowerCase().contains('request')) {
      return Icons.person_add;
    } else if (notification.title.toLowerCase().contains('message') ||
        notification.title.toLowerCase().contains('call') ||
        notification.body.toLowerCase().contains('call')) {
      return Icons.chat_bubble;
    }
    return Icons.notifications;
  }

  Color _colorFor(AppNotification notification) {
    if (notification.accepted) {
      return const Color(0xFF25D366); // WhatsApp Green
    } else if (notification.isFriendRequest) {
      return const Color(0xFF2196F3); // Blue
    } else if (notification.title.toLowerCase().contains('message') ||
        notification.title.toLowerCase().contains('call') ||
        notification.body.toLowerCase().contains('call')) {
      return const Color(0xFF075E54); // Dark Green
    }
    return const Color(0xFFAAAAAA);
  }

  bool _shouldShowFriendRequestActions(AppNotification notification) {
    return notification.isFriendRequest &&
        notification.friendRequestId != null &&
        !notification.accepted;
  }

  Future<void> _respondToFriendRequest(
    AppNotification notification,
    RequestStatus status,
  ) async {
    if (notification.friendRequestId == null) return;
    final request = await widget.repository.fetchFriendRequestById(
      notification.friendRequestId!,
      widget.currentUser.id,
    );
    if (request == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request no longer exists.')),
      );
      return;
    }

    final conversation = await widget.repository.updateFriendRequest(
      request: request,
      status: status,
      currentUser: widget.currentUser,
    );
    await widget.repository.deleteNotification(notification.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == RequestStatus.accepted
              ? 'Friend request accepted.'
              : 'Friend request declined.',
        ),
      ),
    );

    if (status == RequestStatus.accepted && conversation != null) {
      // navigate to conversation if desired
      // Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(...)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppNotification>>(
      stream: widget.repository.watchNotifications(widget.currentUser.id),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? const <AppNotification>[];
        final unreadCount = notifications.where((n) => !n.read).length;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: const Color(0xFF075E54),
            elevation: 0,
            leading: Navigator.of(context).canPop()
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (unreadCount > 0)
                  Text(
                    '$unreadCount new',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
              ],
            ),
            actions: [
              if (unreadCount > 0)
                TextButton(
                  onPressed: () => widget.repository.markNotificationsRead(
                    widget.currentUser.id,
                  ),
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
            ],
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Color(0xFF075E54),
              statusBarIconBrightness: Brightness.light,
            ),
          ),
          body: notifications.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  itemCount: notifications.length,
                  separatorBuilder: (_, index) =>
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    final initial = n.title.trim().isNotEmpty
                        ? n.title.trim()[0].toUpperCase()
                        : 'N';
                    return Container(
                      color: n.read ? Colors.white : const Color(0xFFF0FFF4),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        leading: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFF075E54),
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _colorFor(n),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  _iconFor(n),
                                  size: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          n.title,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF111111),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (n.body.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                n.body,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ],
                            const SizedBox(height: 3),
                            Text(
                              shortTime(n.createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFAAAAAA),
                              ),
                            ),
                            if (_shouldShowFriendRequestActions(n)) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF075E54,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFF075E54),
                                        ),
                                      ),
                                      onPressed: () async {
                                        await _respondToFriendRequest(
                                          n,
                                          RequestStatus.declined,
                                        );
                                      },
                                      child: const Text('Decline'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF25D366,
                                        ),
                                      ),
                                      onPressed: () async {
                                        await _respondToFriendRequest(
                                          n,
                                          RequestStatus.accepted,
                                        );
                                      },
                                      child: const Text('Accept'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: Color(0xFF888888),
                          ),
                          onPressed: () =>
                              widget.repository.deleteNotification(n.id),
                        ),
                        onTap: () {
                          // Tapping marks individual notification as read by deleting/marking if desired,
                          // here we can trigger markNotificationsRead or just let it stay as is.
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Friend requests and alerts will appear here',
            style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
          ),
        ],
      ),
    );
  }
}
