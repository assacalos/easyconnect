# Tests des Fonctionnalités Avancées - Application CRM

## Configuration des Tests

### 1. Prérequis
```bash
# Installation des dépendances
composer install

# Configuration de la base de données
php artisan migrate
php artisan db:seed

# Configuration Pusher (optionnel pour les tests)
# Ajouter dans .env :
# BROADCAST_DRIVER=pusher
# PUSHER_APP_ID=your_app_id
# PUSHER_APP_KEY=your_app_key
# PUSHER_APP_SECRET=your_app_secret
# PUSHER_APP_CLUSTER=mt1

# Démarrage du serveur
php artisan serve
```

### 2. Utilisateurs de Test
- **RH** : rh@example.com / password
- **Technicien** : technicien@example.com / password
- **Patron** : patron@example.com / password
- **Admin** : admin@example.com / password

---

## Tests des Congés

### 1. Connexion et Test de Base
```bash
# Connexion en tant que Technicien
TECH_TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "technicien@example.com", "password": "password"}' | jq -r '.token')

echo "Token Technicien: $TECH_TOKEN"
```

### 2. Créer un Congé
```bash
# Test de création de congé normal
curl -X POST http://localhost:8000/api/my-conges \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TECH_TOKEN" \
  -d '{
    "type_conge": "annuel",
    "date_debut": "2024-02-01",
    "date_fin": "2024-02-05",
    "motif": "Vacances familiales",
    "urgent": false
  }'

# Réponse attendue :
# {
#   "success": true,
#   "conge": {
#     "id": 1,
#     "commercialId": 5,
#     "type_conge": "annuel",
#     "date_debut": "2024-02-01",
#     "date_fin": "2024-02-05",
#     "nombre_jours": 5,
#     "motif": "Vacances familiales",
#     "status": "en_attente",
#     "urgent": false
#   },
#   "message": "Demande de congé créée avec succès"
# }
```

### 3. Test de Conflit de Dates
```bash
# Test de création de congé avec conflit
curl -X POST http://localhost:8000/api/my-conges \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TECH_TOKEN" \
  -d '{
    "type_conge": "annuel",
    "date_debut": "2024-02-01",
    "date_fin": "2024-02-05",
    "motif": "Test de conflit",
    "urgent": false
  }'

# Réponse attendue :
# {
#   "success": false,
#   "message": "Vous avez déjà un congé sur cette période"
# }
```

### 4. Test de Congé Urgent
```bash
# Test de création de congé urgent
curl -X POST http://localhost:8000/api/my-conges \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TECH_TOKEN" \
  -d '{
    "type_conge": "maladie",
    "date_debut": "2024-01-25",
    "date_fin": "2024-01-26",
    "motif": "Maladie familiale urgente",
    "urgent": true
  }'
```

### 5. Liste des Congés
```bash
# Liste des congés du technicien
curl -X GET http://localhost:8000/api/my-conges \
  -H "Authorization: Bearer $TECH_TOKEN"

# Liste avec filtres
curl -X GET "http://localhost:8000/api/my-conges?statut=en_attente" \
  -H "Authorization: Bearer $TECH_TOKEN"

curl -X GET "http://localhost:8000/api/my-conges?type_conge=annuel" \
  -H "Authorization: Bearer $TECH_TOKEN"
```

### 6. Modifier un Congé
```bash
# Modifier un congé (si en attente)
curl -X PUT http://localhost:8000/api/my-conges/1 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TECH_TOKEN" \
  -d '{
    "type_conge": "annuel",
    "date_debut": "2024-02-01",
    "date_fin": "2024-02-07",
    "motif": "Vacances familiales prolongées",
    "urgent": false
  }'
```

