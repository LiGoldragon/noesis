@0x9069a108fd5733fe;

enum Access {
  readOnly @0;
  readWrite @1;
  snapshot @2;
}

enum Action {
  add @0;
  extend @1;
  extract @2;
  fix @3;
  merge @4;
  move @5;
  reduce @6;
  remove @7;
  rename @8;
  replace @9;
  rewrite @10;
  split @11;
}

enum Archetype {
  jupiter @0;
  mars @1;
  mercury @2;
  moon @3;
  saturn @4;
  sun @5;
  venus @6;
}

enum Arity {
  binary @0;
  nullary @1;
  ternary @2;
  unary @3;
  variadic @4;
}

enum Aspect {
  conjunction @0;
  opposition @1;
  sextile @2;
  square @3;
  trine @4;
}

enum Binding {
  constant @0;
  immutable @1;
  mutable @2;
}

enum Cardinality {
  many @0;
  map @1;
  one @2;
  optional @3;
}

enum Change {
  codegen @0;
  contract @1;
  doc @2;
  doctrine @3;
  feat @4;
  fix @5;
  migrate @6;
  nix @7;
  prune @8;
  refactor @9;
  schema @10;
  test @11;
}

enum Constraint {
  forbidden @0;
  optional @1;
  required @2;
}

enum Control {
  break @0;
  continue @1;
  if @2;
  loop @3;
  return @4;
  sequence @5;
}

enum CountUnit {
  arity @0;
  count @1;
  rowCount @2;
}

enum Dignity {
  delusion @0;
  eternal @1;
  proven @2;
  seen @3;
  uncertain @4;
}

enum Direction {
  request @0;
  response @1;
}

enum Domain {
  access @0;
  action @1;
  archetype @2;
  arity @3;
  aspect @4;
  binding @5;
  cardinality @6;
  change @7;
  constraint @8;
  control @9;
  countUnit @10;
  dignity @11;
  direction @12;
  domain @13;
  element @14;
  emailHost @15;
  emailUser @16;
  entityKind @17;
  evaluation @18;
  expr @19;
  functor @20;
  glyph @21;
  language @22;
  modality @23;
  name @24;
  op @25;
  ownership @26;
  pattern @27;
  permission @28;
  phase @29;
  planet @30;
  polarity @31;
  positionUnit @32;
  provenance @33;
  quantifier @34;
  query @35;
  response @36;
  role @37;
  rulership @38;
  scalar @39;
  scalarKind @40;
  scope @41;
  sign @42;
  sizeUnit @43;
  status @44;
  subcommand @45;
  thoughtKind @46;
  timeUnit @47;
  tool @48;
  type @49;
  verdict @50;
  morphism @51;
}

enum Element {
  air @0;
  earth @1;
  fire @2;
  water @3;
}

enum EmailHost {
  goldragonCriomeNet @0;
}

enum EmailUser {
  li @0;
}

enum EntityKind {
  field @0;
  interface @1;
  measureRender @2;
  method @3;
  relation @4;
  variant @5;
}

enum Evaluation {
  lazy @0;
  memoized @1;
  parallel @2;
  strict @3;
}

enum Expr {
  apply @0;
  binaryOp @1;
  block @2;
  letBind @3;
  literal @4;
  match @5;
  ref @6;
  unaryOp @7;
}

enum Functor {
  bijective @0;
  deterministic @1;
  traditionDependent @2;
}

enum Glyph {
  jupiter @0;
  luna @1;
  mars @2;
  mercury @3;
  saturnus @4;
  sol @5;
  venus @6;
}

enum Language {
  english @0;
  latina @1;
  samskrta @2;
}

enum Modality {
  cardinal @0;
  fixed @1;
  mutable @2;
}

enum Name {
  becoming @0;
  bijective @1;
  binary @2;
  bool @3;
  borrow @4;
  borrowMut @5;
  constant @6;
  copy @7;
  criomeStored @8;
  data @9;
  destructure @10;
  deterministic @11;
  domain @12;
  exists @13;
  forAll @14;
  guard @15;
  immutable @16;
  int @17;
  lazy @18;
  liGoldragon @19;
  literal @20;
  lojix @21;
  manifest @22;
  many @23;
  map @24;
  memoized @25;
  move @26;
  none @27;
  nullary @28;
  one @29;
  optional @30;
  own @31;
  parallel @32;
  request @33;
  response @34;
  retired @35;
  samskara @36;
  strict @37;
  ternary @38;
  traditionDependent @39;
  unary @40;
  unique @41;
  variadic @42;
  variant @43;
  wildcard @44;
}

