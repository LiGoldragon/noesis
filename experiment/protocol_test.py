#!/usr/bin/env python3
"""Noesis multi-turn binary protocol test.

Tests the Turn/Response protocol without an LLM — verifies the
harness correctly handles listDomains, describeEnum, etc.

Usage: python3 protocol_test.py [--noesis-bin PATH]
Requires samskara to be running or noesis to spawn it.
"""

import struct
import subprocess
import sys
import time

NOESIS_BIN = sys.argv[1] if len(sys.argv) > 1 else "noesis"

def make_turn(turn_id: int, query: int, arg0: int = 0, arg1: int = 0, arg2: int = 0) -> bytes:
    """Pack a Turn into 10 bytes (5 x u16 little-endian)."""
    return struct.pack("<HHHHH", turn_id, query, arg0, arg1, arg2)

def parse_response(data: bytes) -> dict:
    """Parse Response header (6 bytes: turn_id, response, count)."""
    if len(data) < 6:
        return {"error": f"too short: {len(data)} bytes"}
    turn_id, response, count = struct.unpack("<HHH", data[:6])
    entries = []
    offset = 6
    for _ in range(count):
        if offset + 8 > len(data):
            break
        f0, f1, f2, f3 = struct.unpack("<HHHH", data[offset:offset+8])
        entries.append((f0, f1, f2, f3))
        offset += 8
    return {
        "turn_id": turn_id,
        "response": response,
        "count": count,
        "entries": entries,
    }

# Query discriminants
LIST_TYPES = 0
DESCRIBE_TYPE = 1
LIST_DOMAINS = 2
DESCRIBE_ENUM = 3
REASON = 8

# Response discriminants
DOMAIN_LIST = 2
ENUM_DESCRIPTION = 3

def main():
    print("=== Noesis Multi-Turn Protocol Test ===")
    print()

    # For now, just test the Turn/Response serialization locally
    # (without spawning noesis, since that requires samskara)

    # Test 1: Turn serialization
    turn = make_turn(1, LIST_DOMAINS)
    assert len(turn) == 10
    assert turn == b'\x01\x00\x02\x00\x00\x00\x00\x00\x00\x00'
    print("PASS: Turn(1, listDomains) serializes to 10 bytes")

    # Test 2: Turn with args
    turn = make_turn(2, DESCRIBE_ENUM, arg0=7)
    assert len(turn) == 10
    assert struct.unpack("<HHHHH", turn) == (2, 3, 7, 0, 0)
    print("PASS: Turn(2, describeEnum, 7) serializes correctly")

    # Test 3: Response parsing
    # Simulate: Response(1, domainList, 3) + 3 entries
    header = struct.pack("<HHH", 1, DOMAIN_LIST, 3)
    entries = b""
    for i in range(3):
        entries += struct.pack("<HHHH", i, 0, 0, 0)
    resp = parse_response(header + entries)
    assert resp["turn_id"] == 1
    assert resp["response"] == DOMAIN_LIST
    assert resp["count"] == 3
    assert len(resp["entries"]) == 3
    print("PASS: Response(1, domainList, 3) parses correctly")

    # Test 4: Reason turn (no-op, just logged)
    turn = make_turn(3, REASON)
    assert struct.unpack("<HHHHH", turn) == (3, 8, 0, 0, 0)
    print("PASS: Turn(3, reason) serializes correctly")

    print()
    print("=== All protocol serialization tests passed ===")
    print()
    print("To test with live harness:")
    print(f"  echo -ne '\\x01\\x00\\x02\\x00\\x00\\x00\\x00\\x00\\x00\\x00' | {NOESIS_BIN} --protocol")

if __name__ == "__main__":
    main()