### 7. Test RH - Approuver un Congé
```bash
# Connexion RH
RH_TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "rh@example.com", "password": "password"}' | jq -r '.token')

# Liste des congés pour RH
curl -X GET http://localhost:8000/api/conges \
  -H "Authorization: Bearer $RH_TOKEN"

# Approuver un congé
curl -X POST http://localhost:8000/api/conges/1/approve \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $RH_TOKEN" \
  -d '{
    "commentaire_rh": "Congé approuvé, bonnes vacances !"
  }'
```

### 8. Test RH - Rejeter un Congé
```bash
# Rejeter un congé
curl -X POST http://localhost:8000/api/conges/2/reject \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $RH_TOKEN" \
  -d '{
    "raison_rejet": "Période de forte activité, merci de reporter"
  }'
```

### 9. Statistiques des Congés
```bash
# Statistiques générales
curl -X GET http://localhost:8000/api/conges-statistics \
  -H "Authorization: Bearer $RH_TOKEN"

# Statistiques avec période
curl -X GET "http://localhost:8000/api/conges-statistics?date_debut=2024-01-01&date_fin=2024-12-31" \
  -H "Authorization: Bearer $RH_TOKEN"

# Statistiques pour un utilisateur
curl -X GET "http://localhost:8000/api/conges-statistics?user_id=5" \
  -H "Authorization: Bearer $RH_TOKEN"
```

---

## Tests des Évaluations

### 1. Connexion RH
```bash
# Connexion RH
RH_TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "rh@example.com", "password": "password"}' | jq -r '.token')

echo "Token RH: $RH_TOKEN"
```

### 2. Créer une Évaluation
```bash
# Test de création d'évaluation
curl -X POST http://localhost:8000/api/evaluations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $RH_TOKEN" \
  -d '{
    "user_id": 5,
    "type_evaluation": "annuelle",
    "date_evaluation": "2024-01-15",
    "periode_debut": "2023-01-01",
    "periode_fin": "2023-12-31",
    "criteres_evaluation": {
      "performance": 16,
      "ponctualite": 18,
      "collaboration": 15,
      "initiative": 17,
      "qualite": 16
    },
    "note_globale": 16.4,
    "commentaires_evaluateur": "Excellent travail cette année, très satisfait des performances",
    "objectifs_futurs": "Continuer sur cette lancée, prendre plus d'\''initiatives",
    "confidentiel": true
  }'

# Réponse attendue :
# {
#   "success": true,
#   "evaluation": {
#     "id": 1,
#     "user_id": 5,
#     "evaluateur_id": 4,
#     "type_evaluation": "annuelle",
#     "date_evaluation": "2024-01-15",
#     "note_globale": 16.4,
#     "statut": "en_cours"
#   },
#   "message": "Évaluation créée avec succès"
# }
```

### 3. Liste des Évaluations
```bash
# Liste des évaluations pour RH
curl -X GET http://localhost:8000/api/evaluations \
  -H "Authorization: Bearer $RH_TOKEN"

# Liste avec filtres
curl -X GET "http://localhost:8000/api/evaluations?statut=en_cours" \
  -H "Authorization: Bearer $RH_TOKEN"

curl -X GET "http://localhost:8000/api/evaluations?type_evaluation=annuelle" \
  -H "Authorization: Bearer $RH_TOKEN"
```

### 4. Test Technicien - Voir ses Évaluations
```bash
# Connexion Technicien
TECH_TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "technicien@example.com", "password": "password"}' | jq -r '.token')

# Liste des évaluations du technicien
curl -X GET http://localhost:8000/api/my-evaluations \
  -H "Authorization: Bearer $TECH_TOKEN"

# Détails d'une évaluation
curl -X GET http://localhost:8000/api/my-evaluations/1 \
  -H "Authorization: Bearer $TECH_TOKEN"
```

### 5. Test Technicien - Ajouter Commentaires
```bash
# Ajouter des commentaires d'employé
curl -X POST http://localhost:8000/api/my-evaluations/1/employee-comments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TECH_TOKEN" \
  -d '{
    "commentaires_employe": "Merci pour cette évaluation positive. Je vais continuer à donner le meilleur de moi-même."
  }'
```

