@0xd5deeaec69ca4b13;

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

enum Aspect {
  conjunction @0;
  opposition @1;
  sextile @2;
  square @3;
  trine @4;
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
  aspect @2;
  change @3;
  constraint @4;
  countUnit @5;
  dignity @6;
  direction @7;
  domain @8;
  element @9;
  emailHost @10;
  emailUser @11;
  entityKind @12;
  functor @13;
  glyph @14;
  language @15;
  modality @16;
  name @17;
  permission @18;
  phase @19;
  planet @20;
  positionUnit @21;
  provenance @22;
  role @23;
  rulership @24;
  scalarKind @25;
  scope @26;
  sign @27;
  sizeUnit @28;
  status @29;
  subcommand @30;
  thoughtKind @31;
  timeUnit @32;
  tool @33;
  verdict @34;
  morphism @35;
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
  criomeStored @0;
  liGoldragon @1;
  lojix @2;
  samskara @3;
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

enum Role {
  architect @0;
  firstAgent @1;
  owner @2;
  researcher @3;
  reviewer @4;
  root @5;
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

struct Morphism {
  source @0 :Domain;  # key
  target @1 :Domain;  # key
  via @2 :Role;  # key
  functorType @3 :Functor;
  description @4 :Data;
  phase @5 :Phase;
  dignity @6 :Dignity;
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

