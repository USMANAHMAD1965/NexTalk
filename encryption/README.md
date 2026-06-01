# SecureChat Encryption Module

This folder provides Python AES-256-GCM helpers for SecureChat message transfer.
It matches the Flutter payload format used in Firestore:

```json
{
  "ciphertext": "base64 ciphertext plus auth tag",
  "iv": "base64 12 byte nonce",
  "algorithm": "AES-256-GCM",
  "encryptionVersion": 1
}
```

## Install

```powershell
python -m pip install -r encryption\requirements.txt
```

## Use

```powershell
$key = python -m encryption.message_crypto generate-key
$payload = python -m encryption.message_crypto encrypt --key $key --conversation-id "userA_userB" --message "hello"
python -m encryption.message_crypto decrypt --key $key --conversation-id "userA_userB" --payload-json $payload
```

The same `conversation_id` must be used for encryption and decryption because
it is authenticated associated data. If the conversation id, key, IV, or
ciphertext changes, decryption fails.

## Notes

- Generate one 32-byte base64 chat key per conversation.
- Share/import the chat key through a secure out-of-band process. Do not store
  plaintext chat keys in Firebase.
- Firebase should store only ciphertext/IV payload fields for message bodies.