enum Op {
  add @0;
  and @1;
  div @2;
  eq @3;
  gt @4;
  gte @5;
  iff @6;
  implies @7;
  lt @8;
  lte @9;
  mod @10;
  mul @11;
  negate @12;
  neq @13;
  not @14;
  or @15;
  sub @16;
  xor @17;
}

enum Ownership {
  borrow @0;
  borrowMut @1;
  copy @2;
  move @3;
  own @4;
}

enum Pattern {
  destructure @0;
  guard @1;
  literal @2;
  variant @3;
  wildcard @4;
}

enum Permission {
  allowed @0;
  disallowed @1;
  internal @2;
  restricted @3;
}

enum Phase {
  becoming @0;
  manifest @1;
  retired @2;
}

enum Planet {
  jupiter @0;
  mars @1;
  mercury @2;
  moon @3;
  saturn @4;
  sun @5;
  venus @6;
}

enum Polarity {
  diurnal @0;
  nocturnal @1;
}

enum PositionUnit {
  byteOffset @0;
  index @1;
  line @2;
  ordinal @3;
}

enum Provenance {
  annasArchive @0;
  file @1;
  git @2;
  github @3;
  gitlab @4;
  path @5;
  sourcehut @6;
  tarball @7;
}

enum Quantifier {
  exists @0;
  forAll @1;
  none @2;
  unique @3;
}

enum Query {
  assertFact @0;
  describeEnum @1;
  describeType @2;
  encode @3;
  listDomains @4;
  listMethods @5;
  listTypes @6;
  queryFacts @7;
  reason @8;
}

enum Response {
  domainList @0;
  encoded @1;
  enumDescription @2;
  error @3;
  factAsserted @4;
  factResults @5;
  methodList @6;
  reasoningAck @7;
  typeDescription @8;
  typeList @9;
}

enum Role {
  architect @0;
  firstAgent @1;
  owner @2;
  researcher @3;
  reviewer @4;
  root @5;
}

enum Scalar {
  bool @0;
  data @1;
  domain @2;
  int @3;
}

enum ScalarKind {
  bool @0;
  data @1;
  domain @2;
  int @3;
}

enum Scope {
  criomOS @0;
  mentci @1;
  annasArchive @2;
  criomeCozo @3;
  criomeStore @4;
  criomeStoreContract @5;
  criomeStored @6;
  global @7;
  lojix @8;
  noesisSchema @9;
  samskara @10;
  samskaraCodegen @11;
  samskaraCore @12;
  samskaraLojixContract @13;
  samskaraReader @14;
}

enum Sign {
  aquarius @0;
  aries @1;
  cancer @2;
  capricorn @3;
  gemini @4;
  leo @5;
  libra @6;
  pisces @7;
  sagittarius @8;
  scorpio @9;
  taurus @10;
  virgo @11;
}

enum SizeUnit {
  byte @0;
  kilobyte @1;
  megabyte @2;
}

enum Status {
  approved @0;
  draft @1;
  failing @2;
  notApplicable @3;
  passing @4;
  proposed @5;
}

enum Subcommand {
  add @0;
  bookmark @1;
  build @2;
  check @3;
  clippy @4;
  commit @5;
  describe @6;
  details @7;
  develop @8;
  diff @9;
  downloadUrl @10;
  flake @11;
  fmt @12;
  git @13;
  log @14;
  new @15;
  push @16;
  run @17;
  search @18;
  squash @19;
  status @20;
  test @21;
  update @22;
}

enum ThoughtKind {
  feedback @0;
  observation @1;
  project @2;
  reference @3;
  user @4;
}

enum TimeUnit {
  day @0;
  epochMs @1;
  hour @2;
  minute @3;
  second @4;
  year @5;
}

enum Tool {
  annasArchive @0;
  capnpc @1;
  cargo @2;
  criomeStored @3;
  gh @4;
  git @5;
  gopass @6;
  jj @7;
  nix @8;
  rustAnalyzer @9;
  samskara @10;
  samskaraReader @11;
  sqlite @12;
}

