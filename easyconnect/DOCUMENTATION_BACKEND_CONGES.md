# Documentation Backend - Gestion des Congés

## Vue d'ensemble

Ce document décrit toutes les fonctionnalités backend nécessaires pour la gestion complète des congés (demandes, validation, affichage, statistiques, etc.).

---

## 1. Création d'une Demande de Congé

### Endpoint
**POST** `/api/leave-requests`

### Authentification
L'utilisateur doit être authentifié (le `employee_id` peut être celui de l'utilisateur connecté ou un autre employé si l'utilisateur a les permissions).

### Champs Requis

#### 1. `employee_id` (ID de l'employé)
- **Type** : `integer`
- **Description** : ID de l'employé qui demande le congé
- **Exemple** : `1`

#### 2. `leave_type` (Type de congé)
- **Type** : `string` (enum)
- **Valeurs acceptées** :
  - `"annual"` - Congés payés
  - `"sick"` - Congé maladie
  - `"maternity"` - Congé maternité
  - `"paternity"` - Congé paternité
  - `"personal"` - Congé personnel
  - `"emergency"` - Congé d'urgence
  - `"unpaid"` - Congé sans solde
- **Exemple** : `"annual"`

#### 3. `start_date` (Date de début)
- **Type** : `date` ou `datetime` (format ISO 8601)
- **Contrainte** : Doit être dans le futur ou aujourd'hui
- **Format accepté** :
  - `"2024-12-01"` (date simple)
  - `"2024-12-01T00:00:00Z"` (datetime ISO 8601)
- **Exemple** : `"2024-12-01T00:00:00Z"`

#### 4. `end_date` (Date de fin)
- **Type** : `date` ou `datetime` (format ISO 8601)
- **Contrainte** : Doit être après `start_date`
- **Format accepté** :
  - `"2024-12-15"` (date simple)
  - `"2024-12-15T23:59:59Z"` (datetime ISO 8601)
- **Exemple** : `"2024-12-15T23:59:59Z"`

#### 5. `reason` (Raison du congé)
- **Type** : `string` (text)
- **Longueur min** : 10 caractères
- **Longueur max** : 1000 caractères
- **Description** : Raison détaillée de la demande de congé
- **Exemple** : `"Demande de congés annuels pour repos et détente"`

### Champs Optionnels

#### 6. `comments` (Commentaires)
- **Type** : `string` (text)
- **Longueur max** : 2000 caractères
- **Description** : Commentaires supplémentaires
- **Exemple** : `"Je serai disponible par email en cas d'urgence"`

#### 7. `attachment_paths` (Chemins des pièces jointes)
- **Type** : `array` de `string`
- **Description** : Liste des chemins des fichiers joints (justificatifs, certificats médicaux, etc.)
- **Exemple** : `["uploads/leaves/certificat_medical_123.pdf"]`

### Champs Automatiques (Non requis - gérés par le backend)

