# 📚 Guide Complet Converto

## 🎯 Qu'est-ce que Converto?

Converto est un outil web gratuit qui compresse les images dans vos fichiers PDF et Word, réduisant leur taille de 88 Mo à moins de 5 Mo en quelques secondes.

## 💻 Installation Locale

### Prérequis
- Python 3.7+ 
- Un navigateur web
- Terminal/Command Prompt

### Sur macOS/Linux

```bash
# 1. Cloner/télécharger le projet
cd ~/Desktop
git clone <url-du-projet> Converto
cd Converto

# 2. Installer les dépendances
pip install -r backend/requirements.txt

# 3. Lancer les serveurs (2 terminaux)

# Terminal 1: Backend
cd backend
python app.py

# Terminal 2: Frontend  
cd frontend
python server.py

# 4. Ouvrir dans le navigateur
# http://localhost:3000
```

### Sur Windows

```batch
# 1. Command Prompt (admin)
cd Desktop
git clone <url-du-projet> Converto
cd Converto

# 2. Installer les dépendances
pip install -r backend/requirements.txt

# 3. Lancer les serveurs (2 Command Prompts)

# Command Prompt 1: Backend
cd backend
python app.py

# Command Prompt 2: Frontend
cd frontend
python server.py

# 4. Ouvrir dans le navigateur
# http://localhost:3000
```

## 🖱️ Comment utiliser

### Étapes simples:

1. **Ouvrir l'app** → http://localhost:3000
2. **Upload votre fichier**
   - Glissez-déposez votre PDF/DOCX
   - Ou cliquez pour parcourir
3. **Cliquez sur "Compresser"**
4. **Téléchargez** le fichier compressé

## ⚙️ Configuration

### Changer la qualité de compression

Éditez `backend/app.py`:

```python
# Ligne 80 (DOCX) et ligne 110 (PDF)
img.save(output_path, 'JPEG', quality=60, optimize=True)

# 40-50 = Compression maximale (mauvaise qualité)
# 60-70 = Équilibre (recommandé)
# 80-90 = Meilleure qualité (compression moins importante)
```

### Changer la taille maximale des images

```python
# Ligne 79 (DOCX)
img.thumbnail((800, 800), Image.Resampling.LANCZOS)

# Ligne 109 (PDF)  
img.thumbnail((1024, 1024), Image.Resampling.LANCZOS)

# Plus le chiffre est petit, plus la compression est forte
```

### Changer le port du serveur

Éditez `backend/app.py`:

```python
# Ligne 126
app.run(debug=True, host='0.0.0.0', port=9000)  # Utiliser 9000 au lieu de 8000
```

## 🔧 Dépannage

### "Connexion refused"
- ✅ Vérifiez que les 2 serveurs (backend + frontend) sont actifs
- ✅ Vérifiez les ports: backend=8000, frontend=3000
- ✅ Vérifiez que rien d'autre n'utilise ces ports

### "Port déjà utilisé"
```bash
# macOS/Linux: Trouver et tuer le processus
lsof -i :8000
kill -9 <PID>

# Windows: Utiliser Task Manager ou
netstat -ano | findstr :8000
taskkill /PID <PID> /F
```

### "Fichier corrompu après compression"
- Vérifiez que le fichier original est valide
- Réduisez la qualité: `quality=40`
- Vérifiez que PIL/Pillow est correctement installé

### "Module introuvable"
```bash
# Réinstaller les dépendances
pip install --upgrade -r backend/requirements.txt
```

## 📊 Performances

### Tailles typiques après compression

| Type de fichier | Avant | Après | Réduction |
|-----------------|-------|-------|-----------|
| PDF avec images | 88 Mo | 3-5 Mo | 95% |
| DOCX avec images | 75 Mo | 4-6 Mo | 93% |
| Présentation | 120 Mo | 5-8 Mo | 95% |

### Temps de traitement

| Taille | Temps |
|--------|-------|
| 10 Mo | < 2s |
| 50 Mo | 5-10s |
| 100+ Mo | 15-30s |

## 🔒 Sécurité

### Comment vos fichiers sont traités

✅ **Sûr & Privé:**
- Les fichiers sont temporaires
- Aucun stockage à long terme
- Traitement local sur votre machine
- Suppression automatique après téléchargement
- Validation stricte des types

### Recommandations

- N'utilisez pas sur des réseaux publics non sécurisés
- Pour production, activez HTTPS
- Mettez en place une limite de débit
- Validez les entrées utilisateur

## 🚀 Déployer en ligne

### Options gratuites:

1. **Heroku** → https://heroku.com
   - Gratuit pour 5000 dyno-hours/mois
   ```bash
   bash deploy-heroku.sh
   ```

2. **Railway** → https://railway.app
   - Plus simple, gratuit avec limites

3. **Render** → https://render.com
   - Gratuit, bonne performance

4. **Vercel + Python Backend**
   - Frontend sur Vercel (gratuit)
   - Backend sur Railway/Render

Pour détails complets: voir [DEPLOYMENT.md](DEPLOYMENT.md)

## 🎨 Personnaliser l'interface

### Changer les couleurs

Éditez `frontend/index.html`, ligne ~35:

```css
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
/* Changez les codes couleur (#667eea, #764ba2) */
```

### Ajouter votre logo

Remplacez l'emoji `📄` par votre logo:

```html
<div class="logo">📄</div>
<!-- Ou -->
<div class="logo"><img src="logo.png" alt="Logo"></div>
```

### Changer les messages

Tous les textes sont dans `frontend/index.html`, facile à modifier!

## 📞 Support

### Problèmes?

1. Vérifiez les logs du terminal
2. Vérifiez que Python 3.7+ est installé: `python --version`
3. Vérifiez les ports: `lsof -i :8000` (macOS/Linux)
4. Réinstallez les packages: `pip install -r backend/requirements.txt --force-reinstall`

## 📈 Améliorations futures

Possibilités d'amélioration:

- [ ] Support pour d'autres formats (PPT, XLSX)
- [ ] Compression en temps réel avec barre de progression
- [ ] Historique des compressions
- [ ] Aperçu avant/après
- [ ] Batch compression (plusieurs fichiers)
- [ ] API REST publique
- [ ] Authentification utilisateur
- [ ] Stockage cloud

## 📝 Licence

Libre d'utilisation pour usage personnel et commercial.

## 🙏 Crédits

Créé avec ❤️ pour simplifier vos documents!

---

**Dernière mise à jour:** Juin 2026
**Version:** 1.0.0