enum Type {
  enum @0;
  list @1;
  primitive @2;
  struct @3;
  union @4;
  void @5;
}

enum Verdict {
  dependency @0;
  drift @1;
  error @2;
  evolution @3;
  gap @4;
  redundancy @5;
  violation @6;
}

struct TypedInt {
  measure @0 :UInt16;  # Measure dimension discriminant
  unit @1 :UInt16;     # Unit discriminant within dimension
  magnitude @2 :Int64; # The value
}

struct Measure {
  sign @0 :Sign;  # key
  formula @1 :Data;
  element @2 :Element;
  modality @3 :Modality;
  dimension @4 :Data;
  physical @5 :Data;
  psychological @6 :Data;
  phase @7 :Phase;
  dignity @8 :Dignity;
}

struct Rulership {
  planet @0 :Planet;  # key
  sign @1 :Sign;  # key
  dignityType @2 :Data;  # key
  phase @3 :Phase;
  dignity @4 :Dignity;
}

struct Agent {
  id @0 :Data;  # key
  name @1 :Name;
  role @2 :Role;
  email @3 :Data;
  phase @4 :Phase;
  dignity @5 :Dignity;
}

struct Field {
  relation @0 :Data;  # key
  column @1 :Data;  # key
  scalar @2 :Scalar;
  target @3 :Data;
  unit @4 :Data;
  description @5 :Data;
  phase @6 :Phase;
  dignity @7 :Dignity;
}

struct FieldType {
  relation @0 :Data;  # key
  column @1 :Data;  # key
  kind @2 :ScalarKind;
  targetDomain @3 :Data;
  unitDomain @4 :Data;
  description @5 :Data;
  phase @6 :Phase;
  dignity @7 :Dignity;
}

struct Guideline {
  id @0 :Data;  # key
  domain @1 :Domain;
  planet @2 :Planet;
  compact @3 :Data;
  rationale @4 :Data;
  scope @5 :Scope;
  phase @6 :Phase;
  dignity @7 :Dignity;
}

struct Latina {
  term @0 :Data;  # key
  latina @1 :Data;
  domain @2 :Domain;
  meaning @3 :Data;
}

struct MeasureUnit {
  measure @0 :Data;  # key
  unitDomain @1 :Domain;
  phase @2 :Phase;
  dignity @3 :Dignity;
}

struct ModelScore {
  model @0 :Data;  # key
  schemaHash @1 :Data;  # key
  totalTrials @2 :TypedInt;
  passCount @3 :TypedInt;
  failCount @4 :TypedInt;
  meanByteErrors @5 :TypedInt;
  lastSessionTs @6 :Data;
  phase @7 :Phase;
  dignity @8 :Dignity;
}

struct Morphism {
  source @0 :Domain;  # key
  target @1 :Domain;  # key
  via @2 :Role;  # key
  functorType @3 :Functor;
  description @4 :Data;
  phase @5 :Phase;
  dignity @6 :Dignity;
}

struct NameMap {
  domain @0 :Domain;  # key
  variant @1 :Data;  # key
  generator @2 :Domain;  # key
  position @3 :Data;  # key
  phase @4 :Phase;
  dignity @5 :Dignity;
}

struct Principle {
  id @0 :Data;  # key
  domain @1 :Domain;
  rule @2 :Data;
  reason @3 :Data;
  phase @4 :Phase;
  dignity @5 :Dignity;
}

struct RelationMeta {
  relationName @0 :Data;  # key
  domain @1 :Domain;
  arityType @2 :Data;
  cardinality @3 :Data;
  description @4 :Data;
  why @5 :Data;
  phase @6 :Phase;
  dignity @7 :Dignity;
}

struct RelationTradition {
  relationName @0 :Data;  # key
  tradition @1 :Data;  # key
  sourceText @2 :Data;
  authority @3 :Data;
  phase @4 :Phase;
  dignity @5 :Dignity;
}

struct Repo {
  name @0 :Scope;  # key
  github @1 :Data;
  purpose @2 :Data;
  dependsOn @3 :Data;
  phase @4 :Phase;
  dignity @5 :Dignity;
}

