# Tests Complets de l'API CRM

## Configuration des Tests

### 1. Installation et Configuration
```bash
# Installation des dépendances
composer install

# Configuration de la base de données
php artisan migrate
php artisan db:seed

# Démarrage du serveur
php artisan serve
```

### 2. Utilisateurs de Test
Les utilisateurs suivants sont créés par le seeder :
- **Admin** : admin@example.com / password
- **Commercial** : commercial@example.com / password
- **Comptable** : comptable@example.com / password
- **RH** : rh@example.com / password
- **Technicien** : technicien@example.com / password
- **Patron** : patron@example.com / password

---

## Tests d'Authentification

### 1. Connexion des Utilisateurs
```bash
# Test de connexion Admin
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@example.com", "password": "password"}'

# Test de connexion Commercial
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "commercial@example.com", "password": "password"}'

# Test de connexion Comptable
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "comptable@example.com", "password": "password"}'
```

### 2. Test des Permissions
```bash
# Test d'accès refusé (Commercial essayant d'accéder aux factures)
TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "commercial@example.com", "password": "password"}' | jq -r '.token')

curl -X GET http://localhost:8000/api/factures \
  -H "Authorization: Bearer $TOKEN"
# Doit retourner 403 Forbidden
```

---

## Tests de Gestion des Clients

### 1. Création de Clients
```bash
# Connexion en tant que Commercial
TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "commercial@example.com", "password": "password"}' | jq -r '.token')

# Créer un client
curl -X POST http://localhost:8000/api/clients \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "nom": "Martin",
    "prenom": "Pierre",
    "email": "pierre.martin@example.com",
    "contact": "0123456789",
    "adresse": "456 Avenue des Champs",
    "nom_entreprise": "Entreprise Martin",
    "situation_geographique": "Lyon",
    "status": "en_attente"
  }'

# Créer un autre client
curl -X POST http://localhost:8000/api/clients \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "nom": "Durand",
    "prenom": "Marie",
    "email": "marie.durand@example.com",
    "contact": "0987654321",
    "adresse": "789 Rue de la République",
    "nom_entreprise": "Société Durand",
    "situation_geographique": "Marseille",
    "statut": "en_attente"
  }'
```

### 2. Approbation des Clients
```bash
# Connexion en tant que Patron
TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "patron@example.com", "password": "password"}' | jq -r '.token')

# Approuver le premier client
curl -X POST http://localhost:8000/api/clients/1/approve \
  -H "Authorization: Bearer $TOKEN"

# Rejeter le deuxième client
curl -X POST http://localhost:8000/api/clients/2/reject \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"commentaire": "Informations incomplètes"}'
```

---

## Tests de Gestion des Factures

### 1. Création de Factures
```bash
# Connexion en tant que Comptable
TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "comptable@example.com", "password": "password"}' | jq -r '.token')

# Créer une facture
curl -X POST http://localhost:8000/api/factures \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "client_id": 1,
    "numero_facture": "FAC-2024-001",
    "montant": 1500.00,
    "date_facture": "2024-01-15",
    "description": "Prestation de service",
    "statut": "en_attente"
  }'

# Créer une autre facture
curl -X POST http://localhost:8000/api/factures \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "client_id": 1,
    "numero_facture": "FAC-2024-002",
    "montant": 2500.00,
    "date_facture": "2024-01-20",
    "description": "Consultation",
    "statut": "en_attente"
  }'
```

### 2. Gestion des Paiements
```bash
# Créer un paiement
curl -X POST http://localhost:8000/api/paiements \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "facture_id": 1,
    "montant": 1500.00,
    "date_paiement": "2024-01-16",
    "mode_paiement": "virement",
    "reference": "VIR-2024-001",
    "statut": "en_attente",
    "commentaire": "Paiement par virement"
  }'

# Valider le paiement
curl -X POST http://localhost:8000/api/paiements/1/validate \
  -H "Authorization: Bearer $TOKEN"
```

---

## Tests de Gestion des Pointages

