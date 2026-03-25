//! Multi-turn binary protocol handler.
//! The LLM communicates through typed Turn/Response messages.
//! Each turn is dispatched by Query variant, results logged to session/trial.

use crate::client;
use crate::samskara_rpc_capnp::samskara;

/// A binary turn from the LLM.
#[derive(Debug, Clone)]
pub struct Turn {
    pub turn_id: u16,
    pub query: u16,
    pub arg0: u16,
    pub arg1: u16,
    pub arg2: u16,
}

/// A binary response from the harness.
#[derive(Debug, Clone)]
pub struct Response {
    pub turn_id: u16,
    pub response: u16,
    pub count: u16,
    pub entries: Vec<ResultEntry>,
}

/// A fixed-size result entry.
#[derive(Debug, Clone, Copy)]
pub struct ResultEntry {
    pub field0: u16,
    pub field1: u16,
    pub field2: u16,
    pub field3: u16,
}

/// Query discriminants (must match Query domain ordinal alignment).
mod query {
    pub const LIST_TYPES: u16 = 0;
    pub const DESCRIBE_TYPE: u16 = 1;
    pub const LIST_DOMAINS: u16 = 2;
    pub const DESCRIBE_ENUM: u16 = 3;
    pub const LIST_METHODS: u16 = 4;
    pub const ASSERT_FACT: u16 = 5;
    pub const QUERY_FACTS: u16 = 6;
    pub const ENCODE: u16 = 7;
    pub const REASON: u16 = 8;
}

/// Response discriminants (must match Response domain ordinal alignment).
mod response {
    pub const TYPE_LIST: u16 = 0;
    pub const TYPE_DESCRIPTION: u16 = 1;
    pub const DOMAIN_LIST: u16 = 2;
    pub const ENUM_DESCRIPTION: u16 = 3;
    pub const METHOD_LIST: u16 = 4;
    pub const FACT_ASSERTED: u16 = 5;
    pub const FACT_RESULTS: u16 = 6;
    pub const ENCODED: u16 = 7;
    pub const REASONING_ACK: u16 = 8;
    pub const ERROR: u16 = 9;
}

/// Handle a Turn message from the LLM, return a Response.
pub async fn handle_turn(
    samskara: &samskara::Client,
    turn: &Turn,
) -> Result<Response, Box<dyn std::error::Error>> {
    match turn.query {
        query::LIST_DOMAINS => list_domains(samskara, turn).await,
        query::DESCRIBE_ENUM => describe_enum(samskara, turn).await,
        query::LIST_TYPES => list_types(samskara, turn).await,
        query::DESCRIBE_TYPE => describe_type(samskara, turn).await,
        query::REASON => Ok(Response {
            turn_id: turn.turn_id,
            response: response::REASONING_ACK,
            count: 0,
            entries: vec![],
        }),
        _ => Ok(Response {
            turn_id: turn.turn_id,
            response: response::ERROR,
            count: 0,
            entries: vec![],
        }),
    }
}

/// List all domain enum names as ordinal entries.
async fn list_domains(
    samskara: &samskara::Client,
    turn: &Turn,
) -> Result<Response, Box<dyn std::error::Error>> {
    let script = "?[name] := *Domain{name} :order name";
    let result = client::rpc_query(samskara, script).await?;
    let parsed: serde_json::Value = serde_json::from_slice(&result)?;

    let rows = parsed.get("rows")
        .and_then(|v| v.as_array())
        .map(|a| a.len())
        .unwrap_or(0);

    let entries: Vec<ResultEntry> = (0..rows)
        .map(|i| ResultEntry {
            field0: i as u16,
            field1: 0,
            field2: 0,
            field3: 0,
        })
        .collect();

    Ok(Response {
        turn_id: turn.turn_id,
        response: response::DOMAIN_LIST,
        count: rows as u16,
        entries,
    })
}

/// Describe enum variants for a domain at ordinal arg0.
async fn describe_enum(
    samskara: &samskara::Client,
    turn: &Turn,
) -> Result<Response, Box<dyn std::error::Error>> {
    // First get the domain name at this ordinal
    let domain_name = domain_name_at_ordinal(samskara, turn.arg0).await?;

    // Query its variants
    let script = format!("?[name] := *{domain_name}{{name}} :order name");
    let result = client::rpc_query(samskara, &script).await?;
    let parsed: serde_json::Value = serde_json::from_slice(&result)?;

    let rows = parsed.get("rows")
        .and_then(|v| v.as_array())
        .map(|a| a.len())
        .unwrap_or(0);

    let entries: Vec<ResultEntry> = (0..rows)
        .map(|i| ResultEntry {
            field0: turn.arg0,
            field1: i as u16,
            field2: 0,
            field3: 0,
        })
        .collect();

    Ok(Response {
        turn_id: turn.turn_id,
        response: response::ENUM_DESCRIPTION,
        count: rows as u16,
        entries,
    })
}

