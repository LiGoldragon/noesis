use std::io::Write;
use std::path::PathBuf;

fn is_comment_only(stmt: &str) -> bool {
    stmt.lines().all(|line| {
        let trimmed = line.trim();
        trimmed.is_empty() || trimmed.starts_with('#') || trimmed == "//"
    })
}

fn load_script(db: &criome_cozo::CriomeDb, script: &str) {
    for stmt in criome_cozo::Script::from_str(script) {
        let trimmed = stmt.trim();
        if !trimmed.is_empty() && !is_comment_only(trimmed) {
            db.run_script(trimmed)
                .unwrap_or_else(|e| panic!("script load failed: {e}\nStatement: {trimmed}"));
        }
    }
}

fn main() {
    let out_dir = PathBuf::from(std::env::var("OUT_DIR").unwrap());

    let db = criome_cozo::CriomeDb::open_memory().expect("open memory db for codegen");

    // Load samskara-core boot schema
    load_script(&db, samskara_core::boot::CORE_WORLD_INIT);
    load_script(&db, samskara_core::boot::CORE_WORLD_SEED);

    // Load samskara world schema (from flake-crates)
    load_script(&db, include_str!("flake-crates/samskara/schema/samskara-world-init.cozo"));
    load_script(&db, include_str!("flake-crates/samskara/schema/samskara-world-seed.cozo"));

    // Load noesis schema (creates Direction, Name, units, field_type, etc.)
    load_script(&db, include_str!("flake-crates/noesis-schema/noesis-world-init.cozo"));
    load_script(&db, include_str!("flake-crates/noesis-schema/noesis-world-seed.cozo"));
    load_script(&db, include_str!("flake-crates/noesis-schema/noesis-field-type-seed.cozo"));

    // Load sema-core (new generators, structure, Name mapping)
    load_script(&db, sema_core::INIT);
    load_script(&db, sema_core::SEED);
    load_script(&db, sema_core::FIELD_SEED);

    // Load sema language layer (programming logic, protocol, testing)
    load_script(&db, sema::INIT);
    load_script(&db, sema::SEED);
    load_script(&db, sema::FIELD_SEED);

    // Generate capnp schema — field_type graph is now loaded
    let schema =
        samskara_codegen::SchemaGenerator::from_db(&db).expect("codegen schema generation");

    let capnp_text = schema.to_capnp_text().expect("capnp text generation");
    let capnp_path = out_dir.join("noesis_world.capnp");
    std::fs::write(&capnp_path, &capnp_text).expect("write .capnp file");

    let debug_path = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("schema/noesis_world.capnp");
    let _ = std::fs::write(&debug_path, &capnp_text);

    capnpc::CompilerCommand::new()
        .src_prefix(&out_dir)
        .file(&capnp_path)
        .run()
        .expect("capnp schema compilation failed");

    let hash = schema.schema_hash().expect("schema hash");
    let hash_path = out_dir.join("schema_hash.txt");
    let mut f = std::fs::File::create(&hash_path).expect("create schema_hash.txt");
    write!(f, "{hash}").expect("write schema hash");

    // Compile samskara RPC interface schema (from flake-crates)
    capnpc::CompilerCommand::new()
        .src_prefix("flake-crates/samskara/schema")
        .file("flake-crates/samskara/schema/samskara-rpc.capnp")
        .output_path(&out_dir)
        .run()
        .expect("samskara-rpc.capnp compilation failed");

    println!("cargo:rerun-if-changed=flake-crates/samskara/schema/samskara-rpc.capnp");
    println!("cargo:rerun-if-changed=flake-crates/samskara/schema/samskara-world-init.cozo");
    println!("cargo:rerun-if-changed=flake-crates/samskara/schema/samskara-world-seed.cozo");
    println!("cargo:rerun-if-changed=flake-crates/noesis-schema/noesis-world-init.cozo");
    println!("cargo:rerun-if-changed=flake-crates/noesis-schema/noesis-world-seed.cozo");
    println!("cargo:rerun-if-changed=flake-crates/noesis-schema/noesis-field-type-seed.cozo");
}
