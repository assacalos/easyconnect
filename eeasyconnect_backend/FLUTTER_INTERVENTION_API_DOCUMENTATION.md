# Documentation API Interventions - Format Flutter

## 📋 Champs Requis pour Créer une Intervention

Flutter doit envoyer les données suivantes à l'endpoint `POST /api/interventions-create` :

### ✅ Champs OBLIGATOIRES (Minimum requis)

| Champ Flutter | Type | Format | Description | Exemple |
|--------------|------|--------|-------------|---------|
| `title` | string | - | Titre de l'intervention | `"Réparation climatiseur"` |
| `description` | string | TEXT | Description détaillée de l'intervention | `"Réparation du climatiseur de la salle de réunion"` |
| `type` | string | enum | Type d'intervention | `"external"`, `"on_site"` |
| `priority` | string | enum | Priorité | `"low"`, `"medium"`, `"high"`, `"urgent"` |
| `scheduledDate` ou `scheduled_date` | string | datetime | Date et heure planifiées | `"2024-11-05 14:00:00"` |

### ⚪ Champs OPTIONNELS

| Champ Flutter | Type | Format | Description | Exemple |
|--------------|------|--------|-------------|---------|
| `location` | string | - | Lieu/Adresse de l'intervention | `"123 Rue Principale, Douala"` |
| `clientName` ou `client_name` | string | - | Nom du client | `"Entreprise ABC"` |
| `clientPhone` ou `client_phone` | string | - | Téléphone du client | `"+237 123 456 789"` |
| `clientEmail` ou `client_email` | string | email | Email du client | `"contact@abc.com"` |
| `equipment` | string | - | Équipement concerné | `"Climatiseur Daikin 3kW"` |
| `problemDescription` ou `problem_description` | string | TEXT | Description du problème | `"Le climatiseur ne s'allume plus"` |
| `estimatedDuration` ou `estimated_duration` | double/float | heures | Durée estimée (en heures) | `2.5` |
| `cost` | double/float | - | Coût estimé (en FCFA) | `50000.0` |
| `notes` | string | TEXT | Notes internes | `"Prévoir pièce de rechange"` |
| `attachments` | array | JSON | Pièces jointes (chemins de fichiers) | `["/uploads/file1.pdf"]` |

---

## 📤 Format JSON à Envoyer (Exemple)

### Format Minimal (Requis uniquement)

```json
{
  "title": "Réparation climatiseur",
  "description": "Réparation du climatiseur de la salle de réunion",
  "type": "external",
  "priority": "high",
  "scheduledDate": "2024-11-05 14:00:00"
}
```

### Format Complet (Avec tous les champs)

```json
{
  "title": "Réparation climatiseur",
  "description": "Réparation du climatiseur de la salle de réunion",
  "type": "external",
  "priority": "high",
  "scheduledDate": "2024-11-05 14:00:00",
  "location": "123 Rue Principale, Douala",
  "clientName": "Entreprise ABC",
  "clientPhone": "+237 123 456 789",
  "clientEmail": "contact@abc.com",
  "equipment": "Climatiseur Daikin 3kW",
  "problemDescription": "Le climatiseur ne s'allume plus, aucun voyant ne s'allume",
  "estimatedDuration": 2.5,
  "cost": 50000.0,
  "notes": "Prévoir pièce de rechange et vérifier la garantie",
  "attachments": ["/uploads/schema.pdf"]
}
```

### Format avec snake_case (Alternative)

```json
{
  "title": "Réparation climatiseur",
  "description": "Réparation du climatiseur de la salle de réunion",
  "type": "external",
  "priority": "high",
  "scheduled_date": "2024-11-05 14:00:00",
  "location": "123 Rue Principale, Douala",
  "client_name": "Entreprise ABC",
  "client_phone": "+237 123 456 789",
  "client_email": "contact@abc.com",
  "equipment": "Climatiseur Daikin 3kW",
  "problem_description": "Le climatiseur ne s'allume plus",
  "estimated_duration": 2.5,
  "cost": 50000.0,
  "notes": "Prévoir pièce de rechange",
  "attachments": ["/uploads/schema.pdf"]
}
```

