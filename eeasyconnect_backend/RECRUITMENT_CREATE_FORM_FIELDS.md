# Champs Requis pour Créer une Demande de Recrutement

## Endpoint
**POST** `/api/recruitment-requests`

## Authentification
L'utilisateur doit être authentifié (le `created_by` sera automatiquement rempli avec l'ID de l'utilisateur connecté).

---

## Champs Obligatoires (Required)

### 1. `title` (Titre de l'offre)
- **Type** : `string`
- **Longueur max** : 255 caractères
- **Exemple** : `"Développeur Full Stack"`
- **Description** : Titre de l'offre d'emploi

### 2. `department` (Département)
- **Type** : `string`
- **Longueur max** : 100 caractères
- **Exemple** : `"Technique"` ou `"Ressources Humaines"`
- **Description** : Département concerné par le recrutement

### 3. `position` (Poste)
- **Type** : `string`
- **Longueur max** : 100 caractères
- **Exemple** : `"Développeur"` ou `"Chef de projet"`
- **Description** : Poste à pourvoir

### 4. `description` (Description)
- **Type** : `string` (text)
- **Longueur min** : 50 caractères
- **Exemple** : `"Nous recherchons un développeur full stack expérimenté pour rejoindre notre équipe technique. Le candidat sera responsable du développement et de la maintenance d'applications web modernes."`
- **Description** : Description détaillée du poste

### 5. `requirements` (Exigences)
- **Type** : `string` (text)
- **Longueur min** : 20 caractères
- **Exemple** : `"Bac+3 minimum en informatique, 2-5 ans d'expérience en développement web, maîtrise de PHP/Laravel et JavaScript/React"`
- **Description** : Exigences et compétences requises

### 6. `responsibilities` (Responsabilités)
- **Type** : `string` (text)
- **Longueur min** : 20 caractères
- **Exemple** : `"Développement d'applications web, maintenance du code existant, participation aux réunions d'équipe, documentation technique"`
- **Description** : Responsabilités du poste

### 7. `number_of_positions` (Nombre de postes)
- **Type** : `integer`
- **Valeur min** : 1
- **Valeur max** : 100
- **Exemple** : `2`
- **Description** : Nombre de postes à pourvoir

### 8. `employment_type` (Type d'emploi)
- **Type** : `string` (enum)
- **Valeurs acceptées** :
  - `"full_time"` (Temps plein)
  - `"part_time"` (Temps partiel)
  - `"contract"` (Contrat)
  - `"internship"` (Stage)
- **Exemple** : `"full_time"`
- **Description** : Type de contrat proposé

### 9. `experience_level` (Niveau d'expérience)
- **Type** : `string` (enum)
- **Valeurs acceptées** :
  - `"entry"` (Débutant)
  - `"junior"` (Junior - 0-2 ans)
  - `"mid"` (Intermédiaire - 2-5 ans)
  - `"senior"` (Senior - 5-10 ans)
  - `"expert"` (Expert - 10+ ans)
- **Exemple** : `"mid"`
- **Description** : Niveau d'expérience requis

### 10. `salary_range` (Fourchette salariale)
- **Type** : `string`
- **Longueur max** : 100 caractères
- **Exemple** : `"500000 - 800000 FCFA"` ou `"120 000 - 200 000 FCFA"`
- **Description** : Fourchette salariale proposée

### 11. `location` (Localisation)
- **Type** : `string`
- **Longueur max** : 255 caractères
- **Exemple** : `"Abidjan, Cocody"` ou `"Abidjan"`
- **Description** : Localisation du poste

### 12. `application_deadline` (Date limite de candidature)
- **Type** : `date` ou `datetime` (format ISO 8601)
- **Contrainte** : Doit être dans le futur (après maintenant)
- **Format accepté** : 
  - `"2024-12-31"` (date simple)
  - `"2024-12-31T23:59:59Z"` (datetime ISO 8601)
  - `"2024-12-31 23:59:59"` (datetime standard)
- **Exemple** : `"2024-12-31T23:59:59Z"`
- **Description** : Date limite pour postuler

---

## Champs Automatiques (Non requis - gérés par le backend)

Ces champs sont automatiquement remplis par le backend et ne doivent **PAS** être envoyés :

