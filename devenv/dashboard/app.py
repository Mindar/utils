from flask import Flask, render_template
import os

app = Flask(__name__)

# Services ordered as requested: dashboard, postgres, mailpit, valkey, grafana, prometheus, rest
SERVICES = {
    "Dashboard": {
        "url": "http://localhost:8080",
        "ui": "http://localhost:8080",
        "description": "DevEnv Dashboard",
        "icon": "🎛️",
        "credentials": {
            "URL": "http://localhost:8080"
        }
    },
    "PostgreSQL (pgvector)": {
        "url": "localhost:5432",
        "ui": "http://localhost:5050",
        "ui_name": "pgAdmin",
        "description": "PostgreSQL 18 with pgvector extension",
        "credentials": {
            "URL": "localhost:5432",
            "Database": "devenv",
            "Username": "admin",
            "Password": "admin",
            "Host": "localhost",
            "Port": "5432"
        },
        "icon": "🐘"
    },
    "Mailpit": {
        "url": "http://localhost:8025",
        "ui": "http://localhost:8025",
        "description": "Email testing and SMTP server",
        "credentials": {
            "URL": "http://localhost:8025",
            "SMTP": "localhost:1025"
        },
        "icon": "📧"
    },
    "Valkey": {
        "url": "localhost:6379",
        "ui": "http://localhost:5540",
        "ui_name": "RedisInsight",
        "description": "Valkey (Redis fork) - In-memory data store",
        "credentials": {
            "URL": "localhost:6379",
            "Password": "admin",
            "Host": "localhost",
            "Port": "6379"
        },
        "icon": "🔑"
    },
    "Grafana": {
        "url": "http://localhost:3000",
        "ui": "http://localhost:3000",
        "description": "Observability platform with dashboards",
        "credentials": {
            "URL": "http://localhost:3000",
            "Username": "admin",
            "Password": "admin"
        },
        "icon": "📈"
    },
    "Prometheus": {
        "url": "http://localhost:9090",
        "ui": "http://localhost:9090",
        "description": "Metrics collection and alerting",
        "credentials": {
            "URL": "http://localhost:9090"
        },
        "icon": "📊"
    },
    "LLDAP": {
        "url": "ldap://localhost:3890",
        "ui": "http://localhost:17170",
        "description": "Lightweight LDAP server",
        "credentials": {
            "URL": "ldap://localhost:3890",
            "Web UI": "http://localhost:17170",
            "Base DN": "dc=local,dc=aal,dc=sh",
            "Admin Password": "admin"
        },
        "icon": "🔐"
    },
    "Jaeger": {
        "url": "http://localhost:16686",
        "ui": "http://localhost:16686",
        "description": "Distributed tracing platform",
        "credentials": {
            "URL": "http://localhost:16686"
        },
        "icon": "🔍"
    },
    "Loki": {
        "url": "http://localhost:3100",
        "ui": "http://localhost:3100",
        "description": "Log aggregation system (view in Grafana)",
        "credentials": {
            "URL": "http://localhost:3100"
        },
        "icon": "📋"
    },
    "ClickHouse": {
        "url": "http://localhost:8123",
        "ui": "http://localhost:8123",
        "description": "ClickHouse OLAP Database",
        "credentials": {
            "URL": "http://localhost:8123",
            "Username": "admin",
            "Password": "admin",
            "HTTP Port": "8123",
            "Native Port": "9000"
        },
        "icon": "🏠"
    }
}

@app.route("/")
def index():
    return render_template("index.html", services=SERVICES)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=True)
