# Configuration pour servir le frontend avec Python

import http.server
import socketserver
import os
from pathlib import Path

PORT = 3000
FRONTEND_DIR = Path(__file__).parent

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(FRONTEND_DIR), **kwargs)

    def end_headers(self):
        # Empêcher la mise en cache pour développement
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        return super().end_headers()

if __name__ == "__main__":
    os.chdir(FRONTEND_DIR)
    
    with socketserver.TCPServer(("", PORT), MyHTTPRequestHandler) as httpd:
        print(f"🌐 Serveur frontend sur http://localhost:{PORT}")
        print(f"📂 Serveur les fichiers de: {FRONTEND_DIR}")
        print(f"✅ Appuyez sur Ctrl+C pour arrêter")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n✋ Serveur arrêté")
