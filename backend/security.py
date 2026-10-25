"""
Security, hashing, and token utilities for World of IT backend.
Follows zero-plaintext-secret rules.
"""

import base64
import hashlib
import hmac
import json
import secrets
import time
from datetime import datetime, timezone
from typing import Optional, Dict, Any
from backend.config import settings


def hash_password(password: str) -> str:
    """Hashes a password using PBKDF2-HMAC-SHA256 with a random salt."""
    salt = secrets.token_bytes(16)
    key = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 100_000)
    return f"{base64.b64encode(salt).decode('utf-8')}${base64.b64encode(key).decode('utf-8')}"


def verify_password(password: str, hashed: str) -> bool:
    """Verifies a password against a stored PBKDF2-HMAC-SHA256 hash."""
    try:
        salt_b64, key_b64 = hashed.split("$")
        salt = base64.b64decode(salt_b64.encode("utf-8"))
        expected_key = base64.b64decode(key_b64.encode("utf-8"))
        computed_key = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 100_000)
        return hmac.compare_digest(expected_key, computed_key)
    except Exception:
        return False


def generate_device_secret() -> str:
    """Generates a high-entropy revocable device credential."""
    return f"oit_dev_{secrets.token_urlsafe(32)}"


def hash_device_secret(secret: str) -> str:
    """Hashes device credential with SHA-256 for secure storage."""
    return hashlib.sha256(secret.encode("utf-8")).hexdigest()


def verify_device_secret(secret: str, stored_hash: str) -> bool:
    """Timing-attack-resistant verification of device secret hash."""
    computed = hashlib.sha256(secret.encode("utf-8")).hexdigest()
    return hmac.compare_digest(computed, stored_hash)


def create_access_token(user_id: str, email: str, expires_in_minutes: Optional[int] = None) -> str:
    """Creates a signed JWT-like Bearer token."""
    exp_minutes = expires_in_minutes or settings.TOKEN_EXPIRE_MINUTES
    exp_ts = int(time.time()) + (exp_minutes * 60)
    
    payload = {
        "sub": user_id,
        "email": email,
        "exp": exp_ts,
        "iat": int(time.time()),
        "iss": "world-of-it-backend"
    }
    
    header = {"alg": "HS256", "typ": "JWT"}
    
    header_b64 = base64.urlsafe_b64encode(json.dumps(header).encode("utf-8")).decode("utf-8").rstrip("=")
    payload_b64 = base64.urlsafe_b64encode(json.dumps(payload).encode("utf-8")).decode("utf-8").rstrip("=")
    
    to_sign = f"{header_b64}.{payload_b64}".encode("utf-8")
    signature = hmac.new(settings.SECRET_KEY.encode("utf-8"), to_sign, hashlib.sha256).digest()
    sig_b64 = base64.urlsafe_b64encode(signature).decode("utf-8").rstrip("=")
    
    return f"{header_b64}.{payload_b64}.{sig_b64}"


def verify_access_token(token: str) -> Optional[Dict[str, Any]]:
    """Verifies Bearer token signature and expiration. Returns payload if valid."""
    try:
        parts = token.split(".")
        if len(parts) != 3:
            return None
        
        header_b64, payload_b64, sig_b64 = parts
        to_sign = f"{header_b64}.{payload_b64}".encode("utf-8")
        
        # Add back base64 padding
        pad_len = 4 - (len(sig_b64) % 4)
        if pad_len != 4:
            sig_b64 += "=" * pad_len
        expected_sig = base64.urlsafe_b64decode(sig_b64.encode("utf-8"))
        
        computed_sig = hmac.new(settings.SECRET_KEY.encode("utf-8"), to_sign, hashlib.sha256).digest()
        if not hmac.compare_digest(expected_sig, computed_sig):
            return None
        
        # Decode payload
        payload_pad = 4 - (len(payload_b64) % 4)
        if payload_pad != 4:
            payload_b64 += "=" * payload_pad
        payload_json = base64.urlsafe_b64decode(payload_b64.encode("utf-8")).decode("utf-8")
        payload = json.loads(payload_json)
        
        # Check expiry
        if payload.get("exp", 0) < int(time.time()):
            return None
        
        return payload
    except Exception:
        return None


def generate_pairing_code() -> str:
    """Generates an unambiguous 6-character pairing code."""
    # Exclude easily confused characters like O, 0, I, 1
    alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    return "".join(secrets.choice(alphabet) for _ in range(6))
