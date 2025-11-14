# Champs Nécessaires pour la Création d'un Contrat

## Vue d'ensemble

Ce document liste tous les champs que le frontend doit envoyer au backend pour créer un contrat via l'endpoint `POST /api/contracts`.

---

## Champs Obligatoires (Required)

| Champ | Type | Validation | Description | Exemple |
|-------|------|------------|-------------|---------|
| `employee_id` | `integer` | `required\|exists:employees,id` | ID de l'employé (doit exister dans la table `employees`) | `1` |
| `contract_type` | `string` | `required\|in:permanent,fixed_term,temporary,internship,consultant` | Type de contrat | `"permanent"` |
| `position` | `string` | `required\|string\|max:100` | Poste de l'employé (max 100 caractères) | `"Développeur Full Stack"` |
| `department` | `string` | `required\|string\|max:100` | Département (max 100 caractères) | `"Technique"` |
| `job_title` | `string` | `required\|string\|max:100` | Titre du poste (max 100 caractères) | `"Développeur Senior"` |
| `job_description` | `string` | `required\|string\|min:50` | Description du poste (min 50 caractères) | `"Responsable du développement..."` |
| `gross_salary` | `number` | `required\|numeric\|min:0` | Salaire brut (≥ 0) | `500000.00` |
| `net_salary` | `number` | `required\|numeric\|min:0` | Salaire net (≥ 0) | `400000.00` |
| `salary_currency` | `string` | `required\|string\|max:10` | Devise du salaire | `"FCFA"` |
| `payment_frequency` | `string` | `required\|in:monthly,weekly,daily,hourly` | Fréquence de paiement | `"monthly"` |
| `start_date` | `date` | `required\|date` | Date de début (format ISO 8601 ou YYYY-MM-DD) | `"2024-01-15T00:00:00Z"` |
| `work_location` | `string` | `required\|string\|max:255` | Lieu de travail (max 255 caractères) | `"Abidjan, Cocody"` |
| `work_schedule` | `string` | `required\|in:full_time,part_time,flexible` | Horaire de travail | `"full_time"` |
| `weekly_hours` | `integer` | `required\|integer\|min:1\|max:168` | Heures hebdomadaires (1-168) | `40` |
| `probation_period` | `string` | `required\|in:none,1_month,3_months,6_months` | Période d'essai | `"3_months"` |

---

## Champs Optionnels

| Champ | Type | Validation | Description | Exemple |
|-------|------|------------|-------------|---------|
| `end_date` | `date` | `nullable\|date\|after:start_date\|required_if:contract_type,fixed_term` | Date de fin (obligatoire si `contract_type` = `fixed_term`) | `"2025-01-15T00:00:00Z"` |
| `duration_months` | `integer` | `nullable\|integer\|min:1` | Durée en mois | `12` |
| `notes` | `string` | `nullable\|string` | Notes additionnelles | `"Contrat renouvelable..."` |
| `contract_template` | `string` | `nullable\|string\|max:255` | Référence au modèle de contrat | `"CDI-Standard-2024"` |
| `clauses` | `array` | `nullable\|array` | Tableau de clauses personnalisées | Voir structure ci-dessous |

---

## Structure des Clauses

Si le champ `clauses` est fourni, chaque élément du tableau doit avoir cette structure :

```json
{
  "title": "string",           // Optionnel, défaut: ""
  "content": "string",         // Optionnel, défaut: ""
  "type": "string",            // Optionnel, défaut: "standard"
                              // Valeurs possibles: "standard", "custom", "legal", "benefit"
  "is_mandatory": "boolean",   // Optionnel, défaut: false
  "order": "integer"           // Optionnel, défaut: 1
}
```

### Exemple de clauses

```json
"clauses": [
  {
    "title": "Clause de confidentialité",
    "content": "L'employé s'engage à maintenir la confidentialité des informations de l'entreprise.",
    "type": "legal",
    "is_mandatory": true,
    "order": 1
  },
  {
    "title": "Clause de non-concurrence",
    "content": "L'employé s'engage à ne pas travailler pour un concurrent pendant 2 ans après la fin du contrat.",
    "type": "legal",
    "is_mandatory": false,
    "order": 2
  }
]
```

