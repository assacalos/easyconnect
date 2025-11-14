# Documentation Backend - Gestion des Employés

## Vue d'ensemble

Ce document décrit toutes les spécifications nécessaires pour implémenter le module de gestion des employés dans le backend. Le système permet de créer, gérer, afficher et suivre les employés de l'entreprise.

---

## Table des matières

1. [Endpoints Principaux](#endpoints-principaux)
2. [Création d'un Employé](#création-dun-employé)
3. [Récupération des Employés](#récupération-des-employés)
4. [Mise à Jour d'un Employé](#mise-à-jour-dun-employé)
5. [Suppression d'un Employé](#suppression-dun-employé)
6. [Statistiques et Rapports](#statistiques-et-rapports)
7. [Données de Référence](#données-de-référence)
8. [Gestion des Documents](#gestion-des-documents)
9. [Gestion des Congés](#gestion-des-congés)
10. [Gestion des Performances](#gestion-des-performances)
11. [Permissions et Rôles](#permissions-et-rôles)
12. [Exemples de Requêtes](#exemples-de-requêtes)

---

## Endpoints Principaux

### Base URL
Tous les endpoints commencent par : `/api/employees`

### Authentification
Tous les endpoints nécessitent une authentification Bearer token dans les headers :
```
Authorization: Bearer {token}
Content-Type: application/json
```

---

## Création d'un Employé

### Endpoint
**POST** `/api/employees`

### Description
Crée un nouvel employé dans le système. L'employé est créé avec le statut `"active"` par défaut.

### Champs Obligatoires (Required)

#### 1. `first_name` (Prénom)
- **Type** : `string`
- **Longueur max** : 255 caractères
- **Exemple** : `"Jean"`
- **Description** : Prénom de l'employé

#### 2. `last_name` (Nom)
- **Type** : `string`
- **Longueur max** : 255 caractères
- **Exemple** : `"Dupont"`
- **Description** : Nom de famille de l'employé

#### 3. `email` (Email)
- **Type** : `string` (email)
- **Longueur max** : 255 caractères
- **Exemple** : `"jean.dupont@example.com"`
- **Description** : Adresse email de l'employé (doit être unique)
- **Validation** : Format email valide

### Champs Optionnels

#### 4. `phone` (Téléphone)
- **Type** : `string` (nullable)
- **Longueur max** : 50 caractères
- **Exemple** : `"+237 6 12 34 56 78"`
- **Description** : Numéro de téléphone de l'employé

#### 5. `address` (Adresse)
- **Type** : `string` (nullable, text)
- **Exemple** : `"123 Rue de la Paix, Yaoundé, Cameroun"`
- **Description** : Adresse complète de l'employé

#### 6. `birth_date` (Date de naissance)
- **Type** : `date` ou `datetime` (nullable, format ISO 8601)
- **Format accepté** :
  - `"1990-05-15"` (date simple)
  - `"1990-05-15T00:00:00Z"` (datetime ISO 8601)
- **Exemple** : `"1990-05-15T00:00:00Z"`
- **Description** : Date de naissance de l'employé

#### 7. `gender` (Genre)
- **Type** : `string` (nullable, enum)
- **Valeurs acceptées** :
  - `"male"` (Homme)
  - `"female"` (Femme)
  - `"other"` (Autre)
- **Exemple** : `"male"`
- **Description** : Genre de l'employé

#### 8. `marital_status` (Statut matrimonial)
- **Type** : `string` (nullable, enum)
- **Valeurs acceptées** :
  - `"single"` (Célibataire)
  - `"married"` (Marié(e))
  - `"divorced"` (Divorcé(e))
  - `"widowed"` (Veuf/Veuve)
- **Exemple** : `"married"`
- **Description** : Statut matrimonial de l'employé

#### 9. `nationality` (Nationalité)
- **Type** : `string` (nullable)
- **Longueur max** : 100 caractères
- **Exemple** : `"cameroon"` ou `"Camerounais(e)"`
- **Description** : Nationalité de l'employé

#### 10. `id_number` (Numéro d'identité)
- **Type** : `string` (nullable)
- **Longueur max** : 50 caractères
- **Exemple** : `"123456789012"`
- **Description** : Numéro de carte d'identité ou passeport

#### 11. `social_security_number` (Numéro de sécurité sociale)
- **Type** : `string` (nullable)
- **Longueur max** : 50 caractères
- **Exemple** : `"SS123456789"`
- **Description** : Numéro de sécurité sociale

#### 12. `position` (Poste)
- **Type** : `string` (nullable)
- **Longueur max** : 255 caractères
- **Exemple** : `"Développeur Full Stack"`
- **Description** : Poste occupé par l'employé

#### 13. `department` (Département)
- **Type** : `string` (nullable)
- **Longueur max** : 255 caractères
- **Exemple** : `"Technique"` ou `"Ressources Humaines"`
- **Description** : Département de l'employé

#### 14. `manager` (Manager)
- **Type** : `string` (nullable)
- **Longueur max** : 255 caractères
- **Exemple** : `"Marie Martin"`
- **Description** : Nom du manager direct

#### 15. `hire_date` (Date d'embauche)
- **Type** : `date` ou `datetime` (nullable, format ISO 8601)
- **Format accepté** :
  - `"2024-01-15"` (date simple)
  - `"2024-01-15T00:00:00Z"` (datetime ISO 8601)
- **Exemple** : `"2024-01-15T00:00:00Z"`
- **Description** : Date d'embauche de l'employé

#### 16. `contract_start_date` (Date de début du contrat)
- **Type** : `date` ou `datetime` (nullable, format ISO 8601)
- **Exemple** : `"2024-01-15T00:00:00Z"`
- **Description** : Date de début du contrat

#### 17. `contract_end_date` (Date de fin du contrat)
- **Type** : `date` ou `datetime` (nullable, format ISO 8601)
- **Exemple** : `"2025-01-15T00:00:00Z"`
- **Description** : Date de fin du contrat (pour CDD)
- **Contrainte** : Si fourni, doit être après `contract_start_date`

#### 18. `contract_type` (Type de contrat)
- **Type** : `string` (nullable, enum)
- **Valeurs acceptées** :
  - `"permanent"` (CDI)
  - `"temporary"` (CDD)
  - `"internship"` (Stage)
  - `"consultant"` (Consultant)
- **Exemple** : `"permanent"`
- **Description** : Type de contrat de travail

#### 19. `salary` (Salaire)
- **Type** : `decimal` ou `double` (nullable)
- **Exemple** : `500000.00`
- **Description** : Salaire brut de l'employé

#### 20. `currency` (Devise)
- **Type** : `string` (nullable)
- **Valeurs acceptées** :
  - `"fcfa"` (FCFA)
  - `"eur"` (EUR)
  - `"usd"` (USD)
- **Défaut** : `"fcfa"`
- **Exemple** : `"fcfa"`
- **Description** : Devise du salaire

#### 21. `work_schedule` (Horaires de travail)
- **Type** : `string` (nullable, enum)
- **Valeurs acceptées** :
  - `"full_time"` (Temps plein)
  - `"part_time"` (Temps partiel)
  - `"flexible"` (Flexible)
  - `"shift"` (Par équipes)
- **Exemple** : `"full_time"`
- **Description** : Type d'horaires de travail

#### 22. `profile_picture` (Photo de profil)
- **Type** : `string` (nullable, URL ou chemin de fichier)
- **Exemple** : `"/storage/employees/photos/123.jpg"`
- **Description** : Chemin vers la photo de profil

#### 23. `notes` (Notes)
- **Type** : `string` (nullable, text)
- **Exemple** : `"Employé très motivé, excellent travail d'équipe"`
- **Description** : Notes internes sur l'employé

### Champs Automatiques (Non requis - gérés par le backend)

Ces champs sont automatiquement remplis par le backend et ne doivent **PAS** être envoyés :

- `id` → Généré automatiquement
- `status` → Automatiquement défini à `"active"` (actif)
- `created_at` → Timestamp de création automatique
- `updated_at` → Timestamp de mise à jour automatique
- `created_by` → Automatiquement rempli avec l'ID de l'utilisateur authentifié

---

## Exemple de Requête JSON Complète

```json
{
  "first_name": "Jean",
  "last_name": "Dupont",
  "email": "jean.dupont@example.com",
  "phone": "+237 6 12 34 56 78",
  "address": "123 Rue de la Paix, Yaoundé, Cameroun",
  "birth_date": "1990-05-15T00:00:00Z",
  "gender": "male",
  "marital_status": "married",
  "nationality": "cameroon",
  "id_number": "123456789012",
  "social_security_number": "SS123456789",
  "position": "Développeur Full Stack",
  "department": "Technique",
  "manager": "Marie Martin",
  "hire_date": "2024-01-15T00:00:00Z",
  "contract_start_date": "2024-01-15T00:00:00Z",
  "contract_end_date": null,
  "contract_type": "permanent",
  "salary": 500000.00,
  "currency": "fcfa",
  "work_schedule": "full_time",
  "notes": "Employé très motivé, excellent travail d'équipe"
}
```

---

## Réponse de Succès (201 Created)

```json
{
  "success": true,
  "message": "Employé créé avec succès",
  "data": {
    "id": 1,
    "first_name": "Jean",
    "last_name": "Dupont",
    "email": "jean.dupont@example.com",
    "phone": "+237 6 12 34 56 78",
    "address": "123 Rue de la Paix, Yaoundé, Cameroun",
    "birth_date": "1990-05-15T00:00:00Z",
    "gender": "male",
    "marital_status": "married",
    "nationality": "cameroon",
    "id_number": "123456789012",
    "social_security_number": "SS123456789",
    "position": "Développeur Full Stack",
    "department": "Technique",
    "manager": "Marie Martin",
    "hire_date": "2024-01-15T00:00:00Z",
    "contract_start_date": "2024-01-15T00:00:00Z",
    "contract_end_date": null,
    "contract_type": "permanent",
    "salary": 500000.00,
    "currency": "fcfa",
    "work_schedule": "full_time",
    "status": "active",
    "profile_picture": null,
    "notes": "Employé très motivé, excellent travail d'équipe",
    "created_at": "2024-01-15T10:00:00Z",
    "updated_at": "2024-01-15T10:00:00Z",
    "documents": [],
    "leaves": [],
    "performances": []
  }
}
```

---

## Erreurs de Validation Possibles

### Erreur 422 (Validation Failed)

```json
{
  "success": false,
  "message": "The given data was invalid.",
  "errors": {
    "first_name": ["The first name field is required."],
    "last_name": ["The last name field is required."],
    "email": [
      "The email field is required.",
      "The email has already been taken.",
      "The email must be a valid email address."
    ],
    "contract_end_date": ["The contract end date must be a date after contract start date."],
    "gender": ["The selected gender is invalid."],
    "contract_type": ["The selected contract type is invalid."]
  }
}
```

### Erreurs Communes

1. **Champ obligatoire manquant** : `first_name`, `last_name`, `email` sont obligatoires
2. **Email déjà utilisé** : L'email doit être unique dans le système
3. **Format email invalide** : L'email doit respecter le format standard
4. **Date de fin avant date de début** : `contract_end_date` doit être après `contract_start_date`
5. **Valeur enum invalide** : `gender`, `marital_status`, `contract_type`, `work_schedule`, `currency` doivent correspondre aux valeurs acceptées

---

## Récupération des Employés

### Endpoint
**GET** `/api/employees`

### Description
Récupère la liste des employés avec possibilité de filtrage, recherche et pagination.

### Paramètres de Requête (Query Parameters)

- `search` (string, optionnel) : Recherche dans le nom, prénom, email, poste
- `department` (string, optionnel) : Filtrer par département
- `position` (string, optionnel) : Filtrer par poste
- `status` (string, optionnel) : Filtrer par statut (`active`, `inactive`, `terminated`, `on_leave`)
- `page` (integer, optionnel) : Numéro de page pour la pagination (défaut: 1)
- `limit` (integer, optionnel) : Nombre d'éléments par page (défaut: 15)

### Exemples de Requêtes

```
GET /api/employees
GET /api/employees?status=active
GET /api/employees?department=Technique&position=Développeur
GET /api/employees?search=Jean&page=1&limit=20
```

### Réponse (200 OK) - Format Simple

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "first_name": "Jean",
      "last_name": "Dupont",
      "email": "jean.dupont@example.com",
      "position": "Développeur Full Stack",
      "department": "Technique",
      "status": "active",
      "hire_date": "2024-01-15T00:00:00Z",
      "salary": 500000.00,
      "currency": "fcfa",
      "created_at": "2024-01-15T10:00:00Z",
      "updated_at": "2024-01-15T10:00:00Z"
    }
  ]
}
```

### Réponse (200 OK) - Format Paginé

```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "per_page": 15,
    "total": 45,
    "last_page": 3,
    "from": 1,
    "to": 15,
    "data": [
      {
        "id": 1,
        "first_name": "Jean",
        "last_name": "Dupont",
        "email": "jean.dupont@example.com",
        "position": "Développeur Full Stack",
        "department": "Technique",
        "status": "active",
        "hire_date": "2024-01-15T00:00:00Z",
        "salary": 500000.00,
        "currency": "fcfa",
        "created_at": "2024-01-15T10:00:00Z",
        "updated_at": "2024-01-15T10:00:00Z"
      }
    ]
  }
}
```

**Note** : Le backend peut retourner soit une liste directe, soit un objet paginé. Le frontend gère les deux formats.

---

## Récupération d'un Employé par ID

### Endpoint
**GET** `/api/employees/{id}`

### Description
Récupère les détails complets d'un employé, incluant ses documents, congés et performances.

### Réponse (200 OK)

```json
{
  "success": true,
  "data": {
    "id": 1,
    "first_name": "Jean",
    "last_name": "Dupont",
    "email": "jean.dupont@example.com",
    "phone": "+237 6 12 34 56 78",
    "address": "123 Rue de la Paix, Yaoundé, Cameroun",
    "birth_date": "1990-05-15T00:00:00Z",
    "gender": "male",
    "marital_status": "married",
    "nationality": "cameroon",
    "id_number": "123456789012",
    "social_security_number": "SS123456789",
    "position": "Développeur Full Stack",
    "department": "Technique",
    "manager": "Marie Martin",
    "hire_date": "2024-01-15T00:00:00Z",
    "contract_start_date": "2024-01-15T00:00:00Z",
    "contract_end_date": null,
    "contract_type": "permanent",
    "salary": 500000.00,
    "currency": "fcfa",
    "work_schedule": "full_time",
    "status": "active",
    "profile_picture": null,
    "notes": "Employé très motivé, excellent travail d'équipe",
    "created_at": "2024-01-15T10:00:00Z",
    "updated_at": "2024-01-15T10:00:00Z",
    "documents": [
      {
        "id": 1,
        "employee_id": 1,
        "name": "Contrat de travail",
        "type": "contract",
        "description": "Contrat CDI",
        "file_path": "/storage/documents/contract_1.pdf",
        "file_size": "2.5 MB",
        "expiry_date": null,
        "is_required": true,
        "created_at": "2024-01-15T10:00:00Z",
        "created_by": "Admin"
      }
    ],
    "leaves": [],
    "performances": []
  }
}
```

---

## Mise à Jour d'un Employé

### Endpoint
**PUT** `/api/employees/{id}`

### Description
Met à jour les informations d'un employé existant.

### Champs
Tous les champs de la création sont disponibles pour la mise à jour, avec en plus :

- `status` (string, optionnel) : Statut de l'employé (`active`, `inactive`, `terminated`, `on_leave`)

### Exemple de Requête

```json
{
  "first_name": "Jean",
  "last_name": "Dupont",
  "email": "jean.dupont@example.com",
  "position": "Développeur Senior",
  "department": "Technique",
  "salary": 600000.00,
  "status": "active"
}
```

### Réponse (200 OK)

```json
{
  "success": true,
  "message": "Employé mis à jour avec succès",
  "data": {
    "id": 1,
    "first_name": "Jean",
    "last_name": "Dupont",
    "email": "jean.dupont@example.com",
    "position": "Développeur Senior",
    "department": "Technique",
    "salary": 600000.00,
    "status": "active",
    "updated_at": "2024-01-20T14:30:00Z"
  }
}
```

---

## Suppression d'un Employé

### Endpoint
**DELETE** `/api/employees/{id}`

### Description
Supprime un employé du système. **Attention** : Cette action est irréversible.

### Réponse (200 OK)

```json
{
  "success": true,
  "message": "Employé supprimé avec succès"
}
```

---

## Statistiques et Rapports

### Endpoint
**GET** `/api/employees/stats`

### Description
Récupère les statistiques globales sur les employés.

### Réponse (200 OK)

```json
{
  "success": true,
  "data": {
    "total_employees": 45,
    "active_employees": 38,
    "inactive_employees": 2,
    "on_leave_employees": 3,
    "terminated_employees": 2,
    "new_hires_this_month": 5,
    "departures_this_month": 1,
    "average_salary": 450000.00,
    "departments": [
      "Technique",
      "Ressources Humaines",
      "Commercial",
      "Comptabilité",
      "Direction"
    ],
    "positions": [
      "Développeur",
      "Chef de projet",
      "Manager RH",
      "Comptable",
      "Directeur"
    ],
    "expiring_contracts": 3,
    "expiring_documents": 5
  }
}
```

---

## Données de Référence

### Récupérer les Départements

**GET** `/api/employees/departments`

**Réponse (200 OK)** :
```json
{
  "success": true,
  "data": [
    "Technique",
    "Ressources Humaines",
    "Commercial",
    "Comptabilité",
    "Direction",
    "Support"
  ]
}
```

### Récupérer les Postes

**GET** `/api/employees/positions`

**Réponse (200 OK)** :
```json
{
  "success": true,
  "data": [
    "Développeur",
    "Chef de projet",
    "Manager RH",
    "Comptable",
    "Directeur",
    "Commercial"
  ]
}
```

---

## Gestion des Documents

### Ajouter un Document

**POST** `/api/employees/{employeeId}/documents`

**Body** :
```json
{
  "name": "Contrat de travail",
  "type": "contract",
  "description": "Contrat CDI signé",
  "file_path": "/storage/documents/contract_1.pdf",
  "expiry_date": null,
  "is_required": true
}
```

**Types de documents acceptés** :
- `contract` (Contrat)
- `id_card` (Carte d'identité)
- `passport` (Passeport)
- `diploma` (Diplôme)
- `certificate` (Certificat)
- `medical` (Certificat médical)
- `other` (Autre)

**Réponse (201 Created)** :
```json
{
  "success": true,
  "message": "Document ajouté avec succès",
  "data": {
    "id": 1,
    "employee_id": 1,
    "name": "Contrat de travail",
    "type": "contract",
    "description": "Contrat CDI signé",
    "file_path": "/storage/documents/contract_1.pdf",
    "file_size": "2.5 MB",
    "expiry_date": null,
    "is_required": true,
    "created_at": "2024-01-15T10:00:00Z",
    "created_by": "Admin"
  }
}
```

---

## Gestion des Congés

### Ajouter un Congé

**POST** `/api/employees/{employeeId}/leaves`

**Body** :
```json
{
  "type": "annual",
  "start_date": "2024-06-01T00:00:00Z",
  "end_date": "2024-06-15T00:00:00Z",
  "reason": "Vacances annuelles"
}
```

**Types de congés acceptés** :
- `annual` (Congé annuel)
- `sick` (Congé maladie)
- `maternity` (Congé maternité)
- `paternity` (Congé paternité)
- `personal` (Congé personnel)
- `unpaid` (Congé sans solde)

**Réponse (201 Created)** :
```json
{
  "success": true,
  "message": "Congé ajouté avec succès",
  "data": {
    "id": 1,
    "employee_id": 1,
    "type": "annual",
    "start_date": "2024-06-01T00:00:00Z",
    "end_date": "2024-06-15T00:00:00Z",
    "total_days": 15,
    "reason": "Vacances annuelles",
    "status": "pending",
    "created_at": "2024-01-15T10:00:00Z"
  }
}
```

### Approuver un Congé

**POST** `/api/leaves/{leaveId}/approve`

**Body** :
```json
{
  "comments": "Approuvé, bonnes vacances !"
}
```

### Rejeter un Congé

**POST** `/api/leaves/{leaveId}/reject`

**Body** :
```json
{
  "reason": "Période de congés déjà saturée"
}
```

---

## Gestion des Performances

### Ajouter une Performance

**POST** `/api/employees/{employeeId}/performances`

**Body** :
```json
{
  "period": "Q1 2024",
  "rating": 4.5,
  "comments": "Excellent travail, très proactif",
  "goals": "Améliorer les compétences en leadership",
  "achievements": "Projet X livré avec succès",
  "areas_for_improvement": "Communication avec l'équipe"
}
```

**Réponse (201 Created)** :
```json
{
  "success": true,
  "message": "Performance ajoutée avec succès",
  "data": {
    "id": 1,
    "employee_id": 1,
    "period": "Q1 2024",
    "rating": 4.5,
    "comments": "Excellent travail, très proactif",
    "goals": "Améliorer les compétences en leadership",
    "achievements": "Projet X livré avec succès",
    "areas_for_improvement": "Communication avec l'équipe",
    "status": "draft",
    "created_at": "2024-01-15T10:00:00Z"
  }
}
```

---

## Recherche d'Employés

### Endpoint
**GET** `/api/employees/search?q={query}`

### Description
Recherche des employés par nom, prénom, email ou poste.

### Exemple
```
GET /api/employees/search?q=Jean
```

### Réponse (200 OK)

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "first_name": "Jean",
      "last_name": "Dupont",
      "email": "jean.dupont@example.com",
      "position": "Développeur Full Stack",
      "department": "Technique"
    }
  ]
}
```

---

## Statuts des Employés

### Statuts disponibles

1. **`active`** (Actif) : Employé actuellement en poste
2. **`inactive`** (Inactif) : Employé temporairement inactif
3. **`terminated`** (Terminé) : Employé dont le contrat est terminé
4. **`on_leave`** (En congé) : Employé actuellement en congé

### Transitions de statut

- Un employé peut passer de `active` à `inactive`, `on_leave` ou `terminated`
- Un employé `inactive` peut revenir à `active`
- Un employé `on_leave` peut revenir à `active` à la fin de son congé
- Un employé `terminated` ne peut plus changer de statut

---

## Permissions et Rôles

### Permissions Requises

- **`MANAGE_EMPLOYEES`** : Créer, modifier et supprimer des employés (RH, Admin)
- **`VIEW_EMPLOYEES`** : Voir la liste des employés (Tous les rôles)
- **`APPROVE_EMPLOYEES`** : Approuver/rejeter des employés (Patron, Admin)

### Matrice des Permissions

| Action | RH | Admin | Patron | Autres |
|--------|----|----|----|----|
| Voir la liste des employés | ✅ | ✅ | ✅ | ✅ |
| Créer un employé | ✅ | ✅ | ❌ | ❌ |
| Modifier un employé | ✅ | ✅ | ❌ | ❌ |
| Supprimer un employé | ✅ | ✅ | ❌ | ❌ |
| Approuver un employé | ❌ | ✅ | ✅ | ❌ |
| Rejeter un employé | ❌ | ✅ | ✅ | ❌ |
| Voir les statistiques | ✅ | ✅ | ✅ | ❌ |

---

## Structure de Base de Données Recommandée

### Table `employees`

```sql
CREATE TABLE employees (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(50) NULL,
    address TEXT NULL,
    birth_date DATE NULL,
    gender ENUM('male', 'female', 'other') NULL,
    marital_status ENUM('single', 'married', 'divorced', 'widowed') NULL,
    nationality VARCHAR(100) NULL,
    id_number VARCHAR(50) NULL,
    social_security_number VARCHAR(50) NULL,
    position VARCHAR(255) NULL,
    department VARCHAR(255) NULL,
    manager VARCHAR(255) NULL,
    hire_date DATE NULL,
    contract_start_date DATE NULL,
    contract_end_date DATE NULL,
    contract_type ENUM('permanent', 'temporary', 'internship', 'consultant') NULL,
    salary DECIMAL(10, 2) NULL,
    currency VARCHAR(10) DEFAULT 'fcfa',
    work_schedule ENUM('full_time', 'part_time', 'flexible', 'shift') NULL,
    status ENUM('active', 'inactive', 'terminated', 'on_leave') DEFAULT 'active',
    profile_picture VARCHAR(255) NULL,
    notes TEXT NULL,
    created_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_email (email),
    INDEX idx_department (department),
    INDEX idx_position (position),
    INDEX idx_status (status),
    INDEX idx_hire_date (hire_date)
);
```

### Table `employee_documents`

```sql
CREATE TABLE employee_documents (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    employee_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(255) NOT NULL,
    type ENUM('contract', 'id_card', 'passport', 'diploma', 'certificate', 'medical', 'other') NOT NULL,
    description TEXT NULL,
    file_path VARCHAR(255) NULL,
    file_size VARCHAR(50) NULL,
    expiry_date DATE NULL,
    is_required BOOLEAN DEFAULT FALSE,
    created_by VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    INDEX idx_employee_id (employee_id),
    INDEX idx_type (type),
    INDEX idx_expiry_date (expiry_date)
);
```

### Table `employee_leaves`

```sql
CREATE TABLE employee_leaves (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    employee_id BIGINT UNSIGNED NOT NULL,
    type ENUM('annual', 'sick', 'maternity', 'paternity', 'personal', 'unpaid') NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_days INT NOT NULL,
    reason TEXT NULL,
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    approved_by VARCHAR(255) NULL,
    approved_at TIMESTAMP NULL,
    rejection_reason TEXT NULL,
    created_by VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    INDEX idx_employee_id (employee_id),
    INDEX idx_status (status),
    INDEX idx_start_date (start_date)
);
```

### Table `employee_performances`

```sql
CREATE TABLE employee_performances (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    employee_id BIGINT UNSIGNED NOT NULL,
    period VARCHAR(100) NOT NULL,
    rating DECIMAL(3, 2) NOT NULL,
    comments TEXT NULL,
    goals TEXT NULL,
    achievements TEXT NULL,
    areas_for_improvement TEXT NULL,
    status ENUM('draft', 'submitted', 'reviewed', 'approved') DEFAULT 'draft',
    reviewed_by VARCHAR(255) NULL,
    reviewed_at TIMESTAMP NULL,
    created_by VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    INDEX idx_employee_id (employee_id),
    INDEX idx_period (period),
    INDEX idx_status (status)
);
```

---

## Exemples de Requêtes Flutter/Dart

### Créer un Employé

```dart
final response = await http.post(
  Uri.parse('$baseUrl/api/employees'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body: jsonEncode({
    'first_name': 'Jean',
    'last_name': 'Dupont',
    'email': 'jean.dupont@example.com',
    'phone': '+237 6 12 34 56 78',
    'position': 'Développeur Full Stack',
    'department': 'Technique',
    'hire_date': '2024-01-15T00:00:00Z',
    'contract_type': 'permanent',
    'salary': 500000.00,
    'currency': 'fcfa',
    'work_schedule': 'full_time',
  }),
);
```

### Récupérer les Employés avec Filtres

```dart
final response = await http.get(
  Uri.parse('$baseUrl/api/employees?status=active&department=Technique'),
  headers: {
    'Authorization': 'Bearer $token',
  },
);
```

### Mettre à Jour un Employé

```dart
final response = await http.put(
  Uri.parse('$baseUrl/api/employees/$employeeId'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body: jsonEncode({
    'position': 'Développeur Senior',
    'salary': 600000.00,
  }),
);
```

---

## Notes Importantes

1. **Statut initial** : Toute nouvelle création est créée avec le statut `"active"` (actif)
2. **Email unique** : L'email doit être unique dans le système
3. **Format de date** : Le format ISO 8601 avec timezone (`2024-01-15T00:00:00Z`) est recommandé
4. **Authentification** : Tous les endpoints nécessitent une authentification valide (middleware `auth:sanctum` ou équivalent)
5. **Pagination** : Le backend peut retourner soit une liste directe, soit un objet paginé. Le frontend gère les deux formats
6. **Validation** : Tous les champs enum doivent correspondre exactement aux valeurs acceptées
7. **Dates de contrat** : Si `contract_end_date` est fourni, il doit être après `contract_start_date`
8. **Documents** : Les documents peuvent avoir une date d'expiration pour le suivi
9. **Congés** : Les congés sont créés avec le statut `"pending"` et doivent être approuvés
10. **Performances** : Les performances sont créées avec le statut `"draft"` par défaut

---

## Checklist de Validation pour la Création d'Employé

Avant d'envoyer la requête, vérifier :

- [ ] `first_name` : présent et non vide (max 255 caractères)
- [ ] `last_name` : présent et non vide (max 255 caractères)
- [ ] `email` : présent, format valide et unique dans le système
- [ ] `phone` : optionnel, max 50 caractères
- [ ] `address` : optionnel
- [ ] `birth_date` : optionnel, format ISO 8601 si fourni
- [ ] `gender` : optionnel, une des valeurs (`male`, `female`, `other`)
- [ ] `marital_status` : optionnel, une des valeurs (`single`, `married`, `divorced`, `widowed`)
- [ ] `nationality` : optionnel, max 100 caractères
- [ ] `id_number` : optionnel, max 50 caractères
- [ ] `social_security_number` : optionnel, max 50 caractères
- [ ] `position` : optionnel, max 255 caractères
- [ ] `department` : optionnel, max 255 caractères
- [ ] `manager` : optionnel, max 255 caractères
- [ ] `hire_date` : optionnel, format ISO 8601 si fourni
- [ ] `contract_start_date` : optionnel, format ISO 8601 si fourni
- [ ] `contract_end_date` : optionnel, format ISO 8601 si fourni, doit être après `contract_start_date`
- [ ] `contract_type` : optionnel, une des valeurs (`permanent`, `temporary`, `internship`, `consultant`)
- [ ] `salary` : optionnel, nombre décimal positif
- [ ] `currency` : optionnel, une des valeurs (`fcfa`, `eur`, `usd`), défaut `fcfa`
- [ ] `work_schedule` : optionnel, une des valeurs (`full_time`, `part_time`, `flexible`, `shift`)
- [ ] `profile_picture` : optionnel, URL ou chemin de fichier
- [ ] `notes` : optionnel
- [ ] L'utilisateur est authentifié (token présent dans les headers)
- [ ] Content-Type : `application/json`

---

## Format de Réponse Standard

Toutes les réponses doivent suivre ce format :

### Succès
```json
{
  "success": true,
  "message": "Message de succès",
  "data": { ... }
}
```

### Erreur
```json
{
  "success": false,
  "message": "Message d'erreur",
  "errors": {
    "field": ["Message d'erreur spécifique"]
  }
}
```

---

## Codes de Statut HTTP

- **200 OK** : Requête réussie (GET, PUT, DELETE)
- **201 Created** : Ressource créée avec succès (POST)
- **400 Bad Request** : Requête mal formée
- **401 Unauthorized** : Non authentifié
- **403 Forbidden** : Non autorisé
- **404 Not Found** : Ressource non trouvée
- **422 Unprocessable Entity** : Erreurs de validation
- **500 Internal Server Error** : Erreur serveur

---

## Fin du Document

Ce document couvre toutes les spécifications nécessaires pour implémenter le module de gestion des employés côté backend. Pour toute question ou clarification, référez-vous aux exemples de code Flutter fournis dans ce document.

