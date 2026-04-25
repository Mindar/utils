# DevEnv - Full-Service Local Development Environment

A comprehensive Docker Compose setup for local development with all essential services integrated together.

## Overview

This DevEnv provides a complete local development stack with:
- **Databases**: PostgreSQL (with pgvector), ClickHouse, Valkey (Redis fork)
- **Identity**: LLDAP (Lightweight LDAP)
- **Monitoring**: Prometheus, Grafana, Jaeger, Loki + Promtail
- **Testing**: Mailpit (email testing)
- **Dashboard**: Web-based service discovery and credential management

All services are tightly integrated - for example, LLDAP uses PostgreSQL as its backend database.

## Quick Start

```bash
# Make executable
chmod +x devenv.sh

# (Optional) Add to PATH for global access
ln -s "$(pwd)/devenv.sh" "$HOME/.local/bin/devenv"
# Now you can use just 'devenv' instead of './devenv.sh'

# Start all services (auto-initializes if needed, auto-starts Docker if needed)
./devenv.sh up
# Or if linked to PATH: devenv up

# Stop all services
./devenv.sh down

# Check status
./devenv.sh status

# View logs
./devenv.sh logs
./devenv.sh logs postgres

# Clean containers and networks (keeps data)
./devenv.sh clean

# ⚠️ Purge all data (completely removes everything)
./devenv.sh purge
```

## Services Overview

Once running, access all services through the **Dashboard** at http://localhost:8080

| Service | URL | Credentials | Description |
|---------|-----|-------------|-------------|
| **Dashboard** | http://localhost:8080 | - | Service discovery & credentials UI |
| **PostgreSQL** | localhost:5432 | admin/admin | PostgreSQL with pgvector extension |
| **ClickHouse** | http://localhost:8123 | admin/admin | OLAP database |
| **Valkey** | localhost:6379 | default/admin | Redis-compatible in-memory store |
| **LLDAP** | http://localhost:17170 | admin | Lightweight LDAP server (backend: PostgreSQL) |
| **Prometheus** | http://localhost:9090 | - | Metrics collection & alerting |
| **Jaeger** | http://localhost:16686 | - | Distributed tracing |
| **Grafana** | http://localhost:3000 | admin/admin | Observability dashboards |
| **Loki** | http://localhost:3100 | - | Log aggregation (view in Grafana) |
| **Mailpit** | http://localhost:8025 | - | Email testing & SMTP |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        DevEnv Stack                         │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │  Dashboard  │  │   Grafana   │  │  Prometheus         │ │
│  │  (Flask)    │  │  (UI/Obs)   │  │  (Metrics)          │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │   Jaeger    │  │    Loki     │  │  Promtail           │ │
│  │  (Tracing)  │  │  (Logging)  │  │  (Log Collector)    │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │   LLDAP     │  │   Mailpit   │  │  Valkey             │ │
│  │  (LDAP)     │  │  (Email)    │  │  (Cache/Queue)      │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────┐  ┌────────────────────────────────┐ │
│  │   PostgreSQL        │  │   ClickHouse                  │ │
│  │  (Primary DB)       │  │  (Analytics DB)               │ │
│  │  - devenv DB        │  │                               │ │
│  │  - lldap DB         │  │                               │ │
│  └─────────────────────┘  └────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Service Details

### PostgreSQL (pgvector)
- **Image**: `pgvector/pgvector:pg18-trixie`
- **Features**: Full PostgreSQL 18 (Trixie) with pgvector extension for vector similarity search
- **Note**: PostgreSQL 18+ uses version-specific data path. Volume is mounted at `/var/lib/postgresql`
- **Databases**: `devenv` (main), `lldap` (for LLDAP backend)
- **Connection**: `postgresql://admin:admin@localhost:5432/devenv`

### ClickHouse
- **Image**: `clickhouse/clickhouse-server`
- **Features**: Columnar OLAP database for analytics
- **Ports**: 8123 (HTTP), 9000 (Native protocol)
- **Connection**: `http://admin:admin@localhost:8123`

### Valkey
- **Image**: `valkey/valkey`
- **Features**: Redis-compatible in-memory data store (Redis fork by AWS)
- **Auth**: Password required (`admin`)

### LLDAP
- **Image**: `lldap/lldap`
- **Features**: Lightweight LDAP server with web UI
- **Backend**: Uses PostgreSQL (`lldap` database)
- **Base DN**: `dc=local,dc=aal,dc=sh`

### Monitoring Stack
- **Prometheus**: Metrics collection (port 9090)
- **Grafana**: Unified dashboards (admin/admin)
  - Pre-configured with Prometheus, Loki, Jaeger, and ClickHouse datasources
- **Jaeger**: Distributed tracing (port 16686)
- **Loki + Promtail**: Log aggregation (logs available in Grafana)

### Mailpit
- **Image**: `axllent/mailpit`
- **Features**: Email testing with web UI
- **SMTP**: Port 1025 (for your apps to send mail)
- **Web UI**: Port 8025 (to view captured emails)

## Usage Examples

### Connect to PostgreSQL
```bash
psql postgresql://admin:admin@localhost:5432/devenv
```

