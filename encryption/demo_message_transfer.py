from __future__ import annotations

try:
    from .message_crypto import decrypt_message, encrypt_message, generate_key
except ImportError:
    from message_crypto import decrypt_message, encrypt_message, generate_key


def main() -> None:
    conversation_id = "alice_bob"
    key = generate_key()

    firestore_payload = encrypt_message(
        "Meet after class.",
        key,
        conversation_id,
    )
    print("Stored payload:", firestore_payload)

    delivered_message = decrypt_message(firestore_payload, key, conversation_id)
    print("Delivered message:", delivered_message)


if __name__ == "__main__":
    main()
