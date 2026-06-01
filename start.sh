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
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_error "Le port $port est déjà utilisé!"
        return 1
    fi
    return 0
}

if ! check_port $BACKEND_PORT; then
    exit 1
fi

if ! check_port $FRONTEND_PORT; then
    exit 1
fi

# Créer les fichiers de démarrage temporaires
BACKEND_SCRIPT=$(mktemp)
FRONTEND_SCRIPT=$(mktemp)

cat > "$BACKEND_SCRIPT" << 'BACKEND_EOF'
#!/bin/bash
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/backend"
python app.py
BACKEND_EOF

cat > "$FRONTEND_SCRIPT" << 'FRONTEND_EOF'
#!/bin/bash
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/frontend"
python -m http.server 3000
FRONTEND_EOF

chmod +x "$BACKEND_SCRIPT"
chmod +x "$FRONTEND_SCRIPT"

# Afficher les instructions
echo -e "${YELLOW}📝 Instructions:${NC}"
echo ""
echo "Ouvrez DEUX terminaux séparés et exécutez:"
echo ""
echo -e "${YELLOW}Terminal 1 (Backend):${NC}"
echo "  cd $PROJECT_DIR/backend"
echo "  python app.py"
echo ""
echo -e "${YELLOW}Terminal 2 (Frontend):${NC}"
echo "  cd $PROJECT_DIR/frontend"
echo "  python -m http.server $FRONTEND_PORT"
echo ""
echo -e "${GREEN}Puis ouvrez dans votre navigateur:${NC}"
echo "  ${BLUE}http://localhost:$FRONTEND_PORT${NC}"
echo ""
echo "Appuyez sur Ctrl+C pour arrêter l'application"
echo ""