### 1. Pointage Personnel
```bash
# Connexion en tant que Technicien
TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "technicien@example.com", "password": "password"}' | jq -r '.token')

# Pointer l'arrivée
curl -X POST http://localhost:8000/api/pointages/arrivee \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "lieu": "Bureau principal",
    "commentaire": "Arrivée normale"
  }'

# Pointer le départ
curl -X POST http://localhost:8000/api/pointages/depart \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "commentaire": "Fin de journée"
  }'

# Voir les pointages d'aujourd'hui
curl -X GET http://localhost:8000/api/pointages/today \
  -H "Authorization: Bearer $TOKEN"
```

### 2. Validation des Pointages
```bash
# Connexion en tant que RH
TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "rh@example.com", "password": "password"}' | jq -r '.token')

# Valider un pointage
curl -X POST http://localhost:8000/api/pointages/1/validate \
  -H "Authorization: Bearer $TOKEN"

# Rejeter un pointage
curl -X POST http://localhost:8000/api/pointages/2/reject \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"commentaire": "Heure d\'arrivée incorrecte"}'
```

---

## Tests de Gestion des Fournisseurs

### 1. Création de Fournisseurs
```bash
# Connexion en tant que Comptable
TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "comptable@example.com", "password": "password"}' | jq -r '.token')

# Créer un fournisseur
curl -X POST http://localhost:8000/api/fournisseurs \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "nom": "Fournisseur ABC",
    "email": "contact@fournisseur-abc.com",
    "telephone": "0123456789",
    "adresse": "123 Rue du Commerce",
    "ville": "Paris",
    "code_postal": "75001",
    "pays": "France",
    "contact_principal": "Jean Dupont",
    "telephone_contact": "0987654321",
    "email_contact": "jean.dupont@fournisseur-abc.com",
    "site_web": "https://www.fournisseur-abc.com",
    "statut": "actif",
    "commentaire": "Fournisseur fiable",
    "conditions_paiement": "30 jours",
    "delai_livraison": 7
  }'
```

### 2. Gestion des Bons de Commande
```bash
# Créer un bon de commande
curl -X POST http://localhost:8000/api/bons-de-commande \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "client_id": 1,
    "fournisseur_id": 1,
    "numero_commande": "BC-2024-001",
    "date_commande": "2024-01-15",
    "date_livraison_prevue": "2024-01-22",
    "montant_total": 5000.00,
    "description": "Commande de matériel",
    "statut": "en_attente",
    "commentaire": "Commande urgente",
    "conditions_paiement": "30 jours",
    "delai_livraison": 7
  }'

# Valider le bon de commande
curl -X POST http://localhost:8000/api/bons-de-commande/1/validate \
  -H "Authorization: Bearer $TOKEN"

# Marquer comme en cours
curl -X POST http://localhost:8000/api/bons-de-commande/1/mark-in-progress \
  -H "Authorization: Bearer $TOKEN"

# Marquer comme livré
curl -X POST http://localhost:8000/api/bons-de-commande/1/mark-delivered \
  -H "Authorization: Bearer $TOKEN"
```

---

## Tests de Rapports

### 1. Tableau de Bord
```bash
# Connexion en tant que Patron
TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "patron@example.com", "password": "password"}' | jq -r '.token')

# Tableau de bord général
curl -X GET "http://localhost:8000/api/dashboard?date_debut=2024-01-01&date_fin=2024-12-31" \
  -H "Authorization: Bearer $TOKEN"

# Rapport financier
curl -X GET "http://localhost:8000/api/reports/financial?date_debut=2024-01-01&date_fin=2024-12-31" \
  -H "Authorization: Bearer $TOKEN"

# Rapport RH
curl -X GET "http://localhost:8000/api/reports/hr?date_debut=2024-01-01&date_fin=2024-12-31" \
  -H "Authorization: Bearer $TOKEN"

# Rapport commercial
curl -X GET "http://localhost:8000/api/reports/commercial?date_debut=2024-01-01&date_fin=2024-12-31" \
  -H "Authorization: Bearer $TOKEN"
```

