//! The agent loop — an LLM driving samskara through the noesis harness.
//!
//! The LLM receives a system prompt describing the available domains and
//! CozoScript interface. It produces queries which noesis executes via
//! capnp RPC on samskara. Results are fed back as assistant/user turns.

use crate::client;
use crate::llm::{LlmClient, Message};
use crate::samskara_rpc_capnp::samskara;

/// Build the system prompt — describes what the agent can do.
fn system_prompt() -> String {
    let domains = crate::DOMAIN_NAMES.join(", ");

    format!(
r#"You are an agent running inside the noesis harness. You communicate with
samskara (a CozoDB database) through CozoScript queries.

AVAILABLE DOMAINS (finite enums — {count} total):
{domains}

HOW TO INTERACT:
- Write CozoScript queries to read or write data.
- Every query you write will be executed on samskara and the result returned to you.
- To read: ?[columns] := *relation{{columns}}
- To write: ?[columns] <- [[values]] :put relation {{ key => values }}

PROTOCOL:
- Respond with ONLY a CozoScript query when you want to execute one.
- Prefix your query with QUERY: on its own line.
- Any text not prefixed with QUERY: is treated as thinking/commentary and not executed.
- When you have nothing more to query, respond with DONE.

RULES:
- All data lives in relations. You never see files or the OS.
- phase and dignity columns appear on most relations.
- phase: becoming (staged), manifest (current), retired (archived).
- dignity: eternal, proven, seen, uncertain, delusion.
"#,
        count = crate::DOMAIN_COUNT,
    )
}

/// Run the agent loop: LLM produces queries, noesis executes them on samskara.
pub async fn run_agent_loop(
    llm: &LlmClient,
    samskara: &samskara::Client,
    user_task: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    let mut messages = vec![
        Message::system(&system_prompt()),
        Message::user(user_task),
    ];

    let max_turns = 20;

    for turn in 0..max_turns {
        eprintln!("noesis: agent turn {}", turn + 1);

        let response = llm.chat(&messages).await?;
        eprintln!("noesis: llm response ({} chars)", response.len());

        // Check for DONE
        if response.trim() == "DONE" || response.contains("\nDONE") {
            eprintln!("noesis: agent signaled DONE");
            println!("{response}");
            break;
        }

        // Extract and execute queries
        let mut executed_any = false;
        let mut result_text = String::new();

        for line in response.lines() {
            if let Some(query) = line.strip_prefix("QUERY:") {
                let query = query.trim();
                if query.is_empty() { continue; }

                eprintln!("noesis: executing query: {query}");
                match client::rpc_query(samskara, query).await {
                    Ok(result) => {
                        let text = String::from_utf8_lossy(&result);
                        eprintln!("noesis: result: {} bytes", result.len());
                        result_text.push_str(&format!("Result of `{query}`:\n{text}\n\n"));
                        executed_any = true;
                    }
                    Err(e) => {
                        result_text.push_str(&format!("Error executing `{query}`: {e}\n\n"));
                        executed_any = true;
                    }
                }
            }
        }

        // Print LLM's commentary
        for line in response.lines() {
            if !line.starts_with("QUERY:") {
                println!("{line}");
            }
        }

        // Add the exchange to message history
        messages.push(Message::assistant(&response));

        if executed_any {
            messages.push(Message::user(&result_text));
        } else {
            // LLM didn't produce any queries — it's done or confused
            eprintln!("noesis: no queries in response, ending loop");
            break;
        }
    }

    Ok(())
}
