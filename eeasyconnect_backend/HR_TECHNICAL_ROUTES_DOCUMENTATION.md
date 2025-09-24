# Documentation des Routes RH et Techniques - Application CRM

## Vue d'ensemble
Cette documentation présente les nouvelles routes ajoutées pour les fonctionnalités RH et Techniques dans l'application CRM.

---

## Routes RH (Ressources Humaines)

### Contrôleur : HRController
**Accessible par : RH (role: 4) et Admin (role: 1)**

#### 1. Gestion des Employés

##### Liste des employés
```http
GET /api/hr/employees
```
**Paramètres de requête :**
- `role` (optionnel) : Filtrer par rôle
- `search` (optionnel) : Recherche par nom, prénom ou email

**Réponse :**
```json
{
  "success": true,
  "employees": [...],
  "message": "Liste des employés récupérée avec succès"
}
```

##### Détails d'un employé
```http
GET /api/hr/employees/{id}
```
**Réponse :**
```json
{
  "success": true,
  "employee": {...},
  "statistiques": {
    "total_pointages": 150,
    "pointages_valides": 140,
    "pointages_en_attente": 8,
    "pointages_rejetes": 2,
    "dernier_pointage": {...},
    "pointages_ce_mois": 20
  },
  "message": "Détails de l'employé récupérés avec succès"
}
```

##### Créer un employé
```http
POST /api/hr/employees
```
**Corps de la requête :**
```json
{
  "nom": "Dupont",
  "prenom": "Jean",
  "email": "jean.dupont@example.com",
  "password": "motdepasse123",
  "role": 5
}
```

##### Modifier un employé
```http
PUT /api/hr/employees/{id}
```
**Corps de la requête :**
```json
{
  "nom": "Dupont",
  "prenom": "Jean",
  "email": "jean.dupont@example.com",
  "role": 5
}
```

##### Désactiver un employé
```http
POST /api/hr/employees/{id}/deactivate
```

#### 2. Rapports RH

##### Rapport de présence
```http
GET /api/hr/presence-report
```
**Paramètres de requête :**
- `date_debut` (optionnel) : Date de début
- `date_fin` (optionnel) : Date de fin
- `user_id` (optionnel) : ID de l'employé

**Réponse :**
```json
{
  "success": true,
  "rapport": {
    "periode": {
      "debut": "2024-01-01",
      "fin": "2024-01-31"
    },
    "total_pointages": 500,
    "pointages_valides": 450,
    "pointages_en_attente": 40,
    "pointages_rejetes": 10,
    "par_employe": {...},
    "par_type": {...}
  },
  "message": "Rapport de présence généré avec succès"
}
```

##### Statistiques RH
```http
GET /api/hr/statistics
```
**Réponse :**
```json
{
  "success": true,
  "statistiques": {
    "total_employees": 25,
    "employees_by_role": [...],
    "pointages_aujourdhui": 15,
    "pointages_valides_aujourdhui": 12,
    "taux_presence_aujourdhui": 80.0
  },
  "message": "Statistiques RH récupérées avec succès"
}
```

#### 3. Fonctionnalités Futures

##### Gestion des congés
```http
GET /api/hr/leave-management
```
*À implémenter selon les besoins métier*

##### Évaluations des employés
```http
GET /api/hr/employee-evaluations
```
*À implémenter selon les besoins métier*

---

## Routes Techniques

### Contrôleur : TechnicalController
**Accessible par : Technicien (role: 5) et Admin (role: 1)**

#### 1. Tableau de Bord Technique

##### Dashboard technique
```http
GET /api/technical/dashboard
```
**Paramètres de requête :**
- `date_debut` (optionnel) : Date de début
- `date_fin` (optionnel) : Date de fin

**Réponse :**
```json
{
  "success": true,
  "dashboard": {
    "periode": {
      "debut": "2024-01-01",
      "fin": "2024-01-31"
    },
    "pointages_aujourdhui": [...],
    "statistiques": {
      "total_pointages": 50,
      "pointages_valides": 45,
      "pointages_en_attente": 3,
      "pointages_rejetes": 2,
      "pointages_aujourdhui": 2,
      "derniere_activite": {...},
      "taux_presence": 90.0
    }
  },
  "message": "Tableau de bord technique récupéré avec succès"
}
```

#### 2. Historique et Statistiques