- `status` → Automatiquement défini à `"draft"` (brouillon)
- `created_by` → Automatiquement rempli avec l'ID de l'utilisateur authentifié
- `published_at` → `null` (sera rempli lors de la publication)
- `published_by` → `null` (sera rempli lors de la publication)
- `approved_at` → `null` (sera rempli lors de l'approbation)
- `approved_by` → `null` (sera rempli lors de l'approbation)
- `rejection_reason` → `null` (sera rempli en cas de rejet)

---

## Exemple de Requête JSON Complète

```json
{
  "title": "Développeur Full Stack",
  "department": "Technique",
  "position": "Développeur",
  "description": "Nous recherchons un développeur full stack expérimenté pour rejoindre notre équipe technique. Le candidat sera responsable du développement et de la maintenance d'applications web modernes utilisant les dernières technologies.",
  "requirements": "Bac+3 minimum en informatique, 2-5 ans d'expérience en développement web, maîtrise de PHP/Laravel et JavaScript/React, connaissance de Git et des bonnes pratiques de développement.",
  "responsibilities": "Développement d'applications web, maintenance du code existant, participation aux réunions d'équipe, documentation technique, collaboration avec les autres développeurs.",
  "number_of_positions": 2,
  "employment_type": "full_time",
  "experience_level": "mid",
  "salary_range": "500000 - 800000 FCFA",
  "location": "Abidjan, Cocody",
  "application_deadline": "2024-12-31T23:59:59Z"
}
```

---

## Exemple de Requête Flutter/Dart

```dart
final response = await http.post(
  Uri.parse('$baseUrl/api/recruitment-requests'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body: jsonEncode({
    'title': 'Développeur Full Stack',
    'department': 'Technique',
    'position': 'Développeur',
    'description': 'Nous recherchons un développeur full stack expérimenté...',
    'requirements': 'Bac+3 minimum, 2-5 ans d\'expérience...',
    'responsibilities': 'Développement d\'applications web...',
    'number_of_positions': 2,
    'employment_type': 'full_time',
    'experience_level': 'mid',
    'salary_range': '500000 - 800000 FCFA',
    'location': 'Abidjan, Cocody',
    'application_deadline': '2024-12-31T23:59:59Z',
  }),
);
```

---

## Réponse de Succès (201 Created)

```json
{
  "success": true,
  "message": "Demande de recrutement créée avec succès",
  "data": {
    "id": 1,
    "title": "Développeur Full Stack",
    "department": "Technique",
    "position": "Développeur",
    "description": "...",
    "requirements": "...",
    "responsibilities": "...",
    "number_of_positions": 2,
    "employment_type": "full_time",
    "experience_level": "mid",
    "salary_range": "500000 - 800000 FCFA",
    "location": "Abidjan, Cocody",
    "application_deadline": "2024-12-31T23:59:59Z",
    "status": "draft",
    "rejection_reason": null,
    "published_at": null,
    "published_by": null,
    "published_by_name": null,
    "approved_at": null,
    "approved_by": null,
    "approved_by_name": null,
    "created_at": "2024-01-15T10:00:00Z",
    "updated_at": "2024-01-15T10:00:00Z",
    "applications": []
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
    "title": ["The title field is required."],
    "description": ["The description must be at least 50 characters."],
    "application_deadline": ["The application deadline must be a date after now."],
    "employment_type": ["The selected employment type is invalid."]
  }
}
```

### Erreurs Communes

1. **Champ manquant** : Tous les champs sont obligatoires
2. **Description trop courte** : Minimum 50 caractères
3. **Requirements/Responsibilities trop courts** : Minimum 20 caractères chacun
4. **Date dans le passé** : `application_deadline` doit être dans le futur
5. **Valeur enum invalide** : `employment_type` et `experience_level` doivent correspondre aux valeurs acceptées
6. **Nombre de postes invalide** : Entre 1 et 100

---

## Checklist Frontend

Avant d'envoyer la requête, vérifier :

- [ ] Tous les 12 champs obligatoires sont présents
- [ ] `title` : max 255 caractères
- [ ] `department` : max 100 caractères
- [ ] `position` : max 100 caractères
- [ ] `description` : minimum 50 caractères
- [ ] `requirements` : minimum 20 caractères
- [ ] `responsibilities` : minimum 20 caractères
- [ ] `number_of_positions` : entier entre 1 et 100
- [ ] `employment_type` : une des valeurs (`full_time`, `part_time`, `contract`, `internship`)
- [ ] `experience_level` : une des valeurs (`entry`, `junior`, `mid`, `senior`, `expert`)
- [ ] `salary_range` : max 100 caractères
- [ ] `location` : max 255 caractères
- [ ] `application_deadline` : date dans le futur (format ISO 8601 recommandé)
- [ ] L'utilisateur est authentifié (token présent dans les headers)
- [ ] Content-Type : `application/json`

---

## Notes Importantes

1. **Statut initial** : Toute nouvelle demande est créée avec le statut `"draft"` (brouillon)
2. **Publication** : Pour publier la demande, utiliser l'endpoint `POST /api/recruitment-requests/{id}/publish`
3. **Approbation** : L'approbation se fait via `POST /api/recruitment-requests/{id}/approve` (nécessite le rôle Patron)
4. **Format de date** : Le format ISO 8601 avec timezone (`2024-12-31T23:59:59Z`) est recommandé
5. **Authentification** : L'endpoint nécessite une authentification valide (middleware `auth:sanctum` ou équivalent)