### 2. Rapports Spécifiques
```bash
# Rapport des factures
curl -X GET "http://localhost:8000/api/factures-reports?date_debut=2024-01-01&date_fin=2024-12-31" \
  -H "Authorization: Bearer $TOKEN"

# Rapport des paiements
curl -X GET "http://localhost:8000/api/paiements-reports?date_debut=2024-01-01&date_fin=2024-12-31" \
  -H "Authorization: Bearer $TOKEN"

# Rapport des pointages
curl -X GET "http://localhost:8000/api/pointages-reports?date_debut=2024-01-01&date_fin=2024-12-31" \
  -H "Authorization: Bearer $TOKEN"

# Rapport des fournisseurs
curl -X GET "http://localhost:8000/api/fournisseurs-reports" \
  -H "Authorization: Bearer $TOKEN"
```

---

## Tests de Validation des Données

### 1. Test de Validation des Clients
```bash
# Test avec données invalides
curl -X POST http://localhost:8000/api/clients \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "nom": "",
    "email": "email-invalide",
    "contact": ""
  }'
# Doit retourner des erreurs de validation
```

### 2. Test de Validation des Factures
```bash
# Test avec montant négatif
curl -X POST http://localhost:8000/api/factures \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "client_id": 1,
    "numero_facture": "FAC-2024-003",
    "montant": -100.00,
    "date_facture": "2024-01-15",
    "statut": "en_attente"
  }'
# Doit retourner une erreur de validation
```

---

## Script de Test Automatisé

Créer un fichier `test_complete_api.sh` :

```bash
#!/bin/bash

BASE_URL="http://localhost:8000/api"
echo "=== Test Complet de l'API CRM ==="

# Fonction pour obtenir un token
get_token() {
    local email=$1
    local password=$2
    curl -s -X POST $BASE_URL/login \
        -H "Content-Type: application/json" \
        -d "{\"email\": \"$email\", \"password\": \"$password\"}" | jq -r '.token'
}

# Test de connexion
echo "1. Test de connexion..."
ADMIN_TOKEN=$(get_token "admin@example.com" "password")
COMMERCIAL_TOKEN=$(get_token "commercial@example.com" "password")
COMPTABLE_TOKEN=$(get_token "comptable@example.com" "password")
RH_TOKEN=$(get_token "rh@example.com" "password")
TECHNICIEN_TOKEN=$(get_token "technicien@example.com" "password")
PATRON_TOKEN=$(get_token "patron@example.com" "password")

echo "Tokens obtenus avec succès"

# Test de création de client
echo "2. Test de création de client..."
CLIENT_RESPONSE=$(curl -s -X POST $BASE_URL/clients \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $COMMERCIAL_TOKEN" \
    -d '{
        "nom": "Test",
        "prenom": "Client",
        "email": "test.client@example.com",
        "contact": "0123456789",
        "adresse": "123 Test Street",
        "nom_entreprise": "Test Company",
        "situation_geographique": "Test City",
        "statut": "en_attente"
    }')

echo "Client créé: $CLIENT_RESPONSE"

# Test d'approbation de client
echo "3. Test d'approbation de client..."
APPROVE_RESPONSE=$(curl -s -X POST $BASE_URL/clients/1/approve \
    -H "Authorization: Bearer $PATRON_TOKEN")

echo "Client approuvé: $APPROVE_RESPONSE"

# Test de création de facture
echo "4. Test de création de facture..."
FACTURE_RESPONSE=$(curl -s -X POST $BASE_URL/factures \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $COMPTABLE_TOKEN" \
    -d '{
        "client_id": 1,
        "numero_facture": "FAC-2024-TEST",
        "montant": 1000.00,
        "date_facture": "2024-01-15",
        "description": "Test facture",
        "statut": "en_attente"
    }')

echo "Facture créée: $FACTURE_RESPONSE"

# Test de pointage
echo "5. Test de pointage..."
POINTAGE_RESPONSE=$(curl -s -X POST $BASE_URL/pointages/arrivee \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TECHNICIEN_TOKEN" \
    -d '{
        "lieu": "Bureau test",
        "commentaire": "Test pointage"
    }')

echo "Pointage créé: $POINTAGE_RESPONSE"

# Test de rapport
echo "6. Test de rapport..."
REPORT_RESPONSE=$(curl -s -X GET "$BASE_URL/dashboard?date_debut=2024-01-01&date_fin=2024-12-31" \
    -H "Authorization: Bearer $PATRON_TOKEN")

echo "Rapport généré: $REPORT_RESPONSE"

echo "=== Tests terminés ==="
```

