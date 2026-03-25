#!/usr/bin/env python3
"""Pure binary harness.

Text preamble teaches the schema ONCE. After that, the harness
speaks ONLY capnp binary. The LLM must respond in capnp binary.
If it responds with invalid capnp or text, the harness sends
a capnp error response (also binary). No text ever again after preamble.
"""

import json
import struct
import subprocess
import sys
import urllib.request
import urllib.error

LLM_URL = "http://prometheus.maisiliym.criome:11434/v1"
LLM_KEY = "sk-no-key-required"
LLM_MODEL = "gpt-oss-120b"
SCHEMA_FILE = "test.capnp"

# capnp constants
HEADER = bytes([0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0])
PHASE = {"becoming": 0, "manifest": 1, "retired": 2}
ELEMENT = {"air": 0, "earth": 1, "fire": 2, "water": 3}


def encode_fact(phase: int, element: int, confirmed: int) -> bytes:
    """Build a 24-byte capnp TypedFact from discriminants."""
    return HEADER + struct.pack("<HHB", phase, element, confirmed) + b"\x00\x00\x00"


def encode_error() -> bytes:
    """A 24-byte capnp TypedFact that signals error: all-zeros payload."""
    # phase=becoming(0), element=air(0), confirmed=false(0) — the null message
    # The LLM should learn: all-zero payload = error/retry
    return HEADER + b"\xff\xff\xff\xff\xff\x00\x00\x00"


def decode_fact(raw: bytes) -> str:
    """Decode 24 bytes via capnp decode. Returns text or error string."""
    if len(raw) < 24:
        return f"ERROR:short:{len(raw)}bytes"
    result = subprocess.run(
        ["capnp", "decode", SCHEMA_FILE, "TypedFact"],
        input=raw[:24], capture_output=True,
    )
    if result.returncode == 0:
        return result.stdout.decode().strip()
    return f"ERROR:invalid_capnp"


def is_valid_capnp(raw: bytes) -> bool:
    """Check if bytes are valid capnp TypedFact."""
    if len(raw) < 24:
        return False
    # Must start with the standard header
    if raw[:16] != HEADER:
        return False
    # Verify via capnp decode
    result = subprocess.run(
        ["capnp", "decode", SCHEMA_FILE, "TypedFact"],
        input=raw[:24], capture_output=True,
    )
    return result.returncode == 0


def bytes_to_json_str(b: bytes) -> str:
    """Bytes → JSON string content. Each byte IS a character."""
    return "".join(chr(byte) for byte in b)


def call_llm(messages: list, max_tokens: int = 48) -> dict:
    data = json.dumps({
        "model": LLM_MODEL,
        "temperature": 0,
        "max_tokens": max_tokens,
        "messages": messages,
    }).encode()
    req = urllib.request.Request(
        f"{LLM_URL}/chat/completions",
        data=data,
        headers={
            "Authorization": f"Bearer {LLM_KEY}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"  HTTP {e.code}: {body[:200]}")
        return {"choices": []}
    except Exception as e:
        print(f"  Connection error: {e}")
        return {"choices": []}


def get_response_bytes(response: dict) -> bytes:
    """Extract raw bytes from model response."""
    choices = response.get("choices", [])
    if not choices:
        return b""
    content = choices[0].get("message", {}).get("content", "")
    if not content:
        return b""
    # The string's raw byte values ARE the message
    try:
        return content.encode("latin-1")  # latin-1 preserves byte values 0-255
    except Exception:
        return content.encode("utf-8")


def make_preamble() -> str:
    with open(SCHEMA_FILE) as f:
        schema = f.read()

    return f"""BINARY PROTOCOL — read this preamble, then speak ONLY in raw bytes.

SCHEMA:
{schema}

TypedFact = exactly 24 bytes:
  Bytes 0-15: fixed header (always the same 16 bytes)
  Byte 16-17: phase enum (u16 little-endian: becoming=0, manifest=1, retired=2)
  Byte 18-19: element enum (u16 little-endian: air=0, earth=1, fire=2, water=3)
  Byte 20: confirmed (0x00=false, 0x01=true)
  Bytes 21-23: zero padding

RULES:
1. After this preamble, I send you a 24-byte capnp TypedFact
2. You ECHO it back — respond with the EXACT SAME 24 bytes
3. If you understand, your response must be exactly those 24 raw bytes
4. If you respond with anything other than valid 24-byte capnp, I send an error (bytes 16-20 = 0xFF)
5. NO TEXT. Your response is raw bytes — the actual byte values as characters."""


def main():
    print("=" * 60)
    print("PURE BINARY CAPNP HARNESS")
    print(f"Model: {LLM_MODEL}")
    print("After preamble: ONLY capnp binary, both directions")
    print("Invalid response → binary error message")
    print("=" * 60)
    print()

    messages = [{"role": "system", "content": make_preamble()}]

    # Training: 3 binary echo pairs
    training = [
        (0, 0, 0),  # becoming, air, false
        (1, 2, 1),  # manifest, fire, true
        (2, 1, 1),  # retired, earth, true
    ]

    for phase, element, confirmed in training:
        binary = encode_fact(phase, element, confirmed)
        binary_str = bytes_to_json_str(binary)
        messages.append({"role": "user", "content": binary_str})
        messages.append({"role": "assistant", "content": binary_str})

    # Now test
    tests = [
        (2, 3, 0, "retired, water, false"),
        (1, 1, 0, "manifest, earth, false"),
        (0, 2, 1, "becoming, fire, true"),
        (2, 0, 1, "retired, air, true"),
        (1, 3, 1, "manifest, water, true"),
    ]

    passed = 0
    errors_sent = 0

    for i, (phase, element, confirmed, desc) in enumerate(tests):
        binary_in = encode_fact(phase, element, confirmed)

        print(f"Turn {i+1}: sending 24 bytes ({desc})")
        print(f"  → {list(binary_in)}")

        messages.append({"role": "user", "content": bytes_to_json_str(binary_in)})
        response = call_llm(messages, max_tokens=48)
        raw_out = get_response_bytes(response)

        print(f"  ← {len(raw_out)} bytes: {list(raw_out)[:24]}")

        if is_valid_capnp(raw_out):
            decoded = decode_fact(raw_out)
            print(f"  capnp decode: {decoded}")

            if raw_out[:24] == binary_in:
                print(f"  PASS (exact echo)")
                passed += 1
                messages.append({"role": "assistant", "content": bytes_to_json_str(raw_out[:24])})
            else:
                print(f"  VALID capnp but wrong value")
                # Send error: you got the format right but the content wrong
                error_msg = encode_error()
                print(f"  → ERROR: {list(error_msg)}")
                messages.append({"role": "assistant", "content": bytes_to_json_str(raw_out[:24])})
                messages.append({"role": "user", "content": bytes_to_json_str(error_msg)})
                errors_sent += 1
        else:
            print(f"  INVALID — not capnp (text or wrong format)")
            # Send binary error
            error_msg = encode_error()
            print(f"  → ERROR (binary): {list(error_msg)}")
            messages.append({"role": "assistant", "content": bytes_to_json_str(raw_out[:24] if len(raw_out) >= 24 else raw_out)})
            messages.append({"role": "user", "content": bytes_to_json_str(error_msg)})
            errors_sent += 1

        print()

    print("=" * 60)
    print(f"Results: {passed}/{len(tests)} correct echoes")
    print(f"Binary errors sent: {errors_sent}")
    if passed == len(tests):
        print("ALL PASS — pure binary capnp conversation")
    print("=" * 60)


if __name__ == "__main__":
    main()
