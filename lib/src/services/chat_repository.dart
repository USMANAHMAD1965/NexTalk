part of '../app.dart';

class ChatRepository {
  ChatRepository({required this.firebaseEnabled});

  ChatRepository.offline() : firebaseEnabled = false;

  final bool firebaseEnabled;
  final Map<String, firebase_auth.ConfirmationResult> _webPhoneConfirmations =
      <String, firebase_auth.ConfirmationResult>{};

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  firebase_auth.FirebaseAuth get _auth => firebase_auth.FirebaseAuth.instance;

  FirebaseStorage get _storage => FirebaseStorage.instance;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  Future<AppUser?> currentUser() async {
    if (!firebaseEnabled) return null;
    final user = _auth.currentUser;
    if (user == null) return null;
    if (_requiresEmailVerification(user)) {
      await _auth.signOut();
      return null;
    }
    return _appUserFromFirebaseUser(user);
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    if (!firebaseEnabled) {
      throw 'Firebase is not enabled. Sign in requires a real-time Firebase backend.';
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        await _auth.signOut();
        throw 'Please verify your email first. A new verification link was sent.';
      }
      return _appUserFromFirebaseUser(user);
    } on Object catch (error) {
      throw friendlyFirebaseError(error);
    }
  }

  Future<AppUser> createAccount({
    required String displayName,
    required String email,
    required String password,
  }) async {
    if (!firebaseEnabled) {
      throw 'Firebase is not enabled. Account creation requires a real-time Firebase backend.';
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = credential.user!;
      await firebaseUser.updateDisplayName(displayName.trim());
      final user = AppUser(
        id: firebaseUser.uid,
        displayName: displayName.trim(),
        email: email.trim(),
        initial: initialFromName(displayName),
        online: true,
      );
      await _db.collection('users').doc(user.id).set({
        'displayName': user.displayName,
        'email': user.email,
        'emailLower': user.email.toLowerCase(),
        'initial': user.initial,
        'online': false,
        'bio': user.bio,
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await firebaseUser.sendEmailVerification();
      return user;
    } on Object catch (error) {
      throw friendlyFirebaseError(error);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    if (!firebaseEnabled) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on Object catch (error) {
      throw friendlyFirebaseError(error);
    }
  }

  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (!firebaseEnabled) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      return;
    }

    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw 'Please sign in again before changing your password.';
    }

    try {
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on Object catch (error) {
      throw friendlyFirebaseError(error);
    }
  }

  Future<void> startPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required ValueChanged<AppUser> onAutoVerified,
    required ValueChanged<String> onFailed,
  }) async {
    if (!firebaseEnabled) {
      onFailed(
        'Firebase is not enabled. Phone OTP requires a real-time Firebase backend.',
      );
      return;
    }

    try {
      if (kIsWeb) {
        final confirmationResult = await _auth.signInWithPhoneNumber(
          phoneNumber.trim(),
        );
        _webPhoneConfirmations[confirmationResult.verificationId] =
            confirmationResult;
        onCodeSent(confirmationResult.verificationId);
        return;
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber.trim(),
        verificationCompleted: (credential) async {
          try {
            final user = await _signInWithPhoneCredential(credential);
            onAutoVerified(user);
          } on Object catch (error) {
            onFailed(friendlyFirebaseError(error));
          }
        },
        verificationFailed: (error) => onFailed(friendlyFirebaseError(error)),
        codeSent: (verificationId, _) => onCodeSent(verificationId),
        codeAutoRetrievalTimeout: (_) {},
      );
    } on Object catch (error) {
      onFailed(friendlyFirebaseError(error));
    }
  }

  Future<AppUser> confirmPhoneOtp({
    required String verificationId,
    required String smsCode,
    String? phoneNumber,
  }) async {
    if (!firebaseEnabled) {
      throw 'Firebase is not enabled. Confirming phone OTP requires a real-time Firebase backend.';
    }

    if (kIsWeb) {
      final confirmationResult = _webPhoneConfirmations.remove(verificationId);
      if (confirmationResult == null) {
        throw 'Request a fresh OTP code and try again.';
      }
      final credential = await confirmationResult.confirm(smsCode.trim());
      final user = credential.user;
      if (user == null) {
        throw 'Phone verification failed. Please try again.';
      }
      return _appUserFromFirebaseUser(user);
    }

    final credential = firebase_auth.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    return _signInWithPhoneCredential(credential);
  }

  Future<AppUser> updatePhoneUserDisplayName({
    required AppUser user,
    required String displayName,
  }) async {
    final name = displayName.trim();
    if (name.isEmpty) {
      throw 'Please enter your username.';
    }

    final updatedUser = user.copyWith(
      displayName: name,
      initial: initialFromName(name),
      online: true,
    );

    if (!firebaseEnabled) {
      throw 'Firebase is not enabled. Updating a phone user requires a real-time Firebase backend.';
    }

    final firebaseUser = _auth.currentUser;
    if (firebaseUser?.uid == user.id) {
      await firebaseUser?.updateDisplayName(name);
    }
    await _db.collection('users').doc(user.id).set({
      'displayName': updatedUser.displayName,
      'initial': updatedUser.initial,
      'email': updatedUser.email,
      'online': true,
      if (updatedUser.phoneNumber != null)
        'phoneNumber': updatedUser.phoneNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return updatedUser;
  }

  Future<void> signOut() async {
    if (!firebaseEnabled) return;
    await _auth.signOut();
  }

  Future<void> registerNotificationToken(String userId) async {
    if (!firebaseEnabled) return;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveMessagingToken(userId, token);
    }
  }

  Future<void> _saveMessagingToken(String userId, String token) {
    return _db.collection('users').doc(userId).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'lastFcmToken': token,
      'lastFcmTokenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Conversation> openConversation({
    required AppUser currentUser,
    required AppUser peer,
  }) async {
    if (!firebaseEnabled) {
      throw 'Firebase is not enabled. Opening a conversation requires a real-time Firebase backend.';
    }

    final conversationId = _conversationIdFor(currentUser.id, peer.id);
    final conversationRef = _db.collection('conversations').doc(conversationId);
    final existing = await conversationRef.get();

    if (!existing.exists) {
      await conversationRef.set({
        'participants': _sortedParticipantIds(currentUser.id, peer.id),
        'participantInfo': {
          currentUser.id: _userSummary(currentUser),
          peer.id: _userSummary(peer),
        },
        'lastMessage': '',
        'unreadCounts': {currentUser.id: 0, peer.id: 0},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await conversationRef.set({
        'participants': _sortedParticipantIds(currentUser.id, peer.id),
        'participantInfo': {
          currentUser.id: _userSummary(currentUser),
          peer.id: _userSummary(peer),
        },
      }, SetOptions(merge: true));
    }
    await _upsertConnection(currentUser: currentUser, peer: peer);

    final snapshot = await conversationRef.get();
    return Conversation.fromFirestore(snapshot, currentUser.id);
  }

  Future<AppUser?> findUserByEmail({
    required String email,
    required String currentUserId,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return null;

    if (!firebaseEnabled) {
      return null;
    }

    final users = await _db
        .collection('users')
        .where('emailLower', isEqualTo: normalizedEmail)
        .limit(1)
        .get();
    if (users.docs.isNotEmpty && users.docs.first.id != currentUserId) {
      return AppUser.fromFirestore(users.docs.first);
    }

    final legacyUsers = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();
    if (legacyUsers.docs.isNotEmpty &&
        legacyUsers.docs.first.id != currentUserId) {
      return AppUser.fromFirestore(legacyUsers.docs.first);
    }

    return null;
  }

  Future<Conversation> openConversationByEmail({
    required AppUser currentUser,
    required String email,
  }) async {
    final peer = await findUserByEmail(
      email: email,
      currentUserId: currentUser.id,
    );
    if (peer == null) {
      throw 'No registered user found with that email.';
    }
    return openConversation(currentUser: currentUser, peer: peer);
  }

  Future<AppUser?> findUserByPhone({
    required String phone,
    required String currentUserId,
  }) async {
    if (phone.trim().isEmpty) return null;
    final normalizedPhone = phone.trim();

    if (!firebaseEnabled) {
      return null;
    }

    final users = await _db
        .collection('users')
        .where('phoneNumber', isEqualTo: normalizedPhone)
        .limit(1)
        .get();
    if (users.docs.isNotEmpty && users.docs.first.id != currentUserId) {
      return AppUser.fromFirestore(users.docs.first);
    }
    return null;
  }

  Future<Conversation> openConversationByPhone({
    required AppUser currentUser,
    required String phone,
  }) async {
    final peer = await findUserByPhone(
      phone: phone,
      currentUserId: currentUser.id,
    );
    if (peer == null) {
      throw 'No registered user found with that phone number.';
    }
    return openConversation(currentUser: currentUser, peer: peer);
  }

  Future<void> createCallRequest({
    required String callId,
    required AppUser caller,
    required AppUser callee,
    required String type,
  }) async {
    if (!firebaseEnabled) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return;
    }

    final now = DateTime.now().toUtc();
    final expiresAt = now.add(const Duration(seconds: 45));
    await _db.collection('call_requests').doc(callId).set({
      'callId': callId,
      'callerId': caller.id,
      'calleeId': callee.id,
      'callerName': caller.displayName,
      'callerEmail': caller.email,
      'callerInitial': caller.initial,
      'callerOnline': caller.online,
      'callerPhoneNumber': caller.phoneNumber,
      'type': type,
      'status': 'ringing',
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expiresAt),
    }, SetOptions(merge: true));

    await _db.collection('notifications').add({
      'recipientId': callee.id,
      'senderId': caller.id,
      'type': type == 'video' ? 'incomingVideoCall' : 'incomingVoiceCall',
      'title': '${caller.displayName} is calling you',
      'body': type == 'video' ? 'Incoming video call' : 'Incoming voice call',
      'read': false,
      'createdAt': Timestamp.fromDate(now),
    });
  }

  Stream<List<CallRequest>> watchIncomingCallRequests(String currentUserId) {
    if (!firebaseEnabled) {
      return Stream<List<CallRequest>>.value(<CallRequest>[]);
    }

    return _db
        .collection('call_requests')
        .where('calleeId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .asyncMap((snapshot) async {
          final requests = snapshot.docs
              .map(CallRequest.fromFirestore)
              .toList();

          for (final request in requests) {
            if (request.status == 'ringing' && !request.isRinging) {
              await _rejectExpiredCallRequestIfNeeded(request);
            }
          }

          return requests.where((request) => request.isRinging).toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        });
  }

  Stream<CallRequest?> watchCallRequest(String callId) {
    if (!firebaseEnabled) {
      return Stream<CallRequest?>.value(null);
    }

    return _db.collection('call_requests').doc(callId).snapshots().asyncMap((
      snapshot,
    ) async {
      if (!snapshot.exists) return null;
      final request = CallRequest.fromFirestore(snapshot);
      if (request.status == 'ringing' && !request.isRinging) {
        await _rejectExpiredCallRequestIfNeeded(request);
        return request.copyWith(status: 'rejected');
      }
      return request;
    });
  }

  Future<void> _rejectExpiredCallRequestIfNeeded(CallRequest request) async {
    if (request.status != 'ringing' || request.isRinging) return;

    await _db.collection('call_requests').doc(request.callId).set({
      'status': 'rejected',
      'updatedAt': Timestamp.fromDate(DateTime.now().toUtc()),
    }, SetOptions(merge: true));
  }

  Future<void> acceptCallRequest(String callId) async {
    if (!firebaseEnabled) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return;
    }

    await _db.collection('call_requests').doc(callId).set({
      'status': 'accepted',
      'updatedAt': Timestamp.fromDate(DateTime.now().toUtc()),
    }, SetOptions(merge: true));
  }

  Future<void> rejectCallRequest(String callId) async {
    if (!firebaseEnabled) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return;
    }

    await _db.collection('call_requests').doc(callId).set({
      'status': 'rejected',
      'updatedAt': Timestamp.fromDate(DateTime.now().toUtc()),
    }, SetOptions(merge: true));
  }

  Future<void> endCallRequest(String callId) async {
    if (!firebaseEnabled) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return;
    }

    await _db.collection('call_requests').doc(callId).set({
      'status': 'ended',
      'updatedAt': Timestamp.fromDate(DateTime.now().toUtc()),
    }, SetOptions(merge: true));
  }

  Future<void> cleanupExpiredCallRequests() async {
    if (!firebaseEnabled) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return;
    }

    final now = DateTime.now().toUtc();
    final ringingSnapshot = await _db
        .collection('call_requests')
        .where('status', isEqualTo: 'ringing')
        .get();

    final expiredDocs = ringingSnapshot.docs.where((doc) {
      final expiresAt = dateFromFirestore(doc.data()['expiresAt']);
      return expiresAt.isBefore(now) || expiresAt.isAtSameMomentAs(now);
    }).toList();

    if (expiredDocs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in expiredDocs) {
      batch.update(doc.reference, {
        'status': 'rejected',
        'updatedAt': Timestamp.fromDate(now),
      });
    }
    await batch.commit();
  }

  Stream<List<Conversation>> watchConversations(String currentUserId) {
    if (!firebaseEnabled) {
      return const Stream<List<Conversation>>.empty();
    }

    return _db
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          final items =
              snapshot.docs
                  .map((doc) => Conversation.fromFirestore(doc, currentUserId))
                  .toList()
                ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return items;
        });
  }

  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    if (!firebaseEnabled) {
      return const Stream<List<ChatMessage>>.empty();
    }

    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(ChatMessage.fromFirestore).toList(),
        );
  }

  Future<void> sendMessage({
    required Conversation conversation,
    required AppUser sender,
    required String text,
  }) async {
    if (!firebaseEnabled) {
      throw 'Firebase is not enabled. Sending a message requires a real-time Firebase backend.';
    }

    final conversationRef = _db
        .collection('conversations')
        .doc(conversation.id);
    await conversationRef.set({
      'participants': _sortedParticipantIds(sender.id, conversation.peer.id),
      'participantInfo': {
        sender.id: _userSummary(sender),
        conversation.peer.id: _userSummary(conversation.peer),
      },
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _upsertConnection(currentUser: sender, peer: conversation.peer);
    await conversationRef.collection('messages').add({
      'senderId': sender.id,
      'text': text,
      'type': 'text',
      'status': 'sent',
      'reactions': <String, int>{},
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendRichMessage({
    required Conversation conversation,
    required AppUser sender,
    required ChatMessage message,
  }) async {
    if (!firebaseEnabled) {
      throw 'Firebase is not enabled. Sending a rich message requires a real-time Firebase backend.';
    }

    final preview = _previewForMessage(message);
    final conversationRef = _db
        .collection('conversations')
        .doc(conversation.id);
    await conversationRef.set({
      'participants': _sortedParticipantIds(sender.id, conversation.peer.id),
      'participantInfo': {
        sender.id: _userSummary(sender),
        conversation.peer.id: _userSummary(conversation.peer),
      },
      'lastMessage': preview,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _upsertConnection(currentUser: sender, peer: conversation.peer);
    await conversationRef.collection('messages').add(_messagePayload(message));
  }

  Future<void> reactToMessage({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) async {
    if (!firebaseEnabled) {
      throw 'Firebase is not enabled. Reacting to messages requires a real-time Firebase backend.';
    }

    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .set({
          'reactions': {emoji: FieldValue.increment(1)},
        }, SetOptions(merge: true));
  }

  Future<void> markMessagesRead(String conversationId) async {
    if (!firebaseEnabled) {
      throw 'Firebase is not enabled. Marking messages as read requires a real-time Firebase backend.';
    }
    await _db.collection('conversations').doc(conversationId).set({
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> sendVoiceMessage({
    required Conversation conversation,
    required AppUser sender,
    required String localAudioPath,
    required Duration duration,
  }) async {
    if (!firebaseEnabled) {
      throw 'Firebase is not enabled. Sending a voice message requires a real-time Firebase backend.';
    }

    final conversationRef = _db
        .collection('conversations')
        .doc(conversation.id);
    final messageRef = conversationRef.collection('messages').doc();
    final storagePath =
        'voice_messages/${conversation.id}/${messageRef.id}.m4a';
    final bytes = await XFile(localAudioPath).readAsBytes();
    final uploadTask = await _storage
        .ref(storagePath)
        .putData(bytes, SettableMetadata(contentType: 'audio/mp4'));
    final audioUrl = await uploadTask.ref.getDownloadURL();

    await conversationRef.set({
      'participants': _sortedParticipantIds(sender.id, conversation.peer.id),
      'participantInfo': {
        sender.id: _userSummary(sender),
        conversation.peer.id: _userSummary(conversation.peer),
      },
      'lastMessage': 'Voice message',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _upsertConnection(currentUser: sender, peer: conversation.peer);
    await messageRef.set({
      'senderId': sender.id,
      'text': '',
      'type': 'voice',
      'status': 'sent',
      'audioUrl': audioUrl,
      'audioDurationMs': duration.inMilliseconds,
      'storagePath': storagePath,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static String _previewForMessage(ChatMessage message) {
    return switch (message.type) {
      MessageType.text => message.text,
      MessageType.image => 'Image',
      MessageType.video => 'Video',
      MessageType.document => message.mediaTitle ?? 'Document',
      MessageType.audio => 'Audio',
      MessageType.voice => 'Voice message',
      MessageType.gif => 'GIF',
      MessageType.sticker => 'Sticker',
      MessageType.location => message.mediaTitle ?? 'Location',
      MessageType.contact => message.mediaTitle ?? 'Contact',
      MessageType.poll => message.text.isEmpty ? 'Poll' : message.text,
    };
  }

  static Map<String, Object?> _messagePayload(ChatMessage message) {
    return {
      'senderId': message.senderId,
      'text': message.text,
      'type': message.type.name,
      'status': MessageStatus.sent.name,
      'audioUrl': message.audioUrl,
      'audioDurationMs': message.audioDuration.inMilliseconds,
      'storagePath': message.storagePath,
      'mediaUrl': message.mediaUrl,
      'mediaTitle': message.mediaTitle,
      'caption': message.caption,
      'replyToText': message.replyToText,
      'replyToSender': message.replyToSender,
      'reactions': message.reactions,
      'forwarded': message.forwarded,
      'starred': message.starred,
      'pinned': message.pinned,
      'ephemeral': message.ephemeral,
      'viewOnce': message.viewOnce,
      'pollOptions': message.pollOptions
          .map((option) => option.toMap())
          .toList(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> _upsertConnection({
    required AppUser currentUser,
    required AppUser peer,
  }) async {
    if (!firebaseEnabled) return;

    await _db
        .collection('connections')
        .doc(_conversationIdFor(currentUser.id, peer.id))
        .set({
          'participants': _sortedParticipantIds(currentUser.id, peer.id),
          'participantInfo': {
            currentUser.id: _userSummary(currentUser),
            peer.id: _userSummary(peer),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  static String _conversationIdFor(String firstUserId, String secondUserId) {
    return _sortedParticipantIds(firstUserId, secondUserId).join('_');
  }

  static List<String> _sortedParticipantIds(
    String firstUserId,
    String secondUserId,
  ) {
    return <String>[firstUserId, secondUserId]..sort();
  }

  static Map<String, Object?> _userSummary(AppUser user) {
    return {
      'displayName': user.displayName,
      'email': user.email,
      'initial': user.initial,
      'online': user.online,
      'phoneNumber': user.phoneNumber,
    };
  }

  static AppUser _peerFromParticipantData(
    Map<String, dynamic> data,
    String currentUserId,
  ) {
    final participants =
        (data['participants'] as List?)?.whereType<String>().toList() ??
        <String>[];
    final peerId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => 'friend',
    );
    final participantInfoRaw = data['participantInfo'];
    final participantInfo = participantInfoRaw is Map
        ? Map<String, dynamic>.from(participantInfoRaw)
        : <String, dynamic>{};
    final peerInfoRaw = participantInfo[peerId];
    final peerInfo = peerInfoRaw is Map
        ? Map<String, dynamic>.from(peerInfoRaw)
        : <String, dynamic>{};
    final displayName = (peerInfo['displayName'] as String?) ?? 'Friend';
    final phoneNumber = peerInfo['phoneNumber'] as String?;
    final email =
        (peerInfo['email'] as String?) ?? phoneNumber ?? 'friend@example.com';

    return AppUser(
      id: peerId,
      displayName: displayName,
      email: email,
      initial: (peerInfo['initial'] as String?) ?? initialFromName(displayName),
      online: peerInfo['online'] as bool? ?? false,
      phoneNumber: phoneNumber,
    );
  }

  Stream<List<AppUser>> watchFindPeople(String currentUserId) {
    if (!firebaseEnabled) {
      return const Stream<List<AppUser>>.empty();
    }

    return _db.collection('users').snapshots().map((snapshot) {
      final users =
          snapshot.docs
              .map(AppUser.fromFirestore)
              .where((user) => user.id != currentUserId)
              .toList()
            ..sort((a, b) => a.displayName.compareTo(b.displayName));
      return users;
    });
  }

  Stream<List<AppUser>> watchFriends(String currentUserId) {
    if (!firebaseEnabled) {
      return const Stream<List<AppUser>>.empty();
    }

    return _db
        .collection('connections')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          final friends =
              snapshot.docs
                  .map(
                    (doc) =>
                        _peerFromParticipantData(doc.data(), currentUserId),
                  )
                  .toList()
                ..sort((a, b) => a.displayName.compareTo(b.displayName));
          return friends;
        });
  }

  Future<void> sendFriendRequest(AppUser currentUser, AppUser target) async {
    if (!firebaseEnabled) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return;
    }

    final requestRef = _db.collection('friendRequests').doc();
    await requestRef.set({
      'fromUid': currentUser.id,
      'fromName': currentUser.displayName,
      'fromEmail': currentUser.email,
      'toUid': target.id,
      'toName': target.displayName,
      'toEmail': target.email,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('notifications').add({
      'userId': target.id,
      'title': 'New Friend Request',
      'body': '${currentUser.displayName} sent you a friend request',
      'type': 'friendRequest',
      'friendRequestId': requestRef.id,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<FriendRequest>> watchFriendRequests(
    String currentUserId, {
    required bool sent,
  }) {
    if (!firebaseEnabled) {
      return const Stream<List<FriendRequest>>.empty();
    }

    final field = sent ? 'fromUid' : 'toUid';
    return _db
        .collection('friendRequests')
        .where(field, isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          final requests =
              snapshot.docs
                  .map((doc) => FriendRequest.fromFirestore(doc, sent))
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  Future<Conversation?> updateFriendRequest({
    required FriendRequest request,
    required RequestStatus status,
    required AppUser currentUser,
  }) async {
    if (!firebaseEnabled) {
      throw 'Firebase is not enabled. Updating a friend request requires a real-time Firebase backend.';
    }

    await _db.collection('friendRequests').doc(request.id).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (status != RequestStatus.accepted) return null;

    final conversation = await openConversation(
      currentUser: currentUser,
      peer: request.user,
    );
    await _db.collection('notifications').add({
      'userId': request.user.id,
      'title': 'Friend Request Accepted',
      'body': '${currentUser.displayName} accepted your friend request',
      'type': 'friendAccepted',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return conversation;
  }

  Stream<List<AppNotification>> watchNotifications(String currentUserId) {
    if (!firebaseEnabled) {
      return const Stream<List<AppNotification>>.empty();
    }

    return _db
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          final notifications =
              snapshot.docs.map(AppNotification.fromFirestore).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notifications;
        });
  }

  Future<FriendRequest?> fetchFriendRequestById(
    String requestId,
    String currentUserId,
  ) async {
    if (!firebaseEnabled) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return null;
    }

    final doc = await _db.collection('friendRequests').doc(requestId).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    final sentByMe = data['fromUid'] == currentUserId;
    return FriendRequest.fromFirestore(doc, sentByMe);
  }

  Future<void> markNotificationsRead(String currentUserId) async {
    if (!firebaseEnabled) return;
    final snapshot = await _db
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .where('read', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    if (!firebaseEnabled) return;
    await _db.collection('notifications').doc(notificationId).delete();
  }

  bool _requiresEmailVerification(firebase_auth.User user) {
    final hasEmailProvider = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
    return hasEmailProvider && !user.emailVerified;
  }

  Future<AppUser> _signInWithPhoneCredential(
    firebase_auth.PhoneAuthCredential credential,
  ) async {
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw 'Phone verification failed. Please try again.';
    }
    return _appUserFromFirebaseUser(user);
  }

  Future<AppUser> _appUserFromFirebaseUser(firebase_auth.User user) async {
    final docRef = _db.collection('users').doc(user.uid);
    final doc = await docRef.get();
    if (doc.exists) {
      final existingUser = AppUser.fromFirestore(doc);
      await docRef.set({
        if ((user.email ?? existingUser.email).contains('@'))
          'emailLower': (user.email ?? existingUser.email).toLowerCase(),
        if (user.email != null) 'email': user.email,
        if (user.phoneNumber != null) 'phoneNumber': user.phoneNumber,
        if (user.email != null) 'emailVerified': user.emailVerified,
        'online': true,
      }, SetOptions(merge: true));
      return existingUser.copyWith(
        email: user.email ?? existingUser.email,
        phoneNumber: user.phoneNumber ?? existingUser.phoneNumber,
        online: true,
      );
    }

    final email = user.email;
    final phoneNumber = user.phoneNumber;
    final displayName =
        user.displayName ?? email?.split('@').first ?? phoneNumber ?? 'Friend';
    final appUser = AppUser(
      id: user.uid,
      displayName: displayName,
      email: email ?? phoneNumber ?? 'friend@example.com',
      initial: initialFromName(displayName),
      online: true,
      phoneNumber: phoneNumber,
    );
    final userData = <String, Object?>{
      'displayName': appUser.displayName,
      'email': appUser.email,
      'initial': appUser.initial,
      'online': true,
      'bio': appUser.bio,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (email != null) {
      userData['emailLower'] = email.toLowerCase();
      userData['emailVerified'] = user.emailVerified;
    }
    if (phoneNumber != null) {
      userData['phoneNumber'] = phoneNumber;
    }
    await docRef.set(userData, SetOptions(merge: true));
    return appUser;
  }
}
