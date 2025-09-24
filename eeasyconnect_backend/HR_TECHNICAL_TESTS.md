# Tests des Routes RH et Techniques - Application CRM

## Configuration des Tests

### 1. Prérequis
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
- **RH** : rh@example.com / password
- **Technicien** : technicien@example.com / password
- **Patron** : patron@example.com / password
- **Admin** : admin@example.com / password

---

## Tests des Fonctionnalités RH

### 1. Connexion RH
```bash
# Connexion en tant que RH
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "rh@example.com", "password": "password"}'

# Réponse attendue :
# {
#   "success": true,
#   "token": "1|abc123...",
#   "user": {
#     "id": 4,
#     "nom": "Brown",
#     "prenom": "Charlie",
#     "email": "rh@example.com",
#     "role": 4,
#     "role_name": "RH"
#   },
#   "message": "Connexion réussie"
# }
```

### 2. Gestion des Employés

#### Liste des employés
```bash
# Obtenir le token RH
RH_TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "rh@example.com", "password": "password"}' | jq -r '.token')

# Liste des employés
curl -X GET http://localhost:8000/api/hr/employees \
  -H "Authorization: Bearer $RH_TOKEN"

# Liste avec filtrage par rôle
curl -X GET "http://localhost:8000/api/hr/employees?role=5" \
  -H "Authorization: Bearer $RH_TOKEN"

# Liste avec recherche
curl -X GET "http://localhost:8000/api/hr/employees?search=technicien" \
  -H "Authorization: Bearer $RH_TOKEN"
```

#### Détails d'un employé
```bash
# Détails d'un employé
curl -X GET http://localhost:8000/api/hr/employees/5 \
  -H "Authorization: Bearer $RH_TOKEN"

# Réponse attendue :
# {
#   "success": true,
#   "employee": {...},
#   "statistiques": {
#     "total_pointages": 150,
#     "pointages_valides": 140,
#     "pointages_en_attente": 8,
#     "pointages_rejetes": 2,
#     "dernier_pointage": {...},
#     "pointages_ce_mois": 20
#   },
#   "message": "Détails de l'employé récupérés avec succès"
# }
```

#### Créer un employé
```bash
# Créer un nouvel employé
curl -X POST http://localhost:8000/api/hr/employees \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $RH_TOKEN" \
  -d '{
    "nom": "Nouveau",
    "prenom": "Employé",
    "email": "nouveau.employe@example.com",
    "password": "motdepasse123",
    "role": 5
  }'
```

#### Modifier un employé
```bash
# Modifier un employé
curl -X PUT http://localhost:8000/api/hr/employees/6 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $RH_TOKEN" \
  -d '{
    "nom": "Nouveau",
    "prenom": "Employé Modifié",
    "email": "nouveau.employe@example.com",
    "role": 5
  }'
```

### 3. Rapports RH

#### Rapport de présence
```bash
# Rapport de présence général
curl -X GET "http://localhost:8000/api/hr/presence-report?date_debut=2024-01-01&date_fin=2024-01-31" \
  -H "Authorization: Bearer $RH_TOKEN"

# Rapport de présence pour un employé spécifique
curl -X GET "http://localhost:8000/api/hr/presence-report?date_debut=2024-01-01&date_fin=2024-01-31&user_id=5" \
  -H "Authorization: Bearer $RH_TOKEN"
```

#### Statistiques RH
```bash
# Statistiques RH globales
curl -X GET http://localhost:8000/api/hr/statistics \
  -H "Authorization: Bearer $RH_TOKEN"

# Réponse attendue :
# {
#   "success": true,
#   "statistiques": {
#     "total_employees": 25,
#     "employees_by_role": [
#       {"role": "Commercial", "count": 10},
#       {"role": "Comptable", "count": 5},
#       {"role": "RH", "count": 3},
#       {"role": "Technicien", "count": 5},
#       {"role": "Patron", "count": 2}
#     ],
#     "pointages_aujourdhui": 15,
#     "pointages_valides_aujourdhui": 12,
#     "taux_presence_aujourdhui": 80.0
#   },
#   "message": "Statistiques RH récupérées avec succès"
# }
```

---

## Tests des Fonctionnalités Techniques

### 1. Connexion Technicien
```bash
# Connexion en tant que Technicien
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "technicien@example.com", "password": "password"}'

# Réponse attendue :
# {
#   "success": true,
#   "token": "1|def456...",
#   "user": {
#     "id": 5,
#     "nom": "Davis",
#     "prenom": "Junior",
#     "email": "technicien@example.com",
#     "role": 5,
#     "role_name": "Technicien"
#   },
#   "message": "Connexion réussie"
# }
```

### 2. Tableau de Bord Technique