### 6. Test Technicien - Signer l'Évaluation
```bash
# Signer l'évaluation (employé)
curl -X POST http://localhost:8000/api/my-evaluations/1/sign-employee \
  -H "Authorization: Bearer $TECH_TOKEN"
```

### 7. Test RH - Signer l'Évaluation
```bash
# Signer l'évaluation (évaluateur)
curl -X POST http://localhost:8000/api/evaluations/1/sign-evaluator \
  -H "Authorization: Bearer $RH_TOKEN"
```

### 8. Finaliser une Évaluation
```bash
# Finaliser une évaluation
curl -X POST http://localhost:8000/api/evaluations/1/finalize \
  -H "Authorization: Bearer $RH_TOKEN"
```

### 9. Statistiques des Évaluations
```bash
# Statistiques générales
curl -X GET http://localhost:8000/api/evaluations-statistics \
  -H "Authorization: Bearer $RH_TOKEN"

# Statistiques avec période
curl -X GET "http://localhost:8000/api/evaluations-statistics?date_debut=2024-01-01&date_fin=2024-12-31" \
  -H "Authorization: Bearer $RH_TOKEN"

# Statistiques pour un utilisateur
curl -X GET "http://localhost:8000/api/evaluations-statistics?user_id=5" \
  -H "Authorization: Bearer $RH_TOKEN"
```

---

## Tests des Notifications

### 1. Connexion et Test de Base
```bash
# Connexion en tant que Technicien
TECH_TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "technicien@example.com", "password": "password"}' | jq -r '.token')

echo "Token Technicien: $TECH_TOKEN"
```

### 2. Liste des Notifications
```bash
# Liste des notifications
curl -X GET http://localhost:8000/api/notifications \
  -H "Authorization: Bearer $TECH_TOKEN"

# Liste avec filtres
curl -X GET "http://localhost:8000/api/notifications?status=non_lue" \
  -H "Authorization: Bearer $TECH_TOKEN"

curl -X GET "http://localhost:8000/api/notifications?type=pointage" \
  -H "Authorization: Bearer $TECH_TOKEN"

curl -X GET "http://localhost:8000/api/notifications?priorite=urgente" \
  -H "Authorization: Bearer $TECH_TOKEN"
```

### 3. Notifications Non Lues
```bash
# Notifications non lues
curl -X GET http://localhost:8000/api/notifications/unread \
  -H "Authorization: Bearer $TECH_TOKEN"

# Réponse attendue :
# {
#   "success": true,
#   "notifications": [...],
#   "count": 3,
#   "message": "Notifications non lues récupérées avec succès"
# }
```

### 4. Notifications Urgentes
```bash
# Notifications urgentes
curl -X GET http://localhost:8000/api/notifications/urgent \
  -H "Authorization: Bearer $TECH_TOKEN"
```

### 5. Marquer comme Lue
```bash
# Marquer une notification comme lue
curl -X POST http://localhost:8000/api/notifications/1/mark-read \
  -H "Authorization: Bearer $TECH_TOKEN"

# Marquer toutes comme lues
curl -X POST http://localhost:8000/api/notifications/mark-all-read \
  -H "Authorization: Bearer $TECH_TOKEN"
```

### 6. Archiver une Notification
```bash
# Archiver une notification
curl -X POST http://localhost:8000/api/notifications/1/archive \
  -H "Authorization: Bearer $TECH_TOKEN"

# Archiver toutes les notifications lues
curl -X POST http://localhost:8000/api/notifications/archive-all-read \
  -H "Authorization: Bearer $TECH_TOKEN"
```

### 7. Statistiques des Notifications
```bash
# Statistiques des notifications
curl -X GET http://localhost:8000/api/notifications-statistics \
  -H "Authorization: Bearer $TECH_TOKEN"

# Réponse attendue :
# {
#   "success": true,
#   "statistiques": {
#     "total": 15,
#     "non_lues": 3,
#     "lues": 10,
#     "archivees": 2,
#     "urgentes": 1,
#     "recentes": 8,
#     "par_type": [...],
#     "par_priorite": [...]
#   },
#   "message": "Statistiques des notifications récupérées avec succès"
# }
```

