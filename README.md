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