---

## 🔄 Normalisation Automatique du Backend

Le backend accepte les champs en camelCase et snake_case. Vous pouvez utiliser l'un ou l'autre :

- `scheduledDate` ou `scheduled_date` → `scheduled_date`
- `clientName` ou `client_name` → `client_name`
- `clientPhone` ou `client_phone` → `client_phone`
- `clientEmail` ou `client_email` → `client_email`
- `problemDescription` ou `problem_description` → `problem_description`
- `estimatedDuration` ou `estimated_duration` → `estimated_duration`

---

## 📥 Format de Réponse (Success)

### Status Code : `201 Created`

```json
{
  "success": true,
  "message": "Intervention créée avec succès",
  "data": {
    "id": 1,
    "title": "Réparation climatiseur",
    "description": "Réparation du climatiseur de la salle de réunion",
    "type": "external",
    "type_libelle": "Externe",
    "status": "pending",
    "status_libelle": "En attente",
    "priority": "high",
    "priority_libelle": "Élevée",
    "scheduled_date": "2024-11-05 14:00:00",
    "start_date": null,
    "end_date": null,
    "location": "123 Rue Principale, Douala",
    "client_name": "Entreprise ABC",
    "client_phone": "+237 123 456 789",
    "client_email": "contact@abc.com",
    "equipment": "Climatiseur Daikin 3kW",
    "problem_description": "Le climatiseur ne s'allume plus",
    "solution": null,
    "notes": "Prévoir pièce de rechange",
    "attachments": ["/uploads/schema.pdf"],
    "estimated_duration": 2.5,
    "actual_duration": null,
    "calculated_duration": null,
    "cost": 50000.0,
    "formatted_cost": "50 000,00 €",
    "formatted_estimated_duration": "2.5h",
    "formatted_actual_duration": "N/A",
    "created_by": 1,
    "creator_name": "Jean Dupont",
    "approved_by": null,
    "approver_name": "N/A",
    "approved_at": null,
    "rejection_reason": null,
    "completion_notes": null,
    "is_overdue": false,
    "is_due_soon": false,
    "can_be_edited": true,
    "can_be_approved": true,
    "can_be_rejected": true,
    "can_be_started": false,
    "can_be_completed": false,
    "created_at": "2024-11-02 16:00:00",
    "updated_at": "2024-11-02 16:00:00"
  }
}
```

---

## 📊 Statuts des Interventions

Les statuts possibles pour une intervention sont :

| Status Backend | Status Flutter (Recommandé) | Description |
|----------------|----------------------------|-------------|
| `pending` | `pending` | En attente d'approbation (statut par défaut à la création) |
| `approved` | `approved` | Approuvée - Prête à être démarrée |
| `in_progress` | `inProgress` ou `in_progress` | En cours - Intervention démarrée |
| `completed` | `completed` | Terminée - Intervention finalisée |
| `rejected` | `rejected` | Rejetée - Intervention refusée |

**Note importante :** Une intervention peut seulement être démarrée si elle est approuvée (`approved`).

---

## 📊 Types d'Interventions

Les types possibles sont :

| Type Backend | Type Flutter | Description |
|--------------|--------------|-------------|
| `external` | `external` | Intervention externe (chez le client) |
| `on_site` | `onSite` ou `on_site` | Intervention sur place (dans les locaux) |

---

## 📊 Priorités

Les priorités possibles sont :

| Priorité Backend | Priorité Flutter | Description |
|------------------|------------------|-------------|
| `low` | `low` | Faible |
| `medium` | `medium` | Moyenne (par défaut) |
| `high` | `high` | Élevée |
| `urgent` | `urgent` | Urgente |

---

## 🔍 Validation des Champs

### `title`
- **Requis** : Oui
- **Type** : String
- **Max** : 255 caractères
- **Description** : Titre court de l'intervention
- **Exemple** : `"Réparation climatiseur"`, `"Maintenance préventive serveur"`

