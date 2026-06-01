#!/bin/bash

set -e

echo "🚀 Installation complète de Converto"
echo "========================================"
echo ""

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Fonction pour trouver un port libre
is_port_in_use() {
    local port=$1

    python3 - "$port" <<'PY'
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
        sys.exit(0)
    finally:
        sock.close()

sys.exit(1)
PY
}

find_free_port() {
    local port=$1
    local max_port=$((port + 100))
    
    while [ $port -le $max_port ]; do
        if ! is_port_in_use "$port"; then
            echo $port
            return 0
        fi
        port=$((port + 1))
    done
    
    echo "Aucun port disponible entre $1 et $max_port"
    exit 1
}

# Fonction pour afficher les chemins
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Vérifier Python
print_info "Vérification de Python..."
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 n'est pas installé"
    exit 1
fi

PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
print_success "Python $PYTHON_VERSION trouvé"

# Vérifier le module venv
print_info "Vérification de python3-venv..."
if ! python3 -m venv --help >/dev/null 2>&1; then
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y python3-venv
        print_success "python3-venv installé via apt"
    else
        print_error "Le module venv n'est pas disponible. Installez python3-venv puis relancez."
        exit 1
    fi
else
    print_success "python3-venv trouvé"
fi

# Vérifier Ghostscript (pour PDF)
print_info "Vérification de Ghostscript (pour PDF)..."
if ! command -v gs &> /dev/null; then
    print_error "Ghostscript n'est pas installé. Installation en cours..."
    
    if command -v brew &> /dev/null; then
        brew install ghostscript
        print_success "Ghostscript installé via Homebrew"
    elif command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y ghostscript
        print_success "Ghostscript installé via apt"
    else
        print_error "Impossible d'installer Ghostscript. Installer manuellement svp."
        exit 1
    fi
else
    print_success "Ghostscript trouvé"
fi

# Aller au répertoire du projet
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

print_info "Répertoire du projet: $PROJECT_DIR"

# Installer les dépendances Python
print_info "Installation des dépendances Python..."
python3 -m venv "$PROJECT_DIR/.venv"
"$PROJECT_DIR/.venv/bin/python" -m pip install -q --upgrade pip
"$PROJECT_DIR/.venv/bin/python" -m pip install -q -r "$PROJECT_DIR/backend/requirements.txt"
print_success "Dépendances installées"

cd "$PROJECT_DIR"

# Trouver les ports libres (en partant de 5000 et 3000 respectivement)
print_info "Recherche de ports disponibles..."
BACKEND_PORT=$(find_free_port 5000)
FRONTEND_PORT=$(find_free_port 3000)

print_success "Backend port: $BACKEND_PORT"
print_success "Frontend port: $FRONTEND_PORT"

# Créer un fichier de configuration des ports
cat > "$PROJECT_DIR/.ports" << EOF
BACKEND_PORT=$BACKEND_PORT
FRONTEND_PORT=$FRONTEND_PORT
EOF

echo ""
echo "========================================"
echo -e "${GREEN}✨ Installation réussie!${NC}"
echo "========================================"
echo ""
echo "🚀 Pour démarrer l'application:"
echo ""
echo -e "${YELLOW}Terminal 1 (Backend):${NC}"
echo "  cd $PROJECT_DIR/backend"
echo "  $PROJECT_DIR/.venv/bin/python app.py"
echo ""
echo -e "${YELLOW}Terminal 2 (Frontend):${NC}"
echo "  cd $PROJECT_DIR/frontend"
echo "  python -m http.server $FRONTEND_PORT"
echo ""
echo -e "${BLUE}Ou utilisez le script start.sh:${NC}"
echo "  bash $PROJECT_DIR/start.sh"
echo ""
echo -e "${GREEN}Puis ouvrez dans votre navigateur:${NC}"
echo "  http://localhost:$FRONTEND_PORT"
echo ""