/// List all types (domains + relations) as ordinal entries.
async fn list_types(
    samskara: &samskara::Client,
    turn: &Turn,
) -> Result<Response, Box<dyn std::error::Error>> {
    let script = "?[name] := *Domain{name} :order name";
    let result = client::rpc_query(samskara, script).await?;
    let parsed: serde_json::Value = serde_json::from_slice(&result)?;

    let rows = parsed.get("rows")
        .and_then(|v| v.as_array())
        .map(|a| a.len())
        .unwrap_or(0);

    let entries: Vec<ResultEntry> = (0..rows)
        .map(|i| ResultEntry {
            field0: i as u16,
            field1: 0, // type_kind: enum
            field2: 0,
            field3: 0,
        })
        .collect();

    Ok(Response {
        turn_id: turn.turn_id,
        response: response::TYPE_LIST,
        count: rows as u16,
        entries,
    })
}

/// Describe a type's fields/variants at ordinal arg0.
async fn describe_type(
    samskara: &samskara::Client,
    turn: &Turn,
) -> Result<Response, Box<dyn std::error::Error>> {
    // Same as describe_enum for now (all types in Domain are enums)
    describe_enum(samskara, turn).await
}

/// Get domain name by ordinal position in sorted Domain list.
async fn domain_name_at_ordinal(
    samskara: &samskara::Client,
    ordinal: u16,
) -> Result<String, Box<dyn std::error::Error>> {
    let script = "?[name] := *Domain{name} :order name";
    let result = client::rpc_query(samskara, script).await?;
    let parsed: serde_json::Value = serde_json::from_slice(&result)?;

    let name = parsed.get("rows")
        .and_then(|v| v.as_array())
        .and_then(|rows| rows.get(ordinal as usize))
        .and_then(|row| row.as_array())
        .and_then(|arr| arr.first())
        .and_then(|v| {
            // CozoDB returns strings as either "value" or {"Str": "value"}
            v.as_str().or_else(|| v.get("Str").and_then(|s| s.as_str()))
        })
        .ok_or_else(|| format!("no domain at ordinal {ordinal}"))?;

    Ok(name.to_string())
}

/// Serialize a Turn to bytes (12 bytes: 5 u16 fields).
pub fn turn_to_bytes(turn: &Turn) -> Vec<u8> {
    let mut buf = Vec::with_capacity(10);
    buf.extend_from_slice(&turn.turn_id.to_le_bytes());
    buf.extend_from_slice(&turn.query.to_le_bytes());
    buf.extend_from_slice(&turn.arg0.to_le_bytes());
    buf.extend_from_slice(&turn.arg1.to_le_bytes());
    buf.extend_from_slice(&turn.arg2.to_le_bytes());
    buf
}

/// Deserialize a Turn from bytes.
pub fn turn_from_bytes(data: &[u8]) -> Option<Turn> {
    if data.len() < 10 { return None; }
    Some(Turn {
        turn_id: u16::from_le_bytes([data[0], data[1]]),
        query: u16::from_le_bytes([data[2], data[3]]),
        arg0: u16::from_le_bytes([data[4], data[5]]),
        arg1: u16::from_le_bytes([data[6], data[7]]),
        arg2: u16::from_le_bytes([data[8], data[9]]),
    })
}

/// Serialize a Response to bytes (header + entries).
pub fn response_to_bytes(resp: &Response) -> Vec<u8> {
    let mut buf = Vec::with_capacity(6 + resp.entries.len() * 8);
    buf.extend_from_slice(&resp.turn_id.to_le_bytes());
    buf.extend_from_slice(&resp.response.to_le_bytes());
    buf.extend_from_slice(&resp.count.to_le_bytes());
    for entry in &resp.entries {
        buf.extend_from_slice(&entry.field0.to_le_bytes());
        buf.extend_from_slice(&entry.field1.to_le_bytes());
        buf.extend_from_slice(&entry.field2.to_le_bytes());
        buf.extend_from_slice(&entry.field3.to_le_bytes());
    }
    buf
}