### `description`
- **Requis** : Oui
- **Type** : String (TEXT)
- **Description** : Description détaillée de l'intervention
- **Exemple** : `"Réparation du climatiseur de la salle de réunion, diagnostic complet nécessaire"`

### `type`
- **Requis** : Oui
- **Type** : String (enum)
- **Valeurs** : `"external"`, `"on_site"`
- **Description** : Type d'intervention
- **Exemple** : `"external"` pour une intervention chez le client
- **Note** : Utilisez `/api/intervention-types` pour obtenir la liste des types

### `priority`
- **Requis** : Oui
- **Type** : String (enum)
- **Valeurs** : `"low"`, `"medium"`, `"high"`, `"urgent"`
- **Description** : Niveau de priorité
- **Exemple** : `"high"` pour une intervention urgente

### `scheduledDate` / `scheduled_date`
- **Requis** : Oui
- **Type** : String (datetime)
- **Format** : `"YYYY-MM-DD HH:mm:ss"` ou `"YYYY-MM-DDTHH:mm:ss"`
- **Règle** : Doit être dans le futur (`after:now`)
- **Description** : Date et heure planifiées pour l'intervention
- **Exemple** : `"2024-11-05 14:00:00"` ou `"2024-11-05T14:00:00"`

### `location`
- **Requis** : Non
- **Type** : String
- **Max** : 255 caractères
- **Description** : Adresse/Lieu de l'intervention
- **Exemple** : `"123 Rue Principale, Douala"`, `"Salle de réunion - Bâtiment A"`

### `clientName` / `client_name`
- **Requis** : Non
- **Type** : String
- **Max** : 255 caractères
- **Description** : Nom du client
- **Exemple** : `"Entreprise ABC"`

### `clientPhone` / `client_phone`
- **Requis** : Non
- **Type** : String
- **Max** : 20 caractères
- **Description** : Téléphone du client
- **Exemple** : `"+237 123 456 789"`

### `clientEmail` / `client_email`
- **Requis** : Non
- **Type** : String (email)
- **Max** : 255 caractères
- **Description** : Email du client
- **Exemple** : `"contact@abc.com"`

### `equipment`
- **Requis** : Non
- **Type** : String
- **Max** : 255 caractères
- **Description** : Équipement concerné par l'intervention
- **Exemple** : `"Climatiseur Daikin 3kW"`, `"Serveur HP ProLiant"`

### `problemDescription` / `problem_description`
- **Requis** : Non
- **Type** : String (TEXT)
- **Description** : Description détaillée du problème
- **Exemple** : `"Le climatiseur ne s'allume plus, aucun voyant ne s'allume. Vérifier l'alimentation électrique."`

### `estimatedDuration` / `estimated_duration`
- **Requis** : Non
- **Type** : Nombre (double/float)
- **Min** : 0
- **Précision** : 2 décimales
- **Description** : Durée estimée en heures
- **Exemple** : `2.5` (2 heures 30 minutes), `4.0` (4 heures)

### `cost`
- **Requis** : Non
- **Type** : Nombre (double/float)
- **Min** : 0
- **Précision** : 2 décimales
- **Description** : Coût estimé de l'intervention (en FCFA)
- **Exemple** : `50000.0`, `125000.50`

### `notes`
- **Requis** : Non
- **Type** : String (TEXT)
- **Description** : Notes internes
- **Exemple** : `"Prévoir pièce de rechange et vérifier la garantie"`

### `attachments`
- **Requis** : Non
- **Type** : Array (JSON)
- **Description** : Liste des chemins de fichiers attachés
- **Exemple** : `["/uploads/schema.pdf", "/uploads/image.jpg"]`

---

## 📝 Exemples de Code Flutter

### Exemple 1 : Création Simple

```dart
final intervention = Intervention(
  title: "Réparation climatiseur",
  description: "Réparation du climatiseur de la salle de réunion",
  type: "external",
  priority: "high",
  scheduledDate: "2024-11-05 14:00:00",
);

final result = await interventionService.createIntervention(intervention);
```

