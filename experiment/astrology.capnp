@0xc1d2e3f4a5b60708;

# Expanded astrological domain — 31 domains worth of structure.
# Tests noesis binary encoding with a much richer vocabulary.

enum Sign {
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
}

enum Planet {
  sun @0;
  moon @1;
  mercury @2;
  venus @3;
  mars @4;
  jupiter @5;
  saturn @6;
}

enum Element {
  fire @0;
  earth @1;
  air @2;
  water @3;
}

enum Modality {
  cardinal @0;
  fixed @1;
  mutable @2;
}

enum House {
  h1 @0;
  h2 @1;
  h3 @2;
  h4 @3;
  h5 @4;
  h6 @5;
  h7 @6;
  h8 @7;
  h9 @8;
  h10 @9;
  h11 @10;
  h12 @11;
}

enum Dimension {
  position @0;
  velocity @1;
  acceleration @2;
  control @3;
  moment @4;
  momentum @5;
  force @6;
  massControl @7;
  inertia @8;
  action @9;
  energy @10;
  power @11;
}

enum DignityType {
  domicile @0;
  exaltation @1;
  detriment @2;
  fall @3;
}

enum AspectType {
  conjunction @0;
  sextile @1;
  square @2;
  trine @3;
  opposition @4;
}

enum Sect {
  diurnal @0;
  nocturnal @1;
}

enum Condition {
  combustion @0;
  cazimi @1;
  underBeams @2;
  oriental @3;
  occidental @4;
  retrograde @5;
  direct @6;
  stationary @7;
}

enum Truth {
  yes @0;
  no @1;
  unknown @2;
}

# Structs for different types of astrological facts

struct SignFact {
  sign @0 :Sign;
  element @1 :Element;
  modality @2 :Modality;
  ruler @3 :Planet;
}

struct HouseFact {
  house @0 :House;
  sign @1 :Sign;
  dimension @2 :Dimension;
}

struct RulershipFact {
  planet @0 :Planet;
  sign @1 :Sign;
  dignityType @2 :DignityType;
}

struct AspectFact {
  planet1 @0 :Planet;
  aspect @1 :AspectType;
  planet2 @2 :Planet;
}

struct ConditionFact {
  planet @0 :Planet;
  condition @1 :Condition;
  sect @2 :Sect;
}

struct Query {
  sign @0 :Sign;
  house @1 :House;
  planet @2 :Planet;
}

struct Answer {
  truth @0 :Truth;
  sign @1 :Sign;
  element @2 :Element;
  planet @3 :Planet;
}
