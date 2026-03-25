#!/usr/bin/env python3
"""Pure binary LLM test.

Phase 1: Text preamble teaches the schema + encoding rules + examples.
Phase 2: Switch to binary — the "user message" is raw byte values,
         the expected response is raw byte values.

Tokens are bytes. If the output bytes ARE capnp, the LLM speaks binary.
"""

import json
import struct
import subprocess
import sys
import urllib.request

LLM_URL = "http://prometheus.maisiliym.criome:11434/v1"
LLM_KEY = "sk-no-key-required"
LLM_MODEL = "qwen3.5-27b"

SCHEMA_FILE = "test.capnp"


def capnp_encode(text_value: str) -> bytes:
    result = subprocess.run(
        ["capnp", "encode", SCHEMA_FILE, "TypedFact"],
        input=text_value.encode(),
        capture_output=True,
    )
    return result.stdout


def capnp_decode(binary: bytes) -> str:
    result = subprocess.run(
        ["capnp", "decode", SCHEMA_FILE, "TypedFact"],
        input=binary,
        capture_output=True,
    )
    return result.stdout.decode().strip()


def call_llm(messages: list, max_tokens: int = 64) -> dict:
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
        print(f"  HTTP {e.code}: {body[:300]}")
        return {"choices": []}


def extract_content(response: dict) -> str:
    choices = response.get("choices", [])
    if not choices:
        return ""
    return choices[0].get("message", {}).get("content", "")


def content_to_bytes(content: str) -> bytes:
    """Parse model output to bytes. Try multiple formats."""
    raw = content.strip()

    # JSON array of ints: [0, 0, 0, 0, 2, 0, ...]
    if raw.startswith("[") and raw.endswith("]"):
        try:
            vals = json.loads(raw)
            if isinstance(vals, list) and all(isinstance(v, int) for v in vals):
                return bytes(v & 0xFF for v in vals)
        except Exception:
            pass

    # Hex string: 00000000020000...
    cleaned = raw.replace(" ", "").replace("\n", "").replace("\r", "")
    if cleaned.startswith("0x"):
        cleaned = cleaned[2:]
    try:
        return bytes.fromhex(cleaned)
    except ValueError:
        pass

    # Space/comma-separated decimal: 0 0 0 0 2 0 0 0 ...
    try:
        parts = raw.replace(",", " ").replace("[", "").replace("]", "").split()
        vals = [int(x) for x in parts]
        if all(0 <= v <= 255 for v in vals):
            return bytes(vals)
    except ValueError:
        pass

    return raw.encode("utf-8")


def make_preamble() -> str:
    with open(SCHEMA_FILE) as f:
        schema = f.read()

    examples = []
    training = [
        "(phase = becoming, element = air, confirmed = false)",
        "(phase = manifest, element = fire, confirmed = true)",
        "(phase = retired, element = earth, confirmed = true)",
        "(phase = becoming, element = water, confirmed = true)",
        "(phase = manifest, element = air, confirmed = false)",
    ]

    for text_val in training:
        binary = capnp_encode(text_val)
        byte_list = list(binary)
        examples.append(f"  {text_val}\n  → {byte_list}")

    return f"""You are a binary encoder. You will learn a schema, then communicate purely in byte sequences.

SCHEMA:
{schema}

TypedFact is 24 bytes:
  [0-7]   header:  [0, 0, 0, 0, 2, 0, 0, 0]
  [8-15]  pointer: [0, 0, 0, 0, 1, 0, 0, 0]
  [16-17] phase:   u16 LE (becoming=0, manifest=1, retired=2)
  [18-19] element: u16 LE (air=0, earth=1, fire=2, water=3)
  [20]    confirmed: bool (0=false, 1=true)
  [21-23] padding: [0, 0, 0]

TRAINING EXAMPLES (text → bytes):
{chr(10).join(examples)}

RULES:
- After training, I will give you inputs as byte arrays
- You respond with ONLY a byte array — the 24-byte encoding
- No text, no explanation, no markdown — just the array of 24 integers
- Example response format: [0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2, 0, 1, 0, 0, 0]"""