Ces champs sont automatiquement remplis par le backend et ne doivent **PAS** être envoyés :
- `id` → Généré automatiquement
- `total_days` → Calculé automatiquement à partir de `start_date` et `end_date` (jours ouvrés)
- `status` → Automatiquement défini à `"pending"` (en attente)
- `approved_at` → `null` (sera rempli lors de l'approbation)
- `approved_by` → `null` (sera rempli avec l'ID de l'utilisateur qui approuve)
- `approved_by_name` → `null` (sera rempli avec le nom de l'utilisateur qui approuve)
- `rejection_reason` → `null` (sera rempli en cas de rejet)
- `created_at` → Timestamp de création
- `updated_at` → Timestamp de mise à jour

### Exemple de Requête JSON Complète

```json
{
  "employee_id": 1,
  "leave_type": "annual",
  "start_date": "2024-12-01T00:00:00Z",
  "end_date": "2024-12-15T23:59:59Z",
  "reason": "Demande de congés annuels pour repos et détente. Je souhaite prendre mes congés avant la fin de l'année.",
  "comments": "Je serai disponible par email en cas d'urgence",
  "attachment_paths": []
}
```

### Réponse de Succès (201 Created)

```json
{
  "success": true,
  "message": "Demande de congé créée avec succès",
  "data": {
    "id": 1,
    "employee_id": 1,
    "employee_name": "Jean Dupont",
    "leave_type": "annual",
    "start_date": "2024-12-01T00:00:00Z",
    "end_date": "2024-12-15T23:59:59Z",
    "total_days": 11,
    "reason": "Demande de congés annuels pour repos et détente. Je souhaite prendre mes congés avant la fin de l'année.",
    "status": "pending",
    "comments": "Je serai disponible par email en cas d'urgence",
    "rejection_reason": null,
    "approved_at": null,
    "approved_by": null,
    "approved_by_name": null,
    "created_at": "2024-11-15T10:00:00Z",
    "updated_at": "2024-11-15T10:00:00Z",
    "attachments": []
  }
}
```

### Erreurs de Validation Possibles (422)

```json
{
  "success": false,
  "message": "The given data was invalid.",
  "errors": {
    "employee_id": ["The employee id field is required."],
    "leave_type": ["The selected leave type is invalid."],
    "start_date": ["The start date must be a date after or equal to today."],
    "end_date": ["The end date must be a date after start date."],
    "reason": ["The reason must be at least 10 characters."]
  }
}
```

### Erreurs Communes

1. **Champ manquant** : Tous les champs requis doivent être présents
2. **Type de congé invalide** : `leave_type` doit correspondre aux valeurs acceptées
3. **Date de début dans le passé** : `start_date` doit être aujourd'hui ou dans le futur
4. **Date de fin avant la date de début** : `end_date` doit être après `start_date`
5. **Raison trop courte** : Minimum 10 caractères
6. **Conflit de dates** : Vérifier qu'il n'y a pas de chevauchement avec d'autres congés approuvés

---

## 2. Affichage des Demandes de Congé

### 2.1. Récupérer Toutes les Demandes (RH/Patron)

#### Endpoint
**GET** `/api/leave-requests`

#### Authentification
Requise (rôle RH, Patron ou Admin)

#### Paramètres de Requête (optionnels)

- `status` (string) : Filtrer par statut (`pending`, `approved`, `rejected`, `cancelled`)
- `leave_type` (string) : Filtrer par type de congé
- `employee_id` (integer) : Filtrer par employé
- `start_date` (date) : Date de début pour filtrer les demandes
- `end_date` (date) : Date de fin pour filtrer les demandes

#### Exemple de Requête

```
GET /api/leave-requests?status=pending&leave_type=annual
```

#### Réponse Attendue (200 OK)

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "employee_id": 1,
      "employee_name": "Jean Dupont",
      "leave_type": "annual",
      "start_date": "2024-12-01T00:00:00Z",
      "end_date": "2024-12-15T23:59:59Z",
      "total_days": 11,
      "reason": "Demande de congés annuels...",
      "status": "pending",
      "comments": null,
      "rejection_reason": null,
      "approved_at": null,
      "approved_by": null,
      "approved_by_name": null,
      "created_at": "2024-11-15T10:00:00Z",
      "updated_at": "2024-11-15T10:00:00Z",
      "attachments": []
    }
  ]
}
```

**Format alternatif (pagination)** :

```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 1,
        ...
      }
    ],
    "total": 50,
    "per_page": 15
  }
}
```

### 2.2. Récupérer les Demandes d'un Employé

#### Endpoint
**GET** `/api/leave-requests/employee/{employeeId}`

#### Authentification
Requise (l'employé peut voir ses propres demandes, RH/Patron peuvent voir toutes)

#### Paramètres de Requête (optionnels)

- `status` (string) : Filtrer par statut
- `start_date` (date) : Date de début
- `end_date` (date) : Date de fin

#### Réponse Attendue (200 OK)

Même format que la liste complète.

### 2.3. Récupérer une Demande Spécifique

#### Endpoint
**GET** `/api/leave-requests/{id}`

#### Authentification
Requise

#### Réponse Attendue (200 OK)

```json
{
  "success": true,
  "data": {
    "id": 1,
    "employee_id": 1,
    "employee_name": "Jean Dupont",
    "leave_type": "annual",
    "start_date": "2024-12-01T00:00:00Z",
    "end_date": "2024-12-15T23:59:59Z",
    "total_days": 11,
    "reason": "Demande de congés annuels...",
    "status": "pending",
    "comments": null,
    "rejection_reason": null,
    "approved_at": null,
    "approved_by": null,
    "approved_by_name": null,
    "created_at": "2024-11-15T10:00:00Z",
    "updated_at": "2024-11-15T10:00:00Z",
    "attachments": [
      {
        "id": 1,
        "leave_request_id": 1,
        "file_name": "certificat_medical.pdf",
        "file_path": "uploads/leaves/certificat_medical_123.pdf",
        "file_type": "application/pdf",
        "file_size": 245678,
        "uploaded_at": "2024-11-15T10:05:00Z"
      }
    ],
    "leave_balance": {
      "employee_id": 1,
      "employee_name": "Jean Dupont",
      "annual_leave_days": 25,
      "used_annual_leave": 5,
      "remaining_annual_leave": 20,
      "sick_leave_days": 10,
      "used_sick_leave": 2,
      "remaining_sick_leave": 8,
      "personal_leave_days": 5,
      "used_personal_leave": 0,
      "remaining_personal_leave": 5,
      "last_updated": "2024-11-15T10:00:00Z"
    }
  }
}
```

---

## 3. Validation des Demandes de Congé

### 3.1. Approuver une Demande

#### Endpoint
**PUT** `/api/leave-requests/{id}/approve`

#### Authentification
Requise (rôle RH, Patron ou Admin)

#### Corps de la Requête (optionnel)

```json
{
  "comments": "Demande approuvée. Profitez bien de vos congés !"
}
```

#### Réponse Attendue (200 OK)

```json
{
  "success": true,
  "message": "Demande de congé approuvée avec succès",
  "data": {
    "id": 1,
    "employee_id": 1,
    "employee_name": "Jean Dupont",
    "leave_type": "annual",
    "start_date": "2024-12-01T00:00:00Z",
    "end_date": "2024-12-15T23:59:59Z",
    "total_days": 11,
    "reason": "Demande de congés annuels...",
    "status": "approved",
    "comments": "Demande approuvée. Profitez bien de vos congés !",
    "rejection_reason": null,
    "approved_at": "2024-11-16T09:00:00Z",
    "approved_by": 2,
    "approved_by_name": "Marie Martin",
    "created_at": "2024-11-15T10:00:00Z",
    "updated_at": "2024-11-16T09:00:00Z",
    "attachments": []
  }
}
```

### 3.2. Rejeter une Demande

#### Endpoint
**PUT** `/api/leave-requests/{id}/reject`

#### Authentification
Requise (rôle RH, Patron ou Admin)

#### Corps de la Requête (requis)

```json
{
  "rejection_reason": "Pas assez de jours de congés disponibles. Solde insuffisant."
}
```

#### Réponse Attendue (200 OK)

```json
{
  "success": true,
  "message": "Demande de congé rejetée",
  "data": {
    "id": 1,
    "employee_id": 1,
    "employee_name": "Jean Dupont",
    "leave_type": "annual",
    "start_date": "2024-12-01T00:00:00Z",
    "end_date": "2024-12-15T23:59:59Z",
    "total_days": 11,
    "reason": "Demande de congés annuels...",
    "status": "rejected",
    "comments": null,
    "rejection_reason": "Pas assez de jours de congés disponibles. Solde insuffisant.",
    "approved_at": null,
    "approved_by": null,
    "approved_by_name": null,
    "created_at": "2024-11-15T10:00:00Z",
    "updated_at": "2024-11-16T09:00:00Z",
    "attachments": []
  }
}
```

### 3.3. Annuler une Demande

#### Endpoint
**PUT** `/api/leave-requests/{id}/cancel`

#### Authentification
Requise (l'employé peut annuler ses propres demandes en attente, RH/Patron peuvent annuler toutes)

#### Réponse Attendue (200 OK)

```json
{
  "success": true,
  "message": "Demande de congé annulée",
  "data": {
    "id": 1,
    "status": "cancelled",
    ...
  }
}
```

---

## 4. Modification et Suppression

### 4.1. Modifier une Demande

#### Endpoint
**PUT** `/api/leave-requests/{id}`

#### Authentification
Requise (l'employé peut modifier ses propres demandes en attente, RH/Patron peuvent modifier toutes)

#### Corps de la Requête (tous les champs sont optionnels)

```json
{
  "leave_type": "sick",
  "start_date": "2024-12-02T00:00:00Z",
  "end_date": "2024-12-05T23:59:59Z",
  "reason": "Nouvelle raison",
  "comments": "Nouveaux commentaires"
}
```

#### Réponse Attendue (200 OK)

```json
{
  "success": true,
  "message": "Demande de congé mise à jour avec succès",
  "data": {
    "id": 1,
    ...
  }
}
```

### 4.2. Supprimer une Demande

#### Endpoint
**DELETE** `/api/leave-requests/{id}`

#### Authentification
Requise (l'employé peut supprimer ses propres demandes en attente, RH/Patron peuvent supprimer toutes)

#### Réponse Attendue (200 OK)

```json
{
  "success": true,
  "message": "Demande de congé supprimée avec succès"
}
```

---

## 5. Solde de Congés

### 5.1. Récupérer le Solde d'un Employé

#### Endpoint
**GET** `/api/leave-balance/{employeeId}`

#### Authentification
Requise

#### Réponse Attendue (200 OK)

```json
{
  "success": true,
  "data": {
    "employee_id": 1,
    "employee_name": "Jean Dupont",
    "annual_leave_days": 25,
    "used_annual_leave": 5,
    "remaining_annual_leave": 20,
    "sick_leave_days": 10,
    "used_sick_leave": 2,
    "remaining_sick_leave": 8,
    "personal_leave_days": 5,
    "used_personal_leave": 0,
    "remaining_personal_leave": 5,
    "last_updated": "2024-11-15T10:00:00Z"
  }
}
```

---

## 6. Statistiques

### 6.1. Récupérer les Statistiques des Congés

#### Endpoint
**GET** `/api/leave-stats`

#### Authentification
Requise (rôle RH, Patron ou Admin)

#### Paramètres de Requête (optionnels)

- `start_date` (date) : Date de début pour les statistiques
- `end_date` (date) : Date de fin pour les statistiques
- `employee_id` (integer) : Filtrer par employé

#### Réponse Attendue (200 OK)

```json
{
  "success": true,
  "data": {
    "total_requests": 50,
    "pending_requests": 10,
    "approved_requests": 30,
    "rejected_requests": 5,
    "cancelled_requests": 5,
    "average_approval_time": 2.5,
    "requests_by_type": {
      "annual": 25,
      "sick": 15,
      "maternity": 3,
      "paternity": 2,
      "personal": 3,
      "emergency": 1,
      "unpaid": 1
    },
    "requests_by_month": {
      "2024-01": 5,
      "2024-02": 8,
      "2024-03": 12,
      "2024-04": 10,
      "2024-05": 15
    },
    "recent_requests": [
      {
        "id": 1,
        "employee_name": "Jean Dupont",
        "leave_type": "annual",
        "start_date": "2024-12-01T00:00:00Z",
        "end_date": "2024-12-15T23:59:59Z",
        "status": "pending"
      }
    ]
  }
}
```

---

## 7. Types de Congés

### 7.1. Récupérer les Types de Congés Disponibles

#### Endpoint
**GET** `/api/leave-types`

#### Authentification
Requise

#### Réponse Attendue (200 OK)

```json
{
  "success": true,
  "data": [
    {
      "value": "annual",
      "label": "Congés payés",
      "description": "Congés annuels payés",
      "requires_approval": true,
      "max_days": 30,
      "is_paid": true
    },
    {
      "value": "sick",
      "label": "Congé maladie",
      "description": "Congé pour maladie",
      "requires_approval": true,
      "max_days": 90,
      "is_paid": true
    },
    {
      "value": "maternity",
      "label": "Congé maternité",
      "description": "Congé de maternité",
      "requires_approval": true,
      "max_days": 98,
      "is_paid": true
    },
    {
      "value": "paternity",
      "label": "Congé paternité",
      "description": "Congé de paternité",
      "requires_approval": true,
      "max_days": 11,
      "is_paid": true
    },
    {
      "value": "personal",
      "label": "Congé personnel",
      "description": "Congé pour affaires personnelles",
      "requires_approval": true,
      "max_days": 5,
      "is_paid": false
    },
    {
      "value": "emergency",
      "label": "Congé d'urgence",
      "description": "Congé pour urgence familiale",
      "requires_approval": true,
      "max_days": 3,
      "is_paid": false
    },
    {
      "value": "unpaid",
      "label": "Congé sans solde",
      "description": "Congé non rémunéré",
      "requires_approval": true,
      "max_days": 30,
      "is_paid": false
    }
  ]
}
```

---

## 8. Vérification des Conflits

### 8.1. Vérifier les Conflits de Dates

#### Endpoint
**POST** `/api/leave-requests/check-conflicts`

#### Authentification
Requise

#### Corps de la Requête

```json
{
  "employee_id": 1,
  "start_date": "2024-12-01T00:00:00Z",
  "end_date": "2024-12-15T23:59:59Z",
  "exclude_request_id": null
}
```

#### Réponse Attendue (200 OK)

```json
{
  "success": true,
  "data": {
    "has_conflicts": false,
    "conflicting_requests": []
  }
}
```

**En cas de conflit** :

```json
{
  "success": true,
  "data": {
    "has_conflicts": true,
    "conflicting_requests": [
      {
        "id": 5,
        "start_date": "2024-12-10T00:00:00Z",
        "end_date": "2024-12-20T23:59:59Z",
        "status": "approved"
      }
    ]
  }
}
```

---

## 9. Pièces Jointes

### 9.1. Télécharger une Pièce Jointe

#### Endpoint
**GET** `/api/leave-attachments/{attachmentId}/download`

#### Authentification
Requise

#### Réponse Attendue (200 OK)

```json
{
  "success": true,
  "download_url": "https://example.com/storage/uploads/leaves/certificat_medical_123.pdf"
}
```

---

## 10. Structure de la Base de Données

### Table `leave_requests`

```sql
CREATE TABLE leave_requests (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    employee_id BIGINT UNSIGNED NOT NULL,
    leave_type ENUM('annual', 'sick', 'maternity', 'paternity', 'personal', 'emergency', 'unpaid') NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_days INT NOT NULL,
    reason TEXT NOT NULL,
    status ENUM('pending', 'approved', 'rejected', 'cancelled') DEFAULT 'pending',
    comments TEXT NULL,
    rejection_reason TEXT NULL,
    approved_at TIMESTAMP NULL,
    approved_by BIGINT UNSIGNED NULL,
    approved_by_name VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    INDEX idx_employee_id (employee_id),
    INDEX idx_status (status),
    INDEX idx_leave_type (leave_type),
    INDEX idx_start_date (start_date),
    INDEX idx_end_date (end_date)
);
```

### Table `leave_attachments`

```sql
CREATE TABLE leave_attachments (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    leave_request_id BIGINT UNSIGNED NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_type VARCHAR(100) NOT NULL,
    file_size INT NOT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (leave_request_id) REFERENCES leave_requests(id) ON DELETE CASCADE,
    INDEX idx_leave_request_id (leave_request_id)
);
```

### Table `leave_balances` (optionnel - pour gérer les soldes)

```sql
CREATE TABLE leave_balances (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    employee_id BIGINT UNSIGNED NOT NULL UNIQUE,
    annual_leave_days INT DEFAULT 25,
    used_annual_leave INT DEFAULT 0,
    remaining_annual_leave INT DEFAULT 25,
    sick_leave_days INT DEFAULT 10,
    used_sick_leave INT DEFAULT 0,
    remaining_sick_leave INT DEFAULT 10,
    personal_leave_days INT DEFAULT 5,
    used_personal_leave INT DEFAULT 0,
    remaining_personal_leave INT DEFAULT 5,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    INDEX idx_employee_id (employee_id)
);
```

---

## 11. Règles Métier Importantes

### 11.1. Calcul du Nombre de Jours

- Le `total_days` doit être calculé en **jours ouvrés** (excluant les weekends et jours fériés)
- Exemple : Du lundi 1er décembre au vendredi 15 décembre = 11 jours ouvrés

### 11.2. Validation des Dates

- `start_date` doit être aujourd'hui ou dans le futur
- `end_date` doit être après `start_date`
- Vérifier qu'il n'y a pas de chevauchement avec d'autres congés approuvés du même employé

### 11.3. Vérification du Solde

- Avant d'approuver, vérifier que l'employé a suffisamment de jours disponibles selon le type de congé
- Pour les congés payés (`annual`), vérifier `remaining_annual_leave >= total_days`
- Pour les congés maladie (`sick`), vérifier `remaining_sick_leave >= total_days`
- Pour les congés personnels (`personal`), vérifier `remaining_personal_leave >= total_days`

### 11.4. Mise à Jour du Solde

- Lors de l'approbation d'un congé, déduire les jours du solde correspondant
- Lors de l'annulation d'un congé approuvé, remettre les jours dans le solde

### 11.5. Statuts

- `pending` : En attente d'approbation
- `approved` : Approuvé (les jours sont déduits du solde)
- `rejected` : Rejeté
- `cancelled` : Annulé (si approuvé, les jours sont remis dans le solde)

---

## 12. Codes de Statut HTTP

- `200 OK` : Succès (GET, PUT, DELETE)
- `201 Created` : Ressource créée (POST)
- `400 Bad Request` : Requête invalide
- `401 Unauthorized` : Non authentifié
- `403 Forbidden` : Non autorisé
- `404 Not Found` : Ressource non trouvée
- `422 Unprocessable Entity` : Erreur de validation
- `500 Internal Server Error` : Erreur serveur

---

## 13. Format de Réponse Standard

Toutes les réponses doivent suivre ce format :

```json
{
  "success": true,
  "message": "Message de succès (optionnel)",
  "data": {
    // Données de la réponse
  }
}
```

En cas d'erreur :

```json
{
  "success": false,
  "message": "Message d'erreur",
  "errors": {
    "field": ["Message d'erreur pour ce champ"]
  }
}
```

---

## 14. Checklist de Mise en Place

### Routes à Créer
- [ ] `POST /api/leave-requests` - Créer une demande
- [ ] `GET /api/leave-requests` - Liste toutes les demandes
- [ ] `GET /api/leave-requests/employee/{id}` - Demandes d'un employé
- [ ] `GET /api/leave-requests/{id}` - Détails d'une demande
- [ ] `PUT /api/leave-requests/{id}` - Modifier une demande
- [ ] `DELETE /api/leave-requests/{id}` - Supprimer une demande
- [ ] `PUT /api/leave-requests/{id}/approve` - Approuver
- [ ] `PUT /api/leave-requests/{id}/reject` - Rejeter
- [ ] `PUT /api/leave-requests/{id}/cancel` - Annuler
- [ ] `GET /api/leave-balance/{employeeId}` - Solde d'un employé
- [ ] `GET /api/leave-stats` - Statistiques
- [ ] `GET /api/leave-types` - Types de congés
- [ ] `POST /api/leave-requests/check-conflicts` - Vérifier conflits
- [ ] `GET /api/leave-attachments/{id}/download` - Télécharger pièce jointe

### Fonctionnalités à Implémenter
- [ ] Calcul automatique du nombre de jours ouvrés
- [ ] Vérification des conflits de dates
- [ ] Vérification du solde avant approbation
- [ ] Mise à jour automatique du solde lors de l'approbation/annulation
- [ ] Gestion des permissions (employé vs RH/Patron)
- [ ] Validation des dates (futur, cohérence)
- [ ] Gestion des pièces jointes

---

## 15. Exemple de Route Laravel

```php
// routes/api.php

