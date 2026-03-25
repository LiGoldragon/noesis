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

    // Populate Layer 2: self-describing schema from live DB
    let schema_hash = "build";
    populate_layer2(&db, schema_hash);

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

/// Populate schema_entry and schema_variant from the live DB.
/// Every domain becomes a schema_entry with structure=enum.
/// Every domain variant becomes a schema_variant.
fn populate_layer2(db: &criome_cozo::CriomeDb, schema_hash: &str) {
    // Get all domains
    let domains_result = db.run_script("?[name] := *Domain{name} :order name")
        .expect("query domains for layer2");
    let domains_json: serde_json::Value = serde_json::from_str(
        &domains_result.to_string()
    ).expect("parse domains json");

    let domain_names: Vec<&str> = domains_json.get("rows")
        .and_then(|v| v.as_array())
        .map(|rows| rows.iter()
            .filter_map(|row| row.as_array()
                .and_then(|a| a.first())
                .and_then(|v| v.as_str()))
            .collect())
        .unwrap_or_default();

    // Insert schema_entry for each domain (structure = enum = ordinal 1)
    for (ordinal, domain) in domain_names.iter().enumerate() {
        let script = format!(
            "?[schema, name, structure, ordinal, phase, dignity] <- [[\"{schema_hash}\", \"{domain}\", \"enum\", {ordinal}, \"manifest\", \"eternal\"]] :put schema_entry {{schema, name => structure, ordinal, phase, dignity}}"
        );
        if let Err(e) = db.run_script(&script) {
            eprintln!("cargo:warning=layer2 schema_entry for {domain}: {e}");
        }
    }

    // Insert schema_variant for each domain's variants
    for domain in &domain_names {
        let query = format!("?[name] := *{domain}{{name}} :order name");
        if let Ok(result) = db.run_script(&query) {
            let json: serde_json::Value = serde_json::from_str(
                &result.to_string()
            ).unwrap_or_default();

            if let Some(rows) = json.get("rows").and_then(|v| v.as_array()) {
                for (ordinal, row) in rows.iter().enumerate() {
                    if let Some(variant) = row.as_array().and_then(|a| a.first()).and_then(|v| v.as_str()) {
                        let script = format!(
                            "?[schema, owner, name, ordinal, phase, dignity] <- [[\"{schema_hash}\", \"{domain}\", \"{variant}\", {ordinal}, \"manifest\", \"eternal\"]] :put schema_variant {{schema, owner, name => ordinal, phase, dignity}}"
                        );
                        if let Err(e) = db.run_script(&script) {
                            eprintln!("cargo:warning=layer2 schema_variant {domain}::{variant}: {e}");
                        }
                    }
                }
            }
        }
    }

    eprintln!("cargo:warning=layer2: populated schema_entry + schema_variant for {} domains", domain_names.len());
}
