#!/usr/bin/env python3
"""
Master Gravitas verification engine for World of IT.
Runs deterministic acceptance checks across Firebase Architecture, Desktop Agent, and Flutter App.
Output complies with GRAVITAS standard:
VERDICT: PASS or VERDICT: FAIL
"""

import os
import subprocess
import sys
import time

def run_command(cmd, desc, env=None):
    print(f"\n[RUNNING] {desc}...")
    start = time.time()
    current_env = os.environ.copy()
    if env:
        current_env.update(env)
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True, env=current_env)
    duration = time.time() - start
    if res.returncode == 0:
        print(f"[PASS] {desc} ({duration:.2f}s)")
        return True, res.stdout
    else:
        print(f"[FAIL] {desc} ({duration:.2f}s)")
        print(res.stderr or res.stdout)
        return False, res.stderr or res.stdout

def main():
    print("=" * 65)
    print("  GRAVITAS RELIABILITY RUNTIME - FIREBASE VERIFICATION SUITE")
    print("  Project: World of IT (Flutter + Firebase Realtime DB + Agent)")
    print("=" * 65)

    checks = []

    # 1. Firebase Rules and Config Check
    fb_rules_check, _ = run_command(
        "PYTHONPATH=. .venv/bin/pytest tests/test_firebase_flow.py -v",
        "Firebase Realtime Database Rules & Config Validation",
        env={"PYTHONPATH": "."}
    )
    checks.append(("Firebase Rules & Emulator Config", fb_rules_check))

    # 2. Pytest Suite (All 12 backend, agent, e2e, and firebase tests)
    pytest_check, _ = run_command(
        "PYTHONPATH=. .venv/bin/pytest tests/ -v",
        "Backend & Desktop Agent Test Suite (12 tests)",
        env={"PYTHONPATH": "."}
    )
    checks.append(("Pytest Suite (12 tests)", pytest_check))

    # 3. Flutter Widget and Unit Tests
    flutter_check, _ = run_command(
        "/home/user/flutter/bin/flutter test",
        "Flutter App Tests (Widgets, Models, Routing)"
    )
    checks.append(("Flutter Test Suite (6 tests)", flutter_check))

    # 4. Dart Analysis Check
    dart_check, _ = run_command(
        "/home/user/flutter/bin/dart analyze --no-fatal-warnings",
        "Dart Static Code Analysis"
    )
    checks.append(("Dart Analysis Cleanliness", dart_check))

    # Evaluate results
    all_passed = all(status for _, status in checks)
    print("\n" + "=" * 65)
    print("  VERIFICATION SUMMARY")
    print("=" * 65)
    for name, status in checks:
        badge = "✓ PASS" if status else "✗ FAIL"
        print(f"  {badge:<8} {name}")
    print("=" * 65)

    if all_passed:
        print("\nVERDICT: PASS")
        sys.exit(0)
    else:
        print("\nVERDICT: FAIL -- One or more validators did not pass")
        sys.exit(1)

if __name__ == "__main__":
    main()
