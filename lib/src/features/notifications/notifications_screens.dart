part of '../../../main.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({
    super.key,
    required this.repository,
    required this.currentUser,
  });

  final ChatRepository repository;
  final AppUser currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => repository.markNotificationsRead(currentUser.id),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<AppNotification>>(
          stream: repository.watchNotifications(currentUser.id),
          initialData: sampleNotifications(),
          builder: (context, snapshot) {
            final notifications = snapshot.data ?? sampleNotifications();
            return ListView.separated(
              padding: const EdgeInsets.all(18),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return NotificationCard(notification: notification);
              },
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemCount: notifications.length,
            );
          },
        ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  const NotificationCard({super.key, required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final color = notification.accepted ? AppColors.accent : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: notification.read ? Colors.white : AppColors.softPurple,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint(color, 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              notification.accepted
                  ? Icons.check_circle_rounded
                  : Icons.person_add_alt_1_rounded,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  shortTime(notification.createdAt),
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            visualDensity: VisualDensity.compact,
            onPressed: () {},
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
