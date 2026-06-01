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

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

is_port_free() {
    local port=$1

    python3 - "$port" <<'PY'
import errno
import socket
import sys

port = int(sys.argv[1])
for family, host in ((socket.AF_INET, "0.0.0.0"), (socket.AF_INET6, "::")):
    sock = socket.socket(family, socket.SOCK_STREAM)
    try:
        sock.bind((host, port))
    except OSError as exc:
        if family == socket.AF_INET6 and exc.errno in (errno.EAFNOSUPPORT, errno.EADDRNOTAVAIL):
            continue
        sys.exit(1)
    finally:
        sock.close()

sys.exit(0)
PY
}

find_free_port() {
    local port=$1
    local max_port=$((port + 100))

    while [ "$port" -le "$max_port" ]; do
        if is_port_free "$port"; then
            echo "$port"
            return 0
        fi
        port=$((port + 1))
    done

    print_error "Aucun port disponible entre $1 et $max_port"
    exit 1
}

cleanup() {
    echo ""
    print_info "Arrêt de Converto..."

    if [ -n "${BACKEND_PID:-}" ] && kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
        kill "$BACKEND_PID" >/dev/null 2>&1 || true
    fi

    if [ -n "${FRONTEND_PID:-}" ] && kill -0 "$FRONTEND_PID" >/dev/null 2>&1; then
        kill "$FRONTEND_PID" >/dev/null 2>&1 || true
    fi

    print_success "Serveurs arrêtés"
}

trap cleanup EXIT INT TERM

echo ""
echo "========================================"
echo "🚀 Démarrage automatique de Converto"
echo "========================================"
echo ""

if [ ! -x "$PROJECT_DIR/.venv/bin/python" ]; then
    print_info "Environnement Python absent. Installation automatique..."
    bash "$PROJECT_DIR/install.sh"
fi

PYTHON_BIN="$PROJECT_DIR/.venv/bin/python"

if [ -f "$PROJECT_DIR/.ports" ]; then
    source "$PROJECT_DIR/.ports"
else
    BACKEND_PORT=5000
    FRONTEND_PORT=3000
fi

if ! is_port_free "$BACKEND_PORT"; then
    print_info "Backend port $BACKEND_PORT déjà utilisé, recherche d'un port libre..."
    BACKEND_PORT=$(find_free_port 5000)
fi

if ! is_port_free "$FRONTEND_PORT"; then
    print_info "Frontend port $FRONTEND_PORT déjà utilisé, recherche d'un port libre..."
    FRONTEND_PORT=$(find_free_port 3000)
fi

cat > "$PROJECT_DIR/.ports" << EOF
BACKEND_PORT=$BACKEND_PORT
FRONTEND_PORT=$FRONTEND_PORT
EOF

mkdir -p "$PROJECT_DIR/logs"

print_info "Backend sur le port $BACKEND_PORT"
print_info "Frontend sur le port $FRONTEND_PORT"

(
    cd "$PROJECT_DIR/backend"
    "$PYTHON_BIN" app.py
) > "$PROJECT_DIR/logs/backend.log" 2>&1 &
BACKEND_PID=$!

(
    cd "$PROJECT_DIR/frontend"
    python3 -m http.server "$FRONTEND_PORT" --bind 0.0.0.0
) > "$PROJECT_DIR/logs/frontend.log" 2>&1 &
FRONTEND_PID=$!

sleep 2

if ! kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
    print_error "Le backend n'a pas démarré. Log:"
    tail -n 40 "$PROJECT_DIR/logs/backend.log"
    exit 1
fi

if ! kill -0 "$FRONTEND_PID" >/dev/null 2>&1; then
    print_error "Le frontend n'a pas démarré. Log:"
    tail -n 40 "$PROJECT_DIR/logs/frontend.log"
    exit 1
fi

PUBLIC_IP=$(hostname -I 2>/dev/null | awk '{print $1}')

echo ""
echo "========================================"
echo -e "${GREEN}✨ Converto est lancé${NC}"
echo "========================================"
echo ""
echo -e "${GREEN}Ouvre ce site:${NC}"
if [ -n "$PUBLIC_IP" ]; then
    echo -e "  ${BLUE}http://$PUBLIC_IP:$FRONTEND_PORT${NC}"
fi
echo -e "  ${BLUE}http://localhost:$FRONTEND_PORT${NC}"
echo ""
echo -e "${YELLOW}Logs:${NC}"
echo "  Backend:  $PROJECT_DIR/logs/backend.log"
echo "  Frontend: $PROJECT_DIR/logs/frontend.log"
echo ""
echo "Laisse ce terminal ouvert. Ctrl+C pour arrêter."
echo ""

wait "$BACKEND_PID" "$FRONTEND_PID"