### Exemple 2 : Création avec Tous les Champs

```dart
final intervention = Intervention(
  title: "Réparation climatiseur",
  description: "Réparation du climatiseur de la salle de réunion",
  type: "external",
  priority: "high",
  scheduledDate: "2024-11-05 14:00:00",
  location: "123 Rue Principale, Douala",
  clientName: "Entreprise ABC",
  clientPhone: "+237 123 456 789",
  clientEmail: "contact@abc.com",
  equipment: "Climatiseur Daikin 3kW",
  problemDescription: "Le climatiseur ne s'allume plus",
  estimatedDuration: 2.5,
  cost: 50000.0,
  notes: "Prévoir pièce de rechange",
  attachments: ["/uploads/schema.pdf"],
);

final result = await interventionService.createIntervention(intervention);
```

### Exemple 3 : Envoi Direct via HTTP

```dart
final response = await http.post(
  Uri.parse('$baseUrl/interventions-create'),
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body: json.encode({
    'title': 'Réparation climatiseur',
    'description': 'Réparation du climatiseur de la salle de réunion',
    'type': 'external',
    'priority': 'high',
    'scheduledDate': '2024-11-05 14:00:00',
    'location': '123 Rue Principale, Douala',
    'clientName': 'Entreprise ABC',
  }),
);
```

---

## 🔗 Endpoints Disponibles

### CRUD de Base

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/interventions-list` | Liste des interventions (avec pagination et filtres) |
| `GET` | `/api/interventions-show/{id}` | Détails d'une intervention |
| `POST` | `/api/interventions-create` | Créer une nouvelle intervention |
| `PUT` | `/api/interventions/{id}` | Mettre à jour une intervention |
| `DELETE` | `/api/interventions-destroy/{id}` | Supprimer une intervention |

### Actions sur les Interventions

| Méthode | Endpoint | Description | Body Requis |
|---------|----------|-------------|-------------|
| `POST` | `/api/interventions-approve/{id}` | Approuver une intervention | `{"notes": "..."}` (optionnel) |
| `POST` | `/api/interventions-reject/{id}` | Rejeter une intervention | `{"rejection_reason": "..."}` |
| `POST` | `/api/interventions/{id}/start` | Démarrer une intervention | `{}` |
| `POST` | `/api/interventions/{id}/complete` | Terminer une intervention | `{"completion_notes": "...", "actual_duration": 2.5, "cost": 50000.0}` (tous optionnels) |

### Utilitaires

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/interventions-statistics` | Statistiques des interventions |
| `GET` | `/api/interventions-overdue` | Interventions en retard |
| `GET` | `/api/interventions-due-soon` | Interventions dues bientôt (dans 2h) |
| `GET` | `/api/intervention-types` | Liste des types d'interventions |
| `GET` | `/api/equipment` | Liste des équipements disponibles |

---

## 📊 Format de Réponse - Liste des Interventions

### GET `/api/interventions-list`

