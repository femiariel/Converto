#!/bin/bash

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

if [ "$EUID" -ne 0 ]; then
    print_error "Lance ce script avec sudo ou en root: sudo bash deploy-tunnel.sh"
    exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo ""
echo "========================================"
echo "🚀 Déploiement Converto sans IP visible"
echo "========================================"
echo ""

if [ ! -x "$PROJECT_DIR/.venv/bin/python" ]; then
    print_info "Installation de Converto..."
    bash "$PROJECT_DIR/install.sh"
fi

if [ -f "$PROJECT_DIR/.ports" ]; then
    source "$PROJECT_DIR/.ports"
else
    BACKEND_PORT=5000
    FRONTEND_PORT=3000
fi

print_info "Installation des outils système..."
apt-get update
apt-get install -y curl

if ! command -v cloudflared >/dev/null 2>&1; then
    print_info "Installation de Cloudflare Tunnel..."
    ARCH=$(dpkg --print-architecture)
    case "$ARCH" in
        amd64)
            CLOUDFLARED_DEB="cloudflared-linux-amd64.deb"
            ;;
        arm64)
            CLOUDFLARED_DEB="cloudflared-linux-arm64.deb"
            ;;
        *)
            print_error "Architecture non supportée automatiquement: $ARCH"
            exit 1
            ;;
    esac

    curl -L --output /tmp/cloudflared.deb "https://github.com/cloudflare/cloudflared/releases/latest/download/$CLOUDFLARED_DEB"
    apt-get install -y /tmp/cloudflared.deb
fi

CLOUDFLARED_BIN="$(command -v cloudflared)"

print_info "Création du service Converto..."
cat > /etc/systemd/system/converto.service << EOF
[Unit]
Description=Converto backend
After=network.target

[Service]
Type=simple
WorkingDirectory=$PROJECT_DIR/backend
Environment=CONVERTO_DEBUG=0
ExecStart=$PROJECT_DIR/.venv/bin/python app.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

print_info "Création du tunnel Cloudflare..."
cat > /etc/systemd/system/converto-tunnel.service << EOF
[Unit]
Description=Converto Cloudflare quick tunnel
After=network-online.target converto.service
Wants=network-online.target
Requires=converto.service

[Service]
Type=simple
ExecStart=$CLOUDFLARED_BIN tunnel --no-autoupdate --url http://127.0.0.1:$BACKEND_PORT
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable converto.service converto-tunnel.service
systemctl restart converto.service
systemctl restart converto-tunnel.service

print_info "Attente de l'URL publique..."
PUBLIC_URL=""
for _ in $(seq 1 20); do
    PUBLIC_URL=$(journalctl -u converto-tunnel.service -n 80 --no-pager 2>/dev/null | grep -Eo 'https://[-a-zA-Z0-9.]+\.trycloudflare\.com' | tail -n 1 || true)
    if [ -n "$PUBLIC_URL" ]; then
        break
    fi
    sleep 2
done

echo ""
echo "========================================"
echo -e "${GREEN}✨ Converto tourne en arrière-plan${NC}"
echo "========================================"
echo ""

if [ -n "$PUBLIC_URL" ]; then
    echo -e "${GREEN}URL publique sans IP visible:${NC}"
    echo -e "  ${BLUE}$PUBLIC_URL${NC}"
else
    print_error "URL pas encore trouvée. Réessaie cette commande dans quelques secondes:"
    echo "  journalctl -u converto-tunnel.service -n 100 --no-pager | grep -Eo 'https://[-a-zA-Z0-9.]+\\.trycloudflare\\.com' | tail -n 1"
fi

echo ""
echo -e "${YELLOW}Commandes utiles:${NC}"
echo "  systemctl status converto.service"
echo "  systemctl status converto-tunnel.service"
echo "  journalctl -u converto-tunnel.service -f"
echo "  systemctl restart converto.service converto-tunnel.service"
echo "  systemctl stop converto.service converto-tunnel.service"
echo ""