Exécuter le script :
```bash
chmod +x test_complete_api.sh
./test_complete_api.sh
```

---

## Tests de Performance

### 1. Test de Charge
```bash
# Test avec Apache Bench
ab -n 100 -c 10 -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/list-clients
```

### 2. Test de Concurrence
```bash
# Test de pointage simultané
for i in {1..10}; do
    curl -X POST http://localhost:8000/api/pointages/arrivee \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TECHNICIEN_TOKEN" \
        -d '{"lieu": "Bureau", "commentaire": "Test concurrent"}' &
done
wait
```

---

## Tests de Sécurité

### 1. Test d'Injection SQL
```bash
# Test avec des caractères spéciaux
curl -X POST http://localhost:8000/api/clients \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "nom": "Test\"; DROP TABLE clients; --",
        "email": "test@example.com",
        "contact": "0123456789",
        "adresse": "123 Test Street",
        "nom_entreprise": "Test Company",
        "situation_geographique": "Test City",
        "statut": "en_attente"
    }'
```

### 2. Test de Validation des Tokens
```bash
# Test avec token invalide
curl -X GET http://localhost:8000/api/list-clients \
    -H "Authorization: Bearer token_invalide"
# Doit retourner 401 Unauthorized
```

---

## Tests de Récupération d'Erreur

### 1. Test de Ressources Inexistantes
```bash
# Test avec ID inexistant
curl -X GET http://localhost:8000/api/clients/999 \
    -H "Authorization: Bearer $TOKEN"
# Doit retourner 404 Not Found
```

### 2. Test de Données Manquantes
```bash
# Test avec données manquantes
curl -X POST http://localhost:8000/api/clients \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{}'
# Doit retourner des erreurs de validation
```

---

## Tests de Workflow Complet

### 1. Workflow Client
```bash
# 1. Créer un client (Commercial)
# 2. Approuver le client (Patron)
# 3. Créer une facture (Comptable)
# 4. Créer un paiement (Comptable)
# 5. Valider le paiement (Comptable)
# 6. Générer un rapport (Patron)
```

### 2. Workflow Pointage
```bash
# 1. Pointer l'arrivée (Technicien)
# 2. Pointer le départ (Technicien)
# 3. Valider les pointages (RH)
# 4. Générer un rapport RH (Patron)
```

---

## Tests de Données de Test

### 1. Création de Données de Test
```bash
# Créer plusieurs clients
# Créer plusieurs factures
# Créer plusieurs pointages
# Créer plusieurs fournisseurs
# Créer plusieurs bons de commande
```

### 2. Tests de Filtrage
```bash
# Tester les filtres par date
# Tester les filtres par statut
# Tester les filtres par utilisateur
# Tester les filtres par montant
```

---

## Tests de Rapports

### 1. Tests de Performance des Rapports
```bash
# Tester les rapports avec beaucoup de données
# Tester les rapports sur de longues périodes
# Tester les rapports avec des filtres complexes
```

### 2. Tests de Cohérence des Rapports
```bash
# Vérifier que les totaux correspondent
# Vérifier que les pourcentages sont corrects
# Vérifier que les dates sont cohérentes
```

---

## Tests de Déploiement

### 1. Tests en Production
```bash
# Tester avec des données réelles
# Tester avec des utilisateurs réels
# Tester avec des volumes de données réels
```

### 2. Tests de Monitoring
```bash
# Vérifier les logs
# Vérifier les performances
# Vérifier les erreurs
```

---

## Conclusion

Ces tests couvrent tous les aspects de l'API CRM :
- Authentification et autorisation
- CRUD de toutes les entités
- Workflows métier
- Rapports et analyses
- Sécurité et performance
- Validation des données
- Gestion des erreurs

L'API est maintenant prête pour la production avec un système de rôles robuste et des fonctionnalités complètes pour la gestion CRM.
