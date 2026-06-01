import 'package:chat_app/src/app.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test(
    'encrypts text with unique IVs and decrypts with the chat key',
    () async {
      final encryption = MessageEncryptionService();

      final first = await encryption.encryptText(
        conversationId: 'alice_bob',
        text: 'hello',
      );
      final second = await encryption.encryptText(
        conversationId: 'alice_bob',
        text: 'hello',
      );

      expect(first.ciphertext, isNot('hello'));
      expect(first.ciphertext, isNot(second.ciphertext));
      expect(first.iv, isNot(second.iv));
      expect(
        await encryption.decryptText(
          conversationId: 'alice_bob',
          payload: first,
        ),
        'hello',
      );
    },
  );

  test('binds encrypted payloads to the conversation id', () async {
    final encryption = MessageEncryptionService();
    final payload = await encryption.encryptText(
      conversationId: 'alice_bob',
      text: 'private message',
    );
    final exportedKey = await encryption.exportConversationKey('alice_bob');
    await encryption.importConversationKey(
      conversationId: 'mallory_bob',
      base64Key: exportedKey,
    );

    expect(
      () => encryption.decryptText(
        conversationId: 'mallory_bob',
        payload: payload,
      ),
      throwsA(isA<Object>()),
    );
  });
}