##### Historique des pointages
```http
GET /api/technical/pointage-history
```
**Paramètres de requête :**
- `date_debut` (optionnel) : Date de début
- `date_fin` (optionnel) : Date de fin
- `statut` (optionnel) : Filtrer par statut
- `type_pointage` (optionnel) : Filtrer par type

**Réponse :**
```json
{
  "success": true,
  "pointages": [...],
  "message": "Historique des pointages récupéré avec succès"
}
```

##### Statistiques personnelles
```http
GET /api/technical/personal-statistics
```
**Paramètres de requête :**
- `date_debut` (optionnel) : Date de début
- `date_fin` (optionnel) : Date de fin

**Réponse :**
```json
{
  "success": true,
  "statistiques": {
    "periode": {
      "debut": "2024-01-01",
      "fin": "2024-01-31"
    },
    "total_pointages": 50,
    "pointages_valides": 45,
    "pointages_en_attente": 3,
    "pointages_rejetes": 2,
    "heures_travaillees": 160,
    "taux_presence": 90.0,
    "pointages_par_jour": {...},
    "pointages_par_type": {...},
    "moyenne_par_jour": 1.6
  },
  "message": "Statistiques personnelles récupérées avec succès"
}
```

#### 3. Pointage et Gestion

##### Pointage rapide
```http
POST /api/technical/quick-pointage
```
**Corps de la requête :**
```json
{
  "type": "arrivee",
  "lieu": "Bureau principal",
  "commentaire": "Arrivée normale"
}
```

**Types disponibles :**
- `arrivee` : Pointage d'arrivée
- `depart` : Pointage de départ
- `pause_debut` : Début de pause
- `pause_fin` : Fin de pause

##### Gestion des pauses
```http
GET /api/technical/pause-management
```
**Réponse :**
```json
{
  "success": true,
  "pauses": [...],
  "message": "Gestion des pauses récupérée avec succès"
}
```

#### 4. Rapports Techniques

##### Rapports techniques
```http
GET /api/technical/reports
```
**Paramètres de requête :**
- `date_debut` (optionnel) : Date de début
- `date_fin` (optionnel) : Date de fin

**Réponse :**
```json
{
  "success": true,
  "rapport": {
    "periode": {
      "debut": "2024-01-01",
      "fin": "2024-01-31"
    },
    "total_pointages": 50,
    "pointages_valides": 45,
    "pointages_en_attente": 3,
    "pointages_rejetes": 2,
    "heures_travaillees": 160,
    "par_type": {...},
    "par_lieu": {...},
    "evolution_hebdomadaire": [...]
  },
  "message": "Rapport technique généré avec succès"
}
```

---

## Routes Patron et Admin

### Accès aux Fonctionnalités RH et Techniques
**Accessible par : Patron (role: 6) et Admin (role: 1)**

#### Routes RH pour le Patron
- `GET /api/hr/employees` - Liste des employés
- `GET /api/hr/employees/{id}` - Détails d'un employé
- `GET /api/hr/presence-report` - Rapport de présence
- `GET /api/hr/statistics` - Statistiques RH

#### Routes Techniques pour le Patron
- `GET /api/technical/dashboard` - Dashboard technique
- `GET /api/technical/reports` - Rapports techniques

---

## Exemples d'Utilisation

### 1. Connexion en tant que RH
```bash
# Connexion
TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "rh@example.com", "password": "password"}' | jq -r '.token')

# Liste des employés
curl -X GET http://localhost:8000/api/hr/employees \
  -H "Authorization: Bearer $TOKEN"

# Rapport de présence
curl -X GET "http://localhost:8000/api/hr/presence-report?date_debut=2024-01-01&date_fin=2024-01-31" \
  -H "Authorization: Bearer $TOKEN"
```

### 2. Connexion en tant que Technicien
```bash
# Connexion
TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "technicien@example.com", "password": "password"}' | jq -r '.token')

# Dashboard technique
curl -X GET http://localhost:8000/api/technical/dashboard \
  -H "Authorization: Bearer $TOKEN"

# Pointage rapide
curl -X POST http://localhost:8000/api/technical/quick-pointage \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "type": "arrivee",
    "lieu": "Bureau principal",
    "commentaire": "Arrivée normale"
  }'

# Statistiques personnelles
curl -X GET "http://localhost:8000/api/technical/personal-statistics?date_debut=2024-01-01&date_fin=2024-01-31" \
  -H "Authorization: Bearer $TOKEN"
```

