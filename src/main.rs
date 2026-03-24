mod client;
mod schema;

#[allow(unused)]
mod noesis_world_capnp {
    include!(concat!(env!("OUT_DIR"), "/noesis_world_capnp.rs"));
}

#[allow(unused)]
mod samskara_rpc_capnp {
    include!(concat!(env!("OUT_DIR"), "/samskara_rpc_capnp.rs"));
}

use std::path::PathBuf;

use clap::Parser;

// Generate ALL domain enums and dispatch tables from the Domain registry.
// Zero hand-maintained lists. Adding a domain to samskara → it appears here.
lojix_macros::domain_registry!();

/// Typed integer qualified by Measure and Unit (Young's Geometry of Meaning).
#[derive(Debug, Clone, Copy)]
pub struct TypedInt {
    pub measure: u16,
    pub unit: u16,
    pub magnitude: i64,
}

#[derive(Parser)]
#[command(name = "noesis", about = "Typed binary agent harness — capnp RPC")]
struct Cli {
    /// Verify the schema and print diagnostics
    #[arg(long)]
    verify: bool,

    /// Print all domain enums and their discriminants
    #[arg(long)]
    dump_domains: bool,

    /// Translate a domain discriminant: --translate Phase 1
    #[arg(long, num_args = 2, value_names = &["DOMAIN", "DISCRIMINANT"])]
    translate: Option<Vec<String>>,

    /// Connect to samskara capnp RPC on this Unix socket and run integration test
    #[arg(long, value_name = "SOCKET_PATH")]
    connect: Option<PathBuf>,

    /// Execute a CozoScript query via capnp RPC (requires --connect)
    #[arg(long, value_name = "SCRIPT")]
    query: Option<String>,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let cli = Cli::parse();

    if cli.verify {
        eprintln!("noesis: schema hash = {}", schema::SCHEMA_HASH);
        eprintln!("noesis: verifying domain completeness...");
        verify_domains();
        return Ok(());
    }

    if cli.dump_domains {
        dump_all_domains();
        return Ok(());
    }

    if let Some(args) = &cli.translate {
        let domain = &args[0];
        let disc: u16 = args[1].parse().map_err(|_| "discriminant must be u16")?;
        match translate_domain(domain, disc) {
            Some(name) => println!("{name}"),
            None => eprintln!("unknown: {domain}:{disc}"),
        }
        return Ok(());
    }

    if let Some(socket_path) = &cli.connect {
        let rt = tokio::runtime::Runtime::new()?;
        let local = tokio::task::LocalSet::new();
        return local.block_on(&rt, async {
            run_connected(socket_path, cli.query.as_deref()).await
        });
    }

    eprintln!("noesis: harness ready");
    eprintln!("noesis: schema hash = {}", schema::SCHEMA_HASH);
    eprintln!("noesis: {DOMAIN_COUNT} domains, {} names", DOMAIN_NAMES.len());
    eprintln!("noesis: use --verify, --dump-domains, --translate, or --connect");

    Ok(())
}

async fn run_connected(socket_path: &PathBuf, query: Option<&str>) -> Result<(), Box<dyn std::error::Error>> {
    eprintln!("noesis: connecting to samskara at {}", socket_path.display());

    let (samskara, rpc_system) = client::connect_samskara(socket_path).await?;

    // Drive the RPC system in the background
    tokio::task::spawn_local(rpc_system);

    if let Some(script) = query {
        // Execute a specific query
        eprintln!("noesis: query via capnp RPC: {script}");
        let result = client::rpc_query(&samskara, script).await?;
        let text = String::from_utf8_lossy(&result);
        println!("{text}");
    } else {
        // Integration test: exercise all RPC methods
        eprintln!("noesis: running integration test...");

        // 1. List relations
        eprintln!("  [1] listRelations");
        let result = client::rpc_list_relations(&samskara).await?;
        eprintln!("      got {} bytes", result.len());
        assert!(!result.is_empty(), "listRelations returned empty");

        // 2. Describe a relation
        eprintln!("  [2] describeRelation(Phase)");
        let result = client::rpc_describe_relation(&samskara, "Phase").await?;
        let text = String::from_utf8_lossy(&result);
        eprintln!("      {text}");
        assert!(text.contains("name"), "Phase should have a name column");

        // 3. Query
        eprintln!("  [3] query(?[name] := *Phase{{name}})");
        let result = client::rpc_query(&samskara, "?[name] := *Phase{name} :order name").await?;
        let text = String::from_utf8_lossy(&result);
        eprintln!("      {text}");
        assert!(text.contains("manifest"), "Phase should contain manifest");

        // 4. Assert a thought
        eprintln!("  [4] assertThought(noesis integration test)");
        let hash = client::rpc_assert_thought(
            &samskara,
            "observation",
            "global",
            "draft",
            "noesis integration test",
            "This thought was asserted via capnp RPC from the noesis harness.",
        ).await?;
        let hash_text = String::from_utf8_lossy(&hash);
        eprintln!("      title_hash = {hash_text}");
        assert!(!hash.is_empty(), "assertThought returned empty hash");

        // 5. Query thoughts to find what we just wrote
        eprintln!("  [5] query to verify thought exists");
        let result = client::rpc_query(
            &samskara,
            "?[title] := *thought{kind: \"observation\", scope: \"global\", title_hash, status, title, body, created_ts, updated_ts, phase, dignity}, title == \"noesis integration test\""
        ).await?;
        let text = String::from_utf8_lossy(&result);
        eprintln!("      {text}");
        assert!(text.contains("noesis integration test"), "thought should be findable");

        eprintln!("noesis: integration test PASSED — 5/5 methods verified via capnp RPC");
    }

    Ok(())
}
