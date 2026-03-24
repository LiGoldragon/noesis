//! OpenAI-compatible LLM client for the noesis harness.
//! Supports OpenAI, litellm, and any server speaking the chat completions API.

use serde::{Deserialize, Serialize};

#[derive(Clone)]
pub struct LlmClient {
    http: reqwest::Client,
    base_url: String,
    api_key: Option<String>,
    model: String,
}

#[derive(Serialize)]
struct ChatRequest {
    model: String,
    messages: Vec<Message>,
    temperature: f32,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct Message {
    pub role: String,
    pub content: String,
}

#[derive(Deserialize)]
struct ChatResponse {
    choices: Vec<Choice>,
}

#[derive(Deserialize)]
struct Choice {
    message: Message,
}

impl LlmClient {
    pub fn new(base_url: &str, api_key: Option<String>, model: &str) -> Self {
        Self {
            http: reqwest::Client::new(),
            base_url: base_url.trim_end_matches('/').to_string(),
            api_key,
            model: model.to_string(),
        }
    }

    /// Send a chat completion request and return the assistant's response.
    pub async fn chat(&self, messages: &[Message]) -> Result<String, Box<dyn std::error::Error>> {
        let url = format!("{}/chat/completions", self.base_url);

        let body = ChatRequest {
            model: self.model.clone(),
            messages: messages.to_vec(),
            temperature: 0.0,
        };

        let mut req = self.http.post(&url).json(&body);

        if let Some(key) = &self.api_key {
            req = req.bearer_auth(key);
        }

        let resp = req.send().await?;

        if !resp.status().is_success() {
            let status = resp.status();
            let body = resp.text().await.unwrap_or_default();
            return Err(format!("LLM API error {status}: {body}").into());
        }

        let chat_resp: ChatResponse = resp.json().await?;
        let content = chat_resp
            .choices
            .first()
            .map(|c| c.message.content.clone())
            .unwrap_or_default();

        Ok(content)
    }
}

impl Message {
    pub fn system(content: &str) -> Self {
        Self { role: "system".into(), content: content.into() }
    }

    pub fn user(content: &str) -> Self {
        Self { role: "user".into(), content: content.into() }
    }

    pub fn assistant(content: &str) -> Self {
        Self { role: "assistant".into(), content: content.into() }
    }
}
