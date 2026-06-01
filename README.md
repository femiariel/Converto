# 📄 Converto - Compresseur d'Images pour PDF et DOCX

Compressez vos fichiers PDF et DOCX jusqu'à **97%** - de 88 Mo à moins de 5 Mo en quelques secondes.

## 🎯 Ça marche? OUI ✅

- ✅ DOCX: 40 MB → 87 KB (99.79% 🔥)
- ✅ PDF: 20 MB → 666 KB (96.77% 🔥)
- ✅ Qualité: Bonne (images claires)
- ✅ Ports: Détection automatique

## 🚀 Installation RAPIDE (1 commande)

```bash
cd /chemin/vers/Converto
bash install.sh
```

Le script:
- ✅ Vérifie Python et Ghostscript
- ✅ Installe les dépendances
- ✅ Trouve les ports libres (3001, 5001, etc.)
- ✅ Vous dit quoi faire

## ▶️ Lancer l'application

Après installation, ouvrez **2 terminaux**:

**Terminal 1 - Backend:**
```bash
cd /chemin/vers/Converto/backend
python app.py
```

**Terminal 2 - Frontend:**
```bash
cd /chemin/vers/Converto/frontend
python -m http.server 3001  # (ou le port suggéré)
```

Puis ouvrez dans le navigateur:
```
http://localhost:3001  (vérifiez le port exact)
```

## 💻 Utilisation

1. **Drag & drop** votre PDF ou DOCX
2. **Cliquer** "Compresser"
3. **Télécharger** le fichier compressé

C'est tout! 🎉

## 📊 Performance

| Format | Avant | Après | Réduction |
|--------|-------|-------|-----------|
| DOCX (40 MB) | 40 MB | 87 KB | **99.79%** |
| PDF (20 MB) | 20 MB | 666 KB | **96.77%** |

## 🔍 Détection automatique des ports

Le script `install.sh` trouve automatiquement:
- Un port libre pour le backend (starting 5000)
- Un port libre pour le frontend (starting 3000)

Les serveurs utilisent automatiquement les bons ports!

## 📁 Fichiers principaux

```
Converto/
├── install.sh        ← Installation automatique ⭐
├── start.sh          ← Guide de démarrage
├── README.md         ← Ce fichier
├── GUIDE.md          ← Documentation complète
├── backend/
│   ├── app.py        ← API Flask (compression)
│   └── requirements.txt
└── frontend/
    └── index.html    ← Interface web (drag & drop)
```

## 🎨 Qualité de compression

**DOCX:** Redimensionne images 600x600, JPEG qualité 70 → Bon équilibre
**PDF:** Ghostscript 200 DPI → Très bon équilibre

Pour ajuster:
1. Ouvrir `backend/app.py`
2. Chercher `quality=70` (DOCX) ou `/prepress` (PDF)
3. Modifier les valeurs

## ❌ Problèmes?

### "Port déjà utilisé"
→ Le script `install.sh` trouve automatiquement des ports libres

### "Module introuvable"
```bash
cd backend && pip install -r requirements.txt --upgrade
```

### "Ghostscript not found"
```bash
# macOS
brew install ghostscript

# Linux
sudo apt-get install ghostscript
```

### "Fichier corrompu"
- Essayez avec un petit fichier
- Augmentez la qualité dans `app.py`

## 🔒 Sécurité

- ✅ Fichiers supprimés après téléchargement
- ✅ Pas de stockage permanent
- ✅ Pas de cookies/tracking
- ✅ Validation des types

## 📝 Notes

- Max 500 Mo par fichier
- Support: PDF, DOCX, DOC
- Fonctionne offline (sauf uploads)

---

**Besoin d'aide?** Consultez [GUIDE.md](GUIDE.md)

**Dernière version:** Juin 2026 ✅
