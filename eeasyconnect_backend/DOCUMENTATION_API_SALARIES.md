# Documentation API - Salaires

## 📋 Données à envoyer depuis le Frontend

### 🆕 Création d'un salaire (POST `/api/salaries`)

#### Champs **OBLIGATOIRES** :

| Champ | Type | Format | Description | Exemple |
|-------|------|--------|-------------|---------|
| `employee_id` | integer | - | **ID de l'employé** (doit exister dans la table `employees`) | `1` |
| `base_salary` | number | decimal(10,2) | **Salaire de base** (minimum 0) | `500000.00` |

#### Champs **OPTIONNELS** :

| Champ | Type | Format | Description | Exemple |
|-------|------|--------|-------------|---------|
| `month` | integer/string | 1-12 | Mois (si pas de `period`) | `12` ou `"12"` |
| `year` | integer | 2000-2100 | Année (si pas de `period`) | `2024` |
| `period` | string | "YYYY-MM" | Période complète (alternative à month/year) | `"2024-12"` |
| `period_start` | string | "YYYY-MM-DD" | Date de début de période | `"2024-12-01"` |
| `period_end` | string | "YYYY-MM-DD" | Date de fin de période | `"2024-12-31"` |
| `salary_date` | string | "YYYY-MM-DD" | Date de paiement du salaire | `"2025-01-05"` |
| `notes` | string | max 1000 | Notes/commentaires | `"Salaire décembre"` |
| `justificatif` | array | string[] | Tableau de chemins de fichiers | `["/uploads/file1.pdf"]` |
| `net_salary` | number | decimal(10,2) | Salaire net (sera recalculé) | `450000.00` |
| `bonus` | number | decimal(10,2) | Bonus/indemnités (compatibilité Flutter) | `50000.00` |
| `deductions` | number | decimal(10,2) | Déductions (compatibilité Flutter) | `10000.00` |

#### ⚠️ **Format de période** (2 options) :

**Option 1 : Format simple (Recommandé pour Flutter)**
```json
{
  "employee_id": 1,
  "base_salary": 500000,
  "month": 12,
  "year": 2024
}
```
Le backend génère automatiquement :
- `period` : "2024-12"
- `period_start` : "2024-12-01"
- `period_end` : "2024-12-31"
- `salary_date` : "2025-01-05" (fin du mois + 5 jours)

**Option 2 : Format complet (Backend)**
```json
{
  "employee_id": 1,
  "base_salary": 500000,
  "period": "2024-12",
  "period_start": "2024-12-01",
  "period_end": "2024-12-31",
  "salary_date": "2025-01-05"
}
```

#### 📝 **Exemples de requêtes** :

**Exemple 1 : Format minimal (Recommandé)**
```json
{
  "employee_id": 1,
  "base_salary": 500000,
  "month": 12,
  "year": 2024,
  "notes": "Salaire de décembre 2024"
}
```

**Exemple 2 : Format complet**
```json
{
  "employee_id": 1,
  "base_salary": 500000,
  "period": "2024-12",
  "period_start": "2024-12-01",
  "period_end": "2024-12-31",
  "salary_date": "2025-01-05",
  "notes": "Salaire de décembre 2024",
  "justificatif": ["/uploads/justificatif1.pdf", "/uploads/justificatif2.pdf"]
}
```

**Exemple 3 : Format camelCase (compatibilité Flutter)**
```json
{
  "employeeId": 1,
  "baseSalary": 500000,
  "month": 12,
  "year": 2024,
  "netSalary": 450000
}
```

---

### ✏️ Mise à jour d'un salaire (PUT/PATCH `/api/salaries/{id}`)

#### Champs **MODIFIABLES** (tous optionnels) :

| Champ | Type | Format | Description | Exemple |
|-------|------|--------|-------------|---------|
| `base_salary` | number | decimal(10,2) | Salaire de base | `550000.00` |
| `salary_date` | string | "YYYY-MM-DD" | Date de paiement | `"2025-01-10"` |
| `notes` | string | max 1000 | Notes/commentaires | `"Salaire modifié"` |
| `justificatif` | array | string[] | Tableau de chemins de fichiers | `["/uploads/new.pdf"]` |

