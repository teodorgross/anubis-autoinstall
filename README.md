# Anubis für Gitea - Setup Guide

Komplette Anleitung zur Installation von Anubis als Bot-Schutz für dienste mit Nginx Proxy Manager.

Credits Anubis https://anubis.techaro.lol/$0

## Voraussetzungen

- **Gitea Server** mit laufendem Gitea auf Port 3000
- **Nginx Proxy Manager** für SSL und Domain-Routing
- **Root-Zugriff** auf den Gitea-Server
- **Domain** die auf NPM zeigt (z.B. `git.example.com`)

## 1. Script herunterladen und ausführen

```bash
# Script herunterladen
wget https://git.decentral.icu/teodorgross/anubis-autoinstall/raw/branch/main/anubis.sh$0
chmod +x anubis-setup.sh

# Als root ausführen
sudo ./anubis-setup.sh
```

## 2. Interaktive Konfiguration

Das Script fragt nach folgenden Informationen:

```
Service-Name: gitea
Port des zu schützenden Service: 3000
Domain: git.example.com
Webmaster E-Mail: admin@example.com
Schwierigkeitsgrad: 2 (Mittel - Standard)
HTTPS: y
Automatische robots.txt: y
```

## 3. Automatische Installation

Das Script führt automatisch folgende Schritte aus:

- ✅ **Anubis Repository** installieren
- ✅ **Anubis-User** erstellen 
- ✅ **Freie Ports** finden (meist 8923 für Anubis, 9090 für Metrics)
- ✅ **Konfigurationsdateien** erstellen
- ✅ **Service starten** und aktivieren
- ✅ **Firewall-Regeln** hinzufügen
- ✅ **Management-Script** erstellen

## 4. Generierte Konfiguration

Nach der Installation findest du:

### Konfigurationsdateien
```
/etc/anubis/gitea.env              # Hauptkonfiguration
/etc/anubis/gitea.botPolicies.yaml # Bot-Erkennungsregeln
```

### Management-Script
```bash
anubis-gitea start          # Service starten
anubis-gitea stop           # Service stoppen
anubis-gitea restart        # Service neustarten
anubis-gitea status         # Status anzeigen
anubis-gitea logs           # Live Logs anzeigen
anubis-gitea test           # Schnelltest
anubis-gitea config         # Konfiguration bearbeiten
anubis-gitea policies       # Bot-Policies bearbeiten
anubis-gitea metrics        # Metriken anzeigen
```

## 5. Nginx Proxy Manager konfigurieren

### Domain Setup in NPM:
- **Domain Names:** `git.example.com`
- **Scheme:** `http`
- **Forward Hostname/IP:** `GITEA_SERVER_IP`
- **Forward Port:** `8923` (Anubis-Port, **NICHT** 3000!)
- **Block Common Exploits:** ✅ An
- **Websockets Support:** ✅ An

### SSL Configuration:
- **SSL Certificate:** Request a new SSL Certificate
- **Force SSL:** ✅ An
- **HTTP/2 Support:** ✅ An

## 6. Architektur

```
Internet → NPM (SSL) → Anubis (8923) → Gitea (3000)
```

## 7. Testing

### Lokaler Test
```bash
# Gitea direkt testen
curl -I http://localhost:3000

# Anubis testen
anubis-gitea test

# Service-Status
anubis-gitea status
```

### Externer Test
```bash
# Von außen testen
curl -I https://git.example.com
```

## 8. Logs und Monitoring

### Live Logs verfolgen
```bash
anubis-gitea logs
```

### Metriken anzeigen
```bash
anubis-gitea metrics
```

### Service-Status
```bash
anubis-gitea status
```

## 9. Konfiguration anpassen

### Schwierigkeit ändern
```bash
anubis-gitea config
# DIFFICULTY=2  (leicht)
# DIFFICULTY=4  (mittel) 
# DIFFICULTY=6  (schwer)
anubis-gitea restart
```

### Bot-Policies anpassen
```bash
anubis-gitea policies
# YAML-Datei bearbeiten
anubis-gitea restart
```

## 10. Troubleshooting

### Service läuft nicht
```bash
anubis-gitea status
anubis-gitea logs
```

### 502 Bad Gateway
```bash
# Gitea Status prüfen
systemctl status gitea
curl -I http://localhost:3000

# Anubis Status prüfen
anubis-gitea status
anubis-gitea test
```

### Port-Konflikte
```bash
# Verwendete Ports prüfen
sudo ss -tlnp | grep :8923
sudo ss -tlnp | grep :3000
```

### NPM kann nicht connecten
```bash
# Firewall prüfen
sudo ufw status
sudo ufw allow from NPM_SERVER_IP to any port 8923

# Anubis bindet auf 0.0.0.0?
grep BIND /etc/anubis/gitea.env
# Sollte sein: BIND=0.0.0.0:8923
```

## 11. Wartung

### Service-Updates
```bash
sudo apt update
sudo apt upgrade anubis
anubis-gitea restart
```

### Log-Rotation
Logs werden automatisch von systemd verwaltet.

### Backup der Konfiguration
```bash
sudo cp /etc/anubis/gitea.* /backup/location/
```

## 12. Deinstallation

```bash
# Service stoppen und deaktivieren
anubis-gitea stop
sudo systemctl disable anubis@gitea.service

# Konfigurationsdateien entfernen
sudo rm -f /etc/anubis/gitea.*
sudo rm -f /usr/local/bin/anubis-gitea

# Anubis komplett entfernen
sudo apt remove anubis
```

## Features

✅ **Automatische Bot-Erkennung** mit KI-Schutz  
✅ **Proof-of-Work Challenge** für verdächtige Clients  
✅ **Keine Auswirkung** auf normale Benutzer  
✅ **Skalierbar** für mehrere Services  
✅ **Einfaches Management** mit integrierten Tools  
✅ **Vollständige SSL-Unterstützung** über NPM  
✅ **Live-Monitoring** und Metriken  

