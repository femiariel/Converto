from flask import Flask, request, send_file, jsonify
from flask_cors import CORS
from werkzeug.utils import secure_filename
from PIL import Image
from io import BytesIO
import os
import tempfile
import zipfile
from pathlib import Path
import PyPDF2
from docx import Document
from docx.shared import Inches
import shutil
import subprocess
try:
    import fitz  # PyMuPDF
    HAS_PYMUPDF = True
except ImportError:
    HAS_PYMUPDF = False

app = Flask(__name__)
CORS(app)

# Configuration
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_FOLDER = os.path.join(BASE_DIR, 'uploads')
DOWNLOAD_FOLDER = os.path.join(BASE_DIR, 'downloads')
ALLOWED_EXTENSIONS = {'pdf', 'docx', 'doc'}
MAX_FILE_SIZE = 500 * 1024 * 1024  # 500MB
TARGET_SIZE = 5 * 1024 * 1024  # 5MB

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(DOWNLOAD_FOLDER, exist_ok=True)

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['DOWNLOAD_FOLDER'] = DOWNLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = MAX_FILE_SIZE

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def compress_image(image_stream, max_size=500):
    """Compresse une image en réduisant sa taille et sa qualité"""
    try:
        img = Image.open(image_stream)
        
        # Convertir en RGB si nécessaire
        if img.mode in ('RGBA', 'LA', 'P'):
            rgb_img = Image.new('RGB', img.size, (255, 255, 255))
            rgb_img.paste(img, mask=img.split()[-1] if img.mode == 'RGBA' else None)
            img = rgb_img
        
        # Réduire la taille
        img.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)
        
        # Compresser et sauvegarder
        output = BytesIO()
        img.save(output, format='JPEG', quality=60, optimize=True)
        output.seek(0)
        return output
    except Exception as e:
        print(f"Erreur compression image: {e}")
        return image_stream

def compress_docx(input_path, output_path):
    """Compresse les images dans un fichier DOCX"""
    try:
        # Créer un dossier temporaire
        with tempfile.TemporaryDirectory() as temp_dir:
            # Extraire le DOCX (c'est un ZIP)
            with zipfile.ZipFile(input_path, 'r') as zip_ref:
                zip_ref.extractall(temp_dir)
            
            # Traiter les images
            media_path = os.path.join(temp_dir, 'word', 'media')
            if os.path.exists(media_path):
                for filename in os.listdir(media_path):
                    image_path = os.path.join(media_path, filename)
                    if os.path.isfile(image_path):
                        try:
                            with Image.open(image_path) as img:
                                # Redimensionner pour atteindre 5MB target
                                img.thumbnail((400, 400), Image.Resampling.LANCZOS)
                                
                                # Convertir en RGB
                                if img.mode in ('RGBA', 'LA', 'P'):
                                    rgb_img = Image.new('RGB', img.size, (255, 255, 255))
                                    rgb_img.paste(img, mask=img.split()[-1] if img.mode == 'RGBA' else None)
                                    img = rgb_img
                                
                                # Sauvegarder en JPEG avec bonne qualité
                                img.save(image_path, 'JPEG', quality=70, optimize=True)
                        except Exception as e:
                            print(f"Erreur compression image {filename}: {e}")
            
            # Recréer le ZIP
            with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zip_ref:
                for root, dirs, files in os.walk(temp_dir):
                    for file in files:
                        file_path = os.path.join(root, file)
                        arcname = os.path.relpath(file_path, temp_dir)
                        zip_ref.write(file_path, arcname)
        
        return True
    except Exception as e:
        print(f"Erreur DOCX: {e}")
        return False

def compress_pdf(input_path, output_path):
    """Compresse les images dans un fichier PDF avec Ghostscript"""
    try:
        # Commande Ghostscript pour compresser les images du PDF
        command = [
            'gs',
            '-sDEVICE=pdfwrite',
            '-dCompatibilityLevel=1.4',
            '-dPDFSETTINGS=/prepress',  # Meilleure qualité
            '-dNOPAUSE',
            '-dQUIET',
            '-dBATCH',
            '-dDetectDuplicateImages',
            '-r150x150',  # Résolution 150 DPI pour atteindre 5MB
            '-dDownsampleColorImages=true',
            '-dColorImageResolution=150',
            '-dGrayImageResolution=150',  # Résolution réduite
            f'-sOutputFile={output_path}',
            input_path
        ]
        
        # Exécuter Ghostscript
        result = subprocess.run(command, capture_output=True, text=True, timeout=300)
        
        if result.returncode != 0:
            print(f"Ghostscript error: {result.stderr}")
            return False
        
        return True
    except Exception as e:
        print(f"Erreur PDF avec Ghostscript: {e}")
        return False