struct RepoState {
  name @0 :Scope;  # key
  bookmark @1 :Data;
  buildStatus @2 :Status;
  lastCheckedTs @3 :TypedInt;
  notes @4 :Data;
  phase @5 :Phase;
  dignity @6 :Dignity;
}

struct RpcInterface {
  name @0 :Data;  # key
  description @1 :Data;
  phase @2 :Phase;
  dignity @3 :Dignity;
}

struct RpcMethod {
  interface @0 :Data;  # key
  method @1 :Data;  # key
  description @2 :Data;
  phase @3 :Phase;
  dignity @4 :Dignity;
}

struct RpcParam {
  interface @0 :Data;  # key
  method @1 :Data;  # key
  direction @2 :Direction;  # key
  paramName @3 :Data;  # key
  kind @4 :ScalarKind;
  paramType @5 :Data;
  isOptional @6 :Bool;
  ordinal @7 :TypedInt;
  phase @8 :Phase;
  dignity @9 :Dignity;
}

struct Samskrta {
  term @0 :Data;  # key
  samskrta @1 :Data;
  domain @2 :Domain;
  meaning @3 :Data;
}

struct Sandbox {
  id @0 :Data;  # key
  agentId @1 :Data;
  name @2 :Name;
  dbAccess @3 :Access;
  baseShell @4 :Data;
  description @5 :Data;
  phase @6 :Phase;
  dignity @7 :Dignity;
}

struct SchemaEntry {
  schema @0 :Data;  # key
  name @1 :Data;  # key
  structure @2 :Type;
  ordinal @3 :TypedInt;
  phase @4 :Phase;
  dignity @5 :Dignity;
}

struct SchemaField {
  schema @0 :Data;  # key
  owner @1 :Data;  # key
  name @2 :Data;  # key
  structure @3 :Type;
  target @4 :Data;
  ordinal @5 :TypedInt;
  cardinality @6 :Cardinality;
  phase @7 :Phase;
  dignity @8 :Dignity;
}

struct SchemaMethod {
  schema @0 :Data;  # key
  interface @1 :Data;  # key
  name @2 :Data;  # key
  ordinal @3 :TypedInt;
  phase @4 :Phase;
  dignity @5 :Dignity;
}

struct SchemaParam {
  schema @0 :Data;  # key
  interface @1 :Data;  # key
  method @2 :Data;  # key
  name @3 :Data;  # key
  direction @4 :Direction;
  structure @5 :Type;
  target @6 :Data;
  ordinal @7 :TypedInt;
  phase @8 :Phase;
  dignity @9 :Dignity;
}

struct SchemaVariant {
  schema @0 :Data;  # key
  owner @1 :Data;  # key
  name @2 :Data;  # key
  ordinal @3 :TypedInt;
  phase @4 :Phase;
  dignity @5 :Dignity;
}

struct Session {
  sessionId @0 :Data;  # key
  model @1 :Data;
  schemaHash @2 :Data;
  domainCount @3 :TypedInt;
  variantCount @4 :TypedInt;
  startedTs @5 :Data;
  endedTs @6 :Data;
  phase @7 :Phase;
  dignity @8 :Dignity;
}

struct SessionTurn {
  sessionId @0 :Data;  # key
  turnId @1 :TypedInt;  # key
  query @2 :Query;
  arg0 @3 :TypedInt;
  arg1 @4 :TypedInt;
  arg2 @5 :TypedInt;
  response @6 :Response;
  resultCount @7 :TypedInt;
  latencyMs @8 :TypedInt;
  phase @9 :Phase;
  dignity @10 :Dignity;
}

struct Source {
  id @0 :Data;  # key
  sourceType @1 :Provenance;
  url @2 :Data;
  ref @3 :Data;
  hash @4 :Data;
  description @5 :Data;
  phase @6 :Phase;
  dignity @7 :Dignity;
}

struct SysCommand {
  tool @0 :Tool;  # key
  subcommand @1 :Subcommand;  # key
  status @2 :Permission;
  description @3 :Data;
  phase @4 :Phase;
  dignity @5 :Dignity;
}

