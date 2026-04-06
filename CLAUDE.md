# noesis

LLM binary communication layer. Noesis enables LLMs to communicate via
rkyv-serialized sema types — no JSON, no strings on the wire.

## v1 history

The capnp-based binary harness (50 domain enums, typed binary protocol)
lives in git history. The flake.nix pinned v1 branches for its deps.

## New direction

Noesis will be rewritten in aski. The sema type system provides the
meaning structure; rkyv provides the binary serialization. LLMs receive
and produce typed World snapshots instead of text.

Written in aski, compiled by askic.