```json
{
  "success": true,
  "message": "Liste des interventions récupérée avec succès",
  "data": {
    "data": [
      {
        "id": 1,
        "title": "Réparation climatiseur",
        "description": "Réparation du climatiseur de la salle de réunion",
        "type": "external",
        "type_libelle": "Externe",
        "status": "pending",
        "status_libelle": "En attente",
        "priority": "high",
        "priority_libelle": "Élevée",
        "scheduled_date": "2024-11-05 14:00:00",
        "start_date": null,
        "end_date": null,
        "location": "123 Rue Principale, Douala",
        "client_name": "Entreprise ABC",
        "client_phone": "+237 123 456 789",
        "client_email": "contact@abc.com",
        "equipment": "Climatiseur Daikin 3kW",
        "problem_description": "Le climatiseur ne s'allume plus",
        "solution": null,
        "notes": "Prévoir pièce de rechange",
        "attachments": ["/uploads/schema.pdf"],
        "estimated_duration": 2.5,
        "actual_duration": null,
        "calculated_duration": null,
        "cost": 50000.0,
        "formatted_cost": "50 000,00 €",
        "formatted_estimated_duration": "2.5h",
        "formatted_actual_duration": "N/A",
        "created_by": 1,
        "creator_name": "Jean Dupont",
        "approved_by": null,
        "approver_name": "N/A",
        "approved_at": null,
        "rejection_reason": null,
        "completion_notes": null,
        "is_overdue": false,
        "is_due_soon": false,
        "can_be_edited": true,
        "can_be_approved": true,
        "can_be_rejected": true,
        "can_be_started": false,
        "can_be_completed": false,
        "created_at": "2024-11-02 16:00:00",
        "updated_at": "2024-11-02 16:00:00"
      }
    ],
    "current_page": 1,
    "last_page": 10,
    "per_page": 15,
    "total": 150,
    "from": 1,
    "to": 15
  }
}
```

### Filtres Disponibles

| Paramètre | Type | Description | Exemple |
|-----------|------|-------------|---------|
| `status` | string | Filtrer par statut | `?status=pending` |
| `type` | string | Filtrer par type | `?type=external` |
| `priority` | string | Filtrer par priorité | `?priority=high` |
| `created_by` | int | Filtrer par créateur | `?created_by=1` |
| `date_debut` | date | Date de début | `?date_debut=2024-11-01` |
| `date_fin` | date | Date de fin | `?date_fin=2024-11-30` |
| `location` | string | Recherche par lieu | `?location=Douala` |
| `per_page` | int | Nombre d'éléments par page | `?per_page=20` |

---

## 📊 Format de Réponse - Statistiques

### GET `/api/interventions-statistics`

```json
{
  "success": true,
  "data": {
    "total_interventions": 150,
    "pending_interventions": 20,
    "approved_interventions": 30,
    "in_progress_interventions": 15,
    "completed_interventions": 80,
    "rejected_interventions": 5,
    "external_interventions": 100,
    "on_site_interventions": 50,
    "average_duration": 2.5,
    "total_cost": 7500000.0,
    "interventions_by_month": {
      "2024-11": 25,
      "2024-10": 30,
      "2024-09": 20
    },
    "interventions_by_priority": {
      "low": 30,
      "medium": 60,
      "high": 40,
      "urgent": 20
    }
  },
  "message": "Statistiques récupérées avec succès"
}
```

---

## 📊 Format de Réponse - Types d'Interventions

### GET `/api/intervention-types`

```json
{
  "success": true,
  "data": [
    {
      "value": "external",
      "label": "Externe",
      "icon": "location_on",
      "color": "#3B82F6"
    },
    {
      "value": "on_site",
      "label": "Sur place",
      "icon": "home",
      "color": "#10B981"
    }
  ],
  "message": "Types d'interventions récupérés avec succès"
}
```

---

## 🔄 Workflow d'une Intervention

### États et Transitions

```
1. pending (En attente) - Statut par défaut à la création
   ↓ approve() OU reject()
2a. approved (Approuvée)  OU  2b. rejected (Rejetée)
   ↓ (si approved) start()
3. in_progress (En cours)
   ↓ complete()
4. completed (Terminée)
```

### Actions Disponibles

| Action | Endpoint | Status Requis | Status Résultant |
|--------|----------|--------------|------------------|
| Créer | `POST /interventions-create` | - | `pending` |
| Approuver | `POST /interventions-approve/{id}` | `pending` | `approved` |
| Rejeter | `POST /interventions-reject/{id}` | `pending` | `rejected` |
| Démarrer | `POST /interventions/{id}/start` | `approved` | `in_progress` |
| Terminer | `POST /interventions/{id}/complete` | `in_progress` | `completed` |

---

## 🔄 Actions sur les Interventions

### Approuver une Intervention

**Endpoint** : `POST /api/interventions-approve/{id}`

