from flask import Flask, render_template, jsonify, request
import docker
import os
from datetime import datetime

app = Flask(__name__)

# Get project name from environment
PROJECT_NAME = os.environ.get('COMPOSE_PROJECT_NAME', 'devenv')

# Initialize Docker client
client = docker.from_env()

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
    "Langfuse": {
        "url": "http://localhost:3050",
        "ui": "http://localhost:3050",
        "description": "LLM observability and tracing platform",
        "credentials": {
            "URL": "http://localhost:3050",
            "Email": "admin@local.aal.sh",
            "Password": "password",
            "Public Key": "pk-lf-dev-0000000000000000",
            "Secret Key": "sk-lf-dev-00000000000000000000000000000000"
        },
        "icon": "🔮"
    },
    "MinIO": {
        "url": "http://localhost:9201",
        "ui": "http://localhost:9201",
        "description": "S3-compatible object storage for Langfuse",
        "credentials": {
            "URL": "http://localhost:9201",
            "S3 API": "localhost:9200",
            "Username": "admin",
            "Password": "password"
        },
        "icon": "📦"
    },
    "LLDAP": {
        "url": "ldap://localhost:3890",
        "ui": "http://localhost:17170",
        "description": "Lightweight LDAP server",
        "credentials": {
            "URL": "ldap://localhost:3890",
            "Web UI": "http://localhost:17170",
            "Base DN": "dc=local,dc=aal,dc=sh",
            "Admin Password": "password"
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


def get_container_status():
    """Get status of all devenv containers"""
    containers = []
    try:
        all_containers = client.containers.list(all=True)
        for container in all_containers:
            # Only show containers from this project
            if container.name.startswith(f"{PROJECT_NAME}-"):
                status = container.status
                health = "unknown"
                
                # Get health status if available
                if container.attrs.get('State', {}).get('Health'):
                    health = container.attrs['State']['Health']['Status']
                
                # Calculate uptime
                uptime = "N/A"
                if container.attrs.get('State', {}).get('StartedAt'):
                    started = container.attrs['State']['StartedAt']
                    if started != '0001-01-01T00:00:00Z':
                        started_time = datetime.fromisoformat(started.replace('Z', '+00:00'))
                        uptime_delta = datetime.now(started_time.tzinfo) - started_time
                        hours = int(uptime_delta.total_seconds() // 3600)
                        minutes = int((uptime_delta.total_seconds() % 3600) // 60)
                        uptime = f"{hours}h {minutes}m"
                
                # Get ports
                ports = []
                for port, bindings in container.ports.items():
                    if bindings:
                        for binding in bindings:
                            host_port = binding.get('HostPort', '')
                            if host_port:
                                ports.append(f"{host_port}->{port}")
                
                containers.append({
                    'id': container.short_id,
                    'name': container.name,
                    'image': container.image.tags[0] if container.image.tags else 'unknown',
                    'status': status,
                    'health': health,
                    'uptime': uptime,
                    'ports': ports
                })
    except Exception as e:
        print(f"Error getting containers: {e}")
    
    return containers


@app.route("/")
def index():
    return render_template("index.html", services=SERVICES)


@app.route("/api/containers")
def get_containers():
    """API endpoint to get container status"""
    return jsonify(get_container_status())


@app.route("/api/containers/<container_name>/start", methods=["POST"])
def start_container(container_name):
    """Start a container"""
    try:
        container = client.containers.get(container_name)
        container.start()
        return jsonify({'success': True, 'message': f'Started {container_name}'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route("/api/containers/<container_name>/stop", methods=["POST"])
def stop_container(container_name):
    """Stop a container"""
    try:
        container = client.containers.get(container_name)
        container.stop(timeout=30)
        return jsonify({'success': True, 'message': f'Stopped {container_name}'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route("/api/containers/<container_name>/restart", methods=["POST"])
def restart_container(container_name):
    """Restart a container"""
    try:
        container = client.containers.get(container_name)
        container.restart(timeout=30)
        return jsonify({'success': True, 'message': f'Restarted {container_name}'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route("/api/containers/<container_name>/logs")
def get_logs(container_name):
    """Get container logs"""
    try:
        container = client.containers.get(container_name)
        logs = container.logs(tail=100, timestamps=True).decode('utf-8')
        return jsonify({'success': True, 'logs': logs})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=True)
