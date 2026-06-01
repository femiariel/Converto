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
    print_error "Lance ce script avec sudo ou en root: sudo bash deploy-ngrok.sh"
    exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo ""
echo "========================================"
echo "🚀 Déploiement Converto avec ngrok"
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
fi

if [ -z "${NGROK_AUTHTOKEN:-}" ]; then
    echo "Va sur https://dashboard.ngrok.com/get-started/your-authtoken"
    read -rsp "Colle ton ngrok authtoken ici: " NGROK_AUTHTOKEN
    echo ""
fi

if [ -z "${NGROK_DOMAIN:-}" ]; then
    echo ""
    echo "Pour une URL stable, crée/récupère ton domaine dans ngrok:"
    echo "  https://dashboard.ngrok.com/domains"
    echo "Exemple: ton-nom.ngrok-free.app"
    read -rp "Domaine ngrok stable (laisser vide = URL aléatoire): " NGROK_DOMAIN
fi

print_info "Installation de ngrok..."
apt-get update
apt-get install -y curl

if ! command -v ngrok >/dev/null 2>&1; then
    curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
        | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
    echo "deb https://ngrok-agent.s3.amazonaws.com bookworm main" \
        | tee /etc/apt/sources.list.d/ngrok.list >/dev/null
    apt-get update
    apt-get install -y ngrok
fi

NGROK_BIN="$(command -v ngrok)"

print_info "Configuration du token ngrok..."
$NGROK_BIN config add-authtoken "$NGROK_AUTHTOKEN"

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

if [ -n "$NGROK_DOMAIN" ]; then
    NGROK_DOMAIN="${NGROK_DOMAIN#http://}"
    NGROK_DOMAIN="${NGROK_DOMAIN#https://}"
    NGROK_URL="https://$NGROK_DOMAIN"
    NGROK_EXEC="$NGROK_BIN http http://127.0.0.1:$BACKEND_PORT --url=$NGROK_URL --log=stdout"
else
    NGROK_URL=""
    NGROK_EXEC="$NGROK_BIN http http://127.0.0.1:$BACKEND_PORT --log=stdout"
fi

print_info "Création du service ngrok..."
cat > /etc/systemd/system/converto-ngrok.service << EOF
[Unit]
Description=Converto ngrok tunnel
After=network-online.target converto.service
Wants=network-online.target
Requires=converto.service

[Service]
Type=simple
ExecStart=$NGROK_EXEC
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable converto.service converto-ngrok.service
systemctl restart converto.service
systemctl restart converto-ngrok.service

echo ""
echo "========================================"
echo -e "${GREEN}✨ Converto tourne en arrière-plan avec ngrok${NC}"
echo "========================================"
echo ""

if [ -n "$NGROK_URL" ]; then
    echo -e "${GREEN}URL stable sans IP visible:${NC}"
    echo -e "  ${BLUE}$NGROK_URL${NC}"
else
    echo -e "${YELLOW}URL aléatoire, pas stable. Pour la retrouver:${NC}"
    echo "  journalctl -u converto-ngrok.service -n 100 --no-pager | grep -Eo 'https://[-a-zA-Z0-9.]+\\.ngrok[^ ]+' | tail -n 1"
fi

echo ""
echo -e "${YELLOW}Commandes utiles:${NC}"
echo "  systemctl status converto.service"
echo "  systemctl status converto-ngrok.service"
echo "  journalctl -u converto-ngrok.service -f"
echo "  systemctl restart converto.service converto-ngrok.service"
echo "  systemctl stop converto.service converto-ngrok.service"
echo ""
