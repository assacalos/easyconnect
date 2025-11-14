# Champs Requis pour Créer un Contrat

## Endpoint
**POST** `/api/contracts`

## Authentification
L'utilisateur doit être authentifié (le `created_by` sera automatiquement rempli avec l'ID de l'utilisateur connecté).

---

## Champs Obligatoires (Required)

### 1. `employee_id` (ID de l'employé)
- **Type** : `integer`
- **Exemple** : `1`
- **Description** : ID de l'employé pour lequel le contrat est créé
- **Validation** : Doit exister dans la table `employees`

### 2. `contract_type` (Type de contrat)
- **Type** : `string` (enum)
- **Valeurs acceptées** :
  - `"permanent"` (CDI - Contrat à Durée Indéterminée)
  - `"fixed_term"` (CDD - Contrat à Durée Déterminée)
  - `"temporary"` (Intérim)
  - `"internship"` (Stage)
  - `"consultant"` (Consultant)
- **Exemple** : `"permanent"`
- **Description** : Type de contrat proposé

### 3. `position` (Poste)
- **Type** : `string`
- **Longueur max** : 100 caractères
- **Exemple** : `"Développeur Full Stack"`
- **Description** : Intitulé du poste

### 4. `department` (Département)
- **Type** : `string`
- **Longueur max** : 100 caractères
- **Exemple** : `"Technique"` ou `"Ressources Humaines"`
- **Description** : Département de l'employé

### 5. `job_title` (Titre du poste)
- **Type** : `string`
- **Longueur max** : 100 caractères
- **Exemple** : `"Développeur Senior"`
- **Description** : Titre du poste (peut être identique à `position`)

### 6. `job_description` (Description du poste)
- **Type** : `string` (text)
- **Longueur min** : 50 caractères
- **Exemple** : `"Responsable du développement d'applications web et mobiles, maintenance du code existant, participation aux réunions techniques."`
- **Description** : Description détaillée des responsabilités du poste

### 7. `gross_salary` (Salaire brut)
- **Type** : `decimal` ou `double`
- **Valeur min** : 0
- **Exemple** : `500000.00`
- **Description** : Salaire brut en FCFA

### 8. `net_salary` (Salaire net)
- **Type** : `decimal` ou `double`
- **Valeur min** : 0
- **Exemple** : `400000.00`
- **Description** : Salaire net après déductions (en FCFA)

### 9. `salary_currency` (Devise du salaire)
- **Type** : `string`
- **Longueur max** : 10 caractères
- **Exemple** : `"FCFA"`
- **Description** : Devise utilisée pour le salaire

### 10. `payment_frequency` (Fréquence de paiement)
- **Type** : `string` (enum)
- **Valeurs acceptées** :
  - `"monthly"` (Mensuel)
  - `"weekly"` (Hebdomadaire)
  - `"daily"` (Journalier)
  - `"hourly"` (Horaire)
- **Exemple** : `"monthly"`
- **Description** : Fréquence de paiement du salaire

### 11. `start_date` (Date de début)
- **Type** : `date` ou `datetime` (format ISO 8601)
- **Format accepté** :
  - `"2024-01-15"` (date simple)
  - `"2024-01-15T00:00:00Z"` (datetime ISO 8601)
- **Exemple** : `"2024-01-15T00:00:00Z"`
- **Description** : Date de début du contrat

### 12. `work_location` (Lieu de travail)
- **Type** : `string`
- **Longueur max** : 255 caractères
- **Exemple** : `"Abidjan, Cocody"`
- **Description** : Localisation du lieu de travail

### 13. `work_schedule` (Horaire de travail)
- **Type** : `string` (enum)
- **Valeurs acceptées** :
  - `"full_time"` (Temps plein)
  - `"part_time"` (Temps partiel)
  - `"flexible"` (Flexible)
- **Exemple** : `"full_time"`
- **Description** : Horaire de travail

### 14. `weekly_hours` (Heures hebdomadaires)
- **Type** : `integer`
- **Valeur min** : 1
- **Valeur max** : 168 (7 jours × 24 heures)
- **Exemple** : `40`
- **Description** : Nombre d'heures de travail par semaine

### 15. `probation_period` (Période d'essai)
- **Type** : `string` (enum)
- **Valeurs acceptées** :
  - `"none"` (Aucune)
  - `"1_month"` (1 mois)
  - `"3_months"` (3 mois)
  - `"6_months"` (6 mois)
- **Exemple** : `"3_months"`
- **Description** : Période d'essai

---

## Champs Optionnels

### 16. `end_date` (Date de fin)
- **Type** : `date` ou `datetime` (format ISO 8601)
- **Exemple** : `"2025-01-15T00:00:00Z"`
- **Description** : Date de fin du contrat
- **Validation** : 
  - **OBLIGATOIRE** si `contract_type` est `"fixed_term"` (CDD)
  - Doit être après `start_date`

### 17. `duration_months` (Durée en mois)
- **Type** : `integer`
- **Valeur min** : 1
- **Exemple** : `12`
- **Description** : Durée du contrat en mois (calculé automatiquement si `end_date` est fourni)

### 18. `notes` (Notes)
- **Type** : `string` (text, nullable)
- **Exemple** : `"Contrat renouvelable après évaluation"`
- **Description** : Notes additionnelles sur le contrat

