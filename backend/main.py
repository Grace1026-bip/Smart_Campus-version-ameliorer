# main.py
from flask import Flask, jsonify
from flask_cors import CORS
import os
from dotenv import load_dotenv

# Chargement des variables d'environnement (.env)
load_dotenv()

app = Flask(__name__)
CORS(app)  # Permet à ton application Flutter de communiquer avec le backend sans blocage

@app.route('/api/statut', methods=['GET'])
def verifier_statut():
    return jsonify({
        "statut": "En ligne",
        "projet": "Smart Campus - Bulãli ID",
        "version": "1.0.0"
    }), 200

if __name__ == '__main__':
    # Lance le serveur sur le port 5000, accessible sur ton réseau local
    app.run(host='0.0.0.0', port=5000, debug=True)