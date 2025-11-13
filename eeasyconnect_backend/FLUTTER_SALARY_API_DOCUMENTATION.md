# Documentation API Salaires - Format Flutter

## 📋 Champs Requis pour Créer un Salaire

Flutter doit envoyer les données suivantes à l'endpoint `POST /api/salaries-create` :

### ✅ Champs OBLIGATOIRES (Minimum requis)

| Champ Flutter | Type | Format | Description | Exemple |
|--------------|------|--------|-------------|---------|
| `employeeId` | int | - | ID de l'employé qui reçoit le salaire (sera stocké comme `hr_id`) | `1` |
| `baseSalary` | double/float | - | Salaire de base (en FCFA) | `500000.0` |
| `month` | string/int | "MM" ou 1-12 | Mois du salaire | `"01"`, `"1"` ou `1` |
| `year` | int | - | Année du salaire (2000-2100) | `2024` |

### ⚪ Champs OPTIONNELS

| Champ Flutter | Type | Format | Description | Exemple |
|--------------|------|--------|-------------|---------|
| `netSalary` | double/float | - | Salaire net calculé (sera recalculé après) | `450000.0` |
| `bonus` | double/float | - | Prime/indemnités (sera converti en total_allowances) | `50000.0` |
| `deductions` | double/float | - | Déductions (sera converti en total_deductions) | `25000.0` |
| `notes` | string | - | Notes internes (max 1000 caractères) | `"Salaire janvier 2024"` |

---

## 📤 Format JSON à Envoyer (Exemple)

### Format Minimal (Requis uniquement)

```json
{
  "employeeId": 1,
  "baseSalary": 500000.0,
  "month": "01",
  "year": 2024
}
```

### Format Complet (Avec tous les champs)

```json
{
  "employeeId": 1,
  "baseSalary": 500000.0,
  "netSalary": 450000.0,
  "bonus": 50000.0,
  "deductions": 25000.0,
  "month": "01",
  "year": 2024,
  "notes": "Salaire janvier 2024 - Prime de performance incluse"
}
```

---

## 🔄 Normalisation Automatique du Backend

Le backend convertit automatiquement les champs camelCase vers snake_case :

- `employeeId` → `hr_id` (stocké en base)
- `baseSalary` → `base_salary`
- `netSalary` → `net_salary`
- `bonus` → utilisé pour calculer `total_allowances`
- `deductions` → utilisé pour calculer `total_deductions`

**Note :** Vous pouvez aussi envoyer `employee_id` au lieu de `employeeId`, les deux formats sont acceptés.

---

## 📅 Génération Automatique des Dates

Si vous envoyez uniquement `month` et `year`, le backend génère automatiquement :

- `period` : Format "YYYY-MM" (ex: "2024-01")
- `period_start` : Premier jour du mois (ex: "2024-01-01")
- `period_end` : Dernier jour du mois (ex: "2024-01-31")
- `salary_date` : Fin du mois + 5 jours (ex: "2024-02-05")

**Vous n'avez pas besoin d'envoyer ces champs**, ils sont calculés automatiquement.

---

## 📥 Format de Réponse (Success)

### Status Code : `201 Created`

```json
{
  "success": true,
  "message": "Salaire créé avec succès",
  "data": {
    "id": 1,
    "employee_id": 1,
    "hr_id": 1,
    "employee_name": "John Doe",
    "employee_email": "john@example.com",
    "base_salary": 500000.0,
    "bonus": 0.0,
    "deductions": 0.0,
    "net_salary": 0.0,
    "month": "01",
    "year": 2024,
    "status": "pending",
    "notes": "Salaire janvier 2024",
    "created_by": 2,
    "created_at": "2024-11-02 13:54:10",
    "updated_at": "2024-11-02 13:54:10",
    "period": "2024-01",
    "period_start": "2024-01-01",
    "period_end": "2024-01-31",
    "salary_date": "2024-02-05"
  }
}
```

---

## ❌ Format de Réponse (Erreur)

### Status Code : `422 Validation Error`

```json
{
  "success": false,
  "message": "Erreur de validation",
  "errors": {
    "hr_id": ["The hr id field is required."],
    "base_salary": ["The base salary field is required."]
  }
}
```

### Status Code : `500 Server Error`

```json
{
  "success": false,
  "message": "Erreur lors de la création du salaire: [détails de l'erreur]"
}
```

---

## 🔍 Validation des Champs

### `employeeId` / `employee_id`
- **Requis** : Oui
- **Type** : Entier
- **Valeur** : Doit exister dans la table `users`
- **Exemple** : `1`, `2`, `3`

