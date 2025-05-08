use actix_web::{web, App, HttpResponse, HttpServer, Responder};
use std::net::SocketAddr;
use std::env;
use std::net::IpAddr;
use std::net::Ipv4Addr;
use hostname::get;

async fn home() -> impl Responder {

    let server_name = get()
        .ok()
        .and_then(|h| h.into_string().ok())
        .unwrap_or_else(|| "Unknown".to_string());
    
    let server_ip = match get_local_ip() {
        Some(ip) => ip.to_string(),
        None => "Unavailable".to_string(),
    };

    let html_content = format!(
            r#"
            <html>
                <head><title>Rust Web App</title></head>
                <body>
                    <center>
                        <h1>Welcome to the Rust Web App!</h1>
                        <img src="https://www.rust-lang.org/logos/rust-logo-512x512.png" alt="Rust Logo" width="200" height="200">                    
                        <h2>Server Information</h2>
                        <p>This is a simple web application built with Rust and Actix-web.</p>
                        <p>It is designed to run in a Docker container.</p>
                        <h4>Server Name: {}</h4>
                        <h4>IP Address: {}</h4>
                    </center>
                </body>
            </html>
            "#,
            server_name, server_ip
        );
    
        HttpResponse::Ok()
            .content_type("text/html; charset=utf-8")
            .body(html_content)
    }

fn get_local_ip() -> Option<IpAddr> {
    let hostname = env::var("HOSTNAME").unwrap_or_else(|_| "localhost".to_string());
    if hostname == "localhost" {
        Some(Ipv4Addr::new(127, 0, 0, 1).into())
    } else {
        None
    }
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let addr = "0.0.0.0:8080".parse::<SocketAddr>().unwrap();
    println!("Starting server at {:?}", addr);

    HttpServer::new(|| {
        App::new()
            .route("/", web::get().to(home))
    })
    .bind(addr)?
    .run()
    .await
}
