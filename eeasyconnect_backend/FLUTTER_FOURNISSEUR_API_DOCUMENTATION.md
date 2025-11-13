# Documentation API Fournisseurs - Format Flutter

## 📋 Champs Requis pour Créer un Fournisseur

Flutter doit envoyer les données suivantes à l'endpoint `POST /api/fournisseurs-create` :

### ✅ Champs OBLIGATOIRES (Minimum requis)

| Champ Flutter | Type | Format | Description | Exemple |
|--------------|------|--------|-------------|---------|
| `nom` ou `name` | string | - | Nom du fournisseur | `"Entreprise ABC"` |
| `email` | string | email | Adresse email (unique) | `"contact@abc.com"` |
| `telephone` ou `phone` | string | - | Numéro de téléphone | `"+237 123 456 789"` |
| `adresse` ou `address` | string | TEXT | Adresse complète | `"123 Rue Principale"` |
| `ville` ou `city` | string | - | Ville | `"Douala"` |
| `pays` ou `country` | string | - | Pays | `"Cameroun"` |

### ⚪ Champs OPTIONNELS

| Champ Flutter | Type | Format | Description | Exemple |
|--------------|------|--------|-------------|---------|
| `description` | string | TEXT (max 1000) | Description du fournisseur | `"Fournisseur spécialisé en..."` |
| `noteEvaluation` ou `note_evaluation` | double/float | 0-5 | Note d'évaluation | `4.5` |
| `commentaires` ou `comments` | string | TEXT (max 1000) | Commentaires | `"Très bon fournisseur"` |

**Note importante :** Le champ `contact_principal` a été supprimé. Ne plus l'envoyer.

---

## 📤 Format JSON à Envoyer (Exemple)

### Format Minimal (Requis uniquement)

```json
{
  "nom": "Entreprise ABC",
  "email": "contact@abc.com",
  "telephone": "+237 123 456 789",
  "adresse": "123 Rue Principale",
  "ville": "Douala",
  "pays": "Cameroun"
}
```

### Format Complet (Avec tous les champs)

```json
{
  "nom": "Entreprise ABC",
  "email": "contact@abc.com",
  "telephone": "+237 123 456 789",
  "adresse": "123 Rue Principale, Quartier Bonanjo",
  "ville": "Douala",
  "pays": "Cameroun",
  "description": "Fournisseur spécialisé en matériel informatique et équipements de bureau",
  "noteEvaluation": 4.5,
  "commentaires": "Livraison rapide et service client excellent"
}
```

### Format avec Alias Flutter (Compatibilité camelCase)

```json
{
  "name": "Entreprise ABC",
  "email": "contact@abc.com",
  "phone": "+237 123 456 789",
  "address": "123 Rue Principale",
  "city": "Douala",
  "country": "Cameroun",
  "description": "Fournisseur spécialisé...",
  "noteEvaluation": 4.5,
  "comments": "Très bon fournisseur"
}
```

---

## 🔄 Normalisation Automatique du Backend

Le backend convertit automatiquement les champs camelCase vers snake_case :

- `name` → `nom`
- `phone` → `telephone`
- `address` → `adresse`
- `city` → `ville`
- `country` → `pays`
- `noteEvaluation` → `note_evaluation`
- `comments` → `commentaires`

**Note :** Vous pouvez aussi envoyer les champs en français (`nom`, `telephone`, etc.), les deux formats sont acceptés.

---

## 📥 Format de Réponse (Success)

### Status Code : `201 Created`

```json
{
  "success": true,
  "message": "Fournisseur créé avec succès",
  "data": {
    "id": 1,
    "nom": "Entreprise ABC",
    "email": "contact@abc.com",
    "telephone": "+237 123 456 789",
    "adresse": "123 Rue Principale",
    "ville": "Douala",
    "pays": "Cameroun",
    "description": "Fournisseur spécialisé...",
    "status": "en_attente",
    "note_evaluation": null,
    "commentaires": null,
    "created_by": 1,
    "updated_by": 1,
    "validated_by": null,
    "validated_at": null,
    "validation_comment": null,
    "rejected_by": null,
    "rejected_at": null,
    "rejection_reason": null,
    "rejection_comment": null,
    "created_at": "2024-11-02 15:00:00",
    "updated_at": "2024-11-02 15:00:00",
    "deleted_at": null
  }
}
```