def compress_to_zip(input_path, output_path):
    """Zippe un fichier pour le réduire encore plus"""
    try:
        zip_path = output_path.replace(f".{output_path.split('.')[-1]}", ".zip")
        with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
            zipf.write(input_path, arcname=os.path.basename(input_path))
        return zip_path if os.path.getsize(zip_path) < os.path.getsize(input_path) else None
    except Exception as e:
        print(f"Erreur ZIP: {e}")
        return None

@app.route('/api/upload', methods=['POST'])
def upload_file():
    """Endpoint pour uploader et compresser un fichier"""
    try:
        if 'file' not in request.files:
            return jsonify({'error': 'Aucun fichier'}), 400
        
        file = request.files['file']
        zip_option = request.form.get('zip', 'false').lower() == 'true'
        
        if file.filename == '':
            return jsonify({'error': 'Nom de fichier vide'}), 400
        
        if not allowed_file(file.filename):
            return jsonify({'error': 'Format non supporté. Utilisez PDF ou DOCX'}), 400
        
        # Sauvegarder le fichier
        filename = secure_filename(file.filename)
        input_path = os.path.join(UPLOAD_FOLDER, filename)
        file.save(input_path)
        
        # Traiter selon le type
        ext = filename.rsplit('.', 1)[1].lower()
        output_filename = f"compressed_{Path(filename).stem}.{ext}"
        output_path = os.path.join(DOWNLOAD_FOLDER, output_filename)
        
        # Obtenir la taille originale
        original_size = os.path.getsize(input_path)
        
        if ext == 'pdf':
            success = compress_pdf(input_path, output_path)
        elif ext in ['docx', 'doc']:
            success = compress_docx(input_path, output_path)
        else:
            return jsonify({'error': 'Format non supporté'}), 400
        
        if not success:
            return jsonify({'error': 'Erreur lors de la compression'}), 500
        
        # Obtenir la taille compressée
        compressed_size = os.path.getsize(output_path)
        final_filename = output_filename
        final_size = compressed_size
        is_zipped = False
        
        # Appliquer ZIP optionnel
        if zip_option:
            zip_path = compress_to_zip(output_path, output_path)
            if zip_path:
                os.remove(output_path)  # Supprimer le fichier non-zippé
                output_path = zip_path
                final_filename = os.path.basename(zip_path)
                final_size = os.path.getsize(zip_path)
                is_zipped = True
        
        compression_ratio = (1 - final_size / original_size) * 100
        
        # Nettoyer l'upload
        os.remove(input_path)
        
        return jsonify({
            'success': True,
            'filename': final_filename,
            'original_size': original_size,
            'compressed_size': final_size,
            'compression_ratio': round(compression_ratio, 2),
            'is_zipped': is_zipped
        })
    
    except Exception as e:
        print(f"Erreur: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/download/<filename>', methods=['GET'])
def download_file(filename):
    """Endpoint pour télécharger le fichier compressé"""
    try:
        file_path = os.path.join(DOWNLOAD_FOLDER, secure_filename(filename))
        
        if not os.path.exists(file_path):
            return jsonify({'error': 'Fichier non trouvé'}), 404
        
        response = send_file(file_path, as_attachment=True)
        
        # Nettoyer après téléchargement
        def remove_file(response):
            try:
                os.remove(file_path)
            except:
                pass
            return response
        
        return response
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/health', methods=['GET'])
def health():
    """Vérifier que l'API fonctionne"""
    return jsonify({'status': 'ok'})

if __name__ == '__main__':
    # Lire le port depuis le fichier .ports si disponible
    port = 5000
    ports_file = os.path.join(os.path.dirname(BASE_DIR), '.ports')
    
    if os.path.exists(ports_file):
        try:
            with open(ports_file, 'r') as f:
                for line in f:
                    if line.startswith('BACKEND_PORT='):
                        port = int(line.split('=')[1].strip())
                        break
        except:
            pass
    
    print(f"🚀 Backend démarrant sur le port {port}")
    app.run(debug=True, host='0.0.0.0', port=port)
