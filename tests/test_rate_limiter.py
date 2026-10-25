"""
Unit tests for SlidingWindowRateLimiter and forgot-password rate-limiting security.
"""

import os
import pytest
from fastapi.testclient import TestClient

TEST_DB = "test_rate_limiter.db"
os.environ["DATABASE_PATH"] = TEST_DB

from backend.config import settings
from backend.main import app
from backend.database import init_db
from backend.security import SlidingWindowRateLimiter

client = TestClient(app)

@pytest.fixture(autouse=True)
def setup_test_db():
    settings.DATABASE_PATH = TEST_DB
    if os.path.exists(TEST_DB):
        os.remove(TEST_DB)
    init_db(TEST_DB)
    yield
    if os.path.exists(TEST_DB):
        os.remove(TEST_DB)

def test_sliding_window_rate_limiter_basics():
    limiter = SlidingWindowRateLimiter()
    ip = "192.168.1.100"
    email = "test@example.com"
    
    # 1. First request is allowed
    allowed, msg = limiter.check_and_record(ip, email, cooldown_seconds=0)
    assert allowed is True
    assert msg is None

    # 2. Second request immediately with cooldown
    allowed, msg = limiter.check_and_record(ip, email, cooldown_seconds=60)
    assert allowed is False
    assert "wait" in msg.lower()

def test_sliding_window_max_per_email():
    limiter = SlidingWindowRateLimiter()
    ip = "10.0.0.1"
    email = "max_email@example.com"
    
    # Allow 3 without cooldown
    assert limiter.check_and_record(ip, email, max_per_email=3, cooldown_seconds=0)[0] is True
    assert limiter.check_and_record(ip, email, max_per_email=3, cooldown_seconds=0)[0] is True
    assert limiter.check_and_record(ip, email, max_per_email=3, cooldown_seconds=0)[0] is True
    
    # 4th request must be rejected
    allowed, msg = limiter.check_and_record(ip, email, max_per_email=3, cooldown_seconds=0)
    assert allowed is False
    assert "Too many password reset requests for this email" in msg

def test_sliding_window_max_per_ip():
    limiter = SlidingWindowRateLimiter()
    ip = "192.168.1.50"
    
    # Allow 2 from same IP with different emails
    assert limiter.check_and_record(ip, "user1@example.com", max_per_ip=2, cooldown_seconds=0)[0] is True
    assert limiter.check_and_record(ip, "user2@example.com", max_per_ip=2, cooldown_seconds=0)[0] is True
    
    # 3rd request from same IP must be rejected
    allowed, msg = limiter.check_and_record(ip, "user3@example.com", max_per_ip=2, cooldown_seconds=0)
    assert allowed is False
    assert "Too many requests from this IP" in msg

def test_forgot_password_endpoint_rate_limiting():
    # Make valid request
    email = "ratelimit_test@example.com"
    resp1 = client.post("/api/v1/auth/forgot-password", json={"email": email})
    assert resp1.status_code == 200
    data = resp1.json()
    assert data["status"] == "ok"
    
    # Immediate repeat request must trigger 429 Too Many Requests (cooldown)
    resp2 = client.post("/api/v1/auth/forgot-password", json={"email": email})
    assert resp2.status_code == 429
    assert "Too Many Requests" in resp2.json()["detail"] or "wait" in resp2.json()["detail"].lower()

def test_forgot_password_invalid_email_format():
    resp = client.post("/api/v1/auth/forgot-password", json={"email": "invalid-not-an-email"})
    assert resp.status_code == 422  # Pydantic EmailStr validation failure