## Support

Bei Problemen:
1. **Logs checken:** `anubis-gitea logs`
2. **Status prüfen:** `anubis-gitea status`
3. **Test ausführen:** `anubis-gitea test`
4. **Konfiguration validieren:** `anubis-gitea config`

---



# Anubis for Gitea - Setup Guide

Complete guide for installing Anubis as bot protection for services with Nginx Proxy Manager.

Credits Anubis https://anubis.techaro.lol/

## Prerequisites

- **Gitea Server** with running Gitea on port 3000
- **Nginx Proxy Manager** for SSL and domain routing
- **Root access** to the Gitea server
- **Domain** pointing to NPM (e.g., `git.example.com`)

## 1. Download and run script

```bash
# Download script
wget https://git.decentral.icu/teodorgross/anubis-autoinstall/raw/branch/main/anubis.sh
chmod +x anubis-setup.sh

# Run as root
sudo ./anubis-setup.sh
```

## 2. Interactive configuration

The script asks for the following information:

```
Service name: gitea
Port of service to protect: 3000
Domain: git.example.com
Webmaster email: admin@example.com
Difficulty level: 2 (Medium - Default)
HTTPS: y
Automatic robots.txt: y
```

## 3. Automatic installation

The script automatically performs the following steps:

- ✅ **Install Anubis repository**
- ✅ **Create Anubis user** 
- ✅ **Find free ports** (usually 8923 for Anubis, 9090 for Metrics)
- ✅ **Create configuration files**
- ✅ **Start and enable service**
- ✅ **Add firewall rules**
- ✅ **Create management script**

## 4. Generated configuration

After installation you'll find:

### Configuration files
```
/etc/anubis/gitea.env              # Main configuration
/etc/anubis/gitea.botPolicies.yaml # Bot detection rules
```

### Management script
```bash
anubis-gitea start          # Start service
anubis-gitea stop           # Stop service
anubis-gitea restart        # Restart service
anubis-gitea status         # Show status
anubis-gitea logs           # Show live logs
anubis-gitea test           # Quick test
anubis-gitea config         # Edit configuration
anubis-gitea policies       # Edit bot policies
anubis-gitea metrics        # Show metrics
```

## 5. Configure Nginx Proxy Manager

### Domain setup in NPM:
- **Domain Names:** `git.example.com`
- **Scheme:** `http`
- **Forward Hostname/IP:** `GITEA_SERVER_IP`
- **Forward Port:** `8923` (Anubis port, **NOT** 3000!)
- **Block Common Exploits:** ✅ On
- **Websockets Support:** ✅ On

### SSL Configuration:
- **SSL Certificate:** Request a new SSL Certificate
- **Force SSL:** ✅ On
- **HTTP/2 Support:** ✅ On

## 6. Architecture

```
Internet → NPM (SSL) → Anubis (8923) → Gitea (3000)
```

## 7. Testing

### Local test
```bash
# Test Gitea directly
curl -I http://localhost:3000

# Test Anubis
anubis-gitea test

# Service status
anubis-gitea status
```

### External test
```bash
# Test from outside
curl -I https://git.example.com
```

## 8. Logs and monitoring

### Follow live logs
```bash
anubis-gitea logs
```

### Show metrics
```bash
anubis-gitea metrics
```

### Service status
```bash
anubis-gitea status
```

## 9. Adjust configuration

### Change difficulty
```bash
anubis-gitea config
# DIFFICULTY=2  (easy)
# DIFFICULTY=4  (medium) 
# DIFFICULTY=6  (hard)
anubis-gitea restart
```

### Adjust bot policies
```bash
anubis-gitea policies
# Edit YAML file
anubis-gitea restart
```

## 10. Troubleshooting

### Service not running
```bash
anubis-gitea status
anubis-gitea logs
```

### 502 Bad Gateway
```bash
# Check Gitea status
systemctl status gitea
curl -I http://localhost:3000

# Check Anubis status
anubis-gitea status
anubis-gitea test
```

### Port conflicts
```bash
# Check used ports
sudo ss -tlnp | grep :8923
sudo ss -tlnp | grep :3000
```

### NPM cannot connect
```bash
# Check firewall
sudo ufw status
sudo ufw allow from NPM_SERVER_IP to any port 8923

# Anubis binding to 0.0.0.0?
grep BIND /etc/anubis/gitea.env
# Should be: BIND=0.0.0.0:8923
```

## 11. Maintenance

### Service updates
```bash
sudo apt update
sudo apt upgrade anubis
anubis-gitea restart
```

### Log rotation
Logs are automatically managed by systemd.

### Backup configuration
```bash
sudo cp /etc/anubis/gitea.* /backup/location/
```

## 12. Uninstallation

```bash
# Stop and disable service
anubis-gitea stop
sudo systemctl disable anubis@gitea.service

# Remove configuration files
sudo rm -f /etc/anubis/gitea.*
sudo rm -f /usr/local/bin/anubis-gitea

# Remove Anubis completely
sudo apt remove anubis
```

## Features

✅ **Automatic bot detection** with AI protection  
✅ **Proof-of-Work challenge** for suspicious clients  
✅ **No impact** on normal users  
✅ **Scalable** for multiple services  
✅ **Easy management** with integrated tools  
✅ **Full SSL support** via NPM  
✅ **Live monitoring** and metrics  

## Support

For issues:
1. **Check logs:** `anubis-gitea logs`
2. **Check status:** `anubis-gitea status`
3. **Run test:** `anubis-gitea test`
4. **Validate configuration:** `anubis-gitea config`

---