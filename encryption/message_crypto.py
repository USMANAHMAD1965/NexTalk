"""AES-256-GCM helpers for SecureChat message transfer payloads.

The Flutter app stores message bodies as:
    ciphertext, iv, algorithm, encryptionVersion

This module uses the same payload shape so Python services, scripts, or tests
can encrypt/decrypt messages without changing the Firestore schema.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
from typing import Any

from cryptography.hazmat.primitives.ciphers.aead import AESGCM

ALGORITHM = "AES-256-GCM"
VERSION = 1
KEY_BYTES = 32
IV_BYTES = 12


def generate_key() -> str:
    """Return a new base64 AES-256 key."""
    return base64.b64encode(os.urandom(KEY_BYTES)).decode("ascii")


def encrypt_message(
    message: str,
    key_b64: str,
    conversation_id: str,
) -> dict[str, Any]:
    """Encrypt a UTF-8 message for transfer/storage.

    Args:
        message: Plain message text.
        key_b64: Base64 encoded 32-byte AES key shared by chat participants.
        conversation_id: Conversation id used as authenticated associated data.
    """
    key = _decode_key(key_b64)
    iv = os.urandom(IV_BYTES)
    ciphertext = AESGCM(key).encrypt(
        iv,
        message.encode("utf-8"),
        _associated_data(conversation_id),
    )
    return {
        "ciphertext": base64.b64encode(ciphertext).decode("ascii"),
        "iv": base64.b64encode(iv).decode("ascii"),
        "algorithm": ALGORITHM,
        "encryptionVersion": VERSION,
    }


def decrypt_message(
    payload: dict[str, Any],
    key_b64: str,
    conversation_id: str,
) -> str:
    """Decrypt a transfer/storage payload created by encrypt_message."""
    if payload.get("algorithm", ALGORITHM) != ALGORITHM:
        raise ValueError(f"Unsupported algorithm: {payload.get('algorithm')}")
    if int(payload.get("encryptionVersion", VERSION)) != VERSION:
        raise ValueError(
            f"Unsupported encryption version: {payload.get('encryptionVersion')}"
        )

    key = _decode_key(key_b64)
    iv = base64.b64decode(_required(payload, "iv"))
    ciphertext = base64.b64decode(_required(payload, "ciphertext"))
    plaintext = AESGCM(key).decrypt(
        iv,
        ciphertext,
        _associated_data(conversation_id),
    )
    return plaintext.decode("utf-8")


def _decode_key(key_b64: str) -> bytes:
    try:
        key = base64.b64decode(key_b64, validate=True)
    except Exception as exc:
        raise ValueError("Chat key must be valid base64.") from exc
    if len(key) != KEY_BYTES:
        raise ValueError("AES-256 chat keys must be exactly 32 bytes.")
    return key


def _required(payload: dict[str, Any], field: str) -> str:
    value = payload.get(field)
    if not isinstance(value, str) or not value:
        raise ValueError(f"Missing encrypted payload field: {field}")
    return value


def _associated_data(conversation_id: str) -> bytes:
    return f"conversation:{conversation_id}".encode("utf-8")


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="SecureChat AES-256-GCM helper")
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("generate-key", help="Create a new base64 chat key")

    encrypt_parser = subparsers.add_parser(
        "encrypt",
        help="Encrypt a message and print JSON payload",
    )
    encrypt_parser.add_argument("--key", required=True, help="Base64 AES-256 key")
    encrypt_parser.add_argument(
        "--conversation-id",
        required=True,
        help="Conversation id used for authenticated data",
    )
    encrypt_parser.add_argument("--message", required=True, help="Plain text")

    decrypt_parser = subparsers.add_parser(
        "decrypt",
        help="Decrypt a JSON payload",
    )
    decrypt_parser.add_argument("--key", required=True, help="Base64 AES-256 key")
    decrypt_parser.add_argument(
        "--conversation-id",
        required=True,
        help="Conversation id used for authenticated data",
    )
    decrypt_parser.add_argument(
        "--payload-json",
        required=True,
        help="JSON with ciphertext, iv, algorithm, encryptionVersion",
    )

    return parser


def main() -> None:
    args = _build_parser().parse_args()
    if args.command == "generate-key":
        print(generate_key())
        return

    if args.command == "encrypt":
        payload = encrypt_message(args.message, args.key, args.conversation_id)
        print(json.dumps(payload, separators=(",", ":")))
        return

    if args.command == "decrypt":
        payload = json.loads(args.payload_json)
        print(decrypt_message(payload, args.key, args.conversation_id))


if __name__ == "__main__":
    main()
