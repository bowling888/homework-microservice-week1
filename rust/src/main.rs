use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    routing::get,
    Json, Router,
};
use chrono::{DateTime, FixedOffset, Utc};
use serde::Serialize;
use std::{env, fs, fs::OpenOptions, io::Write, net::SocketAddr};

#[derive(Clone)]
struct AppConfig {
    first_name: String,
    last_name: String,
    nick_name: String,
    language_value: String,
    log_file: String,
}

#[derive(Serialize)]
struct Payload {
    first_name: String,
    last_name: String,
    nick_name: String,
    language: String,
}

fn utc7_timestamp() -> String {
    let offset = FixedOffset::east_opt(7 * 3600).expect("valid fixed offset");
    let now_utc: DateTime<Utc> = Utc::now();
    // Example: 2026-03-20 23:42:08.123 +07:00
    now_utc
        .with_timezone(&offset)
        .format("%Y-%m-%d %H:%M:%S%.3f %:z")
        .to_string()
}

async fn handler(State(cfg): State<AppConfig>) -> impl IntoResponse {
    // Write a simple log line per request.
    // Ensure log directory exists (e.g. /logs mounted via docker volume).
    if let Some(parent) = std::path::Path::new(&cfg.log_file).parent() {
        let _ = fs::create_dir_all(parent);
    }

    match OpenOptions::new()
        .create(true)
        .append(true)
        .open(&cfg.log_file)
    {
        Ok(mut f) => {
            let ts = utc7_timestamp();
            let line = format!(
                "{} [rust] GET / -> {{first_name={}, last_name={}, nick_name={}, language={}}}\n",
                ts,
                cfg.first_name, cfg.last_name, cfg.nick_name, cfg.language_value
            );
            if let Err(e) = f.write_all(line.as_bytes()) {
                eprintln!("[rust] failed to write log {}: {}", cfg.log_file, e);
            }
        }
        Err(e) => {
            eprintln!("[rust] failed to open log {}: {}", cfg.log_file, e);
        }
    }

    let payload = Payload {
        first_name: cfg.first_name.clone(),
        last_name: cfg.last_name.clone(),
        nick_name: cfg.nick_name.clone(),
        language: cfg.language_value.clone(),
    };

    (StatusCode::OK, Json(payload))
}

#[tokio::main]
async fn main() {
    let first_name = env::var("FIRST_NAME").unwrap_or_else(|_| "นิฤมล".to_string());
    let last_name = env::var("LAST_NAME").unwrap_or_else(|_| "ทดสอบ".to_string());
    let nick_name = env::var("NICK_NAME").unwrap_or_else(|_| "Test".to_string());
    let language_value = env::var("LANGUAGE_VALUE").unwrap_or_else(|_| "rust".to_string());
    let log_file = env::var("LOG_FILE").unwrap_or_else(|_| "/logs/rust.log".to_string());

    let cfg = AppConfig {
        first_name,
        last_name,
        nick_name,
        language_value,
        log_file,
    };

    let app = Router::new().route("/", get(handler)).with_state(cfg);
    let addr = SocketAddr::from(([0, 0, 0, 0], 8080));
    let listener = tokio::net::TcpListener::bind(addr)
        .await
        .expect("failed to bind");

    axum::serve(listener, app).await.expect("server crashed");
}

