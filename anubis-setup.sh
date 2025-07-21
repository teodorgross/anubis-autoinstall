#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root!"
        exit 1
    fi
}

detect_os() {
    if [ -f /etc/debian_version ]; then
        OS="debian"
        log_info "Debian/Ubuntu system detected"
    elif [ -f /etc/redhat-release ]; then
        OS="redhat"
        log_info "Red Hat/CentOS/Fedora system detected"
    else
        log_error "Unsupported operating system!"
        exit 1
    fi
}

validate_service_name() {
    local service="$1"
    if [[ ! "$service" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_error "Service name may only contain letters, numbers, underscores and hyphens!"
        return 1
    fi
    return 0
}

validate_port() {
    local port="$1"
    if [[ ! "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        log_error "Port must be a number between 1 and 65535!"
        return 1
    fi
    return 0
}

validate_domain() {
    local domain="$1"
    if [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        log_error "Invalid domain format!"
        return 1
    fi
    return 0
}

validate_email() {
    local email="$1"
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        log_error "Invalid email address!"
        return 1
    fi
    return 0
}

get_input() {
    local prompt="$1"
    local validation_func="$2"
    local value
    
    while true; do
        read -p "$prompt: " value
        if [ -z "$value" ]; then
            log_error "Input cannot be empty!"
            continue
        fi
        
        if $validation_func "$value"; then
            echo "$value"
            return 0
        fi
    done
}

find_free_port() {
    local start_port="$1"
    local port=$start_port
    
    while ss -tlnp | grep -q ":$port "; do
        ((port++))
        if [ $port -gt 65535 ]; then
            log_error "No free port found!"
            exit 1
        fi
    done
    
    echo $port
}

install_anubis_repo() {
    log_info "Installing Anubis repository..."
    
    case $OS in
        "debian")
            if [ ! -f /etc/apt/sources.list.d/techaro-unstable.list ]; then
                wget -q https://pkgs.techaro.lol/deb/unstable/pool/main/t/techaro-repo-unstable/techaro-repo-unstable_1.0.1_all.deb
                dpkg -i techaro-repo-unstable_1.0.1_all.deb || apt-get install -f -y
                rm -f techaro-repo-unstable_1.0.1_all.deb
                apt-get update
            fi
            apt-get install -y anubis
            ;;
        "redhat")
            if [ ! -f /etc/yum.repos.d/techaro-unstable.repo ]; then
                wget -q https://pkgs.techaro.lol/rpm/unstable/techaro-repo-unstable-1.0.1-1.noarch.rpm
                rpm -i techaro-repo-unstable-1.0.1-1.noarch.rpm
                rm -f techaro-repo-unstable-1.0.1-1.noarch.rpm
            fi
            yum install -y anubis || dnf install -y anubis
            ;;
    esac
    
    if ! id "anubis" &>/dev/null; then
        log_info "Creating anubis user..."
        useradd --system --no-create-home --shell /bin/false anubis
        log_success "Anubis user created"
    else
        log_info "Anubis user already exists"
    fi
    
    log_success "Anubis successfully installed!"
}

collect_configuration() {
    log_info "Collecting configuration data..."
    echo
    
    SERVICE_NAME=$(get_input "Service name (e.g. gitea, nextcloud, webapp)" validate_service_name)
    TARGET_PORT=$(get_input "Port of service to protect" validate_port)
    DOMAIN=$(get_input "Domain (e.g. git.example.com)" validate_domain)
    WEBMASTER_EMAIL=$(get_input "Webmaster email" validate_email)
    
    ANUBIS_PORT=$(find_free_port 8900)
    log_info "Using port $ANUBIS_PORT for Anubis"
    
    METRICS_PORT=$(find_free_port 9090)
    log_info "Using port $METRICS_PORT for Metrics"
    
    echo "Choose difficulty level:"
    echo "1) Low (2) - For weak clients"
    echo "2) Medium (4) - Default"
    echo "3) High (6) - For strong protection"
    while true; do
        read -p "Choose (1-3): " difficulty_choice
        case $difficulty_choice in
            1) DIFFICULTY=2; break;;
            2) DIFFICULTY=4; break;;
            3) DIFFICULTY=6; break;;
            *) log_error "Please choose 1, 2 or 3!";;
        esac
    done
    
    while true; do
        read -p "Does the service run over HTTPS? (y/n): " ssl_choice
        case $ssl_choice in
            [Yy]*) COOKIE_SECURE="true"; break;;
            [Nn]*) COOKIE_SECURE="false"; break;;
            *) log_error "Please enter y or n!";;
        esac
    done
    
    while true; do
        read -p "Serve automatic robots.txt? (y/n): " robots_choice
        case $robots_choice in
            [Yy]*) SERVE_ROBOTS="true"; break;;
            [Nn]*) SERVE_ROBOTS="false"; break;;
            *) log_error "Please enter y or n!";;
        esac
    done
    
    BASE_DOMAIN=$(echo "$DOMAIN" | sed 's/^[^.]*\.//')
    
    echo
    log_info "Configuration:"
    echo "  Service: $SERVICE_NAME"
    echo "  Domain: $DOMAIN"
    echo "  Target Port: $TARGET_PORT"
    echo "  Anubis Port: $ANUBIS_PORT"
    echo "  Metrics Port: $METRICS_PORT"
    echo "  Difficulty: $DIFFICULTY"
    echo "  SSL: $COOKIE_SECURE"
    echo "  Robots.txt: $SERVE_ROBOTS"
    echo
    
    while true; do
        read -p "Configuration correct? (y/n): " confirm
        case $confirm in
            [Yy]*) break;;
            [Nn]*) log_info "Exiting script..."; exit 0;;
            *) log_error "Please enter y or n!";;
        esac
    done
}