### `baseSalary` / `base_salary`
- **Requis** : Oui
- **Type** : Nombre (double/float)
- **Min** : 0
- **Exemple** : `500000.0`

### `month`
- **Requis** : Oui (si `period` n'est pas fourni)
- **Type** : String ou Int
- **Format** : "01" à "12" ou 1 à 12
- **Exemple** : `"01"`, `"1"`, `1`

### `year`
- **Requis** : Oui (si `period` n'est pas fourni)
- **Type** : Entier
- **Min** : 2000
- **Max** : 2100
- **Exemple** : `2024`

### `netSalary` / `net_salary`
- **Requis** : Non
- **Type** : Nombre (double/float)
- **Min** : 0
- **Note** : Sera recalculé lors du calcul du salaire
- **Exemple** : `450000.0`

### `bonus`
- **Requis** : Non
- **Type** : Nombre (double/float)
- **Min** : 0
- **Note** : Utilisé pour calculer `total_allowances`
- **Exemple** : `50000.0`

### `deductions`
- **Requis** : Non
- **Type** : Nombre (double/float)
- **Min** : 0
- **Note** : Utilisé pour calculer `total_deductions`
- **Exemple** : `25000.0`

### `notes`
- **Requis** : Non
- **Type** : String
- **Max** : 1000 caractères
- **Exemple** : `"Notes internes"`

---

## 📝 Exemples de Code Flutter

### Exemple 1 : Création Simple

```dart
final salary = Salary(
  employeeId: 1,
  baseSalary: 500000.0,
  month: "01",
  year: 2024,
);

final result = await salaryService.createSalary(salary);
```

### Exemple 2 : Création avec Tous les Champs

```dart
final salary = Salary(
  employeeId: 1,
  baseSalary: 500000.0,
  netSalary: 450000.0,
  bonus: 50000.0,
  deductions: 25000.0,
  month: "01",
  year: 2024,
  notes: "Salaire janvier 2024",
);

final result = await salaryService.createSalary(salary);
```

### Exemple 3 : Envoi Direct via HTTP

```dart
final response = await http.post(
  Uri.parse('$baseUrl/salaries-create'),
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body: json.encode({
    'employeeId': 1,
    'baseSalary': 500000.0,
    'month': '01',
    'year': 2024,
    'notes': 'Salaire janvier 2024',
  }),
);
```

---

## ⚠️ Notes Importantes

1. **Format des Mois** : 
   - Accepte `"01"` ou `"1"` (le backend normalise automatiquement)
   - Accepte aussi les entiers `1` à `12`

2. **Format des IDs** :
   - Vous pouvez envoyer `employeeId` (camelCase) ou `employee_id` (snake_case)
   - Les deux sont convertis en `hr_id` par le backend

3. **Calcul Automatique** :
   - Le salaire net sera recalculé lors de l'appel à `/salaries-calculate/{id}`
   - Les primes et déductions seront traitées via les composants de salaire

4. **Status Initial** :
   - Tous les salaires créés ont le status `draft` (retourné comme `pending` pour Flutter)

5. **Génération Automatique** :
   - `salary_number` : Généré automatiquement (ex: "SAL-2024-0001")
   - `period`, `period_start`, `period_end`, `salary_date` : Générés depuis `month` et `year`

---

## 🔗 Endpoints Associés

- **Créer** : `POST /api/salaries-create`
- **Calculer** : `POST /api/salaries-calculate/{id}`
- **Approuver** : `POST /api/salaries-validate/{id}`
- **Rejeter** : `POST /api/salaries-reject/{id}`
- **Marquer comme payé** : `POST /api/salaries-mark-paid/{id}` ou `POST /api/salaries/{id}/pay`
- **Liste** : `GET /api/salaries-list`
- **Détail** : `GET /api/salaries-show/{id}`
- **Mettre à jour** : `PUT /api/salaries-update/{id}`
- **Supprimer** : `DELETE /api/salaries-destroy/{id}`

---

## ✅ Checklist pour Flutter

Avant d'envoyer la requête, vérifiez :

- [ ] `employeeId` est un entier valide (existe dans users)
- [ ] `baseSalary` est un nombre positif
- [ ] `month` est entre 1 et 12 (ou "01" à "12")
- [ ] `year` est entre 2000 et 2100
- [ ] Token d'authentification est présent dans les headers
- [ ] Headers `Content-Type: application/json` et `Accept: application/json`