### 8. Test Admin - Créer une Notification
```bash
# Connexion Admin
ADMIN_TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@example.com", "password": "password"}' | jq -r '.token')

# Créer une notification
curl -X POST http://localhost:8000/api/notifications \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "user_id": 5,
    "type": "systeme",
    "titre": "Test de notification",
    "message": "Ceci est un test de notification système",
    "data": {
      "test": true,
      "timestamp": "2024-01-20T10:00:00Z"
    },
    "priorite": "normale",
    "canal": "app"
  }'
```

### 9. Test Admin - Nettoyage
```bash
# Nettoyer les notifications expirées
curl -X POST http://localhost:8000/api/notifications/cleanup \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Supprimer les notifications archivées
curl -X DELETE http://localhost:8000/api/notifications/destroy-archived \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

---

## Tests de Workflow Complet

### 1. Workflow Congé Complet
```bash
#!/bin/bash

echo "=== Test du Workflow Congé Complet ==="

# 1. Connexion Technicien
TECH_TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "technicien@example.com", "password": "password"}' | jq -r '.token')

echo "1. Technicien connecté"

# 2. Créer un congé
echo "2. Création d'un congé..."
curl -X POST http://localhost:8000/api/my-conges \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TECH_TOKEN" \
  -d '{
    "type_conge": "annuel",
    "date_debut": "2024-03-01",
    "date_fin": "2024-03-05",
    "motif": "Vacances de printemps",
    "urgent": false
  }'

# 3. Connexion RH
RH_TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "rh@example.com", "password": "password"}' | jq -r '.token')

echo "3. RH connecté"

# 4. Voir les congés en attente
echo "4. Liste des congés en attente..."
curl -X GET "http://localhost:8000/api/conges?statut=en_attente" \
  -H "Authorization: Bearer $RH_TOKEN"

# 5. Approuver le congé
echo "5. Approbation du congé..."
curl -X POST http://localhost:8000/api/conges/1/approve \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $RH_TOKEN" \
  -d '{
    "commentaire_rh": "Congé approuvé, bonnes vacances !"
  }'

# 6. Vérifier les notifications du technicien
echo "6. Vérification des notifications..."
curl -X GET http://localhost:8000/api/notifications/unread \
  -H "Authorization: Bearer $TECH_TOKEN"

echo "=== Workflow Congé Terminé ==="
```

### 2. Workflow Évaluation Complet
```bash
#!/bin/bash

echo "=== Test du Workflow Évaluation Complet ==="

# 1. Connexion RH
RH_TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "rh@example.com", "password": "password"}' | jq -r '.token')

echo "1. RH connecté"

# 2. Créer une évaluation
echo "2. Création d'une évaluation..."
curl -X POST http://localhost:8000/api/evaluations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $RH_TOKEN" \
  -d '{
    "user_id": 5,
    "type_evaluation": "trimestrielle",
    "date_evaluation": "2024-01-20",
    "periode_debut": "2023-10-01",
    "periode_fin": "2023-12-31",
    "criteres_evaluation": {
      "performance": 15,
      "ponctualite": 17,
      "collaboration": 16
    },
    "note_globale": 16.0,
    "commentaires_evaluateur": "Très bon trimestre, continuez ainsi !",
    "objectifs_futurs": "Améliorer encore la collaboration",
    "confidentiel": true
  }'

# 3. Connexion Technicien
TECH_TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "technicien@example.com", "password": "password"}' | jq -r '.token')

echo "3. Technicien connecté"

# 4. Voir l'évaluation
echo "4. Consultation de l'évaluation..."
curl -X GET http://localhost:8000/api/my-evaluations/1 \
  -H "Authorization: Bearer $TECH_TOKEN"