**Body** (optionnel) :
```json
{
  "notes": "Intervention approuvée, budget validé"
}
```

**Réponse** :
```json
{
  "success": true,
  "message": "Intervention approuvée avec succès"
}
```

### Rejeter une Intervention

**Endpoint** : `POST /api/interventions-reject/{id}`

**Body** :
```json
{
  "rejection_reason": "Budget insuffisant, report nécessaire"
}
```

### Démarrer une Intervention

**Endpoint** : `POST /api/interventions/{id}/start`

**Body** : `{}` (vide)

**Réponse** :
```json
{
  "success": true,
  "message": "Intervention démarrée avec succès"
}
```

**Note** : Définit automatiquement `start_date` à maintenant.

### Terminer une Intervention

**Endpoint** : `POST /api/interventions/{id}/complete`

**Body** (tous optionnels) :
```json
{
  "completion_notes": "Intervention terminée avec succès, client satisfait",
  "actual_duration": 2.5,
  "cost": 50000.0
}
```

**Réponse** :
```json
{
  "success": true,
  "message": "Intervention terminée avec succès"
}
```

**Note** : Définit automatiquement `end_date` à maintenant et `status` à `completed`.

---

## ❌ Format de Réponse (Erreur)

### Status Code : `422 Validation Error`

```json
{
  "success": false,
  "message": "The given data was invalid.",
  "errors": {
    "title": ["The title field is required."],
    "type": ["The type must be one of: external, on_site."],
    "scheduled_date": ["The scheduled date must be a date after now."]
  }
}
```

### Status Code : `400 Bad Request`

```json
{
  "success": false,
  "message": "Cette intervention ne peut plus être modifiée"
}
```

### Status Code : `500 Server Error`

```json
{
  "success": false,
  "message": "Erreur lors de la création de l'intervention: [détails de l'erreur]"
}
```

---

## ⚠️ Notes Importantes

1. **Date Planifiée** : 
   - La `scheduled_date` doit être dans le futur
   - Format : `"YYYY-MM-DD HH:mm:ss"` ou `"YYYY-MM-DDTHH:mm:ss"`

2. **Statut par Défaut** :
   - Les interventions sont créées avec le statut `pending` (en attente)
   - Elles doivent être approuvées avant d'être démarrées

3. **Modification** :
   - Une intervention ne peut être modifiée que si elle est `pending` ou `rejected`
   - Une fois `approved`, `in_progress` ou `completed`, elle ne peut plus être modifiée

4. **Durée** :
   - `estimated_duration` : Durée estimée en heures (ex: 2.5 = 2h30)
   - `actual_duration` : Durée réelle en heures (remplie lors de la finalisation)
   - `calculated_duration` : Calculée automatiquement depuis `start_date` et `end_date` si disponibles

5. **Types** :
   - `external` : Intervention externe (chez le client)
   - `on_site` : Intervention sur place (dans les locaux)

6. **Priorités** :
   - `low` : Faible
   - `medium` : Moyenne (par défaut)
   - `high` : Élevée
   - `urgent` : Urgente

7. **Alertes** :
   - `is_overdue` : Intervention en retard (date planifiée dépassée et non terminée)
   - `is_due_soon` : Intervention due bientôt (dans moins de 2 heures)

8. **Permissions** :
   - Les techniciens (role: 5) ne voient que leurs propres interventions
   - Les admins (role: 1) et patrons (role: 6) voient toutes les interventions

---

## ✅ Checklist pour Flutter

Avant d'envoyer la requête, vérifiez :

- [ ] `title` est fourni et non vide (max 255 caractères)
- [ ] `description` est fourni
- [ ] `type` est `"external"` ou `"on_site"`
- [ ] `priority` est `"low"`, `"medium"`, `"high"` ou `"urgent"`
- [ ] `scheduledDate` est dans le futur et au format datetime valide
- [ ] `clientEmail` est un email valide si fourni
- [ ] `estimatedDuration` est un nombre ≥ 0 si fourni
- [ ] `cost` est un nombre ≥ 0 si fourni
- [ ] `attachments` est un tableau si fourni
- [ ] Token d'authentification est présent dans les headers
- [ ] Headers `Content-Type: application/json` et `Accept: application/json`