Route::middleware('auth:sanctum')->group(function () {
    // Routes pour les demandes de congé
    Route::get('/leave-requests', [LeaveRequestController::class, 'index']);
    Route::get('/leave-requests/employee/{employeeId}', [LeaveRequestController::class, 'getEmployeeRequests']);
    Route::get('/leave-requests/{id}', [LeaveRequestController::class, 'show']);
    Route::post('/leave-requests', [LeaveRequestController::class, 'store']);
    Route::put('/leave-requests/{id}', [LeaveRequestController::class, 'update']);
    Route::delete('/leave-requests/{id}', [LeaveRequestController::class, 'destroy']);
    Route::put('/leave-requests/{id}/approve', [LeaveRequestController::class, 'approve']);
    Route::put('/leave-requests/{id}/reject', [LeaveRequestController::class, 'reject']);
    Route::put('/leave-requests/{id}/cancel', [LeaveRequestController::class, 'cancel']);
    
    // Routes pour les soldes et statistiques
    Route::get('/leave-balance/{employeeId}', [LeaveBalanceController::class, 'show']);
    Route::get('/leave-stats', [LeaveStatsController::class, 'index']);
    Route::get('/leave-types', [LeaveTypeController::class, 'index']);
    
    // Routes utilitaires
    Route::post('/leave-requests/check-conflicts', [LeaveRequestController::class, 'checkConflicts']);
    Route::get('/leave-attachments/{id}/download', [LeaveAttachmentController::class, 'download']);
});
```

---

## Notes Importantes

1. **Calcul des jours** : Utiliser une bibliothèque pour calculer les jours ouvrés (excluant weekends et jours fériés)
2. **Gestion du solde** : Mettre à jour automatiquement le solde lors de l'approbation/annulation
3. **Permissions** : Vérifier les permissions selon le rôle (employé peut voir/modifier ses propres demandes, RH/Patron peuvent tout voir)
4. **Validation** : Toujours valider les dates, les conflits et le solde avant d'approuver
5. **Format de date** : Utiliser le format ISO 8601 pour toutes les dates (`YYYY-MM-DDTHH:mm:ssZ`)