#### Dashboard technique
```bash
# Obtenir le token Technicien
TECH_TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "technicien@example.com", "password": "password"}' | jq -r '.token')

# Dashboard technique
curl -X GET http://localhost:8000/api/technical/dashboard \
  -H "Authorization: Bearer $TECH_TOKEN"

# Dashboard avec période spécifique
curl -X GET "http://localhost:8000/api/technical/dashboard?date_debut=2024-01-01&date_fin=2024-01-31" \
  -H "Authorization: Bearer $TECH_TOKEN"
```

### 3. Pointage et Gestion

#### Pointage rapide
```bash
# Pointage d'arrivée
curl -X POST http://localhost:8000/api/technical/quick-pointage \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TECH_TOKEN" \
  -d '{
    "type": "arrivee",
    "lieu": "Bureau principal",
    "commentaire": "Arrivée normale"
  }'

# Pointage de départ
curl -X POST http://localhost:8000/api/technical/quick-pointage \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TECH_TOKEN" \
  -d '{
    "type": "depart",
    "commentaire": "Fin de journée"
  }'

# Début de pause
curl -X POST http://localhost:8000/api/technical/quick-pointage \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TECH_TOKEN" \
  -d '{
    "type": "pause_debut",
    "commentaire": "Pause déjeuner"
  }'

# Fin de pause
curl -X POST http://localhost:8000/api/technical/quick-pointage \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TECH_TOKEN" \
  -d '{
    "type": "pause_fin",
    "commentaire": "Fin de pause"
  }'
```

#### Gestion des pauses
```bash
# Gestion des pauses
curl -X GET http://localhost:8000/api/technical/pause-management \
  -H "Authorization: Bearer $TECH_TOKEN"
```

### 4. Historique et Statistiques

#### Historique des pointages
```bash
# Historique complet
curl -X GET http://localhost:8000/api/technical/pointage-history \
  -H "Authorization: Bearer $TECH_TOKEN"

# Historique avec filtres
curl -X GET "http://localhost:8000/api/technical/pointage-history?date_debut=2024-01-01&date_fin=2024-01-31&statut=valide" \
  -H "Authorization: Bearer $TECH_TOKEN"
```

#### Statistiques personnelles
```bash
# Statistiques personnelles
curl -X GET http://localhost:8000/api/technical/personal-statistics \
  -H "Authorization: Bearer $TECH_TOKEN"

# Statistiques avec période spécifique
curl -X GET "http://localhost:8000/api/technical/personal-statistics?date_debut=2024-01-01&date_fin=2024-01-31" \
  -H "Authorization: Bearer $TECH_TOKEN"
```

#### Rapports techniques
```bash
# Rapports techniques
curl -X GET http://localhost:8000/api/technical/reports \
  -H "Authorization: Bearer $TECH_TOKEN"

# Rapports avec période spécifique
curl -X GET "http://localhost:8000/api/technical/reports?date_debut=2024-01-01&date_fin=2024-01-31" \
  -H "Authorization: Bearer $TECH_TOKEN"
```

---

## Tests des Fonctionnalités Patron

### 1. Connexion Patron
```bash
# Connexion en tant que Patron
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "patron@example.com", "password": "password"}'
```

### 2. Accès aux Fonctionnalités RH
```bash
# Obtenir le token Patron
PATRON_TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "patron@example.com", "password": "password"}' | jq -r '.token')

# Liste des employés (Patron)
curl -X GET http://localhost:8000/api/hr/employees \
  -H "Authorization: Bearer $PATRON_TOKEN"

# Statistiques RH (Patron)
curl -X GET http://localhost:8000/api/hr/statistics \
  -H "Authorization: Bearer $PATRON_TOKEN"

# Rapport de présence (Patron)
curl -X GET "http://localhost:8000/api/hr/presence-report?date_debut=2024-01-01&date_fin=2024-01-31" \
  -H "Authorization: Bearer $PATRON_TOKEN"
```

### 3. Accès aux Fonctionnalités Techniques
```bash
# Dashboard technique (Patron)
curl -X GET http://localhost:8000/api/technical/dashboard \
  -H "Authorization: Bearer $PATRON_TOKEN"

# Rapports techniques (Patron)
curl -X GET http://localhost:8000/api/technical/reports \
  -H "Authorization: Bearer $PATRON_TOKEN"
```

---

## Tests de Validation et Sécurité

### 1. Test d'Accès Refusé
```bash
# Technicien essayant d'accéder aux fonctionnalités RH
curl -X GET http://localhost:8000/api/hr/employees \
  -H "Authorization: Bearer $TECH_TOKEN"
# Doit retourner 403 Forbidden

# Commercial essayant d'accéder aux fonctionnalités techniques
COMMERCIAL_TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "commercial@example.com", "password": "password"}' | jq -r '.token')

curl -X GET http://localhost:8000/api/technical/dashboard \
  -H "Authorization: Bearer $COMMERCIAL_TOKEN"
# Doit retourner 403 Forbidden
```

