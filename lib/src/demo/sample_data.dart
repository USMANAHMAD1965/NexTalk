part of '../../main.dart';

final sampleCurrentUser = AppUser(
  id: 'demo-current-user',
  displayName: 'Programmer',
  email: 'dearprogrammerofficial@gmail.com',
  initial: 'P',
  online: true,
  bio: 'Online',
);

List<AppUser> samplePeople() {
  return const [
    AppUser(
      id: 'john',
      displayName: 'John',
      email: 'john@gmail.com',
      initial: 'J',
      online: false,
    ),
    AppUser(
      id: 'programmer',
      displayName: 'Programmer',
      email: 'programmer@gmail.com',
      initial: 'P',
      online: true,
    ),
    AppUser(
      id: 'dear-programmer',
      displayName: 'Dear Programmer',
      email: 'programmermentor@gmail.com',
      initial: 'D',
      online: true,
    ),
    AppUser(
      id: 'alex',
      displayName: 'Alex',
      email: 'alex@gmail.com',
      initial: 'A',
      online: true,
    ),
  ];
}

List<AppUser> sampleFriends() {
  return samplePeople().where((user) => user.id != 'programmer').toList();
}

List<Conversation> sampleConversations() {
  final now = DateTime.now();
  final people = samplePeople();
  return [
    Conversation(
      id: 'demo-dear-programmer',
      peer: people[2],
      lastMessage: 'Shared a product launch checklist',
      updatedAt: now.subtract(const Duration(minutes: 5)),
      unreadCount: 3,
    ),
    Conversation(
      id: 'demo-alex',
      peer: people[3],
      lastMessage: 'Thank You, Keep Supporting',
      updatedAt: now.subtract(const Duration(hours: 1)),
      unreadCount: 1,
    ),
    Conversation(
      id: 'demo-john',
      peer: people[0],
      lastMessage: 'Hi',
      updatedAt: now.subtract(const Duration(days: 2)),
    ),
  ];
}

List<ChatMessage> sampleMessages() {
  final now = DateTime.now();
  return [
    ChatMessage(
      id: 'm1',
      senderId: 'alex',
      text: 'Morning! Are we still shipping the new chat experience today?',
      createdAt: now.subtract(const Duration(minutes: 34)),
      reactions: const {'👍': 2},
    ),
    ChatMessage(
      id: 'm2',
      senderId: sampleCurrentUser.id,
      text:
          'Yes. I added realtime events, offline queue notes, and call entry points.',
      createdAt: now.subtract(const Duration(minutes: 32)),
      status: MessageStatus.read,
    ),
    ChatMessage(
      id: 'm3',
      senderId: sampleCurrentUser.id,
      text: 'Launch checklist.pdf',
      type: MessageType.document,
      mediaTitle: 'Launch checklist.pdf',
      caption: 'Docs, media, notifications, and security review.',
      createdAt: now.subtract(const Duration(minutes: 29)),
      status: MessageStatus.delivered,
    ),
    ChatMessage(
      id: 'm4',
      senderId: 'alex',
      text: 'Where should we meet the design team?',
      type: MessageType.location,
      mediaTitle: 'Office HQ',
      caption: 'Live location active for 15 minutes',
      createdAt: now.subtract(const Duration(minutes: 25)),
    ),
    ChatMessage(
      id: 'm5',
      senderId: 'alex',
      text: 'Which encryption option should be the default for production?',
      type: MessageType.poll,
      pollOptions: const [
        PollOption(label: 'Signal Protocol', votes: 8, selectedByMe: true),
        PollOption(label: 'AES + RSA only', votes: 2),
        PollOption(label: 'Provider managed', votes: 1),
      ],
      createdAt: now.subtract(const Duration(minutes: 21)),
    ),
    ChatMessage(
      id: 'm6',
      senderId: sampleCurrentUser.id,
      text:
          'Signal Protocol for production. AES/RSA alone is not enough for modern E2EE UX.',
      replyToSender: 'Alex',
      replyToText:
          'Which encryption option should be the default for production?',
      createdAt: now.subtract(const Duration(minutes: 17)),
      status: MessageStatus.read,
      reactions: const {'❤️': 1, '🙏': 1},
    ),
    ChatMessage(
      id: 'm7',
      senderId: sampleCurrentUser.id,
      text: '',
      type: MessageType.voice,
      audioDuration: const Duration(seconds: 18),
      createdAt: now.subtract(const Duration(minutes: 12)),
      status: MessageStatus.read,
    ),
    ChatMessage(
      id: 'm8',
      senderId: 'alex',
      text: 'I will forward this to the group after QA signs off.',
      forwarded: true,
      createdAt: now.subtract(const Duration(minutes: 7)),
    ),
    ChatMessage(
      id: 'm9',
      senderId: sampleCurrentUser.id,
      text:
          'Perfect. I am adding search, reactions, reply preview, attachment actions, and menu controls now.',
      createdAt: now.subtract(const Duration(minutes: 4)),
      status: MessageStatus.sending,
    ),
  ];
}

List<FriendRequest> sampleRequests({required bool sentByMe}) {
  final now = DateTime.now();
  final users = samplePeople();
  if (sentByMe) {
    return [
      FriendRequest(
        id: 'demo-sent-1',
        user: users[0],
        createdAt: now.subtract(const Duration(minutes: 10)),
        status: RequestStatus.pending,
        sentByMe: true,
      ),
      FriendRequest(
        id: 'demo-sent-2',
        user: users[1],
        createdAt: now.subtract(const Duration(hours: 1)),
        status: RequestStatus.pending,
        sentByMe: true,
      ),
      FriendRequest(
        id: 'demo-sent-3',
        user: users[3],
        createdAt: now.subtract(const Duration(days: 1)),
        status: RequestStatus.accepted,
        sentByMe: true,
      ),
    ];
  }

  return [
    FriendRequest(
      id: 'demo-received-1',
      user: users[0],
      createdAt: now.subtract(const Duration(minutes: 3)),
      status: RequestStatus.pending,
    ),
    FriendRequest(
      id: 'demo-received-2',
      user: users[2],
      createdAt: now.subtract(const Duration(hours: 2)),
      status: RequestStatus.pending,
    ),
  ];
}

List<AppNotification> sampleNotifications() {
  final now = DateTime.now();
  return [
    AppNotification(
      id: 'n1',
      title: 'Friend Request Accepted',
      body: 'John accepted your friend request',
      createdAt: now.subtract(const Duration(minutes: 3)),
      accepted: true,
    ),
    AppNotification(
      id: 'n2',
      title: 'New Friend Request',
      body: 'Dear Programmer sent you a friend request',
      createdAt: now.subtract(const Duration(hours: 1)),
    ),
    AppNotification(
      id: 'n3',
      title: 'Friend Request Accepted',
      body: 'Alex accepted your friend request',
      createdAt: now.subtract(const Duration(days: 1)),
      accepted: true,
      read: true,
    ),
  ];
}
