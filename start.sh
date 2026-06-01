#!/bin/bash

set -e

# Couleurs
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

# Aller au répertoire du projet
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

PYTHON_BIN="python3"
if [ -x "$PROJECT_DIR/.venv/bin/python" ]; then
    PYTHON_BIN="$PROJECT_DIR/.venv/bin/python"
fi

# Charger les ports
if [ -f "$PROJECT_DIR/.ports" ]; then
    source "$PROJECT_DIR/.ports"
else
    # Fallback si le fichier n'existe pas
    BACKEND_PORT=5000
    FRONTEND_PORT=3000
    print_info "Utilisation des ports par défaut: Backend=$BACKEND_PORT, Frontend=$FRONTEND_PORT"
fi

echo ""
echo "========================================"
echo "🚀 Démarrage de Converto"
echo "========================================"
echo ""

print_info "Backend sur le port $BACKEND_PORT"
print_info "Frontend sur le port $FRONTEND_PORT"
print_info "Ouvrez: http://localhost:$FRONTEND_PORT"
echo ""

# Vérifier que les ports sont libres
check_port() {
    local port=$1

    if python3 - "$port" <<'PY'
import socket
import sys
import errno

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
    then
        return 0
    else
        print_error "Le port $port est déjà utilisé!"
        return 1
    fi
}

if ! check_port $BACKEND_PORT; then
    exit 1
fi

if ! check_port $FRONTEND_PORT; then
    exit 1
fi

# Afficher les instructions
echo -e "${YELLOW}📝 Instructions:${NC}"
echo ""
echo "Ouvrez DEUX terminaux séparés et exécutez:"
echo ""
echo -e "${YELLOW}Terminal 1 (Backend):${NC}"
echo "  cd $PROJECT_DIR/backend"
echo "  $PYTHON_BIN app.py"
echo ""
echo -e "${YELLOW}Terminal 2 (Frontend):${NC}"
echo "  cd $PROJECT_DIR/frontend"
echo "  python3 -m http.server $FRONTEND_PORT"
echo ""
echo -e "${GREEN}Puis ouvrez dans votre navigateur:${NC}"
echo "  ${BLUE}http://localhost:$FRONTEND_PORT${NC}"
echo ""
echo "Appuyez sur Ctrl+C pour arrêter l'application"
echo ""
