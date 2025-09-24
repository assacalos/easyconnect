# Exemples de Tests API - Application CRM

## Configuration des Tests

### 1. Installation des dépendances
```bash
composer install
php artisan migrate
php artisan db:seed
```

### 2. Démarrage du serveur
```bash
php artisan serve
```

## Tests d'Authentification

### Connexion d'un Commercial
```bash
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "commercial@example.com",
    "password": "password"
  }'
```

**Réponse attendue :**
```json
{
  "success": true,
  "token": "1|abc123...",
  "user": {
    "id": 2,
    "nom": "Fabrice",
    "prenom": "Vagba",
    "email": "commercial@example.com",
    "role": 2,
    "role_name": "Commercial"
  },
  "message": "Connexion réussie"
}
```

### Connexion du Patron
```bash
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "patron@example.com",
    "password": "password"
  }'
```

## Tests de Gestion des Clients

### 1. Créer un client (Commercial)
```bash
curl -X POST http://localhost:8000/api/clients \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {token}" \
  -d '{
    "nom": "Dupont",
    "prenom": "Jean",
    "email": "jean.dupont@example.com",
    "contact": "0123456789",
    "adresse": "123 Rue de la Paix, Paris",
    "nom_entreprise": "Entreprise ABC",
    "situation_geographique": "Paris",
    "status": "en_attente"
  }'
```

### 2. Lister les clients
```bash
curl -X GET http://localhost:8000/api/list-clients \
  -H "Authorization: Bearer {token}"
```

### 3. Voir les détails d'un client
```bash
curl -X GET http://localhost:8000/api/clients-show/1 \
  -H "Authorization: Bearer {token}"
```

### 4. Approuver un client (Patron)
```bash
curl -X POST http://localhost:8000/api/clients/1/approve \
  -H "Authorization: Bearer {token}"
```

### 5. Rejeter un client (Patron)
```bash
curl -X POST http://localhost:8000/api/clients/1/reject \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {token}" \
  -d '{
    "commentaire": "Informations incomplètes"
  }'
```

## Tests de Gestion des Factures

### 1. Créer une facture (Comptable)
```bash
curl -X POST http://localhost:8000/api/factures \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {token}" \
  -d '{
    "client_id": 1,
    "numero_facture": "FAC-2024-001",
    "montant": 1500.00,
    "date_facture": "2024-01-15",
    "description": "Prestation de service",
    "status": "en_attente"
  }'
```

### 2. Lister les factures
```bash
curl -X GET http://localhost:8000/api/factures \
  -H "Authorization: Bearer {token}"
```

### 3. Marquer une facture comme payée
```bash
curl -X POST http://localhost:8000/api/factures/1/mark-paid \
  -H "Authorization: Bearer {token}"
```

### 4. Obtenir les rapports financiers
```bash
curl -X GET "http://localhost:8000/api/factures-reports?date_debut=2024-01-01&date_fin=2024-12-31" \
  -H "Authorization: Bearer {token}"
```

## Tests de Permissions

### 1. Test d'accès refusé (Commercial essayant d'approuver un client)
```bash
# Se connecter en tant que commercial
TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "commercial@example.com", "password": "password"}' | jq -r '.token')

# Essayer d'approuver un client (doit échouer)
curl -X POST http://localhost:8000/api/clients/1/approve \
  -H "Authorization: Bearer $TOKEN"
```

**Réponse attendue :**
```json
{
  "message": "Accès refusé. Rôle insuffisant.",
  "required_roles": [1, 6],
  "user_role": 2
}
```

### 2. Test d'accès refusé (Commercial essayant de créer une facture)
```bash
curl -X POST http://localhost:8000/api/factures \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "client_id": 1,
    "numero_facture": "FAC-2024-002",
    "montant": 2000.00,
    "date_facture": "2024-01-20",
    "status": "en_attente"
  }'
```

## Tests de Validation

### 1. Test de validation des données client
```bash
curl -X POST http://localhost:8000/api/clients \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {token}" \
  -d '{
    "nom": "",
    "email": "email-invalide"
  }'
```

**Réponse attendue :**
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "nom": ["The nom field is required."],
    "email": ["The email must be a valid email address."]
  }
}
```

## Tests de Déconnexion

### Déconnexion
```bash
curl -X POST http://localhost:8000/api/logout \
  -H "Authorization: Bearer {token}"
```

**Réponse attendue :**
```json
{
  "success": true,
  "message": "Déconnexion réussie"
}
```

## Tests d'Informations Utilisateur

### Obtenir les informations de l'utilisateur connecté
```bash
curl -X GET http://localhost:8000/api/me \
  -H "Authorization: Bearer {token}"
```

**Réponse attendue :**
```json
{
  "success": true,
  "user": {
    "id": 2,
    "nom": "Fabrice",
    "prenom": "Vagba",
    "email": "commercial@example.com",
    "role": 2,
    "role_name": "Commercial"
  }
}
```

## Script de Test Automatisé

Créer un fichier `test_api.sh` :

```bash
#!/bin/bash

BASE_URL="http://localhost:8000/api"

echo "=== Test de l'API CRM ==="

# Test de connexion
echo "1. Test de connexion..."
LOGIN_RESPONSE=$(curl -s -X POST $BASE_URL/login \
  -H "Content-Type: application/json" \
  -d '{"email": "commercial@example.com", "password": "password"}')

TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.token')
echo "Token obtenu: $TOKEN"

# Test de création de client
echo "2. Test de création de client..."
CLIENT_RESPONSE=$(curl -s -X POST $BASE_URL/clients \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "nom": "Test",
    "prenom": "Client",
    "email": "test@example.com",
    "contact": "0123456789",
    "adresse": "123 Test Street",
    "nom_entreprise": "Test Company",
    "situation_geographique": "Test City",
    "status": "en_attente"
  }')

echo "Réponse création client: $CLIENT_RESPONSE"

# Test de liste des clients
echo "3. Test de liste des clients..."
LIST_RESPONSE=$(curl -s -X GET $BASE_URL/list-clients \
  -H "Authorization: Bearer $TOKEN")

echo "Liste des clients: $LIST_RESPONSE"

echo "=== Tests terminés ==="
```

Exécuter le script :
```bash
chmod +x test_api.sh
./test_api.sh
```
