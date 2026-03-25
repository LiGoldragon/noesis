#!/usr/bin/env python3
"""Pure binary LLM test.

Text preamble teaches the schema. Then the actual messages
are RAW BINARY BYTES — the prompt string's bytes ARE the capnp message.
The model's output bytes ARE the capnp response.
No arrays. No hex. No text representation. Bytes in, bytes out.
"""

import json
import subprocess
import sys
import urllib.request
import urllib.error

LLM_URL = "http://prometheus.maisiliym.criome:11434/v1"
LLM_KEY = "sk-no-key-required"
LLM_MODEL = "gpt-oss-120b"
SCHEMA_FILE = "test.capnp"


def capnp_encode(text_value: str) -> bytes:
    result = subprocess.run(
        ["capnp", "encode", SCHEMA_FILE, "TypedFact"],
        input=text_value.encode(), capture_output=True,
    )
    return result.stdout


def capnp_decode(binary: bytes) -> str:
    result = subprocess.run(
        ["capnp", "decode", SCHEMA_FILE, "TypedFact"],
        input=binary, capture_output=True,
    )
    return result.stdout.decode().strip()


def bytes_to_json_str(b: bytes) -> str:
    """Convert raw bytes to a JSON-safe string where each byte IS a character.
    Non-printable bytes become unicode escapes in the JSON encoding,
    but the tokenizer sees them as individual byte tokens."""
    chars = []
    for byte in b:
        if byte == 0:
            chars.append("\x00")
        elif byte < 0x20 or byte == 0x7f:
            chars.append(chr(byte))
        elif byte == ord('"'):
            chars.append('"')
        elif byte == ord('\\'):
            chars.append('\\')
        else:
            chars.append(chr(byte))
    return "".join(chars)


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
        print(f"  Error: {e}")
        return {"choices": []}


def extract_raw_bytes(response: dict) -> bytes:
    """Get the raw bytes of the model's output.
    The content string's encoding IS the binary."""
    choices = response.get("choices", [])
    if not choices:
        return b""
    content = choices[0].get("message", {}).get("content", "")
    # The string's bytes ARE the message
    return content.encode("utf-8") if content else b""


def make_preamble() -> str:
    with open(SCHEMA_FILE) as f:
        schema = f.read()

    return f"""You are a binary capnp encoder. After this preamble, ALL communication is raw bytes. No text.

SCHEMA:
{schema}

TypedFact = 24 bytes:
  [0-7]   header:  0x00 0x00 0x00 0x00 0x02 0x00 0x00 0x00
  [8-15]  pointer: 0x00 0x00 0x00 0x00 0x01 0x00 0x00 0x00
  [16-17] phase:   u16LE (becoming=0, manifest=1, retired=2)
  [18-19] element: u16LE (air=0, earth=1, fire=2, water=3)
  [20]    confirmed: 0x00=false, 0x01=true
  [21-23] padding: 0x00 0x00 0x00

PROTOCOL:
- I send you 3 bytes: [phase_byte, element_byte, confirmed_byte]
- You respond with the FULL 24 raw bytes of the capnp encoding
- Your response IS the bytes. Not hex. Not text. The actual byte values as characters.

TRAINING (I show text, you respond with raw 24 bytes):"""


def main():
    print("=" * 60)
    print("PURE BINARY LLM TEST")
    print(f"Model: {LLM_MODEL}")
    print("Preamble: text schema teaching")
    print("Messages: RAW BINARY BYTES as string characters")
    print("=" * 60)
    print()

    # Training examples as (text_description, capnp_bytes)
    training = [
        "(phase = becoming, element = air, confirmed = false)",
        "(phase = manifest, element = fire, confirmed = true)",
        "(phase = retired, element = earth, confirmed = true)",
    ]

    # Build conversation: system preamble + training pairs
    messages = [{"role": "system", "content": make_preamble()}]

    # Add training: user sends text description, assistant responds with raw bytes
    for text_val in training:
        binary = capnp_encode(text_val)
        binary_str = bytes_to_json_str(binary)
        messages.append({"role": "user", "content": text_val})
        messages.append({"role": "assistant", "content": binary_str})

    # Transition message
    messages.append({
        "role": "user",
        "content": "Good. Now switching to pure binary. I send 3 bytes, you send 24 bytes. No text."
    })
    messages.append({
        "role": "assistant",
        "content": bytes_to_json_str(b"\x00")  # ACK byte
    })

    # Now test: send raw bytes, expect raw bytes back
    tests = [
        # (phase, element, confirmed) as raw byte values
        (2, 3, 0, "(phase = retired, element = water, confirmed = false)"),
        (1, 1, 0, "(phase = manifest, element = earth, confirmed = false)"),
        (0, 2, 1, "(phase = becoming, element = fire, confirmed = true)"),
        (2, 0, 1, "(phase = retired, element = air, confirmed = true)"),
        (1, 3, 1, "(phase = manifest, element = water, confirmed = true)"),
    ]

    passed = 0
    total = len(tests)

    for i, (phase, element, confirmed, text_desc) in enumerate(tests):
        # The input IS binary: 3 raw bytes
        input_bytes = bytes([phase, element, confirmed])
        input_str = bytes_to_json_str(input_bytes)

        expected = capnp_encode(text_desc)

        print(f"Test {i+1}: sending bytes [{phase}, {element}, {confirmed}]")
        print(f"  = {text_desc}")
        print(f"  Input bytes: {list(input_bytes)}")
        print(f"  Expected output: {list(expected)} ({len(expected)} bytes)")

        messages.append({"role": "user", "content": input_str})
        response = call_llm(messages, max_tokens=48)
        output_bytes = extract_raw_bytes(response)

        print(f"  Got {len(output_bytes)} bytes: {list(output_bytes)[:24]}")

        if len(output_bytes) >= 24 and output_bytes[:24] == expected:
            decoded = capnp_decode(output_bytes[:24])
            print(f"  capnp decode: {decoded}")
            print(f"  PASS")
            passed += 1
            messages.append({"role": "assistant", "content": bytes_to_json_str(expected)})
        else:
            print(f"  FAIL")
            if len(output_bytes) >= 24:
                try:
                    decoded = capnp_decode(output_bytes[:24])
                    print(f"  capnp decode (attempt): {decoded}")
                except Exception:
                    print(f"  capnp decode failed")
                for j in range(min(24, len(output_bytes))):
                    e = expected[j] if j < len(expected) else "?"
                    g = output_bytes[j]
                    if e != g:
                        print(f"    byte {j}: expected {e}, got {g}")
            # Still add correct answer for context
            messages.append({"role": "assistant", "content": bytes_to_json_str(expected)})
        print()

    print("=" * 60)
    print(f"Results: {passed}/{total}")
    if passed == total:
        print("ALL PASS — LLM produces raw capnp binary bytes directly")
    print("=" * 60)


if __name__ == "__main__":
    main()