# 5. Ajouter des commentaires
echo "5. Ajout de commentaires..."
curl -X POST http://localhost:8000/api/my-evaluations/1/employee-comments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TECH_TOKEN" \
  -d '{
    "commentaires_employe": "Merci pour cette évaluation positive. Je vais continuer à progresser."
  }'

# 6. Signer l'évaluation
echo "6. Signature de l'évaluation..."
curl -X POST http://localhost:8000/api/my-evaluations/1/sign-employee \
  -H "Authorization: Bearer $TECH_TOKEN"

# 7. RH signe l'évaluation
echo "7. Signature RH..."
curl -X POST http://localhost:8000/api/evaluations/1/sign-evaluator \
  -H "Authorization: Bearer $RH_TOKEN"

echo "=== Workflow Évaluation Terminé ==="
```

### 3. Workflow Notifications Complet
```bash
#!/bin/bash

echo "=== Test du Workflow Notifications Complet ==="

# 1. Connexion Technicien
TECH_TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "technicien@example.com", "password": "password"}' | jq -r '.token')

echo "1. Technicien connecté"

# 2. Voir les notifications
echo "2. Liste des notifications..."
curl -X GET http://localhost:8000/api/notifications \
  -H "Authorization: Bearer $TECH_TOKEN"

# 3. Voir les notifications non lues
echo "3. Notifications non lues..."
curl -X GET http://localhost:8000/api/notifications/unread \
  -H "Authorization: Bearer $TECH_TOKEN"

# 4. Marquer une notification comme lue
echo "4. Marquage comme lue..."
curl -X POST http://localhost:8000/api/notifications/1/mark-read \
  -H "Authorization: Bearer $TECH_TOKEN"

# 5. Voir les statistiques
echo "5. Statistiques des notifications..."
curl -X GET http://localhost:8000/api/notifications-statistics \
  -H "Authorization: Bearer $TECH_TOKEN"

# 6. Archiver une notification
echo "6. Archivage d'une notification..."
curl -X POST http://localhost:8000/api/notifications/1/archive \
  -H "Authorization: Bearer $TECH_TOKEN"

echo "=== Workflow Notifications Terminé ==="
```

---

## Tests de Performance

### 1. Test de Charge - Notifications
```bash
# Test avec Apache Bench pour les notifications
ab -n 100 -c 10 -H "Authorization: Bearer $TECH_TOKEN" http://localhost:8000/api/notifications

# Test avec Apache Bench pour les congés
ab -n 100 -c 10 -H "Authorization: Bearer $TECH_TOKEN" http://localhost:8000/api/my-conges

# Test avec Apache Bench pour les évaluations
ab -n 100 -c 10 -H "Authorization: Bearer $RH_TOKEN" http://localhost:8000/api/evaluations
```

### 2. Test de Concurrence
```bash
# Test de création simultanée de congés
for i in {1..10}; do
    curl -X POST http://localhost:8000/api/my-conges \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $TECH_TOKEN" \
      -d "{
        \"type_conge\": \"annuel\",
        \"date_debut\": \"2024-0$((i+1))-01\",
        \"date_fin\": \"2024-0$((i+1))-05\",
        \"motif\": \"Test de concurrence $i\",
        \"urgent\": false
      }" &
done
wait
```

---

## Tests de Validation et Sécurité

### 1. Test d'Accès Refusé
```bash
# Technicien essayant d'accéder aux congés d'autres utilisateurs
curl -X GET http://localhost:8000/api/conges \
  -H "Authorization: Bearer $TECH_TOKEN"
# Doit retourner 403 Forbidden

# Technicien essayant d'approuver un congé
curl -X POST http://localhost:8000/api/conges/1/approve \
  -H "Authorization: Bearer $TECH_TOKEN"
