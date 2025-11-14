# Documentation Backend - Gestion des Contrats

## Vue d'ensemble

Ce document décrit toutes les spécifications nécessaires pour implémenter le module de gestion des contrats dans le backend. Le système permet de créer, gérer, approuver, résilier et suivre les contrats de travail des employés.

---

## Table des matières

1. [Endpoints Principaux](#endpoints-principaux)
2. [Création d'un Contrat](#création-dun-contrat)
3. [Récupération des Contrats](#récupération-des-contrats)
4. [Gestion des Statuts](#gestion-des-statuts)
5. [Clauses et Pièces Jointes](#clauses-et-pièces-jointes)
6. [Statistiques et Rapports](#statistiques-et-rapports)
7. [Modèles de Contrat](#modèles-de-contrat)
8. [Permissions et Rôles](#permissions-et-rôles)
9. [Exemples de Requêtes](#exemples-de-requêtes)

---

## Endpoints Principaux

### Base URL
Tous les endpoints commencent par : `/api/contracts`

### Authentification
Tous les endpoints nécessitent une authentification Bearer Token dans les headers :
```
Authorization: Bearer {token}
Content-Type: application/json
```

---

## Création d'un Contrat

### Endpoint
**POST** `/api/contracts`

### Description
Crée un nouveau contrat de travail pour un employé. Le contrat est créé avec le statut `"pending"` (en attente) par défaut, directement soumis pour approbation.

### Champs Obligatoires (Required)

#### 1. `employee_id` (ID de l'employé)
- **Type** : `integer`
- **Description** : ID de l'employé pour lequel le contrat est créé
- **Exemple** : `1`
- **Validation** : Doit exister dans la table `employees`

#### 2. `contract_type` (Type de contrat)
- **Type** : `string` (enum)
- **Valeurs acceptées** :
  - `"permanent"` (CDI - Contrat à Durée Indéterminée)
  - `"fixed_term"` (CDD - Contrat à Durée Déterminée)
  - `"temporary"` (Intérim)
  - `"internship"` (Stage)
  - `"consultant"` (Consultant)
- **Exemple** : `"permanent"`
- **Validation** : Doit être une des valeurs acceptées

#### 3. `position` (Poste)
- **Type** : `string`
- **Longueur max** : 100 caractères
- **Exemple** : `"Développeur Full Stack"`
- **Description** : Intitulé du poste

#### 4. `department` (Département)
- **Type** : `string`
- **Longueur max** : 100 caractères
- **Exemple** : `"Technique"` ou `"Ressources Humaines"`
- **Description** : Département de l'employé

#### 5. `job_title` (Titre du poste)
- **Type** : `string`
- **Longueur max** : 100 caractères
- **Exemple** : `"Développeur Senior"`
- **Description** : Titre du poste (peut être identique à `position`)

#### 6. `job_description` (Description du poste)
- **Type** : `string` (text)
- **Longueur min** : 50 caractères
- **Exemple** : `"Responsable du développement d'applications web et mobiles, maintenance du code existant, participation aux réunions techniques."`
- **Description** : Description détaillée des responsabilités du poste

#### 7. `gross_salary` (Salaire brut)
- **Type** : `decimal` ou `double`
- **Valeur min** : 0
- **Exemple** : `500000.00`
- **Description** : Salaire brut en FCFA

#### 8. `net_salary` (Salaire net)
- **Type** : `decimal` ou `double`
- **Valeur min** : 0
- **Exemple** : `400000.00`
- **Description** : Salaire net après déductions (en FCFA)

#### 9. `salary_currency` (Devise du salaire)
- **Type** : `string`
- **Longueur max** : 10 caractères
- **Exemple** : `"FCFA"`
- **Description** : Devise utilisée pour le salaire

#### 10. `payment_frequency` (Fréquence de paiement)
- **Type** : `string` (enum)
- **Valeurs acceptées** :
  - `"monthly"` (Mensuel)
  - `"weekly"` (Hebdomadaire)
  - `"daily"` (Journalier)
  - `"hourly"` (Horaire)
- **Exemple** : `"monthly"`
- **Validation** : Doit être une des valeurs acceptées

#### 11. `start_date` (Date de début)
- **Type** : `date` ou `datetime` (format ISO 8601)
- **Format accepté** :
  - `"2024-01-15"` (date simple)
  - `"2024-01-15T00:00:00Z"` (datetime ISO 8601)
- **Exemple** : `"2024-01-15T00:00:00Z"`
- **Description** : Date de début du contrat
- **Validation** : Doit être une date valide

#### 12. `work_location` (Lieu de travail)
- **Type** : `string`
- **Longueur max** : 255 caractères
- **Exemple** : `"Abidjan, Cocody"`
- **Description** : Localisation du lieu de travail

#### 13. `work_schedule` (Horaire de travail)
- **Type** : `string` (enum)
- **Valeurs acceptées** :
  - `"full_time"` (Temps plein)
  - `"part_time"` (Temps partiel)
  - `"flexible"` (Flexible)
- **Exemple** : `"full_time"`
- **Validation** : Doit être une des valeurs acceptées

#### 14. `weekly_hours` (Heures hebdomadaires)
- **Type** : `integer`
- **Valeur min** : 1
- **Valeur max** : 168 (7 jours × 24 heures)
- **Exemple** : `40`
- **Description** : Nombre d'heures de travail par semaine

#### 15. `probation_period` (Période d'essai)
- **Type** : `string` (enum)
- **Valeurs acceptées** :
  - `"none"` (Aucune)
  - `"1_month"` (1 mois)
  - `"3_months"` (3 mois)
  - `"6_months"` (6 mois)
- **Exemple** : `"3_months"`
- **Validation** : Doit être une des valeurs acceptées

### Champs Optionnels

#### 16. `end_date` (Date de fin)
- **Type** : `date` ou `datetime` (format ISO 8601)
- **Exemple** : `"2025-01-15T00:00:00Z"`
- **Description** : Date de fin du contrat (obligatoire pour les CDD)
- **Validation** : 
  - Si `contract_type` est `"fixed_term"`, ce champ est obligatoire
  - Doit être après `start_date`

#### 17. `duration_months` (Durée en mois)
- **Type** : `integer`
- **Valeur min** : 1
- **Exemple** : `12`
- **Description** : Durée du contrat en mois (calculé automatiquement si `end_date` est fourni)

#### 18. `notes` (Notes)
- **Type** : `string` (text, nullable)
- **Exemple** : `"Contrat renouvelable après évaluation"`
- **Description** : Notes additionnelles sur le contrat

#### 19. `contract_template` (Modèle de contrat)
- **Type** : `string` (nullable)
- **Exemple** : `"CDI-Standard-2024"`
- **Description** : Référence au modèle de contrat utilisé

#### 20. `clauses` (Clauses personnalisées)
- **Type** : `array` d'objets `ContractClause` (nullable)
- **Structure** :
  ```json
  {
    "title": "Clause de confidentialité",
    "content": "L'employé s'engage à maintenir la confidentialité...",
    "type": "legal",
    "is_mandatory": true,
    "order": 1
  }
  ```
- **Description** : Liste des clauses personnalisées à ajouter au contrat

### Champs Automatiques (Non requis - gérés par le backend)

Ces champs sont automatiquement remplis par le backend et ne doivent **PAS** être envoyés :

- `id` → Généré automatiquement
- `contract_number` → Généré automatiquement (format : `CTR-YYYYMMDD-XXXXXX`)
- `employee_name` → Récupéré depuis la table `employees`
- `employee_email` → Récupéré depuis la table `employees`
- `employee_phone` → Récupéré depuis la table `employees` (si disponible)
- `status` → Automatiquement défini à `"pending"` (en attente)
- `reporting_manager` → Récupéré depuis la table `employees` (si disponible)
- `health_insurance` → Récupéré depuis la table `employees` (si disponible)
- `retirement_plan` → Récupéré depuis la table `employees` (si disponible)
- `vacation_days` → Calculé selon le type de contrat et la politique de l'entreprise
- `other_benefits` → Récupéré depuis la table `employees` (si disponible)
- `approved_at` → `null` (sera rempli lors de l'approbation)
- `approved_by` → `null` (sera rempli lors de l'approbation)
- `approved_by_name` → `null` (sera rempli lors de l'approbation)
- `rejection_reason` → `null` (sera rempli en cas de rejet)
- `termination_reason` → `null` (sera rempli lors de la résiliation)
- `termination_date` → `null` (sera rempli lors de la résiliation)
- `created_at` → Timestamp automatique
- `updated_at` → Timestamp automatique

---

## Exemple de Requête JSON Complète

```json
{
  "employee_id": 1,
  "contract_type": "permanent",
  "position": "Développeur Full Stack",
  "department": "Technique",
  "job_title": "Développeur Senior",
  "job_description": "Responsable du développement d'applications web et mobiles utilisant les technologies modernes. Maintenance du code existant, participation aux réunions techniques, collaboration avec l'équipe.",
  "gross_salary": 500000.00,
  "net_salary": 400000.00,
  "salary_currency": "FCFA",
  "payment_frequency": "monthly",
  "start_date": "2024-01-15T00:00:00Z",
  "end_date": null,
  "duration_months": null,
  "work_location": "Abidjan, Cocody",
  "work_schedule": "full_time",
  "weekly_hours": 40,
  "probation_period": "3_months",
  "notes": "Contrat renouvelable après évaluation annuelle",
  "contract_template": "CDI-Standard-2024",
  "clauses": [
    {
      "title": "Clause de confidentialité",
      "content": "L'employé s'engage à maintenir la confidentialité des informations de l'entreprise.",
      "type": "legal",
      "is_mandatory": true,
      "order": 1
    }
  ]
}
```

---

## Réponse de Succès (201 Created)

```json
{
  "success": true,
  "message": "Contrat créé avec succès",
  "data": {
    "id": 1,
    "contract_number": "CTR-20240115-000001",
    "employee_id": 1,
    "employee_name": "Jean Dupont",
    "employee_email": "jean.dupont@example.com",
    "employee_phone": "+225 07 12 34 56 78",
    "contract_type": "permanent",
    "position": "Développeur Full Stack",
    "department": "Technique",
    "job_title": "Développeur Senior",
    "job_description": "Responsable du développement d'applications web et mobiles...",
    "gross_salary": 500000.00,
    "net_salary": 400000.00,
    "salary_currency": "FCFA",
    "payment_frequency": "monthly",
    "start_date": "2024-01-15T00:00:00Z",
    "end_date": null,
    "duration_months": null,
    "work_location": "Abidjan, Cocody",
    "work_schedule": "full_time",
    "weekly_hours": 40,
    "probation_period": "3_months",
    "reporting_manager": "Marie Martin",
    "health_insurance": "CNPS",
    "retirement_plan": "CNPS",
    "vacation_days": 25,
    "other_benefits": "Assurance santé, tickets restaurant",
    "status": "pending",
    "termination_reason": null,
    "termination_date": null,
    "notes": "Contrat renouvelable après évaluation annuelle",
    "contract_template": "CDI-Standard-2024",
    "approved_at": null,
    "approved_by": null,
    "approved_by_name": null,
    "rejection_reason": null,
    "created_at": "2024-01-15T10:00:00Z",
    "updated_at": "2024-01-15T10:00:00Z",
    "clauses": [
      {
        "id": 1,
        "contract_id": 1,
        "title": "Clause de confidentialité",
        "content": "L'employé s'engage à maintenir la confidentialité des informations de l'entreprise.",
        "type": "legal",
        "is_mandatory": true,
        "order": 1,
        "created_at": "2024-01-15T10:00:00Z",
        "updated_at": "2024-01-15T10:00:00Z"
      }
    ],
    "attachments": [],
    "history": [
      {
        "id": 1,
        "contract_id": 1,
        "action": "created",
        "action_text": "Contrat créé",
        "notes": null,
        "user_name": "Admin User",
        "created_at": "2024-01-15T10:00:00Z"
      }
    ]
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
    "employee_id": ["The employee id field is required."],
    "contract_type": ["The selected contract type is invalid."],
    "job_description": ["The job description must be at least 50 characters."],
    "gross_salary": ["The gross salary must be greater than 0."],
    "end_date": ["The end date must be a date after start date."],
    "weekly_hours": ["The weekly hours must be between 1 and 168."]
  }
}
```

### Erreurs Communes

1. **Champ manquant** : Tous les champs obligatoires doivent être présents
2. **Description trop courte** : `job_description` doit contenir au moins 50 caractères
3. **Type de contrat invalide** : `contract_type` doit correspondre aux valeurs acceptées
4. **Date de fin avant date de début** : `end_date` doit être après `start_date`
5. **Heures hebdomadaires invalides** : `weekly_hours` doit être entre 1 et 168
6. **Employé inexistant** : `employee_id` doit exister dans la base de données
7. **CDD sans date de fin** : Si `contract_type` est `"fixed_term"`, `end_date` est obligatoire

---

## Récupération des Contrats

### 1. Liste de tous les contrats

**GET** `/api/contracts`

#### Paramètres de requête (optionnels)

- `status` : Filtrer par statut (`pending`, `active`, `expired`, `terminated`, `cancelled`)
- `contract_type` : Filtrer par type (`permanent`, `fixed_term`, `temporary`, `internship`, `consultant`)
- `department` : Filtrer par département
- `employee_id` : Filtrer par ID d'employé
- `page` : Numéro de page (pour la pagination)
- `per_page` : Nombre d'éléments par page (défaut : 15)

#### Exemple de requête
```
GET /api/contracts?status=active&contract_type=permanent&department=Technique&page=1&per_page=20
```

#### Réponse (200 OK)

```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "per_page": 20,
    "total": 45,
    "last_page": 3,
    "data": [
      {
        "id": 1,
        "contract_number": "CTR-20240115-000001",
        "employee_id": 1,
        "employee_name": "Jean Dupont",
        "employee_email": "jean.dupont@example.com",
        "contract_type": "permanent",
        "position": "Développeur Full Stack",
        "department": "Technique",
        "job_title": "Développeur Senior",
        "gross_salary": 500000.00,
        "net_salary": 400000.00,
        "salary_currency": "FCFA",
        "payment_frequency": "monthly",
        "start_date": "2024-01-15T00:00:00Z",
        "end_date": null,
        "work_location": "Abidjan, Cocody",
        "work_schedule": "full_time",
        "weekly_hours": 40,
        "probation_period": "3_months",
        "status": "active",
        "created_at": "2024-01-15T10:00:00Z",
        "updated_at": "2024-01-15T10:00:00Z"
      }
    ]
  }
}
```

**Note** : Le backend peut retourner soit une liste directe `{"success": true, "data": [...]}`, soit un objet paginé `{"success": true, "data": {"current_page": 1, "data": [...]}}`. Le frontend doit gérer les deux formats.

### 2. Détails d'un contrat

**GET** `/api/contracts/{id}`

#### Réponse (200 OK)

```json
{
  "success": true,
  "data": {
    "id": 1,
    "contract_number": "CTR-20240115-000001",
    "employee_id": 1,
    "employee_name": "Jean Dupont",
    "employee_email": "jean.dupont@example.com",
    "employee_phone": "+225 07 12 34 56 78",
    "contract_type": "permanent",
    "position": "Développeur Full Stack",
    "department": "Technique",
    "job_title": "Développeur Senior",
    "job_description": "Responsable du développement...",
    "gross_salary": 500000.00,
    "net_salary": 400000.00,
    "salary_currency": "FCFA",
    "payment_frequency": "monthly",
    "start_date": "2024-01-15T00:00:00Z",
    "end_date": null,
    "duration_months": null,
    "work_location": "Abidjan, Cocody",
    "work_schedule": "full_time",
    "weekly_hours": 40,
    "probation_period": "3_months",
    "reporting_manager": "Marie Martin",
    "health_insurance": "CNPS",
    "retirement_plan": "CNPS",
    "vacation_days": 25,
    "other_benefits": "Assurance santé, tickets restaurant",
    "status": "active",
    "termination_reason": null,
    "termination_date": null,
    "notes": "Contrat renouvelable après évaluation annuelle",
    "contract_template": "CDI-Standard-2024",
    "approved_at": "2024-01-16T09:00:00Z",
    "approved_by": 2,
    "approved_by_name": "Marie Martin",
    "rejection_reason": null,
    "created_at": "2024-01-15T10:00:00Z",
    "updated_at": "2024-01-16T09:00:00Z",
    "clauses": [...],
    "attachments": [...],
    "history": [...]
  }
}
```

---

## Gestion des Statuts

### Statuts disponibles

1. **`pending`** (En attente) : Contrat créé et soumis, en attente d'approbation
2. **`active`** (Actif) : Contrat approuvé et en cours
3. **`expired`** (Expiré) : Contrat arrivé à expiration (pour CDD)
4. **`terminated`** (Résilié) : Contrat résilié avant terme
5. **`cancelled`** (Annulé) : Contrat annulé (en attente)

### Transitions de statut

#### 1. Approuver un contrat (Pending → Active)

**PUT** `/api/contracts/{id}/approve`

**Description** : Approuve un contrat en attente. Nécessite les permissions d'approbation (Patron ou Admin).

**Body (optionnel)** :
```json
{
  "notes": "Contrat approuvé après révision"
}
```

**Réponse (200 OK)** :
```json
{
  "success": true,
  "message": "Contrat approuvé avec succès",
  "data": {
    "id": 1,
    "status": "active",
    "approved_at": "2024-01-16T09:00:00Z",
    "approved_by": 2,
    "approved_by_name": "Marie Martin",
    "updated_at": "2024-01-16T09:00:00Z"
  }
}
```

#### 2. Rejeter un contrat (Pending → Cancelled)

**PUT** `/api/contracts/{id}/reject`

**Description** : Rejette un contrat en attente. Nécessite les permissions d'approbation.

**Body (obligatoire)** :
```json
{
  "rejection_reason": "Les conditions salariales ne sont pas conformes à la politique de l'entreprise"
}
```

**Réponse (200 OK)** :
```json
{
  "success": true,
  "message": "Contrat rejeté",
  "data": {
    "id": 1,
    "status": "cancelled",
    "rejection_reason": "Les conditions salariales ne sont pas conformes...",
    "updated_at": "2024-01-16T10:00:00Z"
  }
}
```

#### 3. Résilier un contrat (Active → Terminated)

**PUT** `/api/contracts/{id}/terminate`

**Description** : Résilie un contrat actif.

**Body (obligatoire)** :
```json
{
  "termination_reason": "Démission de l'employé",
  "termination_date": "2024-06-30T00:00:00Z",
  "notes": "Résiliation à l'amiable"
}
```

**Réponse (200 OK)** :
```json
{
  "success": true,
  "message": "Contrat résilié avec succès",
  "data": {
    "id": 1,
    "status": "terminated",
    "termination_reason": "Démission de l'employé",
    "termination_date": "2024-06-30T00:00:00Z",
    "updated_at": "2024-06-30T12:00:00Z"
  }
}
```

#### 4. Annuler un contrat (Pending → Cancelled)

**PUT** `/api/contracts/{id}/cancel`

**Description** : Annule un contrat en attente.

**Body (optionnel)** :
```json
{
  "reason": "Contrat remplacé par une nouvelle version"
}
```

**Réponse (200 OK)** :
```json
{
  "success": true,
  "message": "Contrat annulé",
  "data": {
    "id": 1,
    "status": "cancelled",
    "updated_at": "2024-01-15T12:00:00Z"
  }
}
```

---

## Mise à jour d'un Contrat

### Endpoint
**PUT** `/api/contracts/{id}`

### Description
Met à jour un contrat existant. Seuls les contrats avec le statut `"pending"` peuvent être modifiés.

### Body (tous les champs sont optionnels)
```json
{
  "contract_type": "permanent",
  "position": "Développeur Full Stack",
  "department": "Technique",
  "job_title": "Développeur Senior",
  "job_description": "Nouvelle description...",
  "gross_salary": 550000.00,
  "net_salary": 440000.00,
  "salary_currency": "FCFA",
  "payment_frequency": "monthly",
  "start_date": "2024-01-15T00:00:00Z",
  "end_date": null,
  "duration_months": null,
  "work_location": "Abidjan, Cocody",
  "work_schedule": "full_time",
  "weekly_hours": 40,
  "probation_period": "3_months",
  "notes": "Notes mises à jour"
}
```

### Réponse (200 OK)
```json
{
  "success": true,
  "message": "Contrat mis à jour avec succès",
  "data": {
    "id": 1,
    "updated_at": "2024-01-15T13:00:00Z",
    ...
  }
}
```

---

## Suppression d'un Contrat

### Endpoint
**DELETE** `/api/contracts/{id}`

### Description
Supprime un contrat. Seuls les contrats avec le statut `"pending"` ou `"cancelled"` peuvent être supprimés.

### Réponse (200 OK)
```json
{
  "success": true,
  "message": "Contrat supprimé avec succès"
}
```

---

## Clauses et Pièces Jointes

### 1. Récupérer les clauses d'un contrat

**GET** `/api/contracts/{id}/clauses`

**Réponse (200 OK)** :
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "contract_id": 1,
      "title": "Clause de confidentialité",
      "content": "L'employé s'engage à maintenir la confidentialité...",
      "type": "legal",
      "is_mandatory": true,
      "order": 1,
      "created_at": "2024-01-15T10:00:00Z",
      "updated_at": "2024-01-15T10:00:00Z"
    }
  ]
}
```

### 2. Ajouter une clause à un contrat

**POST** `/api/contracts/{id}/clauses`

**Body** :
```json
{
  "title": "Clause de non-concurrence",
  "content": "L'employé s'engage à ne pas travailler pour un concurrent...",
  "type": "legal",
  "is_mandatory": true,
  "order": 2
}
```

**Types de clauses acceptés** :
- `"standard"` : Clause standard
- `"custom"` : Clause personnalisée
- `"legal"` : Clause légale
- `"benefit"` : Clause de bénéfices

**Réponse (201 Created)** :
```json
{
  "success": true,
  "message": "Clause ajoutée avec succès",
  "data": {
    "id": 2,
    "contract_id": 1,
    "title": "Clause de non-concurrence",
    "content": "L'employé s'engage à ne pas travailler pour un concurrent...",
    "type": "legal",
    "is_mandatory": true,
    "order": 2,
    "created_at": "2024-01-15T14:00:00Z",
    "updated_at": "2024-01-15T14:00:00Z"
  }
}
```

### 3. Récupérer les pièces jointes d'un contrat

**GET** `/api/contracts/{id}/attachments`

**Réponse (200 OK)** :
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "contract_id": 1,
      "file_name": "contrat_signe.pdf",
      "file_path": "/storage/contracts/1/contrat_signe.pdf",
      "file_type": "application/pdf",
      "file_size": 245678,
      "attachment_type": "contract",
      "description": "Contrat signé par les deux parties",
      "uploaded_at": "2024-01-15T15:00:00Z",
      "uploaded_by": 1,
      "uploaded_by_name": "Admin User"
    }
  ]
}
```

### 4. Ajouter une pièce jointe à un contrat

**POST** `/api/contracts/{id}/attachments`

**Body** :
```json
{
  "file_name": "contrat_signe.pdf",
  "file_path": "/storage/contracts/1/contrat_signe.pdf",
  "file_type": "application/pdf",
  "file_size": 245678,
  "attachment_type": "contract",
  "description": "Contrat signé par les deux parties"
}
```

**Types de pièces jointes acceptés** :
- `"contract"` : Contrat signé
- `"addendum"` : Avenant
- `"amendment"` : Modification
- `"termination"` : Document de résiliation
- `"other"` : Autre

**Réponse (201 Created)** :
```json
{
  "success": true,
  "message": "Pièce jointe ajoutée avec succès",
  "data": {
    "id": 1,
    "contract_id": 1,
    "file_name": "contrat_signe.pdf",
    "file_path": "/storage/contracts/1/contrat_signe.pdf",
    "file_type": "application/pdf",
    "file_size": 245678,
    "attachment_type": "contract",
    "description": "Contrat signé par les deux parties",
    "uploaded_at": "2024-01-15T15:00:00Z",
    "uploaded_by": 1,
    "uploaded_by_name": "Admin User"
  }
}
```

---

## Statistiques et Rapports

### 1. Statistiques des contrats

**GET** `/api/contract-stats`

#### Paramètres de requête (optionnels)

- `start_date` : Date de début (format ISO 8601)
- `end_date` : Date de fin (format ISO 8601)
- `department` : Filtrer par département
- `contract_type` : Filtrer par type de contrat

#### Exemple de requête
```
GET /api/contract-stats?start_date=2024-01-01&end_date=2024-12-31&department=Technique
```

#### Réponse (200 OK)

```json
{
  "success": true,
  "data": {
    "total_contracts": 45,
    "pending_contracts": 3,
    "active_contracts": 30,
    "expired_contracts": 4,
    "terminated_contracts": 2,
    "cancelled_contracts": 1,
    "contracts_expiring_soon": 5,
    "average_salary": 450000.00,
    "contracts_by_type": {
      "permanent": 25,
      "fixed_term": 15,
      "temporary": 3,
      "internship": 2,
      "consultant": 0
    },
    "contracts_by_department": {
      "Technique": 20,
      "Commercial": 10,
      "Ressources Humaines": 8,
      "Comptabilité": 5,
      "Support": 2
    },
    "recent_contracts": [
      {
        "id": 1,
        "contract_number": "CTR-20240115-000001",
        "employee_name": "Jean Dupont",
        "contract_type": "permanent",
        "status": "active",
        "created_at": "2024-01-15T10:00:00Z"
      }
    ]
  }
}
```

### 2. Contrats expirant bientôt

**GET** `/api/contracts/expiring`

#### Paramètres de requête (optionnels)

- `days_ahead` : Nombre de jours à l'avance (défaut : 30)

#### Exemple de requête
```
GET /api/contracts/expiring?days_ahead=30
```

#### Réponse (200 OK)

```json
{
  "success": true,
  "data": [
    {
      "id": 5,
      "contract_number": "CTR-20240115-000005",
      "employee_name": "Marie Martin",
      "contract_type": "fixed_term",
      "end_date": "2024-02-15T00:00:00Z",
      "days_until_expiry": 25,
      "status": "active"
    }
  ]
}
```

---

## Modèles de Contrat

### 1. Récupérer les modèles de contrat

**GET** `/api/contract-templates`

#### Paramètres de requête (optionnels)

- `contract_type` : Filtrer par type de contrat
- `department` : Filtrer par département

#### Réponse (200 OK)

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "CDI Standard 2024",
      "description": "Modèle de contrat CDI standard pour 2024",
      "contract_type": "permanent",
      "department": null,
      "content": "Contenu du modèle de contrat...",
      "is_active": true,
      "default_clauses": [
        {
          "id": 1,
          "title": "Clause de confidentialité",
          "content": "...",
          "type": "legal",
          "is_mandatory": true,
          "order": 1
        }
      ],
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

---

## Utilitaires

### 1. Générer un numéro de contrat

**GET** `/api/contracts/generate-number`

**Description** : Génère un numéro de contrat unique au format `CTR-YYYYMMDD-XXXXXX`.

**Réponse (200 OK)** :
```json
{
  "success": true,
  "contract_number": "CTR-20240115-000001"
}
```

### 2. Récupérer les employés disponibles pour un contrat

**GET** `/api/employees/available-for-contract`

**Description** : Retourne la liste des employés disponibles pour créer un nouveau contrat (employés sans contrat actif ou avec contrat expiré).

**Réponse (200 OK)** :
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Jean Dupont",
      "email": "jean.dupont@example.com",
      "phone": "+225 07 12 34 56 78",
      "position": "Développeur",
      "department": "Technique",
      "current_contract": null
    },
    {
      "id": 2,
      "name": "Marie Martin",
      "email": "marie.martin@example.com",
      "phone": "+225 07 12 34 56 79",
      "position": "Designer",
      "department": "Commercial",
      "current_contract": {
        "id": 10,
        "contract_number": "CTR-20230101-000010",
        "status": "expired",
        "end_date": "2023-12-31T00:00:00Z"
      }
    }
  ]
}
```

---

## Permissions et Rôles

### Permissions requises

1. **`MANAGE_CONTRACTS`** : Créer, modifier, supprimer des contrats (RH, Admin)
2. **`APPROVE_CONTRACTS`** : Approuver/rejeter des contrats (Patron, Admin)
3. **`VIEW_CONTRACTS`** : Voir les contrats (Tous les rôles autorisés)

### Matrice des permissions

| Action | RH | Patron | Admin | Autres |
|--------|----|----|----|----|
| Créer un contrat | ✅ | ✅ | ✅ | ❌ |
| Modifier un contrat (pending) | ✅ | ✅ | ✅ | ❌ |
| Approuver un contrat | ❌ | ✅ | ✅ | ❌ |
| Rejeter un contrat | ❌ | ✅ | ✅ | ❌ |
| Résilier un contrat | ✅ | ✅ | ✅ | ❌ |
| Annuler un contrat | ✅ | ✅ | ✅ | ❌ |
| Supprimer un contrat | ✅ | ✅ | ✅ | ❌ |
| Voir tous les contrats | ✅ | ✅ | ✅ | ❌ |
| Voir ses propres contrats | ✅ | ✅ | ✅ | ✅ (si employé) |

---

## Checklist de Validation pour la Création de Contrat

Avant d'envoyer la requête, vérifier :

- [ ] `employee_id` : Présent et existe dans la base de données
- [ ] `contract_type` : Une des valeurs acceptées (`permanent`, `fixed_term`, `temporary`, `internship`, `consultant`)
- [ ] `position` : Max 100 caractères
- [ ] `department` : Max 100 caractères
- [ ] `job_title` : Max 100 caractères
- [ ] `job_description` : Minimum 50 caractères
- [ ] `gross_salary` : Nombre positif
- [ ] `net_salary` : Nombre positif (généralement < `gross_salary`)
- [ ] `salary_currency` : Max 10 caractères
- [ ] `payment_frequency` : Une des valeurs acceptées (`monthly`, `weekly`, `daily`, `hourly`)
- [ ] `start_date` : Date valide (format ISO 8601)
- [ ] `end_date` : 
  - Si `contract_type` est `"fixed_term"`, obligatoire
  - Doit être après `start_date`
- [ ] `work_location` : Max 255 caractères
- [ ] `work_schedule` : Une des valeurs acceptées (`full_time`, `part_time`, `flexible`)
- [ ] `weekly_hours` : Entre 1 et 168
- [ ] `probation_period` : Une des valeurs acceptées (`none`, `1_month`, `3_months`, `6_months`)
- [ ] L'utilisateur est authentifié (token présent dans les headers)
- [ ] Content-Type : `application/json`

---

## Notes Importantes

1. **Statut initial** : Toute nouvelle demande est créée avec le statut `"pending"` (en attente), directement soumise pour approbation
2. **Approbation** : L'approbation se fait via `PUT /api/contracts/{id}/approve` (nécessite le rôle Patron ou Admin)
4. **Format de date** : Le format ISO 8601 avec timezone (`2024-01-15T00:00:00Z`) est recommandé
5. **Authentification** : Tous les endpoints nécessitent une authentification valide (middleware `auth:sanctum` ou équivalent)
6. **Numéro de contrat** : Généré automatiquement au format `CTR-YYYYMMDD-XXXXXX` (ex: `CTR-20240115-000001`)
7. **Historique** : Toutes les actions (création, approbation, rejet, résiliation, annulation) sont enregistrées dans l'historique du contrat
8. **CDD obligatoire** : Pour les contrats de type `"fixed_term"`, la date de fin (`end_date`) est obligatoire
9. **Modification** : Seuls les contrats avec le statut `"pending"` peuvent être modifiés
10. **Suppression** : Seuls les contrats avec le statut `"pending"` ou `"cancelled"` peuvent être supprimés

---

## Structure de la Base de Données Recommandée

### Table `contracts`

```sql
- id (primary key)
- contract_number (unique, string)
- employee_id (foreign key -> employees.id)
- contract_type (enum)
- position (string)
- department (string)
- job_title (string)
- job_description (text)
- gross_salary (decimal)
- net_salary (decimal)
- salary_currency (string)
- payment_frequency (enum)
- start_date (date)
- end_date (date, nullable)
- duration_months (integer, nullable)
- work_location (string)
- work_schedule (enum)
- weekly_hours (integer)
- probation_period (enum)
- reporting_manager (string, nullable)
- employee_phone (string, nullable)
- health_insurance (string, nullable)
- retirement_plan (string, nullable)
- vacation_days (integer, nullable)
- other_benefits (text, nullable)
- status (enum)
- termination_reason (text, nullable)
- termination_date (date, nullable)
- notes (text, nullable)
- contract_template (string, nullable)
- approved_at (timestamp, nullable)
- approved_by (foreign key -> users.id, nullable)
- rejection_reason (text, nullable)
- created_at (timestamp)
- updated_at (timestamp)
```

### Table `contract_clauses`

```sql
- id (primary key)
- contract_id (foreign key -> contracts.id)
- title (string)
- content (text)
- type (enum)
- is_mandatory (boolean)
- order (integer)
- created_at (timestamp)
- updated_at (timestamp)
```

### Table `contract_attachments`

```sql
- id (primary key)
- contract_id (foreign key -> contracts.id)
- file_name (string)
- file_path (string)
- file_type (string)
- file_size (integer)
- attachment_type (enum)
- description (text, nullable)
- uploaded_at (timestamp)
- uploaded_by (foreign key -> users.id)
```

### Table `contract_history`

```sql
- id (primary key)
- contract_id (foreign key -> contracts.id)
- action (enum: 'created', 'approved', 'rejected', 'terminated', 'cancelled', 'updated')
- action_text (string, nullable)
- notes (text, nullable)
- user_id (foreign key -> users.id, nullable)
- user_name (string, nullable)
- created_at (timestamp)
```

---

## Exemples de Requêtes Flutter/Dart

### Créer un contrat

```dart
final response = await http.post(
  Uri.parse('$baseUrl/api/contracts'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body: jsonEncode({
    'employee_id': 1,
    'contract_type': 'permanent',
    'position': 'Développeur Full Stack',
    'department': 'Technique',
    'job_title': 'Développeur Senior',
    'job_description': 'Responsable du développement d\'applications web et mobiles...',
    'gross_salary': 500000.00,
    'net_salary': 400000.00,
    'salary_currency': 'FCFA',
    'payment_frequency': 'monthly',
    'start_date': '2024-01-15T00:00:00Z',
    'work_location': 'Abidjan, Cocody',
    'work_schedule': 'full_time',
    'weekly_hours': 40,
    'probation_period': '3_months',
  }),
);
```

### Récupérer tous les contrats

```dart
final response = await http.get(
  Uri.parse('$baseUrl/api/contracts?status=active&page=1&per_page=20'),
  headers: {
    'Authorization': 'Bearer $token',
  },
);
```

### Approuver un contrat

```dart
final response = await http.put(
  Uri.parse('$baseUrl/api/contracts/$contractId/approve'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body: jsonEncode({
    'notes': 'Contrat approuvé après révision',
  }),
);
```

---

## Conclusion

Ce document fournit toutes les spécifications nécessaires pour implémenter le module de gestion des contrats dans le backend. Assurez-vous de :

1. Implémenter tous les endpoints listés
2. Respecter les validations et contraintes décrites
3. Gérer correctement les transitions de statut
4. Enregistrer l'historique de toutes les actions
5. Implémenter les permissions selon la matrice fournie
6. Générer automatiquement les numéros de contrat
7. Gérer la pagination pour les listes
8. Retourner les réponses dans le format JSON standardisé

Pour toute question ou clarification, référez-vous aux exemples de requêtes et réponses fournis dans ce document.

