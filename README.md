# Anubis for Gitea - Setup Guide

Complete guide for installing Anubis as bot protection for services with Nginx Proxy Manager.

Credits Anubis https://anubis.techaro.lol

## Prerequisites

- **Gitea Server** with running Gitea on port 3000
- **Nginx Proxy Manager** for SSL and domain routing
- **Root access** to the Gitea server
- **Domain** pointing to NPM (e.g., `git.example.com`)

## 1. Download and Execute Script

```bash
# Download script (Gitea Mirror)
wget https://git.decentral.icu/t30d0r/anubis-autoinstall/raw/branch/main/anubis-setup.sh
# OR
# Download script (Github Mirror)
wget https://github.com/the-real-t30d0r/anubis-autoinstall/raw/branch/main/anubis-setup.sh
chmod +x anubis-setup.sh

# Execute as root
sudo ./anubis-setup.sh
```

## 2. Interactive Configuration

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

## 3. Automatic Installation

The script automatically performs the following steps:

- ✅ **Install Anubis repository**
- ✅ **Create Anubis user** 
- ✅ **Find free ports** (usually 8923 for Anubis, 9090 for Metrics)
- ✅ **Create configuration files**
- ✅ **Start and enable service**
- ✅ **Add firewall rules**
- ✅ **Create management script**

## 4. Generated Configuration

After installation, you'll find:

### Configuration Files
```
/etc/anubis/gitea.env              # Main configuration
/etc/anubis/gitea.botPolicies.yaml # Bot detection rules
```

### Management Script
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

### Domain Setup in NPM:
- **Domain Names:** `git.example.com`
- **Scheme:** `http`
- **Forward Hostname/IP:** `GITEA_SERVER_IP`
- **Forward Port:** `8900` (Anubis port, **NOT** 3000!)
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

### Local Test
```bash
# Test Gitea directly
curl -I http://localhost:3000

# Test Anubis
anubis-gitea test

# Service status
anubis-gitea status
```

### External Test
```bash
# Test from outside
curl -I https://git.example.com
```

## 8. Logs and Monitoring

### Follow Live Logs
```bash
anubis-gitea logs
```

### Show Metrics
```bash
anubis-gitea metrics
```

### Service Status
```bash
anubis-gitea status
```

## 9. Adjust Configuration

### Change Difficulty
```bash
anubis-gitea config
# DIFFICULTY=2  (easy)
# DIFFICULTY=4  (medium) 
# DIFFICULTY=6  (hard)
anubis-gitea restart
```

### Adjust Bot Policies
```bash
anubis-gitea policies
# Edit YAML file
anubis-gitea restart
```

## 10. Troubleshooting

### Service Not Running
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

### Port Conflicts
```bash
# Check used ports
sudo ss -tlnp | grep :8900
sudo ss -tlnp | grep :3000
```

### NPM Cannot Connect
```bash
# Check firewall
sudo ufw status
sudo ufw allow from NPM_SERVER_IP to any port 8900

# Does Anubis bind to 0.0.0.0?
grep BIND /etc/anubis/gitea.env
# Should be: BIND=0.0.0.0:8900
```

## 11. Maintenance

### Service Updates
```bash
sudo apt update
sudo apt upgrade anubis
anubis-gitea restart
```

### Log Rotation
Logs are automatically managed by systemd.

### Configuration Backup
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