struct SysCommandAlt {
  tool @0 :Tool;  # key
  subcommand @1 :Subcommand;  # key
  altTool @2 :Tool;
  altSubcommand @3 :Subcommand;
  description @4 :Data;
  phase @5 :Phase;
  dignity @6 :Dignity;
}

struct SysCommandFlag {
  tool @0 :Tool;  # key
  subcommand @1 :Subcommand;  # key
  flag @2 :Data;  # key
  constraint @3 :Constraint;
  description @4 :Data;
  phase @5 :Phase;
  dignity @6 :Dignity;
}

struct SysCommandUsage {
  tool @0 :Tool;  # key
  subcommand @1 :Subcommand;  # key
  notes @2 :Data;
  examples @3 :Data;
  phase @4 :Phase;
  dignity @5 :Dignity;
}

struct SysWorkflow {
  workflow @0 :Data;  # key
  step @1 :TypedInt;  # key
  tool @2 :Tool;
  subcommand @3 :Subcommand;
  flags @4 :Data;
  description @5 :Data;
  phase @6 :Phase;
  dignity @7 :Dignity;
}

struct SysWorkflowMeta {
  workflow @0 :Data;  # key
  name @1 :Data;
  description @2 :Data;
  scope @3 :Scope;
  phase @4 :Phase;
  dignity @5 :Dignity;
}

struct Thought {
  kind @0 :ThoughtKind;  # key
  scope @1 :Scope;  # key
  titleHash @2 :Data;  # key
  status @3 :Status;
  title @4 :Data;
  body @5 :Data;
  createdTs @6 :TypedInt;
  updatedTs @7 :TypedInt;
  phase @8 :Phase;
  dignity @9 :Dignity;
}

struct ThoughtLink {
  fromKind @0 :ThoughtKind;  # key
  fromScope @1 :Scope;  # key
  fromHash @2 :Data;  # key
  toKind @3 :ThoughtKind;  # key
  toScope @4 :Scope;  # key
  toHash @5 :Data;  # key
  relType @6 :Data;
}

struct ThoughtTag {
  kind @0 :ThoughtKind;  # key
  scope @1 :Scope;  # key
  titleHash @2 :Data;  # key
  tag @3 :Data;  # key
}

struct Translation {
  entityKind @0 :EntityKind;  # key
  entityDomain @1 :Data;  # key
  entityName @2 :Data;  # key
  language @3 :Language;  # key
  text @4 :Data;
  phase @5 :Phase;
  dignity @6 :Dignity;
}

struct Trial {
  sessionId @0 :Data;  # key
  trialId @1 :TypedInt;  # key
  target @2 :Data;
  targetOrdinal @3 :TypedInt;
  expectedHash @4 :Data;
  actualHash @5 :Data;
  expectedSize @6 :TypedInt;
  actualSize @7 :TypedInt;
  pass @8 :Bool;
  byteErrors @9 :TypedInt;
  phase @10 :Phase;
  dignity @11 :Dignity;
}

struct WorldCommit {
  id @0 :Data;  # key
  parentId @1 :Data;
  agentId @2 :Data;
  sessionId @3 :Data;
  message @4 :Data;
  ts @5 :TypedInt;
  manifestHash @6 :Data;
}

struct WorldCommitRef {
  commitId @0 :Data;  # key
  refType @1 :Data;  # key
  refValue @2 :Data;
}

struct WorldDelta {
  commitId @0 :Data;  # key
  seq @1 :TypedInt;  # key
  relationName @2 :Data;
  operation @3 :Action;
  rowKey @4 :Data;
  rowData @5 :Data;
}

struct WorldManifest {
  commitId @0 :Data;  # key
  relationName @1 :Data;  # key
  rowCount @2 :TypedInt;
  contentHash @3 :Data;
}

struct WorldSchema {
  relationName @0 :Data;  # key
  createScript @1 :Data;
  phase @2 :Phase;
  dignity @3 :Dignity;
}

struct WorldSnapshot {
  commitId @0 :Data;  # key
  relationName @1 :Data;  # key
  data @2 :Data;
  readerVersion @3 :Data;
  byteCount @4 :TypedInt;
}

struct WorldSnapshotIndex {
  commitId @0 :Data;  # key
  snapshotExists @1 :Bool;
  nearestSnapshotId @2 :Data;
  deltaDepth @3 :TypedInt;
}

