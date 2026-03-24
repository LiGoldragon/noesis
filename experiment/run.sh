#!/usr/bin/env bash
# Noesis binary LLM experiment
# Tests whether an LLM can produce valid capnp binary from a schema preamble.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEMA="$SCRIPT_DIR/test.capnp"

LLM_URL="${NOESIS_LLM_URL:-http://prometheus.maisiliym.criome:11434/v1}"
LLM_KEY="${NOESIS_LLM_KEY:-sk-no-key-required}"
LLM_MODEL="${NOESIS_LLM_MODEL:-llama-3.2-1b-instruct}"

# The schema IS the preamble
SCHEMA_TEXT=$(cat "$SCHEMA")

# Example encodings for the preamble
EXAMPLES=""
for val in \
  '(phase = becoming, element = air, confirmed = false)' \
  '(phase = manifest, element = fire, confirmed = true)'; do
  hex=$(echo "$val" | capnp encode "$SCHEMA" TypedFact | od -A n -t x1 | tr -d ' \n')
  EXAMPLES="$EXAMPLES
$val
hex: $hex
"
done

# The test: ask the LLM to produce the binary for a specific value
TARGET='(phase = retired, element = water, confirmed = false)'
EXPECTED_HEX=$(echo "$TARGET" | capnp encode "$SCHEMA" TypedFact | od -A n -t x1 | tr -d ' \n')

PROMPT=$(cat << 'SYSPROMPT'
You are an agent in a capnp binary environment. You communicate ONLY in Cap'n Proto binary encoding.

Here is your schema:

SYSPROMPT
)

PROMPT="$PROMPT
$SCHEMA_TEXT

Here are example encodings of TypedFact:

$EXAMPLES
Now produce the hex encoding of this TypedFact:
$TARGET

Respond with ONLY the hex bytes, nothing else. No explanation, no text, just the hex string."

echo "=== EXPERIMENT: capnp binary LLM generation ==="
echo "Schema: $SCHEMA"
echo "Model: $LLM_MODEL"
echo "Target: $TARGET"
echo "Expected: $EXPECTED_HEX"
echo

# Call the LLM
RESPONSE=$(curl -s "$LLM_URL/chat/completions" \
  -H "Authorization: Bearer $LLM_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg model "$LLM_MODEL" \
    --arg prompt "$PROMPT" \
    '{model: $model, temperature: 0, messages: [{role: "user", content: $prompt}]}'
  )" | jq -r '.choices[0].message.content // "ERROR"')

# Clean response — strip whitespace, newlines
CLEAN=$(echo "$RESPONSE" | tr -d ' \n\r\t')

echo "LLM raw:  $RESPONSE"
echo "Cleaned:  $CLEAN"
echo "Expected: $EXPECTED_HEX"
echo

if [ "$CLEAN" = "$EXPECTED_HEX" ]; then
  echo "RESULT: EXACT MATCH — LLM produced valid capnp binary"

  # Verify by decoding
  echo "$CLEAN" | sed 's/\(..\)/\\x\1/g' | xargs printf | capnp decode "$SCHEMA" TypedFact
else
  echo "RESULT: MISMATCH"
  echo "  expected: $EXPECTED_HEX"
  echo "  got:      $CLEAN"

  # Try to decode what the LLM produced anyway
  echo
  echo "Attempting to decode LLM output..."
  echo "$CLEAN" | sed 's/\(..\)/\\x\1/g' | xargs printf 2>/dev/null | capnp decode "$SCHEMA" TypedFact 2>&1 || echo "  (decode failed)"
fi