---

## 📋 Mapping des Champs Flutter ↔ Backend

| Flutter (camelCase) | Backend (snake_case) | Description |
|---------------------|---------------------|-------------|
| `title` | `title` | Titre (identique) |
| `description` | `description` | Description (identique) |
| `type` | `type` | Type (identique) |
| `priority` | `priority` | Priorité (identique) |
| `scheduledDate` | `scheduled_date` | Date planifiée |
| `location` | `location` | Lieu (identique) |
| `clientName` | `client_name` | Nom client |
| `clientPhone` | `client_phone` | Téléphone client |
| `clientEmail` | `client_email` | Email client |
| `equipment` | `equipment` | Équipement (identique) |
| `problemDescription` | `problem_description` | Description problème |
| `estimatedDuration` | `estimated_duration` | Durée estimée |
| `cost` | `cost` | Coût (identique) |
| `notes` | `notes` | Notes (identique) |
| `attachments` | `attachments` | Pièces jointes (identique) |

---

## 📝 Exemples d'Utilisation Complète

### 1. Créer une Intervention

```dart
final intervention = Intervention(
  title: "Réparation climatiseur",
  description: "Réparation du climatiseur de la salle de réunion",
  type: "external",
  priority: "high",
  scheduledDate: "2024-11-05 14:00:00",
  location: "123 Rue Principale, Douala",
  clientName: "Entreprise ABC",
  clientPhone: "+237 123 456 789",
  equipment: "Climatiseur Daikin 3kW",
  problemDescription: "Le climatiseur ne s'allume plus",
  estimatedDuration: 2.5,
);

final createdIntervention = await interventionService.createIntervention(intervention);
```

### 2. Approuver une Intervention

```dart
// Approuver une intervention en attente
final approvedIntervention = await interventionService.approveIntervention(
  createdIntervention.id,
  notes: "Intervention approuvée, budget validé"
);
// Status passe de 'pending' à 'approved'
```

### 3. Démarrer une Intervention

```dart
// Démarrer une intervention approuvée
final startedIntervention = await interventionService.startIntervention(
  approvedIntervention.id
);
// Status passe de 'approved' à 'in_progress'
// start_date est défini automatiquement
```

### 4. Terminer une Intervention

```dart
// Terminer une intervention en cours
final completedIntervention = await interventionService.completeIntervention(
  startedIntervention.id,
  completionNotes: "Intervention terminée avec succès",
  actualDuration: 2.5,
  cost: 50000.0
);
// Status passe de 'in_progress' à 'completed'
// end_date est défini automatiquement
```

### 5. Rejeter une Intervention (Alternative)

```dart
// Rejeter une intervention en attente
final rejectedIntervention = await interventionService.rejectIntervention(
  createdIntervention.id,
  rejectionReason: "Budget insuffisant, report nécessaire"
);
// Status passe de 'pending' à 'rejected'
```

---

## 🎯 Résumé Rapide

### Champs Minimaux Requis pour Créer une Intervention :

```json
{
  "title": "Réparation climatiseur",
  "description": "Réparation du climatiseur de la salle de réunion",
  "type": "external",
  "priority": "high",
  "scheduledDate": "2024-11-05 14:00:00"
}
```

### Workflow Minimal :

1. **Créer** : `POST /interventions-create` → status `pending`
2. **Approuver** : `POST /interventions-approve/{id}` → status `approved`
3. **Démarrer** : `POST /interventions/{id}/start` → status `in_progress`
4. **Terminer** : `POST /interventions/{id}/complete` → status `completed`

**Alternative si rejetée :**
- **Rejeter** : `POST /interventions-reject/{id}` → status `rejected`

---

Cette documentation contient toutes les informations nécessaires pour intégrer la gestion des interventions dans Flutter sans problèmes de concordance avec le backend.

