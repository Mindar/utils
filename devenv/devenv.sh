#!/bin/bash

# DevEnv Management Script
# Usage: devenv [command]
#        ./devenv.sh [command]  (when run directly)

set -e

# Version
VERSION="1.0.0"

# Get the directory of the actual script (resolves symlinks)
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
PROJECT_NAME="devenv"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"
INIT_MARKER="${SCRIPT_DIR}/.devenv-initialized"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[DevEnv]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if docker and docker-compose are installed
check_prerequisites() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
}

# Check if docker is running and start it if not
ensure_docker_running() {
    if ! docker info &> /dev/null; then
        print_warning "Docker is not running. Attempting to start it..."
        
        # Try to start docker using systemctl
        if command -v systemctl &> /dev/null; then
            print_status "Starting Docker service with systemctl..."
            if sudo -n true 2>/dev/null; then
                # User has passwordless sudo
                sudo systemctl start docker
            else
                # Need to prompt for password
                print_status "Docker service requires elevated privileges. Please enter your sudo password."
                sudo systemctl start docker
            fi
            
            # Wait a bit for docker to start
            sleep 2
            
            # Verify docker is now running
            if ! docker info &> /dev/null; then
                print_error "Failed to start Docker service. Please start it manually."
                exit 1
            fi
            print_success "Docker service started successfully"
        else
            print_error "Cannot start Docker automatically (systemctl not available)."
            print_error "Please start Docker manually and try again."
            exit 1
        fi
    fi
}

# Check if devenv is initialized
is_initialized() {
    # Check if volumes exist and have data
    local postgres_volume
    postgres_volume=$(docker volume ls -q -f "name=${PROJECT_NAME}_postgres_data" 2>/dev/null || true)
    
    if [ -z "$postgres_volume" ]; then
        return 1
    fi
    
    # Check if init marker exists
    if [ ! -f "$INIT_MARKER" ]; then
        return 1
    fi
    
    return 0
}

# Mark devenv as initialized
mark_initialized() {
    touch "$INIT_MARKER"
}

# Start the development environment
start() {
    print_status "Starting DevEnv..."
    
    check_prerequisites
    ensure_docker_running
    
    cd "${SCRIPT_DIR}"
    
    # Check if already initialized
    if ! is_initialized; then
        print_status "First time initialization detected..."
        print_status "Creating volumes and starting services..."
    fi
    
    # Build and start services
    docker-compose -f "${COMPOSE_FILE}" -p "${PROJECT_NAME}" up -d --build
    
    # Mark as initialized
    mark_initialized
    
    print_success "DevEnv started successfully!"
    echo ""
    echo "📊 Dashboard: http://localhost:8080"
    echo ""
    echo "Available Services:"
    echo "  🐘 PostgreSQL:    localhost:5432 (admin/admin)"
    echo "  🏠 ClickHouse:    http://localhost:8123 (admin/admin)"
    echo "  🔑 Valkey:        localhost:6379 (admin)"
    echo "  🔮 Langfuse:      http://localhost:3050 (admin/admin)"
    echo "  📦 MinIO:         http://localhost:9201 (admin/password)"
    echo "  📊 Prometheus:    http://localhost:9090"
    echo "  🔍 Jaeger:        http://localhost:16686"
    echo "  📈 Grafana:       http://localhost:3000 (admin/admin)"
    echo "  📋 Loki:          http://localhost:3100"
    echo "  📧 Mailpit:       http://localhost:8025"
    echo "  🔐 LLDAP:         http://localhost:17170 (admin)"
    echo ""
}

# Stop the development environment
stop() {
    print_status "Stopping DevEnv..."
    
    cd "${SCRIPT_DIR}"
    docker-compose -f "${COMPOSE_FILE}" -p "${PROJECT_NAME}" down
    
    print_success "DevEnv stopped successfully!"
}

# Restart the development environment
restart() {
    print_status "Restarting DevEnv..."
    stop
    start
}

# Show status of all services
status() {
    print_status "DevEnv Status:"
    echo ""
    
    cd "${SCRIPT_DIR}"
    docker-compose -f "${COMPOSE_FILE}" -p "${PROJECT_NAME}" ps
    
    echo ""
    echo "Service URLs:"
    echo "  Dashboard:    http://localhost:8080"
    echo "  PostgreSQL:   localhost:5432"
    echo "  ClickHouse:   http://localhost:8123"
    echo "  Valkey:       localhost:6379"
    echo "  LLDAP:        http://localhost:17170"
    echo "  Prometheus:   http://localhost:9090"
    echo "  Jaeger:       http://localhost:16686"
    echo "  Grafana:      http://localhost:3000"
    echo "  Loki:         http://localhost:3100"
    echo "  Mailpit:      http://localhost:8025"
}