create_config_files() {
    log_info "Creating configuration files..."
    
    mkdir -p /etc/anubis
    
    cat > "/etc/anubis/${SERVICE_NAME}.env" << EOF
BIND=0.0.0.0:${ANUBIS_PORT}
BIND_NETWORK=tcp
DIFFICULTY=${DIFFICULTY}
METRICS_BIND=127.0.0.1:${METRICS_PORT}
METRICS_BIND_NETWORK=tcp
POLICY_FNAME=/etc/anubis/${SERVICE_NAME}.botPolicies.yaml
TARGET=http://127.0.0.1:${TARGET_PORT}
COOKIE_DOMAIN=${BASE_DOMAIN}
COOKIE_SECURE=${COOKIE_SECURE}
SERVE_ROBOTS_TXT=${SERVE_ROBOTS}
WEBMASTER_EMAIL=${WEBMASTER_EMAIL}
EOF

    cp /usr/share/doc/anubis/botPolicies.yaml "/etc/anubis/${SERVICE_NAME}.botPolicies.yaml"
    
    chown anubis:anubis "/etc/anubis/${SERVICE_NAME}.env"
    chown anubis:anubis "/etc/anubis/${SERVICE_NAME}.botPolicies.yaml"
    
    log_success "Configuration files created!"
}

start_service() {
    log_info "Starting Anubis service..."
    
    systemctl enable anubis@${SERVICE_NAME}.service
    systemctl start anubis@${SERVICE_NAME}.service
    
    sleep 2
    
    if systemctl is-active --quiet anubis@${SERVICE_NAME}.service; then
        log_success "Anubis service is running!"
    else
        log_error "Service could not be started!"
        systemctl status anubis@${SERVICE_NAME}.service
        exit 1
    fi
}

configure_firewall() {
    log_info "Configuring firewall..."
    
    if command -v ufw >/dev/null 2>&1; then
        ufw allow $ANUBIS_PORT/tcp comment "Anubis ${SERVICE_NAME}"
        log_success "UFW rule added"
    fi
    
    if command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --permanent --add-port=${ANUBIS_PORT}/tcp
        firewall-cmd --reload
        log_success "Firewalld rule added"
    fi
}



