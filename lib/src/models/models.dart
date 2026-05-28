part of '../../main.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.initial,
    this.online = false,
    this.bio = 'Ready to chat',
    this.phoneNumber,
  });

  final String id;
  final String displayName;
  final String email;
  final String initial;
  final bool online;
  final String bio;
  final String? phoneNumber;

  AppUser copyWith({
    String? id,
    String? displayName,
    String? email,
    String? initial,
    bool? online,
    String? bio,
    String? phoneNumber,
  }) {
    return AppUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      initial: initial ?? this.initial,
      online: online ?? this.online,
      bio: bio ?? this.bio,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final displayName = (data['displayName'] as String?)?.trim();
    final email = (data['email'] as String?)?.trim();
    final phoneNumber = (data['phoneNumber'] as String?)?.trim();
    return AppUser(
      id: doc.id,
      displayName: displayName?.isNotEmpty == true ? displayName! : 'Friend',
      email: email?.isNotEmpty == true
          ? email!
          : phoneNumber?.isNotEmpty == true
          ? phoneNumber!
          : 'friend@example.com',
      initial:
          (data['initial'] as String?) ??
          initialFromName(displayName ?? email ?? 'F'),
      online: data['online'] as bool? ?? false,
      bio: (data['bio'] as String?) ?? 'Ready to chat',
      phoneNumber: phoneNumber,
    );
  }
}

class Conversation {
  const Conversation({
    required this.id,
    required this.peer,
    required this.lastMessage,
    required this.updatedAt,
    this.unreadCount = 0,
  });

  final String id;
  final AppUser peer;
  final String lastMessage;
  final DateTime updatedAt;
  final int unreadCount;

  factory Conversation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String currentUserId,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final participants =
        (data['participants'] as List?)?.whereType<String>().toList() ??
        <String>[];
    final peerId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => (data['peerId'] as String?) ?? 'friend',
    );
    final participantInfoRaw = data['participantInfo'];
    final participantInfo = participantInfoRaw is Map
        ? Map<String, dynamic>.from(participantInfoRaw)
        : <String, dynamic>{};
    final peerInfoRaw = participantInfo[peerId];
    final peerInfo = peerInfoRaw is Map
        ? Map<String, dynamic>.from(peerInfoRaw)
        : <String, dynamic>{};
    final unreadCountsRaw = data['unreadCounts'];
    final unreadCounts = unreadCountsRaw is Map
        ? Map<String, dynamic>.from(unreadCountsRaw)
        : <String, dynamic>{};
    final unreadValue = unreadCounts[currentUserId];
    final peerName =
        (peerInfo['displayName'] as String?) ??
        (data['peerName'] as String?) ??
        'Friend';
    final peerPhone = peerInfo['phoneNumber'] as String?;
    final peerEmail =
        (peerInfo['email'] as String?) ??
        (data['peerEmail'] as String?) ??
        peerPhone ??
        'friend@example.com';
    final lastMessage = (data['lastMessage'] as String?)?.trim();

    return Conversation(
      id: doc.id,
      peer: AppUser(
        id: peerId,
        displayName: peerName,
        email: peerEmail,
        initial:
            (peerInfo['initial'] as String?) ??
            (data['peerInitial'] as String?) ??
            initialFromName(peerName),
        online:
            (peerInfo['online'] as bool?) ??
            (data['peerOnline'] as bool?) ??
            false,
        phoneNumber: peerPhone,
      ),
      lastMessage: lastMessage?.isNotEmpty == true
          ? lastMessage!
          : 'Start a conversation',
      updatedAt: dateFromFirestore(data['updatedAt']),
      unreadCount: unreadValue is int
          ? unreadValue
          : unreadValue is num
          ? unreadValue.toInt()
          : data['unreadCount'] as int? ?? 0,
    );
  }
}

enum MessageType {
  text,
  image,
  video,
  document,
  audio,
  voice,
  gif,
  sticker,
  location,
  contact,
  poll,
}

enum MessageStatus { sending, sent, delivered, read, failed }

