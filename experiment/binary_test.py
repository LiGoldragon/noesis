#!/usr/bin/env python3
"""Noesis binary LLM experiment.

Tests whether an LLM can produce raw capnp binary bytes
that deserialize against our schema.

The LLM receives the .capnp schema as preamble plus example
binary encodings, then must produce the correct byte sequence
for a target value. We extract actual bytes from the token
stream via the logprobs API.
"""

import json
import subprocess
import sys
import requests

SCHEMA = "test.capnp"
LLM_URL = "http://prometheus.maisiliym.criome:11434/v1"
LLM_KEY = "sk-no-key-required"
LLM_MODEL = "llama-3.2-1b-instruct"

def capnp_encode(text_value: str) -> bytes:
    """Encode a capnp text value to binary."""
    result = subprocess.run(
        ["capnp", "encode", SCHEMA, "TypedFact"],
        input=text_value.encode(),
        capture_output=True,
    )
    return result.stdout

def capnp_decode(binary: bytes) -> str:
    """Decode capnp binary to text."""
    result = subprocess.run(
        ["capnp", "decode", SCHEMA, "TypedFact"],
        input=binary,
        capture_output=True,
    )
    return result.stdout.decode().strip()

def bytes_to_hex(b: bytes) -> str:
    return b.hex()

def make_preamble() -> str:
    """Build the schema + examples preamble."""
    with open(SCHEMA) as f:
        schema = f.read()

    examples = []
    for text_val in [
        "(phase = becoming, element = air, confirmed = false)",
        "(phase = manifest, element = fire, confirmed = true)",
        "(phase = retired, element = earth, confirmed = true)",
    ]:
        binary = capnp_encode(text_val)
        # Show as raw byte values
        byte_list = list(binary)
        examples.append(f"  {text_val}\n  bytes: {byte_list}\n  length: {len(binary)} bytes")

    return f"""You are a Cap'n Proto binary encoder. You produce RAW BINARY output — actual bytes, not text.

Schema:
{schema}

Example binary encodings of TypedFact (shown as byte value lists):

{chr(10).join(examples)}

The encoding structure:
- Bytes 0-15: capnp message header (always: [0,0,0,0, 2,0,0,0, 0,0,0,0, 1,0,0,0])
- Bytes 16-17: Phase enum (little-endian u16: becoming=0, manifest=1, retired=2)
- Bytes 18-19: Element enum (little-endian u16: air=0, earth=1, fire=2, water=3)
- Byte 20: confirmed Bool (0=false, 1=true)
- Bytes 21-23: padding zeros

You MUST respond with EXACTLY 24 raw bytes. No text. No explanation. Just the bytes."""

def call_llm(prompt: str, target: str) -> dict:
    """Call LLM and get raw byte output via logprobs."""
    resp = requests.post(
        f"{LLM_URL}/chat/completions",
        headers={
            "Authorization": f"Bearer {LLM_KEY}",
            "Content-Type": "application/json",
        },
        json={
            "model": LLM_MODEL,
            "temperature": 0,
            "max_tokens": 48,  # enough for 24 bytes as tokens
            "logprobs": True,
            "messages": [
                {"role": "system", "content": prompt},
                {"role": "user", "content": f"Encode: {target}"},
            ],
        },
    )
    return resp.json()

def extract_bytes(response: dict) -> bytes:
    """Extract raw bytes from logprobs."""
    choices = response.get("choices", [])
    if not choices:
        return b""

    logprobs = choices[0].get("logprobs", {})
    content = logprobs.get("content", [])

    raw = bytearray()
    for token_info in content:
        token_bytes = token_info.get("bytes", [])
        raw.extend(token_bytes)

    return bytes(raw)

def main():
    target = "(phase = retired, element = water, confirmed = false)"
    expected = capnp_encode(target)

    print(f"=== Noesis Binary LLM Experiment ===")
    print(f"Model: {LLM_MODEL}")
    print(f"Target: {target}")
    print(f"Expected bytes: {list(expected)}")
    print(f"Expected hex: {bytes_to_hex(expected)}")
    print()

    preamble = make_preamble()
    print(f"Preamble: {len(preamble)} chars")
    print()

    print("Calling LLM...")
    response = call_llm(preamble, target)

    # Extract bytes from token stream
    raw_bytes = extract_bytes(response)
    text_content = response.get("choices", [{}])[0].get("message", {}).get("content", "")

    print(f"Text output: {repr(text_content[:200])}")
    print(f"Raw bytes ({len(raw_bytes)}): {list(raw_bytes)}")
    print(f"Raw hex: {bytes_to_hex(raw_bytes)}")
    print()

    # Check exact match
    if raw_bytes == expected:
        print("RESULT: EXACT MATCH")
        decoded = capnp_decode(raw_bytes)
        print(f"Decoded: {decoded}")
    elif raw_bytes[:24] == expected:
        print("RESULT: MATCH (first 24 bytes)")
        decoded = capnp_decode(raw_bytes[:24])
        print(f"Decoded: {decoded}")
    else:
        print("RESULT: MISMATCH")
        print(f"  expected: {list(expected)}")
        print(f"  got:      {list(raw_bytes[:24])}")

        # Try to decode anyway
        try:
            if len(raw_bytes) >= 24:
                decoded = capnp_decode(raw_bytes[:24])
                print(f"  decoded (attempt): {decoded}")
        except Exception as e:
            print(f"  decode failed: {e}")

        # Show token-by-token breakdown
        logprobs = response.get("choices", [{}])[0].get("logprobs", {}).get("content", [])
        print(f"\nToken breakdown ({len(logprobs)} tokens):")
        for i, t in enumerate(logprobs[:30]):
            print(f"  [{i}] id={t.get('id','?')} token={repr(t.get('token',''))} bytes={t.get('bytes',[])} logprob={t.get('logprob',0):.3f}")

if __name__ == "__main__":
    main()
