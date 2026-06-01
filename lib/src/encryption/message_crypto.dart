part of '../app.dart';

class EncryptedMessagePayload {
  const EncryptedMessagePayload({
    required this.ciphertext,
    required this.iv,
    this.algorithm = MessageEncryptionService.algorithm,
    this.version = MessageEncryptionService.version,
  });

  final String ciphertext;
  final String iv;
  final String algorithm;
  final int version;

  Map<String, Object> toMessageMap() {
    return {
      'ciphertext': ciphertext,
      'iv': iv,
      'algorithm': algorithm,
      'encryptionVersion': version,
    };
  }

  Map<String, Object> toPrefixedMap(String prefix) {
    final normalized = prefix.trim();
    return {
      '${normalized}Ciphertext': ciphertext,
      '${normalized}Iv': iv,
      '${normalized}Algorithm': algorithm,
      '${normalized}EncryptionVersion': version,
    };
  }

  static EncryptedMessagePayload? fromMessageData(Map<String, dynamic> data) {
    return _fromValues(
      ciphertext: data['ciphertext'],
      iv: data['iv'],
      algorithm: data['algorithm'],
      version: data['encryptionVersion'],
    );
  }

  static EncryptedMessagePayload? fromPrefixedData(
    Map<String, dynamic> data,
    String prefix,
  ) {
    final normalized = prefix.trim();
    return _fromValues(
      ciphertext: data['${normalized}Ciphertext'],
      iv: data['${normalized}Iv'],
      algorithm: data['${normalized}Algorithm'],
      version: data['${normalized}EncryptionVersion'],
    );
  }

  static EncryptedMessagePayload? _fromValues({
    required Object? ciphertext,
    required Object? iv,
    required Object? algorithm,
    required Object? version,
  }) {
    final ciphertextText = ciphertext as String?;
    final ivText = iv as String?;
    final algorithmText =
        (algorithm as String?) ?? MessageEncryptionService.algorithm;
    final versionNumber = version is int
        ? version
        : version is num
        ? version.toInt()
        : MessageEncryptionService.version;

    if (ciphertextText == null ||
        ciphertextText.isEmpty ||
        ivText == null ||
        ivText.isEmpty) {
      return null;
    }

    return EncryptedMessagePayload(
      ciphertext: ciphertextText,
      iv: ivText,
      algorithm: algorithmText,
      version: versionNumber,
    );
  }
}

class MessageEncryptionException implements Exception {
  const MessageEncryptionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MessageEncryptionService {
  MessageEncryptionService({
    FlutterSecureStorage? secureStorage,
    String storagePrefix = 'securechat',
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _storagePrefix = storagePrefix;

  static const algorithm = 'AES-256-GCM';
  static const version = 1;
  static const encryptedPreview = 'Encrypted message';
  static const decryptFailedPreview = 'Unable to decrypt message';

  final FlutterSecureStorage _secureStorage;
  final String _storagePrefix;
  final Map<String, Future<encrypt.Key?>> _keyCache =
      <String, Future<encrypt.Key?>>{};

  Future<EncryptedMessagePayload> encryptText({
    required String conversationId,
    required String text,
  }) async {
    final key = await _keyForConversation(conversationId, create: true);
    if (key == null) {
      throw const MessageEncryptionException('Chat key could not be created.');
    }

    final iv = encrypt.IV.fromSecureRandom(12);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.gcm),
    );
    final encrypted = encrypter.encrypt(
      text,
      iv: iv,
      associatedData: _associatedData(conversationId),
    );

    return EncryptedMessagePayload(ciphertext: encrypted.base64, iv: iv.base64);
  }

  Future<String> decryptText({
    required String conversationId,
    required EncryptedMessagePayload payload,
  }) async {
    if (payload.algorithm != algorithm || payload.version != version) {
      throw MessageEncryptionException(
        'Unsupported encrypted message format: ${payload.algorithm} v${payload.version}.',
      );
    }

    final key = await _keyForConversation(conversationId, create: false);
    if (key == null) {
      throw const MessageEncryptionException(
        'Missing secure chat key for this conversation.',
      );
    }

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.gcm),
    );
    return encrypter.decrypt(
      encrypt.Encrypted.fromBase64(payload.ciphertext),
      iv: encrypt.IV.fromBase64(payload.iv),
      associatedData: _associatedData(conversationId),
    );
  }

  Future<String> exportConversationKey(String conversationId) async {
    final key = await _keyForConversation(conversationId, create: false);
    if (key == null) {
      throw const MessageEncryptionException(
        'No chat key has been created for this conversation yet.',
      );
    }
    return key.base64;
  }

  Future<void> importConversationKey({
    required String conversationId,
    required String base64Key,
  }) async {
    final key = encrypt.Key.fromBase64(base64Key);
    if (key.length != 32) {
      throw const MessageEncryptionException(
        'AES-256 chat keys must be exactly 32 bytes.',
      );
    }

    await _secureStorage.write(
      key: _storageKeyForConversation(conversationId),
      value: base64Key,
    );
    _keyCache.remove(conversationId);
  }

  Future<encrypt.Key?> _keyForConversation(
    String conversationId, {
    required bool create,
  }) {
    final cached = _keyCache[conversationId];
    if (cached != null && create) {
      return cached.then((key) {
        if (key != null) return key;
        _keyCache.remove(conversationId);
        return _readOrCreateKey(conversationId, create: true);
      });
    }

    return _keyCache.putIfAbsent(conversationId, () async {
      return _readOrCreateKey(conversationId, create: create);
    });
  }

  Future<encrypt.Key?> _readOrCreateKey(
    String conversationId, {
    required bool create,
  }) async {
    final storageKey = _storageKeyForConversation(conversationId);
    final existing = await _secureStorage.read(key: storageKey);
    if (existing != null && existing.isNotEmpty) {
      return encrypt.Key.fromBase64(existing);
    }

    if (!create) return null;

    final key = encrypt.Key.fromSecureRandom(32);
    await _secureStorage.write(key: storageKey, value: key.base64);
    return key;
  }

  String _storageKeyForConversation(String conversationId) {
    final normalized = conversationId.trim().replaceAll(RegExp(r'\s+'), '_');
    return '$_storagePrefix.chat_key.$normalized';
  }

  Uint8List _associatedData(String conversationId) {
    return Uint8List.fromList(utf8.encode('conversation:$conversationId'));
  }
}