enum PresenceState { online, offline, typing, recording }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.type = MessageType.text,
    this.status = MessageStatus.read,
    this.audioUrl,
    this.audioDuration = Duration.zero,
    this.storagePath,
    this.mediaUrl,
    this.mediaTitle,
    this.caption,
    this.replyToText,
    this.replyToSender,
    this.reactions = const <String, int>{},
    this.forwarded = false,
    this.starred = false,
    this.pinned = false,
    this.ephemeral = false,
    this.viewOnce = false,
    this.pollOptions = const <PollOption>[],
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final MessageType type;
  final MessageStatus status;
  final String? audioUrl;
  final Duration audioDuration;
  final String? storagePath;
  final String? mediaUrl;
  final String? mediaTitle;
  final String? caption;
  final String? replyToText;
  final String? replyToSender;
  final Map<String, int> reactions;
  final bool forwarded;
  final bool starred;
  final bool pinned;
  final bool ephemeral;
  final bool viewOnce;
  final List<PollOption> pollOptions;

  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final typeName = (data['type'] as String?) ?? 'text';
    final statusName = (data['status'] as String?) ?? 'read';
    final durationMs = data['audioDurationMs'];
    final reactionsRaw = data['reactions'];
    final pollOptionsRaw = data['pollOptions'];
    return ChatMessage(
      id: doc.id,
      senderId: (data['senderId'] as String?) ?? 'friend',
      text: (data['text'] as String?) ?? '',
      createdAt: dateFromFirestore(data['createdAt']),
      type: MessageType.values.firstWhere(
        (type) => type.name == typeName,
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (status) => status.name == statusName,
        orElse: () => MessageStatus.read,
      ),
      audioUrl: data['audioUrl'] as String?,
      audioDuration: Duration(
        milliseconds: durationMs is int
            ? durationMs
            : durationMs is num
            ? durationMs.toInt()
            : 0,
      ),
      storagePath: data['storagePath'] as String?,
      mediaUrl: data['mediaUrl'] as String?,
      mediaTitle: data['mediaTitle'] as String?,
      caption: data['caption'] as String?,
      replyToText: data['replyToText'] as String?,
      replyToSender: data['replyToSender'] as String?,
      reactions: reactionsRaw is Map
          ? reactionsRaw.map(
              (key, value) =>
                  MapEntry(key.toString(), value is num ? value.toInt() : 1),
            )
          : const <String, int>{},
      forwarded: data['forwarded'] as bool? ?? false,
      starred: data['starred'] as bool? ?? false,
      pinned: data['pinned'] as bool? ?? false,
      ephemeral: data['ephemeral'] as bool? ?? false,
      viewOnce: data['viewOnce'] as bool? ?? false,
      pollOptions: pollOptionsRaw is List
          ? pollOptionsRaw
                .whereType<Map>()
                .map(
                  (item) => PollOption.fromMap(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const <PollOption>[],
    );
  }
}

class PollOption {
  const PollOption({
    required this.label,
    required this.votes,
    this.selectedByMe = false,
  });

  final String label;
  final int votes;
  final bool selectedByMe;

  factory PollOption.fromMap(Map<String, dynamic> data) {
    final votes = data['votes'];
    return PollOption(
      label: (data['label'] as String?) ?? 'Option',
      votes: votes is num ? votes.toInt() : 0,
      selectedByMe: data['selectedByMe'] as bool? ?? false,
    );
  }

  Map<String, Object?> toMap() => {
    'label': label,
    'votes': votes,
    'selectedByMe': selectedByMe,
  };
}

enum RequestStatus { pending, accepted, declined }

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.user,
    required this.createdAt,
    required this.status,
    this.sentByMe = false,
  });

  final String id;
  final AppUser user;
  final DateTime createdAt;
  final RequestStatus status;
  final bool sentByMe;

  factory FriendRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    bool sentByMe,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final prefix = sentByMe ? 'to' : 'from';
    final name = (data['${prefix}Name'] as String?) ?? 'Friend';
    final email = (data['${prefix}Email'] as String?) ?? 'friend@example.com';
    final statusText = (data['status'] as String?) ?? 'pending';
    return FriendRequest(
      id: doc.id,
      sentByMe: sentByMe,
      createdAt: dateFromFirestore(data['createdAt']),
      status: switch (statusText) {
        'accepted' => RequestStatus.accepted,
        'declined' => RequestStatus.declined,
        _ => RequestStatus.pending,
      },
      user: AppUser(
        id: (data['${prefix}Uid'] as String?) ?? doc.id,
        displayName: name,
        email: email,
        initial: initialFromName(name),
        online: data['${prefix}Online'] as bool? ?? false,
      ),
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.accepted = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final bool accepted;

  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return AppNotification(
      id: doc.id,
      title: (data['title'] as String?) ?? 'Notification',
      body: (data['body'] as String?) ?? '',
      createdAt: dateFromFirestore(data['createdAt']),
      read: data['read'] as bool? ?? false,
      accepted: data['type'] == 'friendAccepted',
    );
  }
}
