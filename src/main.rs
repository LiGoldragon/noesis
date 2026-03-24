mod schema;

#[allow(unused)]
mod noesis_world_capnp {
    include!(concat!(env!("OUT_DIR"), "/noesis_world_capnp.rs"));
}

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

    eprintln!("noesis: harness ready");
    eprintln!("noesis: schema hash = {}", schema::SCHEMA_HASH);
    eprintln!("noesis: {DOMAIN_COUNT} domains, {} names", DOMAIN_NAMES.len());
    eprintln!("noesis: use --verify, --dump-domains, or --translate DOMAIN DISC");

    Ok(())
}