---

## 📊 Statuts des Fournisseurs

Les statuts possibles pour un fournisseur sont **UNIQUEMENT** les 3 suivants :

| Status Backend | Status Flutter (Recommandé) | Description |
|----------------|----------------------------|-------------|
| `en_attente` | `pending` ou `en_attente` | En attente de validation (statut par défaut à la création) |
| `valide` | `approved` ou `validated` | Validé par le patron/admin |
| `rejete` | `rejected` ou `rejete` | Rejeté |

**Note importante :** Un fournisseur ne peut être utilisé que s'il est validé (`valide`).

---

## 🔍 Validation des Champs

### `nom` / `name`
- **Requis** : Oui
- **Type** : String
- **Max** : 255 caractères
- **Exemple** : `"Entreprise ABC"`

### `email`
- **Requis** : Oui
- **Type** : String (format email)
- **Unicité** : Doit être unique dans la base de données
- **Exemple** : `"contact@abc.com"`
- **Note** : L'email sera vérifié pour le format et l'unicité

### `telephone` / `phone`
- **Requis** : Oui
- **Type** : String
- **Max** : 20 caractères
- **Exemple** : `"+237 123 456 789"` ou `"698765432"`

### `adresse` / `address`
- **Requis** : Oui
- **Type** : String (TEXT)
- **Max** : 500 caractères
- **Exemple** : `"123 Rue Principale, Quartier Bonanjo"`

### `ville` / `city`
- **Requis** : Oui
- **Type** : String
- **Max** : 100 caractères
- **Exemple** : `"Douala"`, `"Yaoundé"`

### `pays` / `country`
- **Requis** : Oui
- **Type** : String
- **Max** : 100 caractères
- **Exemple** : `"Cameroun"`

### `description`
- **Requis** : Non
- **Type** : String (TEXT)
- **Max** : 1000 caractères
- **Description** : Description détaillée du fournisseur
- **Exemple** : `"Fournisseur spécialisé en matériel informatique et équipements de bureau"`

### `noteEvaluation` / `note_evaluation`
- **Requis** : Non
- **Type** : Nombre (double/float)
- **Min** : 0
- **Max** : 5
- **Description** : Note d'évaluation du fournisseur
- **Exemple** : `4.5`

### `commentaires` / `comments`
- **Requis** : Non
- **Type** : String (TEXT)
- **Max** : 1000 caractères
- **Description** : Commentaires sur le fournisseur
- **Exemple** : `"Livraison rapide et service client excellent"`

---

## 📝 Exemples de Code Flutter

### Exemple 1 : Création Simple

```dart
final fournisseur = Fournisseur(
  nom: "Entreprise ABC",
  email: "contact@abc.com",
  telephone: "+237 123 456 789",
  adresse: "123 Rue Principale",
  ville: "Douala",
  pays: "Cameroun",
);

final result = await fournisseurService.createFournisseur(fournisseur);
```

### Exemple 2 : Création avec Tous les Champs

```dart
final fournisseur = Fournisseur(
  nom: "Entreprise ABC",
  email: "contact@abc.com",
  telephone: "+237 123 456 789",
  adresse: "123 Rue Principale, Quartier Bonanjo",
  ville: "Douala",
  pays: "Cameroun",
  description: "Fournisseur spécialisé en matériel informatique",
  noteEvaluation: 4.5,
  commentaires: "Livraison rapide",
);

final result = await fournisseurService.createFournisseur(fournisseur);
```

### Exemple 3 : Envoi Direct via HTTP (avec camelCase)

```dart
final response = await http.post(
  Uri.parse('$baseUrl/fournisseurs-create'),
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body: json.encode({
    'name': 'Entreprise ABC',
    'email': 'contact@abc.com',
    'phone': '+237 123 456 789',
    'address': '123 Rue Principale',
    'city': 'Douala',
    'country': 'Cameroun',
    'description': 'Fournisseur spécialisé...',
  }),
);
```

