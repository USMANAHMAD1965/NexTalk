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
      lastMessage: 'who are you?',
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
      text: 'I am fine, what about you? I hope you are doing well!',
      createdAt: now.subtract(const Duration(minutes: 18)),
    ),
    ChatMessage(
      id: 'm2',
      senderId: sampleCurrentUser.id,
      text: 'How are you?',
      createdAt: now.subtract(const Duration(minutes: 16)),
    ),
    ChatMessage(
      id: 'm3',
      senderId: sampleCurrentUser.id,
      text: 'I am also good.',
      createdAt: now.subtract(const Duration(minutes: 15)),
    ),
    ChatMessage(
      id: 'm4',
      senderId: sampleCurrentUser.id,
      text: 'Please subscribe my channel.',
      createdAt: now.subtract(const Duration(minutes: 14)),
    ),
    ChatMessage(
      id: 'm5',
      senderId: 'alex',
      text: 'I liked your content.',
      createdAt: now.subtract(const Duration(minutes: 12)),
    ),
    ChatMessage(
      id: 'm6',
      senderId: 'alex',
      text: 'Keep it up...',
      createdAt: now.subtract(const Duration(minutes: 11)),
    ),
    ChatMessage(
      id: 'm7',
      senderId: sampleCurrentUser.id,
      text: 'Thank You, Keep Supporting',
      createdAt: now.subtract(const Duration(minutes: 10)),
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