# Show logs for a specific service or all services
logs() {
    local service="$1"
    
    cd "${SCRIPT_DIR}"
    
    if [ -z "$service" ]; then
        print_status "Showing logs for all services (Ctrl+C to exit)..."
        docker-compose -f "${COMPOSE_FILE}" -p "${PROJECT_NAME}" logs -f --tail=100
    else
        print_status "Showing logs for $service (Ctrl+C to exit)..."
        docker-compose -f "${COMPOSE_FILE}" -p "${PROJECT_NAME}" logs -f --tail=100 "$service"
    fi
}

# Clean up containers and networks (keeps volumes)
clean() {
    print_warning "This will remove all containers and networks!"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        print_status "Cleaning up DevEnv..."
        cd "${SCRIPT_DIR}"
        docker-compose -f "${COMPOSE_FILE}" -p "${PROJECT_NAME}" down --remove-orphans
        print_success "DevEnv cleaned up successfully!"
    else
        print_status "Cleanup cancelled."
    fi
}

# Purge all data - completely remove everything
purge() {
    print_warning "⚠️  WARNING: This will DELETE ALL DATA in your DevEnv!"
    print_warning "    All databases, logs, and configurations will be permanently removed."
    print_warning "    This action CANNOT be undone!"
    echo ""
    read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirm
    
    if [ "$confirm" = "yes" ]; then
        print_status "Stopping DevEnv..."
        cd "${SCRIPT_DIR}"
        docker-compose -f "${COMPOSE_FILE}" -p "${PROJECT_NAME}" down 2>/dev/null || true
        
        print_status "Removing all volumes and data..."
        docker-compose -f "${COMPOSE_FILE}" -p "${PROJECT_NAME}" down -v --remove-orphans 2>/dev/null || true
        
        # Also explicitly remove the volumes and networks
        docker volume rm -f "${PROJECT_NAME}_postgres_data" "${PROJECT_NAME}_clickhouse_data" "${PROJECT_NAME}_valkey_data" "${PROJECT_NAME}_prometheus_data" "${PROJECT_NAME}_grafana_data" "${PROJECT_NAME}_loki_data" "${PROJECT_NAME}_mailpit_data" 2>/dev/null || true
        
        # Remove the Docker network
        docker network rm -f "${PROJECT_NAME}_devenv" 2>/dev/null || true
        
        # Remove init marker
        if [ -n "$INIT_MARKER" ] && [ -f "$INIT_MARKER" ] && [ "$(basename "$INIT_MARKER")" = ".devenv-initialized" ]; then
            rm -f "$INIT_MARKER"
        fi
        
        print_success "All data purged successfully!"
        echo ""
        print_status "Your DevEnv has been completely removed."
        print_status "Run './devenv.sh up' to create a new environment."
    else
        print_status "Purge cancelled. No data was removed."
    fi
}

# Show version
show_version() {
    echo "DevEnv version $VERSION"
}

# Display help
help() {
    echo "DevEnv Management Script"
    echo ""
    echo "Usage: ./devenv.sh [command]"
    echo ""
    echo "Commands:"
    echo "  up       Start the development environment (auto-initializes if needed)"
    echo "  down     Stop the development environment"
    echo "  restart  Restart the development environment"
    echo "  status   Show status of all services"
    echo "  logs     Show logs (optionally specify service name)"
    echo "  clean    Remove all containers and networks (keeps data)"
    echo "  purge    ⚠️  DELETE ALL DATA and containers (no reinit)"
    echo "  version  Show version information"
    echo "  help     Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./devenv.sh up"
    echo "  ./devenv.sh logs postgres"
    echo "  ./devenv.sh purge"
    echo ""
    echo "Notes:"
    echo "  - The 'up' command will automatically start Docker if it's not running"
    echo "  - The 'up' command will automatically initialize the environment on first run"
    echo "  - Use 'purge' to completely reset all data and start fresh"
}

# Main command handler
case "${1:-help}" in
    up|start)
        start
        ;;
    down|stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    logs)
        logs "$2"
        ;;
    clean)
        clean
        ;;
    purge)
        purge
        ;;
    version|--version|-v)
        show_version
        ;;
    help|--help|-h)
        help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        help
        exit 1
        ;;
esac