#### ⚠️ **Contraintes** :
- Le salaire doit être en statut `draft` pour être modifiable
- Si le statut est `calculated`, `approved` ou `paid`, la modification est bloquée

#### 📝 **Exemple de requête** :
```json
{
  "base_salary": 550000,
  "salary_date": "2025-01-10",
  "notes": "Salaire mis à jour avec augmentation"
}
```

---

## 📤 Réponse du serveur

### Réponse de création (201 Created)

```json
{
  "success": true,
  "data": {
    "id": 1,
    "employee_id": 1,
    "hr_id": 1,
    "employee_name": "John Doe",
    "employee_email": "john.doe@example.com",
    "salary_number": "SAL-2024-0001",
    "base_salary": 500000,
    "gross_salary": 0,
    "net_salary": 0,
    "bonus": 0,
    "deductions": 0,
    "month": "12",
    "year": 2024,
    "period": "2024-12",
    "period_start": "2024-12-01",
    "period_end": "2024-12-31",
    "salary_date": "2025-01-05",
    "status": "pending",
    "status_libelle": "Brouillon",
    "notes": "Salaire de décembre 2024",
    "justificatif": [],
    "created_by": 1,
    "created_at": "2024-12-20 10:30:00",
    "updated_at": "2024-12-20 10:30:00"
  },
  "message": "Salaire créé avec succès"
}
```

### Réponse d'erreur de validation (422 Unprocessable Entity)

```json
{
  "success": false,
  "message": "Erreur de validation",
  "errors": {
    "employee_id": ["Le champ employee_id est obligatoire."],
    "base_salary": ["Le champ base_salary doit être un nombre."]
  }
}
```

---

## 🔄 Statuts du salaire

| Statut Backend | Statut Flutter | Description |
|----------------|----------------|-------------|
| `draft` | `pending` | Brouillon (modifiable) |
| `calculated` | `pending` | Calculé (prêt pour approbation) |
| `approved` | `approved` | Approuvé (prêt pour paiement) |
| `paid` | `paid` | Payé |
| `cancelled` | `rejected` | Annulé/Rejeté |

---

## 📌 Points importants

1. **`employee_id` est obligatoire** et doit exister dans la table `employees`
2. **`base_salary` est obligatoire** et doit être >= 0
3. **Format de période** : Utilisez `month` + `year` (plus simple) ou `period` + dates complètes
4. **Le `salary_number` est généré automatiquement** par le backend
5. **Les calculs** (gross_salary, net_salary, etc.) sont effectués lors de l'appel à `/api/salaries/{id}/calculate`
6. **Compatibilité camelCase** : Le backend accepte aussi `employeeId`, `baseSalary`, `netSalary`
7. **Compatibilité `hr_id`** : Le backend accepte aussi `hr_id` mais le convertit en `employee_id`

---

## 🔗 Endpoints disponibles

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/salaries` | Liste des salaires |
| GET | `/api/salaries/{id}` | Détails d'un salaire |
| POST | `/api/salaries` | Créer un salaire |
| PUT/PATCH | `/api/salaries/{id}` | Mettre à jour un salaire |
| DELETE | `/api/salaries/{id}` | Supprimer un salaire |
| POST | `/api/salaries/{id}/calculate` | Calculer un salaire |
| POST | `/api/salaries/{id}/approve` | Approuver un salaire |
| POST | `/api/salaries/{id}/mark-as-paid` | Marquer comme payé |
| POST | `/api/salaries/{id}/reject` | Rejeter un salaire |
| GET | `/api/salaries/pending` | Salaires en attente |

---

## 💡 Exemple complet Flutter/Dart

```dart
// Créer un salaire
final response = await http.post(
  Uri.parse('$baseUrl/api/salaries'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body: jsonEncode({
    'employee_id': 1,
    'base_salary': 500000.00,
    'month': 12,
    'year': 2024,
    'notes': 'Salaire de décembre 2024',
  }),
);

// Mettre à jour un salaire
final updateResponse = await http.put(
  Uri.parse('$baseUrl/api/salaries/1'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body: jsonEncode({
    'base_salary': 550000.00,
    'notes': 'Salaire mis à jour',
  }),
);
```

