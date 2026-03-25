mod client;
mod harness;
mod protocol;
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

    /// Connect to an already-running samskara (skip spawning)
    #[arg(long, value_name = "SOCKET_PATH")]
    connect: Option<PathBuf>,

    /// Path to samskara binary (default: find in PATH)
    #[arg(long, value_name = "PATH")]
    samskara_bin: Option<PathBuf>,

    /// Directory for Unix sockets (default: /tmp/noesis)
    #[arg(long, value_name = "DIR")]
    run_dir: Option<PathBuf>,

    /// Execute a single CozoScript query then exit
    #[arg(long, value_name = "SCRIPT")]
    query: Option<String>,

    /// Run multi-turn binary protocol (stdin: Turn bytes, stdout: Response bytes)
    #[arg(long)]
    protocol: bool,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let cli = Cli::parse();

    // Offline commands
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

    // Online commands
    let rt = tokio::runtime::Runtime::new()?;
    let local = tokio::task::LocalSet::new();
    local.block_on(&rt, async { run_harness(cli).await })
}

async fn run_harness(cli: Cli) -> Result<(), Box<dyn std::error::Error>> {
    let samskara_client = if let Some(socket_path) = &cli.connect {
        eprintln!("noesis: connecting to samskara at {}", socket_path.display());
        let (client, rpc_system) = client::connect_samskara(socket_path).await?;
        tokio::task::spawn_local(rpc_system);
        ConnectedHarness::External(client)
    } else {
        let mut config = harness::HarnessConfig::default_config();
        if let Some(bin) = &cli.samskara_bin {
            config.samskara_bin = bin.clone();
        }
        if let Some(dir) = &cli.run_dir {
            config.run_dir = dir.clone();
        }
        let h = harness::Harness::boot(config).await?;
        ConnectedHarness::Owned(h)
    };

    let samskara = samskara_client.samskara_ref();

    if cli.protocol {
        // Multi-turn binary protocol mode
        eprintln!("noesis: protocol mode — reading Turn bytes from stdin, writing Response bytes to stdout");
        eprintln!("noesis: schema hash = {}", schema::SCHEMA_HASH);
        eprintln!("noesis: {DOMAIN_COUNT} domains");

        use tokio::io::AsyncReadExt;
        use tokio::io::AsyncWriteExt;
        let mut stdin = tokio::io::stdin();
        let mut stdout = tokio::io::stdout();
        let mut buf = [0u8; 10]; // Turn is 10 bytes

        loop {
            match stdin.read_exact(&mut buf).await {
                Ok(_) => {
                    let turn = match protocol::turn_from_bytes(&buf) {
                        Some(t) => t,
                        None => {
                            eprintln!("noesis: invalid turn bytes");
                            continue;
                        }
                    };
                    eprintln!("noesis: turn {} query={} args=({},{},{})",
                        turn.turn_id, turn.query, turn.arg0, turn.arg1, turn.arg2);

                    match protocol::handle_turn(samskara, &turn).await {
                        Ok(resp) => {
                            eprintln!("noesis: response {} kind={} count={}",
                                resp.turn_id, resp.response, resp.count);
                            let bytes = protocol::response_to_bytes(&resp);
                            stdout.write_all(&bytes).await?;
                            stdout.flush().await?;
                        }
                        Err(e) => {
                            eprintln!("noesis: turn error: {e}");
                            let err_resp = protocol::Response {
                                turn_id: turn.turn_id,
                                response: 9, // error
                                count: 0,
                                entries: vec![],
                            };
                            let bytes = protocol::response_to_bytes(&err_resp);
                            stdout.write_all(&bytes).await?;
                            stdout.flush().await?;
                        }
                    }
                }
                Err(_) => break, // EOF
            }
        }
    } else if let Some(script) = &cli.query {
        // Single query mode
        let result = client::rpc_query(samskara, script).await?;
        println!("{}", String::from_utf8_lossy(&result));
    } else {
        // Interactive REPL
        eprintln!("noesis: harness ready — enter CozoScript queries (Ctrl-D to exit)");
        eprintln!("noesis: schema hash = {}", schema::SCHEMA_HASH);
        eprintln!("noesis: {DOMAIN_COUNT} domains");

        use tokio::io::AsyncBufReadExt;
        let stdin = tokio::io::stdin();
        let mut reader = tokio::io::BufReader::new(stdin);
        let mut line = String::new();

        loop {
            eprint!("noesis> ");
            line.clear();
            match reader.read_line(&mut line).await {
                Ok(0) => break,
                Ok(_) => {
                    let trimmed = line.trim();
                    if trimmed.is_empty() { continue; }
                    if trimmed == "exit" || trimmed == "quit" { break; }

                    match client::rpc_query(samskara, trimmed).await {
                        Ok(result) => println!("{}", String::from_utf8_lossy(&result)),
                        Err(e) => eprintln!("error: {e}"),
                    }
                }
                Err(e) => {
                    eprintln!("read error: {e}");
                    break;
                }
            }
        }
    }

    if let ConnectedHarness::Owned(h) = samskara_client {
        h.shutdown().await?;
    }

    Ok(())
}

enum ConnectedHarness {
    External(crate::samskara_rpc_capnp::samskara::Client),
    Owned(harness::Harness),
}

impl ConnectedHarness {
    fn samskara_ref(&self) -> &crate::samskara_rpc_capnp::samskara::Client {
        match self {
            ConnectedHarness::External(c) => c,
            ConnectedHarness::Owned(h) => &h.samskara,
        }
    }
}