# Doit retourner 403 Forbidden
```

### 2. Test de Validation des Données
```bash
# Test avec données invalides pour créer un congé
curl -X POST http://localhost:8000/api/my-conges \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TECH_TOKEN" \
  -d '{
    "type_conge": "type_invalide",
    "date_debut": "date_invalide",
    "date_fin": "2024-01-01",
    "motif": ""
  }'
# Doit retourner des erreurs de validation

# Test avec données invalides pour créer une évaluation
curl -X POST http://localhost:8000/api/evaluations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $RH_TOKEN" \
  -d '{
    "user_id": 999,
    "type_evaluation": "type_invalide",
    "note_globale": 25
  }'
# Doit retourner des erreurs de validation
```

### 3. Test de Ressources Inexistantes
```bash
# Test avec ID de congé inexistant
curl -X GET http://localhost:8000/api/my-conges/999 \
  -H "Authorization: Bearer $TECH_TOKEN"
# Doit retourner 404 Not Found

# Test avec ID d'évaluation inexistant
curl -X GET http://localhost:8000/api/my-evaluations/999 \
  -H "Authorization: Bearer $TECH_TOKEN"
# Doit retourner 404 Not Found
```

---

## Script de Test Automatisé Complet

Créer un fichier `test_advanced_features.sh` :

```bash
#!/bin/bash

BASE_URL="http://localhost:8000/api"
echo "=== Test des Fonctionnalités Avancées ==="

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
TECH_TOKEN=$(get_token "technicien@example.com" "password")
RH_TOKEN=$(get_token "rh@example.com" "password")
ADMIN_TOKEN=$(get_token "admin@example.com" "password")

echo "Tokens obtenus avec succès"

# Test des congés
echo "2. Test des congés..."
curl -s -X POST $BASE_URL/my-conges \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TECH_TOKEN" \
  -d '{
    "type_conge": "annuel",
    "date_debut": "2024-02-01",
    "date_fin": "2024-02-05",
    "motif": "Test de congé",
    "urgent": false
  }' | jq '.success'

curl -s -X GET $BASE_URL/my-conges \
  -H "Authorization: Bearer $TECH_TOKEN" | jq '.success'

# Test des évaluations
echo "3. Test des évaluations..."
curl -s -X POST $BASE_URL/evaluations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $RH_TOKEN" \
  -d '{
    "user_id": 5,
    "type_evaluation": "annuelle",
    "date_evaluation": "2024-01-15",
    "periode_debut": "2023-01-01",
    "periode_fin": "2023-12-31",
    "criteres_evaluation": {"performance": 16},
    "note_globale": 16.0,
    "commentaires_evaluateur": "Test d'\''évaluation"
  }' | jq '.success'

curl -s -X GET $BASE_URL/my-evaluations \
  -H "Authorization: Bearer $TECH_TOKEN" | jq '.success'

# Test des notifications
echo "4. Test des notifications..."
curl -s -X GET $BASE_URL/notifications \
  -H "Authorization: Bearer $TECH_TOKEN" | jq '.success'

curl -s -X GET $BASE_URL/notifications/unread \
  -H "Authorization: Bearer $TECH_TOKEN" | jq '.success'

# Test des statistiques
echo "5. Test des statistiques..."
curl -s -X GET $BASE_URL/notifications-statistics \
  -H "Authorization: Bearer $TECH_TOKEN" | jq '.success'

curl -s -X GET $BASE_URL/conges-statistics \
  -H "Authorization: Bearer $RH_TOKEN" | jq '.success'

curl -s -X GET $BASE_URL/evaluations-statistics \
  -H "Authorization: Bearer $RH_TOKEN" | jq '.success'

echo "=== Tests terminés ==="
```

Exécuter le script :
```bash
chmod +x test_advanced_features.sh
./test_advanced_features.sh
```

---

## Tests de Données de Test

### 1. Création de Données de Test
```bash
# Créer plusieurs congés
for i in {1..5}; do
    curl -X POST http://localhost:8000/api/my-conges \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $TECH_TOKEN" \
      -d "{
        \"type_conge\": \"annuel\",
        \"date_debut\": \"2024-0$((i+1))-01\",
        \"date_fin\": \"2024-0$((i+1))-05\",
        \"motif\": \"Test de congé $i\",
        \"urgent\": false
      }"