### 3. Connexion en tant que Patron
```bash
# Connexion
TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "patron@example.com", "password": "password"}' | jq -r '.token')

# Statistiques RH
curl -X GET http://localhost:8000/api/hr/statistics \
  -H "Authorization: Bearer $TOKEN"

# Dashboard technique
curl -X GET http://localhost:8000/api/technical/dashboard \
  -H "Authorization: Bearer $TOKEN"
```

---

## Permissions par Rôle

### RH (Role: 4)
- ✅ Gestion complète des employés
- ✅ Validation des pointages
- ✅ Rapports RH détaillés
- ✅ Statistiques de présence
- ❌ Accès aux fonctionnalités techniques

### Technicien (Role: 5)
- ✅ Pointage personnel
- ✅ Dashboard technique
- ✅ Statistiques personnelles
- ✅ Rapports techniques
- ❌ Gestion des autres employés

### Patron (Role: 6)
- ✅ Accès à tous les rapports RH
- ✅ Accès aux dashboards techniques
- ✅ Statistiques globales
- ✅ Validation des pointages

### Admin (Role: 1)
- ✅ Accès complet à toutes les fonctionnalités
- ✅ Gestion des employés
- ✅ Tous les rapports
- ✅ Toutes les statistiques

---

## Fonctionnalités Avancées

### 1. Calcul des Heures Travaillées
- Calcul automatique basé sur les pointages d'arrivée et de départ
- Prise en compte des pauses
- Statistiques hebdomadaires et mensuelles

### 2. Gestion des Pauses
- Pointage des débuts et fins de pause
- Historique des pauses
- Statistiques de temps de pause

### 3. Rapports Personnalisés
- Filtrage par période
- Filtrage par employé
- Filtrage par type de pointage
- Export des données

### 4. Tableaux de Bord
- Vue d'ensemble des activités
- Indicateurs de performance
- Alertes et notifications
- Tendances et évolutions

---

## Sécurité et Validation

### Authentification
- Toutes les routes nécessitent un token valide
- Vérification du rôle utilisateur
- Contrôle d'accès granulaire

### Validation des Données
- Validation des paramètres d'entrée
- Contrôles de cohérence métier
- Messages d'erreur explicites

### Permissions
- RH : Accès aux données de tous les employés
- Technicien : Accès uniquement à ses propres données
- Patron : Accès en lecture à toutes les données
- Admin : Accès complet

---

## Tests et Exemples

### Script de Test Complet
```bash
#!/bin/bash

BASE_URL="http://localhost:8000/api"

echo "=== Test des Routes RH et Techniques ==="

# Test RH
echo "1. Test des fonctionnalités RH..."
RH_TOKEN=$(curl -s -X POST $BASE_URL/login \
  -H "Content-Type: application/json" \
  -d '{"email": "rh@example.com", "password": "password"}' | jq -r '.token')

curl -X GET $BASE_URL/hr/employees \
  -H "Authorization: Bearer $RH_TOKEN"

curl -X GET $BASE_URL/hr/statistics \
  -H "Authorization: Bearer $RH_TOKEN"

# Test Technique
echo "2. Test des fonctionnalités techniques..."
TECH_TOKEN=$(curl -s -X POST $BASE_URL/login \
  -H "Content-Type: application/json" \
  -d '{"email": "technicien@example.com", "password": "password"}' | jq -r '.token')

curl -X GET $BASE_URL/technical/dashboard \
  -H "Authorization: Bearer $TECH_TOKEN"

curl -X POST $BASE_URL/technical/quick-pointage \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TECH_TOKEN" \
  -d '{"type": "arrivee", "lieu": "Bureau", "commentaire": "Test"}'

echo "=== Tests terminés ==="
```

---

## Conclusion

Les nouvelles routes RH et Techniques offrent :

1. **Gestion complète des employés** pour les RH
2. **Pointage et suivi personnel** pour les techniciens
3. **Rapports et statistiques détaillés** pour tous les rôles
4. **Tableaux de bord personnalisés** selon le rôle
5. **Sécurité et permissions** appropriées

L'API est maintenant complète avec des fonctionnalités RH et Techniques robustes pour la gestion des ressources humaines et le suivi des activités techniques.
