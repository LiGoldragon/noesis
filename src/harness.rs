//! The noesis harness — spawns agent processes, connects via capnp RPC,
//! and provides a unified interface for interacting with the agent ecosystem.

use std::path::{Path, PathBuf};
use std::process::Stdio;

use crate::client;
use crate::samskara_rpc_capnp::samskara;

/// A managed agent process with its capnp RPC client.
pub struct AgentHandle {
    pub name: String,
    pub socket_path: PathBuf,
    pub process: tokio::process::Child,
}

/// The harness state — owns all agent connections.
pub struct Harness {
    pub samskara: samskara::Client,
    pub samskara_handle: AgentHandle,
    run_dir: PathBuf,
}

impl Harness {
    /// Boot the harness: spawn agents, wait for sockets, connect.
    pub async fn boot(config: HarnessConfig) -> Result<Self, Box<dyn std::error::Error>> {
        let run_dir = config.run_dir.clone();
        std::fs::create_dir_all(&run_dir)?;

        // Spawn samskara
        let samskara_socket = run_dir.join("samskara.sock");
        let samskara_handle = spawn_agent(
            "samskara",
            &config.samskara_bin,
            &[
                "--memory",
                "--socket",
                samskara_socket.to_str().unwrap(),
            ],
            &samskara_socket,
        ).await?;

        // Connect capnp client
        let (samskara_client, rpc_system) = client::connect_samskara(&samskara_socket).await?;
        tokio::task::spawn_local(rpc_system);

        eprintln!("noesis: harness booted — samskara connected via capnp RPC");

        Ok(Harness {
            samskara: samskara_client,
            samskara_handle,
            run_dir,
        })
    }

    /// Execute a CozoScript query on samskara.
    pub async fn query(&self, script: &str) -> Result<String, Box<dyn std::error::Error>> {
        let result = client::rpc_query(&self.samskara, script).await?;
        Ok(String::from_utf8_lossy(&result).into_owned())
    }

    /// List all relations in samskara.
    pub async fn list_relations(&self) -> Result<String, Box<dyn std::error::Error>> {
        let result = client::rpc_list_relations(&self.samskara).await?;
        Ok(String::from_utf8_lossy(&result).into_owned())
    }

    /// Assert a thought via capnp RPC.
    pub async fn assert_thought(
        &self,
        kind: &str,
        scope: &str,
        status: &str,
        title: &str,
        body: &str,
    ) -> Result<String, Box<dyn std::error::Error>> {
        let result = client::rpc_assert_thought(&self.samskara, kind, scope, status, title, body).await?;
        Ok(String::from_utf8_lossy(&result).into_owned())
    }

    /// Shut down all agent processes.
    pub async fn shutdown(mut self) -> Result<(), Box<dyn std::error::Error>> {
        eprintln!("noesis: shutting down agents...");
        self.samskara_handle.process.kill().await?;
        let _ = std::fs::remove_file(&self.samskara_handle.socket_path);
        let _ = std::fs::remove_dir(&self.run_dir);
        eprintln!("noesis: shutdown complete");
        Ok(())
    }
}

/// Configuration for the harness.
pub struct HarnessConfig {
    /// Directory for Unix sockets.
    pub run_dir: PathBuf,
    /// Path to samskara binary.
    pub samskara_bin: PathBuf,
}

impl HarnessConfig {
    pub fn default_config() -> Self {
        // Find samskara binary: check PATH first, then common locations
        let samskara_bin = which("samskara")
            .unwrap_or_else(|| PathBuf::from("samskara"));

        Self {
            run_dir: PathBuf::from("/tmp/noesis"),
            samskara_bin,
        }
    }
}

/// Spawn an agent process and wait for its socket to appear.
async fn spawn_agent(
    name: &str,
    bin: &Path,
    args: &[&str],
    socket_path: &Path,
) -> Result<AgentHandle, Box<dyn std::error::Error>> {
    // Remove stale socket
    let _ = std::fs::remove_file(socket_path);

    eprintln!("noesis: spawning {name} → {} {}", bin.display(), args.join(" "));

    let process = tokio::process::Command::new(bin)
        .args(args)
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|e| format!("failed to spawn {name}: {e}"))?;

    // Wait for socket to appear (up to 10 seconds)
    for i in 0..100 {
        if socket_path.exists() {
            eprintln!("noesis: {name} socket ready ({}ms)", i * 100);
            return Ok(AgentHandle {
                name: name.to_string(),
                socket_path: socket_path.to_path_buf(),
                process,
            });
        }
        tokio::time::sleep(std::time::Duration::from_millis(100)).await;
    }

    Err(format!("{name} socket did not appear at {} within 10s", socket_path.display()).into())
}

fn which(name: &str) -> Option<PathBuf> {
    std::env::var_os("PATH").and_then(|paths| {
        std::env::split_paths(&paths)
            .map(|p| p.join(name))
            .find(|p| p.exists())
    })
}
