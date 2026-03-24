@0xa1b2c3d4e5f60001;

enum Phase {
  becoming @0;
  manifest @1;
  retired @2;
}

enum Element {
  air @0;
  earth @1;
  fire @2;
  water @3;
}

struct TypedFact {
  phase @0 :Phase;
  element @1 :Element;
  confirmed @2 :Bool;
}
