//! capnp RPC client for connecting to samskara and other agents.

use std::path::Path;

use futures::AsyncReadExt;

use crate::samskara_rpc_capnp::samskara;

/// Connect to a samskara capnp RPC server on a Unix socket.
/// Returns the Samskara client capability.
pub async fn connect_samskara(
    socket_path: &Path,
) -> Result<(samskara::Client, capnp_rpc::RpcSystem<capnp_rpc::rpc_twoparty_capnp::Side>), Box<dyn std::error::Error>> {
    let stream = tokio::net::UnixStream::connect(socket_path).await?;
    let stream = tokio_util::compat::TokioAsyncReadCompatExt::compat(stream);
    let (reader, writer) = stream.split();

    let network = capnp_rpc::twoparty::VatNetwork::new(
        reader,
        writer,
        capnp_rpc::rpc_twoparty_capnp::Side::Client,
        Default::default(),
    );

    let mut rpc_system = capnp_rpc::RpcSystem::new(Box::new(network), None);
    let client: samskara::Client = rpc_system.bootstrap(capnp_rpc::rpc_twoparty_capnp::Side::Server);

    Ok((client, rpc_system))
}

/// Call samskara's query method over capnp RPC.
pub async fn rpc_query(client: &samskara::Client, script: &str) -> Result<Vec<u8>, Box<dyn std::error::Error>> {
    let mut request = client.query_request();
    request.get().set_script(script.as_bytes());
    let response = request.send().promise.await?;
    let result = response.get()?.get_result()?;
    Ok(result.to_vec())
}

/// Call samskara's listRelations method over capnp RPC.
pub async fn rpc_list_relations(client: &samskara::Client) -> Result<Vec<u8>, Box<dyn std::error::Error>> {
    let request = client.list_relations_request();
    let response = request.send().promise.await?;
    let result = response.get()?.get_result()?;
    Ok(result.to_vec())
}

/// Call samskara's describeRelation method over capnp RPC.
pub async fn rpc_describe_relation(client: &samskara::Client, name: &str) -> Result<Vec<u8>, Box<dyn std::error::Error>> {
    let mut request = client.describe_relation_request();
    request.get().set_name(name.as_bytes());
    let response = request.send().promise.await?;
    let result = response.get()?.get_result()?;
    Ok(result.to_vec())
}

/// Call samskara's assertThought method over capnp RPC.
pub async fn rpc_assert_thought(
    client: &samskara::Client,
    kind: &str,
    scope: &str,
    status: &str,
    title: &str,
    body: &str,
) -> Result<Vec<u8>, Box<dyn std::error::Error>> {
    let mut request = client.assert_thought_request();
    let mut params = request.get();
    params.set_kind(kind.as_bytes());
    params.set_scope(scope.as_bytes());
    params.set_status(status.as_bytes());
    params.set_title(title.as_bytes());
    params.set_body(body.as_bytes());
    let response = request.send().promise.await?;
    let result = response.get()?.get_title_hash()?;
    Ok(result.to_vec())
}