run_tests() {
    log_info "Running tests..."
    
    if ss -tlnp | grep -q ":${ANUBIS_PORT} "; then
        log_success "Anubis is running on port ${ANUBIS_PORT}"
    else
        log_error "Anubis is not running on port ${ANUBIS_PORT}!"
        return 1
    fi
    
    if curl -s http://localhost:${METRICS_PORT}/metrics >/dev/null; then
        log_success "Metrics available on port ${METRICS_PORT}"
    else
        log_warning "Metrics not reachable"
    fi
    
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:${ANUBIS_PORT} | grep -q "200\|301\|302"; then
        log_success "Anubis responds correctly"
    else
        log_warning "Anubis response unusual"
    fi
}

create_management_functions() {
    log_info "Creating management script..."
    
    cat > "/usr/local/bin/anubis-${SERVICE_NAME}" << EOF
#!/bin/bash

case "\$1" in
    start)
        systemctl start anubis@${SERVICE_NAME}.service
        ;;
    stop)
        systemctl stop anubis@${SERVICE_NAME}.service
        ;;
    restart)
        systemctl restart anubis@${SERVICE_NAME}.service
        ;;
    status)
        systemctl status anubis@${SERVICE_NAME}.service
        ;;
    logs)
        journalctl -u anubis@${SERVICE_NAME}.service -f
        ;;
    config)
        nano /etc/anubis/${SERVICE_NAME}.env
        ;;
    policies)
        nano /etc/anubis/${SERVICE_NAME}.botPolicies.yaml
        ;;
    test)
        curl -I http://localhost:${ANUBIS_PORT}
        ;;
    metrics)
        curl http://localhost:${METRICS_PORT}/metrics
        ;;
    *)
        echo "Usage: \$0 {start|stop|restart|status|logs|config|policies|test|metrics}"
        exit 1
        ;;
esac
EOF

    chmod +x "/usr/local/bin/anubis-${SERVICE_NAME}"
    log_success "Management script created: anubis-${SERVICE_NAME}"
}

show_summary() {
    log_success "Installation completed!"
    echo
    echo "=================================="
    echo "  ANUBIS SETUP SUMMARY"
    echo "=================================="
    echo "Service: $SERVICE_NAME"
    echo "Domain: $DOMAIN"
    echo "Anubis Port: $ANUBIS_PORT"
    echo "Metrics Port: $METRICS_PORT"
    echo "Target Service: http://127.0.0.1:$TARGET_PORT"
    echo
    echo "Configuration files:"
    echo "  - /etc/anubis/${SERVICE_NAME}.env"
    echo "  - /etc/anubis/${SERVICE_NAME}.botPolicies.yaml"
    echo
    echo "Management commands:"
    echo "  anubis-${SERVICE_NAME} start|stop|restart|status"
    echo "  anubis-${SERVICE_NAME} logs      # Live logs"
    echo "  anubis-${SERVICE_NAME} config    # Edit configuration"
    echo "  anubis-${SERVICE_NAME} policies  # Edit bot policies"
    echo "  anubis-${SERVICE_NAME} test      # Quick test"
    echo "  anubis-${SERVICE_NAME} metrics   # Show metrics"
    echo
    echo "Next steps:"
    echo "1. Point DNS to this server"
    echo "2. Test with 'anubis-${SERVICE_NAME} test'"
    echo
    echo "Service running on: http://localhost:${ANUBIS_PORT}"
    echo "Metrics available: http://localhost:${METRICS_PORT}/metrics"
    echo "=================================="
}

main() {
    clear
    echo "=================================="
    echo "  ANUBIS UNIVERSAL SETUP SCRIPT"
    echo "=================================="
    echo "Automatic installation and configuration"
    echo "of Anubis for arbitrary services"
    echo "=================================="
    echo
    
    check_root
    detect_os
    install_anubis_repo
    collect_configuration
    create_config_files
    start_service
    configure_firewall
    run_tests
    create_management_functions
    show_summary
}

main "$@"