---

## Valeurs Acceptées pour les Enums

### `contract_type`
- `"permanent"` - CDI (Contrat à Durée Indéterminée)
- `"fixed_term"` - CDD (Contrat à Durée Déterminée)
- `"temporary"` - Intérim
- `"internship"` - Stage
- `"consultant"` - Consultant

### `payment_frequency`
- `"monthly"` - Mensuel
- `"weekly"` - Hebdomadaire
- `"daily"` - Journalier
- `"hourly"` - Horaire

### `work_schedule`
- `"full_time"` - Temps plein
- `"part_time"` - Temps partiel
- `"flexible"` - Flexible

### `probation_period`
- `"none"` - Aucune
- `"1_month"` - 1 mois
- `"3_months"` - 3 mois
- `"6_months"` - 6 mois

### `clause.type` (si clauses fournies)
- `"standard"` - Clause standard
- `"custom"` - Clause personnalisée
- `"legal"` - Clause légale
- `"benefit"` - Clause de bénéfices

---

## Exemple de Requête JSON Complète

### Exemple 1 : Contrat CDI (permanent)

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

### Exemple 2 : Contrat CDD (fixed_term)

```json
{
  "employee_id": 2,
  "contract_type": "fixed_term",
  "position": "Designer UI/UX",
  "department": "Design",
  "job_title": "Designer Senior",
  "job_description": "Création d'interfaces utilisateur modernes et intuitives. Collaboration avec l'équipe de développement pour assurer la cohérence visuelle des applications.",
  "gross_salary": 400000.00,
  "net_salary": 320000.00,
  "salary_currency": "FCFA",
  "payment_frequency": "monthly",
  "start_date": "2024-02-01T00:00:00Z",
  "end_date": "2025-01-31T23:59:59Z",
  "duration_months": 12,
  "work_location": "Abidjan, Plateau",
  "work_schedule": "full_time",
  "weekly_hours": 40,
  "probation_period": "1_month",
  "notes": "Contrat CDD de 12 mois",
  "contract_template": null,
  "clauses": []
}
```

### Exemple 3 : Contrat Stage (internship)

```json
{
  "employee_id": 3,
  "contract_type": "internship",
  "position": "Stagiaire Développement",
  "department": "Technique",
  "job_title": "Stagiaire",
  "job_description": "Stage de 6 mois pour apprendre les technologies de développement web et mobile. Participation aux projets de l'équipe sous supervision.",
  "gross_salary": 100000.00,
  "net_salary": 100000.00,
  "salary_currency": "FCFA",
  "payment_frequency": "monthly",
  "start_date": "2024-03-01T00:00:00Z",
  "end_date": "2024-08-31T23:59:59Z",
  "duration_months": 6,
  "work_location": "Abidjan, Cocody",
  "work_schedule": "full_time",
  "weekly_hours": 35,
  "probation_period": "none",
  "notes": "Stage académique",
  "contract_template": null,
  "clauses": []
}
```

---

## Règles de Validation Importantes

### 1. Date de fin (`end_date`)
- **Obligatoire** si `contract_type` = `"fixed_term"`
- **Optionnel** pour les autres types de contrats
- **Doit être après** `start_date`

### 2. Description du poste (`job_description`)
- **Minimum 50 caractères** requis
- Doit être une description détaillée des responsabilités

### 3. Heures hebdomadaires (`weekly_hours`)
- **Minimum** : 1 heure
- **Maximum** : 168 heures (7 jours × 24 heures)

### 4. Salaires
- `gross_salary` et `net_salary` doivent être **≥ 0**
- Généralement, `net_salary` < `gross_salary` (après déductions)

### 5. Employé
- `employee_id` **doit exister** dans la table `employees`
- L'employé sera automatiquement chargé pour remplir `employee_name` et `employee_email`

---

## Champs Générés Automatiquement

Ces champs sont gérés par le backend et **ne doivent PAS être envoyés** :

