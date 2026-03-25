#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

MODEL="${1:-nemotron-3-super-120b-a12b}"
SCHEMA="astrology.capnp"
URL="http://prometheus.maisiliym.criome:11434/v1"
KEY="sk-no-key-required"

# Generate examples from multiple struct types
gen_example() {
  local struct="$1" text="$2"
  local bytes=$(echo "$text" | capnp encode "$SCHEMA" "$struct" | od -A n -t u1 | tr '\n' ' ' | tr -s ' ' | sed 's/^ //' | sed 's/ $//')
  echo "$struct $text = [$bytes]"
}

EXAMPLES=""
EXAMPLES="$EXAMPLES
$(gen_example SignFact '(sign = aries, element = fire, modality = cardinal, ruler = mars)')
$(gen_example SignFact '(sign = taurus, element = earth, modality = fixed, ruler = venus)')
$(gen_example SignFact '(sign = cancer, element = water, modality = cardinal, ruler = moon)')
$(gen_example HouseFact '(house = h1, sign = aries, dimension = acceleration)')
$(gen_example HouseFact '(house = h7, sign = libra, dimension = position)')
$(gen_example RulershipFact '(planet = mars, sign = aries, dignityType = domicile)')
$(gen_example RulershipFact '(planet = venus, sign = pisces, dignityType = exaltation)')
$(gen_example AspectFact '(planet1 = sun, aspect = conjunction, planet2 = mercury)')
$(gen_example ConditionFact '(planet = mars, condition = retrograde, sect = nocturnal)')
$(gen_example Answer '(truth = yes, sign = leo, element = fire, planet = sun)')
"

SYSTEM="You encode Cap'n Proto binary. Messages are 24 bytes: 16-byte header [0,0,0,0,2,0,0,0,0,0,0,0,1,0,0,0] + 8 data bytes.

Data bytes are little-endian u16 enum discriminants in field order.

Enums:
Sign: aries=0 taurus=1 gemini=2 cancer=3 leo=4 virgo=5 libra=6 scorpio=7 sagittarius=8 capricorn=9 aquarius=10 pisces=11
Planet: sun=0 moon=1 mercury=2 venus=3 mars=4 jupiter=5 saturn=6
Element: fire=0 earth=1 air=2 water=3
Modality: cardinal=0 fixed=1 mutable=2
House: h1=0 h2=1 h3=2 h4=3 h5=4 h6=5 h7=6 h8=7 h9=8 h10=9 h11=10 h12=11
Dimension: position=0 velocity=1 acceleration=2 control=3 moment=4 momentum=5 force=6 massControl=7 inertia=8 action=9 energy=10 power=11
DignityType: domicile=0 exaltation=1 detriment=2 fall=3
AspectType: conjunction=0 sextile=1 square=2 trine=3 opposition=4
Sect: diurnal=0 nocturnal=1
Condition: combustion=0 cazimi=1 underBeams=2 oriental=3 occidental=4 retrograde=5 direct=6 stationary=7
Truth: yes=0 no=1 unknown=2

Struct layouts (data bytes only, all u16 LE):
SignFact: sign, element, modality, ruler
HouseFact: house, sign, dimension, (pad 0,0)
RulershipFact: planet, sign, dignityType, (pad 0,0)
AspectFact: planet1, aspect, planet2, (pad 0,0)
ConditionFact: planet, condition, sect, (pad 0,0)
Answer: truth, sign, element, planet

Examples:
$EXAMPLES
Respond with ONLY the byte list."

run_test() {
  local label="$1" struct="$2" text="$3"
  local expected=$(echo "$text" | capnp encode "$SCHEMA" "$struct" | od -A n -t u1 | tr '\n' ' ' | tr -s ' ' | sed 's/^ //' | sed 's/ $//')

  echo "--- TEST: $label ---"
  echo "Expected: [$expected]"

  local result=$(curl -s --max-time 600 "$URL/chat/completions" \
    -H "Authorization: Bearer $KEY" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
      --arg model "$MODEL" \
      --arg system "$SYSTEM" \
      --arg user "$struct $text" \
      '{model: $model, temperature: 0, messages: [{role: "system", content: $system}, {role: "user", content: $user}]}')" | jq -r '.choices[0].message.content // "EMPTY"')

  echo "Got:      $result"
  if [ "[$expected]" = "$result" ]; then
    echo "PASS"
  else
    echo "FAIL"
  fi
  echo
}

echo "=== Expanded Astrology Test Battery ==="
echo "Model: $MODEL"
echo "Schema: $SCHEMA (11 enums, 7 structs)"
echo

# Novel SignFacts
run_test "SignFact: scorpio water fixed mars" SignFact '(sign = scorpio, element = water, modality = fixed, ruler = mars)'
run_test "SignFact: aquarius air fixed saturn" SignFact '(sign = aquarius, element = air, modality = fixed, ruler = saturn)'

# Novel HouseFacts
run_test "HouseFact: h10 capricorn control" HouseFact '(house = h10, sign = capricorn, dimension = control)'
run_test "HouseFact: h5 leo force" HouseFact '(house = h5, sign = leo, dimension = force)'

# Novel RulershipFacts
run_test "RulershipFact: saturn libra exaltation" RulershipFact '(planet = saturn, sign = libra, dignityType = exaltation)'
run_test "RulershipFact: sun aries exaltation" RulershipFact '(planet = sun, sign = aries, dignityType = exaltation)'

# Novel AspectFacts
run_test "AspectFact: jupiter trine saturn" AspectFact '(planet1 = jupiter, aspect = trine, planet2 = saturn)'
run_test "AspectFact: venus square mars" AspectFact '(planet1 = venus, aspect = square, planet2 = mars)'

# Novel ConditionFacts
run_test "ConditionFact: saturn stationary diurnal" ConditionFact '(planet = saturn, condition = stationary, sect = diurnal)'

# Novel Answers
run_test "Answer: no pisces water jupiter" Answer '(truth = no, sign = pisces, element = water, planet = jupiter)'
