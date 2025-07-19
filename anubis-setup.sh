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
        log_error "Dieses Script muss als root ausgeführt werden!"
        exit 1
    fi
}

detect_os() {
    if [ -f /etc/debian_version ]; then
        OS="debian"
        log_info "Debian/Ubuntu System erkannt"
    elif [ -f /etc/redhat-release ]; then
        OS="redhat"
        log_info "Red Hat/CentOS/Fedora System erkannt"
    else
        log_error "Nicht unterstütztes Betriebssystem!"
        exit 1
    fi
}

validate_service_name() {
    local service="$1"
    if [[ ! "$service" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_error "Service-Name darf nur Buchstaben, Zahlen, Unterstriche und Bindestriche enthalten!"
        return 1
    fi
    return 0
}

validate_port() {
    local port="$1"
    if [[ ! "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        log_error "Port muss eine Zahl zwischen 1 und 65535 sein!"
        return 1
    fi
    return 0
}

validate_domain() {
    local domain="$1"
    if [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        log_error "Ungültiges Domain-Format!"
        return 1
    fi
    return 0
}

validate_email() {
    local email="$1"
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        log_error "Ungültige E-Mail-Adresse!"
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
            log_error "Eingabe darf nicht leer sein!"
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
            log_error "Kein freier Port gefunden!"
            exit 1
        fi
    done
    
    echo $port
}

install_anubis_repo() {
    log_info "Installiere Anubis Repository..."
    
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
        log_info "Erstelle anubis-User..."
        useradd --system --no-create-home --shell /bin/false anubis
        log_success "Anubis-User erstellt"
    else
        log_info "Anubis-User bereits vorhanden"
    fi
    
    log_success "Anubis erfolgreich installiert!"
}

collect_configuration() {
    log_info "Sammle Konfigurationsdaten..."
    echo
    
    SERVICE_NAME=$(get_input "Service-Name (z.B. gitea, nextcloud, webapp)" validate_service_name)
    TARGET_PORT=$(get_input "Port des zu schützenden Service" validate_port)
    DOMAIN=$(get_input "Domain (z.B. git.example.com)" validate_domain)
    WEBMASTER_EMAIL=$(get_input "Webmaster E-Mail" validate_email)
    
    ANUBIS_PORT=$(find_free_port 8900)
    log_info "Verwende Port $ANUBIS_PORT für Anubis"
    
    METRICS_PORT=$(find_free_port 9090)
    log_info "Verwende Port $METRICS_PORT für Metrics"
    
    echo "Schwierigkeitsgrad wählen:"
    echo "1) Niedrig (2) - Für schwache Clients"
    echo "2) Mittel (4) - Standard"
    echo "3) Hoch (6) - Für starke Protection"
    while true; do
        read -p "Wähle (1-3): " difficulty_choice
        case $difficulty_choice in
            1) DIFFICULTY=2; break;;
            2) DIFFICULTY=4; break;;
            3) DIFFICULTY=6; break;;
            *) log_error "Bitte 1, 2 oder 3 wählen!";;
        esac
    done
    
    while true; do
        read -p "Läuft der Service über HTTPS? (y/n): " ssl_choice
        case $ssl_choice in
            [Yy]*) COOKIE_SECURE="true"; break;;
            [Nn]*) COOKIE_SECURE="false"; break;;
            *) log_error "Bitte y oder n eingeben!";;
        esac
    done
    
    while true; do
        read -p "Automatische robots.txt servieren? (y/n): " robots_choice
        case $robots_choice in
            [Yy]*) SERVE_ROBOTS="true"; break;;
            [Nn]*) SERVE_ROBOTS="false"; break;;
            *) log_error "Bitte y oder n eingeben!";;
        esac
    done
    
    BASE_DOMAIN=$(echo "$DOMAIN" | sed 's/^[^.]*\.//')
    
    echo
    log_info "Konfiguration:"
    echo "  Service: $SERVICE_NAME"
    echo "  Domain: $DOMAIN"
    echo "  Target Port: $TARGET_PORT"
    echo "  Anubis Port: $ANUBIS_PORT"
    echo "  Metrics Port: $METRICS_PORT"
    echo "  Schwierigkeit: $DIFFICULTY"
    echo "  SSL: $COOKIE_SECURE"
    echo "  Robots.txt: $SERVE_ROBOTS"
    echo
    
    while true; do
        read -p "Konfiguration korrekt? (y/n): " confirm
        case $confirm in
            [Yy]*) break;;
            [Nn]*) log_info "Script beenden..."; exit 0;;
            *) log_error "Bitte y oder n eingeben!";;
        esac
    done
}