### 19. `contract_template` (Modèle de contrat)
- **Type** : `string` (nullable)
- **Exemple** : `"CDI-Standard-2024"`
- **Description** : Référence au modèle de contrat utilisé

### 20. `clauses` (Clauses personnalisées)
- **Type** : `array` d'objets (nullable)
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
- **Types de clauses acceptés** :
  - `"standard"` : Clause standard
  - `"custom"` : Clause personnalisée
  - `"legal"` : Clause légale
  - `"benefit"` : Clause de bénéfices
- **Description** : Liste des clauses personnalisées à ajouter au contrat

---

## Champs Automatiques (Non requis - gérés par le backend)

Ces champs sont automatiquement remplis par le backend et ne doivent **PAS** être envoyés :

- `id` → Généré automatiquement
- `contract_number` → Généré automatiquement (format : `CTR-YYYYMMDD-XXXXXX`)
- `employee_name` → Récupéré depuis la table `employees`
- `employee_email` → Récupéré depuis la table `employees`
- `employee_phone` → Récupéré depuis la table `employees` (si disponible)
- `status` → Automatiquement défini à `"pending"` (en attente, directement soumis pour approbation)
- `reporting_manager` → Récupéré depuis la table `employees` (champ `manager`)
- `health_insurance` → À implémenter si nécessaire
- `retirement_plan` → À implémenter si nécessaire
- `vacation_days` → À calculer selon le type de contrat
- `other_benefits` → À implémenter si nécessaire
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

## Exemple pour CDD (Contrat à Durée Déterminée)

```json
{
  "employee_id": 2,
  "contract_type": "fixed_term",
  "position": "Commercial",
  "department": "Commercial",
  "job_title": "Commercial Junior",
  "job_description": "Prospection de nouveaux clients, gestion du portefeuille client existant, participation aux salons et événements commerciaux.",
  "gross_salary": 300000.00,
  "net_salary": 240000.00,
  "salary_currency": "FCFA",
  "payment_frequency": "monthly",
  "start_date": "2024-01-15T00:00:00Z",
  "end_date": "2024-12-31T23:59:59Z",
  "duration_months": 12,
  "work_location": "Abidjan, Plateau",
  "work_schedule": "full_time",
  "weekly_hours": 40,
  "probation_period": "3_months",
  "notes": "CDD renouvelable une fois"
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
    "health_insurance": null,
    "retirement_plan": null,
    "vacation_days": null,
    "other_benefits": null,
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
        "content": "L'employé s'engage à maintenir la confidentialité...",
        "type": "legal",
        "is_mandatory": true,
        "order": 1,
        "created_at": "2024-01-15T10:00:00Z",
        "updated_at": "2024-01-15T10:00:00Z"
      }
    ],
    "attachments": [],
    "history": []
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
    "end_date": ["The end date field is required when contract type is fixed_term."],
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
7. **CDD sans date de fin** : Si `contract_type` est `"fixed_term"`, `end_date` est **obligatoire**
8. **Devise manquante** : `salary_currency` est **obligatoire**

---

## Checklist Frontend

Avant d'envoyer la requête, vérifier :

- [ ] Tous les 15 champs obligatoires sont présents
- [ ] `position` : max 100 caractères
- [ ] `department` : max 100 caractères
- [ ] `job_title` : max 100 caractères
- [ ] `job_description` : minimum 50 caractères
- [ ] `gross_salary` : nombre positif
- [ ] `net_salary` : nombre positif (généralement < `gross_salary`)
- [ ] `salary_currency` : max 10 caractères (obligatoire)
- [ ] `payment_frequency` : une des valeurs (`monthly`, `weekly`, `daily`, `hourly`)
- [ ] `start_date` : date valide (format ISO 8601)
- [ ] `end_date` : 
  - Si `contract_type` est `"fixed_term"`, **OBLIGATOIRE**
  - Doit être après `start_date`
- [ ] `work_location` : max 255 caractères
- [ ] `work_schedule` : une des valeurs (`full_time`, `part_time`, `flexible`)
- [ ] `weekly_hours` : entre 1 et 168
- [ ] `probation_period` : une des valeurs (`none`, `1_month`, `3_months`, `6_months`)
- [ ] L'utilisateur est authentifié (token présent dans les headers)
- [ ] Content-Type : `application/json`

---

## Notes Importantes

1. **Statut initial** : Toute nouvelle demande est créée avec le statut `"pending"` (en attente), directement soumise pour approbation
2. **Approbation** : L'approbation se fait via `PUT /api/contracts/{id}/approve` (nécessite le rôle Patron ou Admin)
3. **Format de date** : Le format ISO 8601 avec timezone (`2024-01-15T00:00:00Z`) est recommandé
4. **Authentification** : L'endpoint nécessite une authentification valide (middleware `auth:sanctum` ou équivalent)
5. **Numéro de contrat** : Généré automatiquement au format `CTR-YYYYMMDD-XXXXXX` (ex: `CTR-20240115-000001`)
6. **CDD obligatoire** : Pour les contrats de type `"fixed_term"`, la date de fin (`end_date`) est **obligatoire**
7. **Clauses** : Les clauses peuvent être ajoutées lors de la création ou après via `POST /api/contracts/{id}/clauses`