done

# Créer plusieurs évaluations
for i in {1..3}; do
    curl -X POST http://localhost:8000/api/evaluations \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $RH_TOKEN" \
      -d "{
        \"user_id\": 5,
        \"type_evaluation\": \"trimestrielle\",
        \"date_evaluation\": \"2024-0$((i+1))-15\",
        \"periode_debut\": \"2023-0$((i+1))-01\",
        \"periode_fin\": \"2023-0$((i+1))-31\",
        \"criteres_evaluation\": {\"performance\": $((15+i))},
        \"note_globale\": $((15+i)).0,
        \"commentaires_evaluateur\": \"Test d'\''évaluation $i\"
      }"
done
```

### 2. Tests de Filtrage
```bash
# Tester les filtres par statut
curl -X GET "http://localhost:8000/api/my-conges?statut=en_attente" \
  -H "Authorization: Bearer $TECH_TOKEN"

curl -X GET "http://localhost:8000/api/evaluations?statut=en_cours" \
  -H "Authorization: Bearer $RH_TOKEN"

curl -X GET "http://localhost:8000/api/notifications?statut=non_lue" \
  -H "Authorization: Bearer $TECH_TOKEN"

# Tester les filtres par type
curl -X GET "http://localhost:8000/api/my-conges?type_conge=annuel" \
  -H "Authorization: Bearer $TECH_TOKEN"

curl -X GET "http://localhost:8000/api/evaluations?type_evaluation=annuelle" \
  -H "Authorization: Bearer $RH_TOKEN"

curl -X GET "http://localhost:8000/api/notifications?type=pointage" \
  -H "Authorization: Bearer $TECH_TOKEN"

# Tester les filtres par priorité
curl -X GET "http://localhost:8000/api/notifications?priorite=urgente" \
  -H "Authorization: Bearer $TECH_TOKEN"
```

---

## Tests de Rapports

### 1. Tests de Performance des Rapports
```bash
# Tester les rapports avec beaucoup de données
curl -X GET "http://localhost:8000/api/conges-statistics?date_debut=2023-01-01&date_fin=2024-12-31" \
  -H "Authorization: Bearer $RH_TOKEN"

curl -X GET "http://localhost:8000/api/evaluations-statistics?date_debut=2023-01-01&date_fin=2024-12-31" \
  -H "Authorization: Bearer $RH_TOKEN"

curl -X GET "http://localhost:8000/api/notifications-statistics" \
  -H "Authorization: Bearer $TECH_TOKEN"
```

### 2. Tests de Cohérence des Rapports
```bash
# Vérifier que les totaux correspondent
curl -X GET http://localhost:8000/api/conges-statistics \
  -H "Authorization: Bearer $RH_TOKEN" | jq '.statistiques'

curl -X GET http://localhost:8000/api/evaluations-statistics \
  -H "Authorization: Bearer $RH_TOKEN" | jq '.statistiques'

curl -X GET http://localhost:8000/api/notifications-statistics \
  -H "Authorization: Bearer $TECH_TOKEN" | jq '.statistiques'
```

---

## Conclusion

Ces tests couvrent tous les aspects des nouvelles fonctionnalités avancées :

- **Gestion des congés** avec workflow complet
- **Évaluations des employés** avec système de signature
- **Notifications en temps réel** avec gestion complète
- **Sécurité et validation** des données
- **Performance et concurrence**
- **Workflows complets** par rôle
- **Tests de charge** et de performance
- **Validation des permissions** et de la sécurité

L'API est maintenant complète avec des fonctionnalités avancées robustes pour la gestion des ressources humaines, l'évaluation des employés, et les notifications en temps réel.