---

## 🔗 Endpoints Disponibles

### CRUD de Base

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/fournisseurs-list` | Liste des fournisseurs (avec pagination et filtres) |
| `GET` | `/api/fournisseurs-show/{id}` | Détails d'un fournisseur |
| `POST` | `/api/fournisseurs-create` | Créer un nouveau fournisseur |
| `PUT` | `/api/fournisseurs-update/{id}` | Mettre à jour un fournisseur |
| `DELETE` | `/api/fournisseurs-destroy/{id}` | Supprimer un fournisseur (soft delete) |

### Actions sur les Fournisseurs

| Méthode | Endpoint | Description | Body Requis |
|---------|----------|-------------|-------------|
| `POST` | `/api/fournisseurs-validate/{id}` | Valider un fournisseur | `{"validation_comment": "..."}` (optionnel) |
| `POST` | `/api/fournisseurs-reject/{id}` | Rejeter un fournisseur | `{"rejection_reason": "...", "rejection_comment": "..."}` |

---

## 📊 Format de Réponse - Liste des Fournisseurs

### GET `/api/fournisseurs-list`

```json
{
  "success": true,
  "message": "Fournisseurs récupérés avec succès",
  "data": [
    {
      "id": 1,
      "nom": "Entreprise ABC",
      "email": "contact@abc.com",
      "telephone": "+237 123 456 789",
      "adresse": "123 Rue Principale",
      "ville": "Douala",
      "pays": "Cameroun",
      "description": "Fournisseur spécialisé...",
      "status": "en_attente",
      "status_text": "En attente",
      "status_color": "orange",
      "note_evaluation": 4.5,
      "commentaires": "Très bon fournisseur",
      "created_at": "2024-11-02 15:00:00",
      "updated_at": "2024-11-02 15:00:00"
    }
  ],
  "pagination": {
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
| `statut` ou `status` | string | Filtrer par statut | `?statut=en_attente` |
| `search` | string | Recherche dans nom, email, ville | `?search=ABC` |
| `sort_by` | string | Champ de tri | `?sort_by=nom` |
| `sort_order` | string | Ordre (asc/desc) | `?sort_order=asc` |
| `per_page` | int | Nombre d'éléments par page | `?per_page=20` |

---

## 🔄 Workflow d'un Fournisseur

### États et Transitions

```
1. en_attente (En attente) - Statut par défaut à la création
   ↓ validate() OU reject()
2a. valide (Validé)  OU  2b. rejete (Rejeté)
```

### Actions Disponibles

| Action | Endpoint | Status Requis | Status Résultant |
|--------|----------|--------------|------------------|
| Créer | `POST /fournisseurs-create` | - | `en_attente` |
| Valider | `POST /fournisseurs-validate/{id}` | `en_attente` | `valide` |
| Rejeter | `POST /fournisseurs-reject/{id}` | `en_attente` | `rejete` |

---

## ❌ Format de Réponse (Erreur)

### Status Code : `422 Validation Error`

```json
{
  "success": false,
  "message": "Erreurs de validation",
  "errors": {
    "nom": ["Le nom du fournisseur est obligatoire."],
    "email": ["Cet email est déjà utilisé par un autre fournisseur."],
    "telephone": ["Le téléphone est obligatoire."]
  }
}
```

### Status Code : `400 Bad Request`

```json
{
  "success": false,
  "message": "Cette opération ne peut pas être effectuée dans l'état actuel du fournisseur"
}
```

### Status Code : `500 Server Error`

```json
{
  "success": false,
  "message": "Erreur lors de la création du fournisseur: [détails de l'erreur]"
}
```

---

## ⚠️ Notes Importantes

1. **Email Unique** : 
   - L'email doit être unique dans la base de données
   - Si un fournisseur avec le même email existe déjà, vous recevrez une erreur 422

2. **Statut par Défaut** :
   - Les fournisseurs sont créés avec le statut `en_attente`
   - Seuls les fournisseurs validés (`valide`) peuvent être utilisés pour les commandes

3. **Soft Delete** :
   - La suppression est un soft delete (pas de suppression physique)
   - Le champ `deleted_at` sera renseigné

4. **Normalisation** :
   - Le backend accepte les champs en français (`nom`, `telephone`, etc.) ET en anglais (`name`, `phone`, etc.)
   - Utilisez celui qui vous convient le mieux

5. **Champ Contact Supprimé** :
   - Le champ `contact_principal` a été supprimé
   - Ne plus l'envoyer dans les requêtes

---

## ✅ Checklist pour Flutter

Avant d'envoyer la requête, vérifiez :

- [ ] `nom` ou `name` est fourni et non vide
- [ ] `email` est un email valide et unique
- [ ] `telephone` ou `phone` est fourni
- [ ] `adresse` ou `address` est fournie
- [ ] `ville` ou `city` est fournie
- [ ] `pays` ou `country` est fourni
- [ ] Token d'authentification est présent dans les headers
- [ ] Headers `Content-Type: application/json` et `Accept: application/json`

---

## 📋 Mapping des Champs Flutter ↔ Backend

| Flutter (camelCase) | Backend (snake_case) | Description |
|---------------------|---------------------|-------------|
| `name` | `nom` | Nom du fournisseur |
| `email` | `email` | Email (identique) |
| `phone` | `telephone` | Numéro de téléphone |
| `address` | `adresse` | Adresse complète |
| `city` | `ville` | Ville |
| `country` | `pays` | Pays |
| `description` | `description` | Description (identique) |
| `noteEvaluation` | `note_evaluation` | Note d'évaluation |
| `comments` | `commentaires` | Commentaires |

---

## 📝 Exemples d'Utilisation Complète

### 1. Créer un Fournisseur

```dart
final fournisseur = Fournisseur(
  nom: "Entreprise ABC",
  email: "contact@abc.com",
  telephone: "+237 123 456 789",
  adresse: "123 Rue Principale",
  ville: "Douala",
  pays: "Cameroun",
);

final createdFournisseur = await fournisseurService.createFournisseur(fournisseur);
```

### 2. Valider un Fournisseur

```dart
// Valider un fournisseur en attente
final validatedFournisseur = await fournisseurService.validateFournisseur(
  createdFournisseur.id,
  validationComment: "Fournisseur vérifié et approuvé"
);
// Status passe de 'en_attente' à 'valide'
```

### 3. Rejeter un Fournisseur (Alternative)

```dart
// Rejeter un fournisseur en attente
final rejectedFournisseur = await fournisseurService.rejectFournisseur(
  createdFournisseur.id,
  rejectionReason: "Documents incomplets",
  rejectionComment: "Le fournisseur n'a pas fourni tous les documents requis"
);
// Status passe de 'en_attente' à 'rejete'
```

### 4. Mettre à Jour un Fournisseur

```dart
// Mettre à jour les informations d'un fournisseur
final updatedFournisseur = await fournisseurService.updateFournisseur(
  fournisseurId,
  nom: "Nouveau Nom",
  telephone: "+237 987 654 321",
  description: "Nouvelle description"
);
```

---

## 🎯 Résumé Rapide

### Champs Minimaux Requis pour Créer un Fournisseur :

```json
{
  "nom": "Entreprise ABC",
  "email": "contact@abc.com",
  "telephone": "+237 123 456 789",
  "adresse": "123 Rue Principale",
  "ville": "Douala",
  "pays": "Cameroun"
}
```

### Workflow Minimal :

1. **Créer** : `POST /fournisseurs-create` → status `en_attente`
2. **Valider** : `POST /fournisseurs-validate/{id}` → status `valide`

**Alternative si rejeté :**
- **Rejeter** : `POST /fournisseurs-reject/{id}` → status `rejete`

---

Cette documentation contient toutes les informations nécessaires pour intégrer les fournisseurs dans Flutter sans problèmes de concordance avec le backend.