### Connect to ClickHouse
```bash
curl 'http://admin:admin@localhost:8123/'
```

### Connect to Valkey
```bash
redis-cli -h localhost -p 6379 -a admin
```

### Send Test Email
```bash
telnet localhost 1025
HELO localhost
MAIL FROM: test@example.com
RCPT TO: recipient@example.com
DATA
Subject: Test Email

This is a test email.
.
QUIT
```

### Query Logs in Grafana
1. Open Grafana at http://localhost:3000
2. Go to Explore
3. Select Loki datasource
4. Query: `{job="docker"}` or `{container="devenv-postgres"}`

## Customization

### Environment Variables

Service configurations are in `docker-compose.yml`. Key variables:

- `POSTGRES_PASSWORD`: Change PostgreSQL password
- `CLICKHOUSE_PASSWORD`: Change ClickHouse password
- `GF_SECURITY_ADMIN_PASSWORD`: Change Grafana password
- `LLDAP_LDAP_USER_PASS`: Change LLDAP admin password

### Add New Services

Edit `docker-compose.yml` and add your service:

```yaml
  myservice:
    image: myimage:latest
    ports:
      - "8081:8080"
    networks:
      - devenv
```

Then update `dashboard/app.py` to include the new service in the `SERVICES` dictionary.

### Persistent Data

All data is stored in Docker volumes:
- `postgres_data`: PostgreSQL data
- `clickhouse_data`: ClickHouse data
- `valkey_data`: Valkey data
- `prometheus_data`: Prometheus metrics
- `grafana_data`: Grafana dashboards and config
- `loki_data`: Loki logs
- `mailpit_data`: Mailpit emails

Use `./devenv.sh clean` to remove all volumes (WARNING: data will be lost).

## Requirements

- Docker Engine 20.10+
- Docker Compose 2.0+
- ~4GB RAM available

## DevEnv Commands

| Command | Description |
|---------|-------------|
| `./devenv.sh up` | Start the environment (auto-initializes if needed, auto-starts Docker) |
| `./devenv.sh down` | Stop all services |
| `./devenv.sh restart` | Restart all services |
| `./devenv.sh status` | Show status of all services |
| `./devenv.sh logs [service]` | Show logs for all or specific service |
| `./devenv.sh clean` | Remove containers/networks (keeps data volumes) |
| `./devenv.sh purge` | ⚠️ **Delete all data** - completely removes everything (no reinit) |
| `./devenv.sh version` | Show version information (also `--version` or `-v`) |
| `./devenv.sh help` | Show help message |

**Note**: If you linked the script to PATH (see Quick Start), you can use `devenv` instead of `./devenv.sh` (e.g., `devenv up`, `devenv status`).

### Automatic Initialization

The `up` command will automatically detect if this is the first run and initialize the environment accordingly. An initialization marker (`.devenv-initialized`) is created after the first successful start.

### Automatic Docker Management

If Docker is not running when you execute `./devenv.sh up`, the script will attempt to start it automatically using `systemctl`. This may prompt for your sudo password if you don't have passwordless sudo configured.

### Purge vs Clean

- **clean**: Removes containers and networks, but preserves all data volumes. Use this when you want to temporarily stop and restart without losing data.
- **purge**: ⚠️ **Destructive operation** - Removes everything including data volumes. Use this when you want to completely remove your DevEnv. No reinitialization happens - you'll need to run `./devenv.sh up` afterwards if you want to start fresh.

## Troubleshooting

### Port Conflicts
If ports are already in use, edit `docker-compose.yml` and change the host port:
```yaml
ports:
  - "5433:5432"  # Use 5433 instead of 5432
```

### Services Not Starting
Check logs:
```bash
./devenv.sh logs
./devenv.sh logs postgres
```

### Dashboard Not Accessible
Ensure the dashboard container built successfully:
```bash
docker-compose logs dashboard
```

### Reset Everything

**Quick reset (removes containers, keeps data):**
```bash
./devenv.sh clean
./devenv.sh up
```

**Complete removal (removes all data):**
```bash
./devenv.sh purge
```

The `purge` command will:
1. Stop all services
2. Delete all volumes, data, and networks
3. Remove the initialization marker

After purging, run `./devenv.sh up` to create a fresh environment.

## Development

### Rebuilding the Dashboard
```bash
docker-compose build dashboard
docker-compose up -d dashboard
```

### Modifying Configurations
- **Prometheus**: Edit `config/prometheus.yml`
- **Grafana Datasources**: Edit `config/grafana-datasources.yaml`
- **Loki**: Edit `config/loki-config.yaml`
- **Promtail**: Edit `config/promtail-config.yaml`

After config changes:
```bash
./devenv.sh restart
```

## Security Notes

⚠️ **This is for local development only!**

- Default passwords are intentionally simple (`admin`/`admin`)
- Services bind to all interfaces (0.0.0.0)
- No TLS/SSL configured
- Do not expose these services to the internet

For production use:
- Change all default passwords
- Enable TLS
- Use secrets management
- Restrict network access

## License

MIT - Feel free to use and modify for your development needs.

## Contributing

Contributions welcome! Feel free to submit issues or pull requests.
