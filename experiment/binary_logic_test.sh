#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

MODEL="${1:-nemotron-3-super-120b-a12b}"
SCHEMA="logic.capnp"
URL="http://prometheus.maisiliym.criome:11434/v1"
KEY="sk-no-key-required"

# Build preamble: schema + many binary examples
SCHEMA_TEXT=$(cat "$SCHEMA")

# Generate examples as "text -> bytes" pairs
EXAMPLES=""
for s in \
  '(subject = aries, relation = hasElement, object = fire)' \
  '(subject = aries, relation = hasModality, object = cardinal)' \
  '(subject = aries, relation = hasRuler, object = mars)' \
  '(subject = taurus, relation = hasElement, object = earth)' \
  '(subject = taurus, relation = hasModality, object = fixed)' \
  '(subject = gemini, relation = hasElement, object = air)' \
  '(subject = cancer, relation = hasElement, object = water)' \
  '(subject = leo, relation = hasElement, object = fire)' \
  '(subject = leo, relation = hasRuler, object = sun)' \
  '(subject = aries, relation = opposes, object = libra)' \
  '(subject = aries, relation = trines, object = leo)'; do
  bytes=$(echo "$s" | capnp encode "$SCHEMA" Statement | od -A n -t u1 | tr '\n' ' ' | tr -s ' ' | sed 's/^ //' | sed 's/ $//')
  EXAMPLES="$EXAMPLES
Statement $s
binary: [$bytes]
"
done

# Add Answer examples
for a in \
  '(truth = yes, subject = aries, relation = hasElement, object = fire)' \
  '(truth = no, subject = aries, relation = hasElement, object = water)' \
  '(truth = yes, subject = leo, relation = hasRuler, object = sun)'; do
  bytes=$(echo "$a" | capnp encode "$SCHEMA" Answer | od -A n -t u1 | tr '\n' ' ' | tr -s ' ' | sed 's/^ //' | sed 's/ $//')
  EXAMPLES="$EXAMPLES
Answer $a
binary: [$bytes]
"
done

# Target: what does scorpio hasElement water look like as an Answer?
TARGET='(truth = yes, subject = scorpio, relation = hasElement, object = water)'
EXPECTED_BYTES=$(echo "$TARGET" | capnp encode "$SCHEMA" Answer | od -A n -t u1 | tr '\n' ' ' | tr -s ' ' | sed 's/^ //' | sed 's/ $//')

SYSTEM="You are a Cap'n Proto binary encoder. You output raw bytes only.

Schema:
$SCHEMA_TEXT

All messages are exactly 24 bytes:
- Bytes 0-15: header [0 0 0 0 2 0 0 0 0 0 0 0 1 0 0 0] (always constant)
- Bytes 16-23: data fields as little-endian u16 values

Statement data layout (bytes 16-23):
  u16 subject, u16 relation, u16 object, (2 padding zeros)

Answer data layout (bytes 16-23):
  u16 truth, u16 subject, u16 relation, u16 object

Entity discriminants: aries=0 taurus=1 gemini=2 cancer=3 leo=4 virgo=5 libra=6 scorpio=7 sagittarius=8 capricorn=9 aquarius=10 pisces=11 fire=12 earth=13 air=14 water=15 cardinal=16 fixed=17 mutable=18 sun=19 moon=20 mercury=21 venus=22 mars=23 jupiter=24 saturn=25

Relation discriminants: hasElement=0 hasModality=1 hasRuler=2 opposes=3 trines=4 squares=5

Truth discriminants: yes=0 no=1 unknown=2

Examples:
$EXAMPLES
Respond with ONLY the 24 byte values as a comma-separated list of decimal integers in square brackets. Nothing else."

echo "=== Binary Logic Test ==="
echo "Model: $MODEL"
echo "Target: $TARGET"
echo "Expected: [$EXPECTED_BYTES]"
echo

RESPONSE=$(curl -s --max-time 120 "$URL/chat/completions" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg model "$MODEL" \
    --arg system "$SYSTEM" \
    --arg user "Encode this Answer: $TARGET" \
    '{
      model: $model,
      temperature: 0,
      max_tokens: 100,
      messages: [
        {role: "system", content: $system},
        {role: "user", content: $user}
      ]
    }')" | jq -r '.choices[0].message.content // "ERROR"')

echo "LLM response: $RESPONSE"
echo "Expected:     [$EXPECTED_BYTES]"
echo

# Try to verify by parsing the response as byte values
CLEAN=$(echo "$RESPONSE" | grep -o '\[.*\]' | head -1)
if [ -n "$CLEAN" ]; then
  echo "Parsed: $CLEAN"
  # Convert to binary and try to decode
  BYTES=$(echo "$CLEAN" | tr -d '[]' | tr ',' '\n' | tr -d ' ' | while read b; do printf "\\x$(printf '%02x' "$b")"; done)
  echo "Attempting capnp decode..."
  echo "$BYTES" | capnp decode "$SCHEMA" Answer 2>&1 || echo "(decode failed)"
fi