### 2. Test de Validation des Données
```bash
# Test avec données invalides pour créer un employé
curl -X POST http://localhost:8000/api/hr/employees \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $RH_TOKEN" \
  -d '{
    "nom": "",
    "email": "email-invalide",
    "role": 99
  }'
# Doit retourner des erreurs de validation

# Test avec type de pointage invalide
curl -X POST http://localhost:8000/api/technical/quick-pointage \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TECH_TOKEN" \
  -d '{
    "type": "type_invalide",
    "commentaire": "Test"
  }'
# Doit retourner une erreur de validation
```

### 3. Test de Ressources Inexistantes
```bash
# Test avec ID d'employé inexistant
curl -X GET http://localhost:8000/api/hr/employees/999 \
  -H "Authorization: Bearer $RH_TOKEN"
# Doit retourner 404 Not Found
```

---

## Tests de Performance

### 1. Test de Charge
```bash
# Test avec Apache Bench pour les routes RH
ab -n 100 -c 10 -H "Authorization: Bearer $RH_TOKEN" http://localhost:8000/api/hr/employees

# Test avec Apache Bench pour les routes techniques
ab -n 100 -c 10 -H "Authorization: Bearer $TECH_TOKEN" http://localhost:8000/api/technical/dashboard
```

### 2. Test de Concurrence
```bash
# Test de pointage simultané
for i in {1..10}; do
    curl -X POST http://localhost:8000/api/technical/quick-pointage \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $TECH_TOKEN" \
      -d '{"type": "arrivee", "lieu": "Bureau", "commentaire": "Test concurrent"}' &
done
wait
```

---

## Script de Test Automatisé

Créer un fichier `test_hr_technical.sh` :

```bash
#!/bin/bash

BASE_URL="http://localhost:8000/api"
echo "=== Test des Routes RH et Techniques ==="

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
RH_TOKEN=$(get_token "rh@example.com" "password")
TECH_TOKEN=$(get_token "technicien@example.com" "password")
PATRON_TOKEN=$(get_token "patron@example.com" "password")

echo "Tokens obtenus avec succès"

# Test des fonctionnalités RH
echo "2. Test des fonctionnalités RH..."
curl -s -X GET $BASE_URL/hr/employees \
  -H "Authorization: Bearer $RH_TOKEN" | jq '.success'

curl -s -X GET $BASE_URL/hr/statistics \
  -H "Authorization: Bearer $RH_TOKEN" | jq '.success'

# Test des fonctionnalités techniques
echo "3. Test des fonctionnalités techniques..."
curl -s -X GET $BASE_URL/technical/dashboard \
  -H "Authorization: Bearer $TECH_TOKEN" | jq '.success'

curl -s -X POST $BASE_URL/technical/quick-pointage \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TECH_TOKEN" \
  -d '{"type": "arrivee", "lieu": "Bureau", "commentaire": "Test"}' | jq '.success'

# Test des fonctionnalités Patron
echo "4. Test des fonctionnalités Patron..."
curl -s -X GET $BASE_URL/hr/statistics \
  -H "Authorization: Bearer $PATRON_TOKEN" | jq '.success'

curl -s -X GET $BASE_URL/technical/dashboard \
  -H "Authorization: Bearer $PATRON_TOKEN" | jq '.success'

echo "=== Tests terminés ==="
```

Exécuter le script :
```bash
chmod +x test_hr_technical.sh
./test_hr_technical.sh
```

---

## Tests de Workflow Complet

### 1. Workflow RH Complet
```bash
# 1. Connexion RH
# 2. Liste des employés
# 3. Création d'un nouvel employé
# 4. Modification de l'employé
# 5. Génération d'un rapport de présence
# 6. Consultation des statistiques RH
```

### 2. Workflow Technique Complet
```bash
# 1. Connexion Technicien
# 2. Pointage d'arrivée
# 3. Pointage de pause
# 4. Pointage de fin de pause
# 5. Pointage de départ
# 6. Consultation des statistiques personnelles
# 7. Génération d'un rapport technique
```

### 3. Workflow Patron Complet
```bash
# 1. Connexion Patron
# 2. Consultation des statistiques RH
# 3. Consultation du dashboard technique
# 4. Génération de rapports
# 5. Validation des pointages
```

---

## Tests de Données de Test

### 1. Création de Données de Test
```bash
# Créer plusieurs employés
# Créer plusieurs pointages
# Créer des données sur différentes périodes
# Tester avec des volumes de données importants
```

### 2. Tests de Filtrage
```bash
# Tester les filtres par date
# Tester les filtres par statut
# Tester les filtres par type
# Tester les filtres par employé
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

## Conclusion

Ces tests couvrent tous les aspects des nouvelles routes RH et Techniques :

- **Authentification et autorisation** par rôle
- **CRUD des employés** pour les RH
- **Pointage et suivi personnel** pour les techniciens
- **Rapports et statistiques** détaillés
- **Sécurité et validation** des données
- **Performance et concurrence**
- **Workflows complets** par rôle

L'API est maintenant complète avec des fonctionnalités RH et Techniques robustes pour la gestion des ressources humaines et le suivi des activités techniques.
