#!/usr/bin/env python3
"""
Serveur de test simple pour vérifier la connectivité depuis l'émulateur
"""
import http.server
import socketserver
import json
from urllib.parse import urlparse, parse_qs

class TestHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/api/test':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            response = {"message": "Serveur de test accessible", "status": "ok"}
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_POST(self):
        if self.path == '/api/login':
            # Lire le body de la requête
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            
            try:
                data = json.loads(post_data.decode('utf-8'))
                email = data.get('email', '')
                password = data.get('password', '')
                
                # Simulation d'une réponse de login
                if email == 'boss@boss.com' and password == 'password':
                    response = {
                        "success": True,
                        "message": "Connexion réussie",
                        "data": {
                            "user": {
                                "id": 1,
                                "email": "boss@boss.com",
                                "nom": "Boss",
                                "role": 6
                            },
                            "token": "test_token_12345"
                        }
                    }
                    self.send_response(200)
                else:
                    response = {
                        "success": False,
                        "message": "Email ou mot de passe incorrect"
                    }
                    self.send_response(401)
                
                self.send_header('Content-type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps(response).encode())
                
            except Exception as e:
                self.send_response(400)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                response = {"success": False, "message": f"Erreur: {str(e)}"}
                self.wfile.write(json.dumps(response).encode())
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == "__main__":
    PORT = 8000
    print(f"🚀 Démarrage du serveur de test sur le port {PORT}")
    print(f"📱 URL pour émulateur: http://10.0.2.2:{PORT}/api")
    print(f"💻 URL pour navigateur: http://localhost:{PORT}/api")
    print("🔑 Test login: boss@boss.com / password")
    print("⏹️  Arrêter avec Ctrl+C")
    
    with socketserver.TCPServer(("0.0.0.0", PORT), TestHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n🛑 Serveur arrêté")