def run_test(test_num: int, target_text: str, messages: list) -> tuple:
    """Run one test. Returns (passed, updated_messages)."""
    expected = capnp_encode(target_text)
    expected_list = list(expected)

    # Build binary-style prompt: show the target as its semantic components
    # but ask for bytes back. After first few tests, switch to pure byte input.
    if test_num <= 3:
        # Early tests: text input, byte output (teaching phase)
        user_msg = f"Encode: {target_text}"
    else:
        # Later tests: byte input (the "query" is a partial encoding to complete)
        # Give the phase and element as discriminant values
        parts = target_text.strip("()").split(",")
        phase_map = {"becoming": 0, "manifest": 1, "retired": 2}
        element_map = {"air": 0, "earth": 1, "fire": 2, "water": 3}
        bool_map = {"false": 0, "true": 1}

        phase_val = phase_map.get(parts[0].split("=")[1].strip(), 0)
        element_val = element_map.get(parts[1].split("=")[1].strip(), 0)
        confirmed_val = bool_map.get(parts[2].split("=")[1].strip(), 0)

        # Pure binary prompt: just the discriminant values
        user_msg = f"[{phase_val}, {element_val}, {confirmed_val}]"

    messages.append({"role": "user", "content": user_msg})

    print(f"Test {test_num}: {target_text}")
    print(f"  Prompt: {user_msg}")
    print(f"  Expected: {expected_list}")

    response = call_llm(messages, max_tokens=80)
    content = extract_content(response)
    actual = content_to_bytes(content)

    print(f"  Model says: {content[:120]}")
    print(f"  Parsed: {list(actual)[:24]}")

    passed = False
    if len(actual) >= 24 and actual[:24] == expected:
        decoded = capnp_decode(actual[:24])
        print(f"  capnp decode: {decoded}")
        print(f"  ✓ PASS — bit-for-bit capnp")
        passed = True
        # Add the correct response to conversation history
        messages.append({"role": "assistant", "content": json.dumps(expected_list)})
    else:
        print(f"  ✗ FAIL")
        if len(actual) >= 24:
            for i in range(24):
                e = expected_list[i]
                g = actual[i] if i < len(actual) else "?"
                if e != g:
                    print(f"    byte {i}: expected {e}, got {g}")
            try:
                decoded = capnp_decode(actual[:24])
                print(f"  capnp decode (attempt): {decoded}")
            except Exception:
                pass
        # Still add correct answer so conversation stays on track
        messages.append({"role": "assistant", "content": json.dumps(expected_list)})

    return passed, messages


def main():
    print("=" * 60)
    print("PURE BINARY LLM TEST")
    print(f"Model: {LLM_MODEL}")
    print(f"Phase 1: text preamble teaches schema")
    print(f"Phase 2: binary-only (byte arrays in, byte arrays out)")
    print("=" * 60)
    print()

    tests = [
        # Phase 1: text input → byte output (teaching)
        "(phase = retired, element = water, confirmed = false)",
        "(phase = manifest, element = earth, confirmed = false)",
        "(phase = becoming, element = fire, confirmed = true)",
        # Phase 2: binary input → byte output (pure binary)
        "(phase = retired, element = air, confirmed = true)",
        "(phase = manifest, element = water, confirmed = true)",
        "(phase = becoming, element = earth, confirmed = false)",
        "(phase = retired, element = fire, confirmed = false)",
    ]

    preamble = make_preamble()
    messages = [{"role": "system", "content": preamble}]

    passed = 0
    total = len(tests)

    for i, target in enumerate(tests):
        ok, messages = run_test(i + 1, target, messages)
        if ok:
            passed += 1
        print()

    print("=" * 60)
    print(f"Results: {passed}/{total}")
    if passed == total:
        print("ALL PASS — LLM produces bit-for-bit valid capnp binary")
    elif passed >= 4:
        print(f"Binary phase: {passed-3}/{total-3} pure binary tests passed")
    print("=" * 60)


if __name__ == "__main__":
    main()
