@0xb1c2d3e4f5060708;

# Logical statements language — all domains, no strings.
# Subjects, verbs, objects are enum discriminants.
# The LLM speaks this language in raw binary.

enum Entity {
  # What can be a subject or object
  aries @0;
  taurus @1;
  gemini @2;
  cancer @3;
  leo @4;
  virgo @5;
  libra @6;
  scorpio @7;
  sagittarius @8;
  capricorn @9;
  aquarius @10;
  pisces @11;
  fire @12;
  earth @13;
  air @14;
  water @15;
  cardinal @16;
  fixed @17;
  mutable @18;
  sun @19;
  moon @20;
  mercury @21;
  venus @22;
  mars @23;
  jupiter @24;
  saturn @25;
}

enum Relation {
  # How entities relate
  hasElement @0;
  hasModality @1;
  hasRuler @2;
  opposes @3;
  trines @4;
  squares @5;
}

enum Truth {
  yes @0;
  no @1;
  unknown @2;
}

struct Statement {
  # A fact: subject relation object
  subject @0 :Entity;
  relation @1 :Relation;
  object @2 :Entity;
}

struct Query {
  # Ask about a relationship
  subject @0 :Entity;
  relation @1 :Relation;
  object @2 :Entity;
}

struct Answer {
  # Response to a query
  truth @0 :Truth;
  subject @1 :Entity;
  relation @2 :Relation;
  object @3 :Entity;
}