create_config_files() {
    log_info "Erstelle Konfigurationsdateien..."
    
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
    
    log_success "Konfigurationsdateien erstellt!"
}

start_service() {
    log_info "Starte Anubis Service..."
    
    systemctl enable anubis@${SERVICE_NAME}.service
    systemctl start anubis@${SERVICE_NAME}.service
    
    sleep 2
    
    if systemctl is-active --quiet anubis@${SERVICE_NAME}.service; then
        log_success "Anubis Service läuft!"
    else
        log_error "Service konnte nicht gestartet werden!"
        systemctl status anubis@${SERVICE_NAME}.service
        exit 1
    fi
}

configure_firewall() {
    log_info "Konfiguriere Firewall..."
    
    if command -v ufw >/dev/null 2>&1; then
        ufw allow $ANUBIS_PORT/tcp comment "Anubis ${SERVICE_NAME}"
        log_success "UFW Regel hinzugefügt"
    fi
    
    if command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --permanent --add-port=${ANUBIS_PORT}/tcp
        firewall-cmd --reload
        log_success "Firewalld Regel hinzugefügt"
    fi
}



run_tests() {
    log_info "Führe Tests durch..."
    
    if ss -tlnp | grep -q ":${ANUBIS_PORT} "; then
        log_success "Anubis läuft auf Port ${ANUBIS_PORT}"
    else
        log_error "Anubis läuft nicht auf Port ${ANUBIS_PORT}!"
        return 1
    fi
    
    if curl -s http://localhost:${METRICS_PORT}/metrics >/dev/null; then
        log_success "Metrics verfügbar auf Port ${METRICS_PORT}"
    else
        log_warning "Metrics nicht erreichbar"
    fi
    
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:${ANUBIS_PORT} | grep -q "200\|301\|302"; then
        log_success "Anubis antwortet korrekt"
    else
        log_warning "Anubis Response ungewöhnlich"
    fi
}

create_management_functions() {
    log_info "Erstelle Management-Script..."
    
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
    log_success "Management-Script erstellt: anubis-${SERVICE_NAME}"
}

show_summary() {
    log_success "Installation abgeschlossen!"
    echo
    echo "=================================="
    echo "  ANUBIS SETUP ZUSAMMENFASSUNG"
    echo "=================================="
    echo "Service: $SERVICE_NAME"
    echo "Domain: $DOMAIN"
    echo "Anubis Port: $ANUBIS_PORT"
    echo "Metrics Port: $METRICS_PORT"
    echo "Target Service: http://127.0.0.1:$TARGET_PORT"
    echo
    echo "Konfigurationsdateien:"
    echo "  - /etc/anubis/${SERVICE_NAME}.env"
    echo "  - /etc/anubis/${SERVICE_NAME}.botPolicies.yaml"
    echo
    echo "Management-Befehle:"
    echo "  anubis-${SERVICE_NAME} start|stop|restart|status"
    echo "  anubis-${SERVICE_NAME} logs      # Live Logs"
    echo "  anubis-${SERVICE_NAME} config    # Konfiguration bearbeiten"
    echo "  anubis-${SERVICE_NAME} policies  # Bot-Policies bearbeiten"
    echo "  anubis-${SERVICE_NAME} test      # Schnelltest"
    echo "  anubis-${SERVICE_NAME} metrics   # Metriken anzeigen"
    echo
    echo "Nächste Schritte:"
    echo "1. DNS auf diesen Server zeigen lassen"
    echo "2. Mit 'anubis-${SERVICE_NAME} test' testen"
    echo
    echo "Service läuft auf: http://localhost:${ANUBIS_PORT}"
    echo "Metrics verfügbar: http://localhost:${METRICS_PORT}/metrics"
    echo "=================================="
}

main() {
    clear
    echo "=================================="
    echo "  ANUBIS UNIVERSAL SETUP SCRIPT"
    echo "=================================="
    echo "Automatische Installation und Konfiguration"
    echo "von Anubis für beliebige Services"
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