| Champ | Description |
|-------|-------------|
| `id` | Généré automatiquement |
| `contract_number` | Généré automatiquement (format: `CTR-YYYYMMDD-XXXXXX`) |
| `employee_name` | Récupéré depuis la table `employees` |
| `employee_email` | Récupéré depuis la table `employees` |
| `status` | Automatiquement défini à `"pending"` |
| `created_by` | Récupéré depuis l'utilisateur authentifié |
| `created_at` | Timestamp automatique |
| `updated_at` | Timestamp automatique |

---

## Format de Date Recommandé

Utiliser le format **ISO 8601** :

- **Format complet** : `"2024-01-15T00:00:00Z"` (datetime avec timezone)
- **Format date simple** : `"2024-01-15"` (accepté aussi)

### Exemples de dates valides

```json
"start_date": "2024-01-15T00:00:00Z"
"start_date": "2024-01-15T10:30:00Z"
"start_date": "2024-01-15"
"end_date": "2025-01-15T23:59:59Z"
```

---

## Endpoint

**POST** `/api/contracts`

### Headers Requis

```
Authorization: Bearer {token}
Content-Type: application/json
```

### Réponse de Succès (201 Created)

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
    "reporting_manager": null,
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

### Erreurs de Validation Possibles (422)

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

---

## Checklist de Validation Frontend

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
3. **Format de date** : Le format ISO 8601 avec timezone (`2024-01-15T00:00:00Z`) est recommandé
4. **Authentification** : Tous les endpoints nécessitent une authentification valide (middleware `auth:sanctum` ou équivalent)
5. **Numéro de contrat** : Généré automatiquement au format `CTR-YYYYMMDD-XXXXXX` (ex: `CTR-20240115-000001`)
6. **Historique** : Toutes les actions (création, approbation, rejet, résiliation, annulation) sont enregistrées dans l'historique du contrat
7. **CDD obligatoire** : Pour les contrats de type `"fixed_term"`, la date de fin (`end_date`) est obligatoire
8. **Modification** : Seuls les contrats avec le statut `"pending"` peuvent être modifiés
9. **Suppression** : Seuls les contrats avec le statut `"pending"` ou `"cancelled"` peuvent être supprimés

---

## Exemple de Code Flutter/Dart

```dart
Future<Map<String, dynamic>> createContract({
  required int employeeId,
  required String contractType,
  required String position,
  required String department,
  required String jobTitle,
  required String jobDescription,
  required double grossSalary,
  required double netSalary,
  required String salaryCurrency,
  required String paymentFrequency,
  required DateTime startDate,
  DateTime? endDate,
  int? durationMonths,
  required String workLocation,
  required String workSchedule,
  required int weeklyHours,
  required String probationPeriod,
  String? notes,
  String? contractTemplate,
  List<Map<String, dynamic>>? clauses,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/contracts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'employee_id': employeeId,
        'contract_type': contractType,
        'position': position,
        'department': department,
        'job_title': jobTitle,
        'job_description': jobDescription,
        'gross_salary': grossSalary,
        'net_salary': netSalary,
        'salary_currency': salaryCurrency,
        'payment_frequency': paymentFrequency,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'duration_months': durationMonths,
        'work_location': workLocation,
        'work_schedule': workSchedule,
        'weekly_hours': weeklyHours,
        'probation_period': probationPeriod,
        'notes': notes,
        'contract_template': contractTemplate,
        'clauses': clauses,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Erreur lors de la création: ${response.statusCode}');
    }
  } catch (e) {
    rethrow;
  }
}
```

---

## Conclusion

Ce document fournit toutes les informations nécessaires pour implémenter la création de contrats côté frontend. Assurez-vous de :

1. Valider tous les champs avant l'envoi
2. Gérer les erreurs de validation (422)
3. Afficher les messages d'erreur appropriés
4. Respecter les contraintes spécifiques (end_date pour fixed_term, etc.)
5. Utiliser le format ISO 8601 pour les dates

Pour toute question ou clarification, référez-vous aux exemples de requêtes et réponses fournis dans ce document.

