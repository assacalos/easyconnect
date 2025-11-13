# Rapport de Compatibilité : Modèles Salary Flutter vs Backend Laravel

## 📋 Résumé Exécutif

Ce document compare les modèles et services de salaire du frontend Flutter avec l'API backend Laravel pour identifier les incompatibilités et proposer des corrections.

---

## 🔴 PROBLÈMES CRITIQUES IDENTIFIÉS

### 1. **Modèle Salary - Champs Incompatibles**

#### ❌ Champs manquants dans le modèle Flutter (présents dans le backend) :
- `salary_number` : Numéro unique du salaire (généré automatiquement par le backend)
- `hr_id` : ID de l'utilisateur RH qui a créé le salaire
- `period` : Période du salaire (format string, ex: "2024-01")
- `period_start` : Date de début de la période
- `period_end` : Date de fin de la période
- `salary_date` : Date de paiement prévue (différent de `paid_at`)
- `gross_salary` : Salaire brut (calculé après calcul)
- `total_allowances` : Total des indemnités
- `total_deductions` : Total des déductions (différent de `deductions`)
- `total_taxes` : Total des impôts
- `total_social_security` : Total des charges sociales
- `calculated_at` : Date/heure de calcul
- `paid_by` : ID de l'utilisateur qui a marqué comme payé (différent de `approvedBy`)

#### ❌ Champs présents dans Flutter mais absents/incorrects dans le backend :
- `bonus` : Le backend utilise `total_allowances` qui inclut les bonuses, pas un champ `bonus` séparé
- `deductions` : Le backend utilise `total_deductions` (nom différent)
- `month` : Le backend utilise `period` (format "YYYY-MM") et non un champ `month` séparé
- `year` : Le backend utilise `period` qui contient l'année, pas un champ `year` séparé
- `employeeName` : Disponible via relation `employee` mais pas comme champ direct
- `employeeEmail` : Disponible via relation `employee` mais pas comme champ direct
- `createdBy` : Le backend utilise `hr_id` (celui qui crée le salaire)
- `approvedAt` : Format string dans Flutter mais `datetime` dans le backend
- `paidAt` : Format string dans Flutter mais `datetime` dans le backend
- `rejectionReason` : Le backend utilise `notes` avec status "cancelled", pas un champ dédié

#### ⚠️ Statuts différents :
- **Backend** : `draft`, `calculated`, `approved`, `paid`, `cancelled`
- **Flutter** : `pending`, `approved`, `paid`, `rejected` (manque `draft`, `calculated`, `cancelled`)

---

### 2. **Routes API Incompatibles**

#### ❌ Routes utilisées dans Flutter mais non trouvées dans le backend :

1. **`/salaries-validate/{id}`** 
   - Flutter utilise : `salaries-validate/{id}`
   - Backend utilise : `salaries-validate/{id}` → pointe vers `validateSalary()` qui **n'existe pas** dans le contrôleur
   - **Solution** : Le backend doit utiliser `/salaries-validate/{id}` qui appelle `approve()` ou créer la méthode `validateSalary()`

2. **`/salaries-reject/{id}`**
   - Flutter utilise : `salaries-reject/{id}`
   - Backend : Route existe mais méthode `reject()` **n'existe pas** dans SalaryController
   - **Solution** : Implémenter la méthode `reject()` qui change le status à `cancelled`

3. **`/salaries-pending`**
   - Flutter utilise : `salaries-pending`
   - Backend : **Route n'existe pas**
   - **Solution** : Ajouter la route ou filtrer avec `?status=draft` sur `/salaries-list`

4. **`/salaries/{id}/pay`**
   - Flutter utilise : `salaries/{id}/pay`
   - Backend utilise : `/salaries-mark-paid/{id}`
   - **Solution** : Utiliser la route backend ou ajouter un alias

5. **`/salaries/stats`**
   - Flutter utilise : `salaries/stats`
   - Backend utilise : `/salaries-statistics`
   - **Solution** : Utiliser la route backend ou ajouter un alias

6. **`/employees-list`**
   - Flutter utilise : `employees-list`
   - Backend : Route existe mais sous `/employees` (ligne 500 de api.php)
   - **Solution** : Utiliser `/employees` ou ajouter un alias

---

### 3. **Structure des Réponses JSON**

#### ❌ Format de réponse différent :

**Backend retourne (index)** :
```json
{
  "success": true,
  "data": {
    "data": [...],  // Liste paginée
    "current_page": 1,
    "per_page": 15,
    ...
  }
}
```

**Flutter attend** :
```json
{
  "data": [...]  // Liste directe
}
// OU
{
  "salaries": [...]  // Alternative
}
```

**Solution** : Le service Flutter doit gérer la pagination Laravel correctement.

---

### 4. **Création de Salaire - Champs Requis**

#### ❌ Champs manquants dans `createSalary()` Flutter :

Le backend requiert (dans `store()`) :
- `employee_id` : ✅ Présent
- `period` : ❌ **MANQUANT** (requis, format "YYYY-MM")
- `period_start` : ❌ **MANQUANT** (requis, date)
- `period_end` : ❌ **MANQUANT** (requis, date)
- `salary_date` : ❌ **MANQUANT** (requis, date)
- `base_salary` : ✅ Présent
- `notes` : ✅ Présent (optionnel)

**Le modèle Flutter n'a pas** :
- `period`
- `period_start`
- `period_end`
- `salary_date`

---

### 5. **Modèle SalaryComponent - Incompatibilités**

#### ❌ Champs incompatibles :

**Backend SalaryComponent** :
- `code` : Code unique du composant
- `calculation_type` : `fixed`, `percentage`, `hourly`, `performance`
- `default_value` : Valeur par défaut
- `is_taxable` : Imposable ou non
- `is_social_security` : Soumis aux charges sociales
- `is_mandatory` : Obligatoire
- `calculation_rules` : Règles de calcul (JSON)

**Flutter SalaryComponent** :
- `amount` : ❌ Ce champ n'existe pas dans le backend (calculé dynamiquement)
- `type` : ✅ Compatible mais valeurs différentes
  - Backend : `base`, `allowance`, `deduction`, `bonus`, `overtime`
  - Flutter : `base`, `bonus`, `deduction` (manque `allowance`, `overtime`)

---

### 6. **Statistiques - Structure Différente**

**Backend retourne** (`statistics()`):
```json
{
  "total_salaries": 10,
  "draft_salaries": 2,
  "calculated_salaries": 3,
  "approved_salaries": 4,
  "paid_salaries": 1,
  "cancelled_salaries": 0,
  "total_base_salary": 50000.00,
  "total_gross_salary": 55000.00,
  "total_net_salary": 44000.00,
  "total_allowances": 5000.00,
  "total_deductions": 1000.00,
  "total_taxes": 8000.00,
  "total_social_security": 2000.00
}
```

**Flutter attend** (`SalaryStats`) :
```dart
- totalSalaries (double) ❌ Backend retourne int
- pendingSalaries ❌ Backend utilise "draft_salaries" et "calculated_salaries"
- approvedSalaries ✅ Compatible
- paidSalaries ✅ Compatible
- totalEmployees ❌ N'existe pas dans le backend
- pendingCount ❌ N'existe pas dans le backend
- approvedCount ❌ N'existe pas dans le backend
- paidCount ❌ N'existe pas dans le backend
- salariesByMonth ❌ N'existe pas dans le backend
- countByMonth ❌ N'existe pas dans le backend
```

---

## ✅ CORRECTIONS RECOMMANDÉES

### **Option 1 : Modifier le Backend (Recommandé pour cohérence)**

#### 1. Ajouter les méthodes manquantes dans `SalaryController.php` :

```php
/**
 * Valider un salaire (alias pour approve)
 */
public function validateSalary(Request $request, $id)
{
    return $this->approve($request, $id);
}

/**
 * Rejeter un salaire
 */
public function reject(Request $request, $id)
{
    try {
        $salary = Salary::find($id);

        if (!$salary) {
            return response()->json([
                'success' => false,
                'message' => 'Salaire non trouvé'
            ], 404);
        }

        $validated = $request->validate([
            'reason' => 'nullable|string|max:1000'
        ]);

        if ($salary->cancel($validated['reason'] ?? null)) {
            return response()->json([
                'success' => true,
                'message' => 'Salaire rejeté avec succès'
            ]);
        } else {
            return response()->json([
                'success' => false,
                'message' => 'Ce salaire ne peut pas être rejeté'
            ], 400);
        }

    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'message' => 'Erreur lors du rejet: ' . $e->getMessage()
        ], 500);
    }
}

/**
 * Récupérer les salaires en attente
 */
public function pending(Request $request)
{
    $query = Salary::with(['employee', 'hr', 'salaryItems.salaryComponent'])
        ->whereIn('status', ['draft', 'calculated']);

    // ... (reprendre la logique de index avec filtres)
    
    return response()->json([
        'success' => true,
        'data' => $salaries,
        'message' => 'Salaires en attente récupérés avec succès'
    ]);
}
```

#### 2. Ajouter les routes manquantes dans `routes/api.php` :

```php
// Dans le groupe role:1,3,6 (comptables, admin, patron)
Route::get('/salaries-pending', [SalaryController::class, 'pending']);
Route::post('/salaries/{id}/pay', [SalaryController::class, 'markAsPaid']); // Alias
Route::get('/salaries/stats', [SalaryController::class, 'statistics']); // Alias
Route::get('/employees-list', [EmployeeController::class, 'index']); // Alias
```

#### 3. Modifier `SalaryController::statistics()` pour inclure les champs Flutter :

```php
public function statistics(Request $request)
{
    // ... code existant ...
    
    // Ajouter les données attendues par Flutter
    $stats['total_employees'] = User::where('role', 4)->count();
    $stats['pending_count'] = $stats['draft_salaries'] + $stats['calculated_salaries'];
    $stats['approved_count'] = $stats['approved_salaries'];
    $stats['paid_count'] = $stats['paid_salaries'];
    
    // Calculer les salaires par mois
    $salariesByMonth = Salary::selectRaw('period, SUM(net_salary) as total')
        ->groupBy('period')
        ->pluck('total', 'period')
        ->toArray();
    
    $stats['salaries_by_month'] = $salariesByMonth;
    
    // Compter par mois
    $countByMonth = Salary::selectRaw('period, COUNT(*) as count')
        ->groupBy('period')
        ->pluck('count', 'period')
        ->toArray();
    
    $stats['count_by_month'] = $countByMonth;
    
    return response()->json([
        'success' => true,
        'data' => $stats,
        'message' => 'Statistiques récupérées avec succès'
    ]);
}
```

#### 4. Modifier `index()` pour retourner aussi les champs attendus par Flutter :

Ajouter dans la transformation des données :
```php
'employee_id' => $salary->employee_id,
'employee_email' => $salary->employee->email ?? null,
'month' => $salary->period ? substr($salary->period, 5, 2) : null, // Extraire MM de YYYY-MM
'year' => $salary->period ? substr($salary->period, 0, 4) : null, // Extraire YYYY
'bonus' => $salary->total_allowances, // Alias pour compatibilité
'deductions' => $salary->total_deductions, // Alias pour compatibilité
'created_by' => $salary->hr_id,
'approved_at' => $salary->approved_at?->format('Y-m-d H:i:s'),
'paid_at' => $salary->paid_at?->format('Y-m-d H:i:s'),
'rejection_reason' => $salary->status === 'cancelled' ? $salary->notes : null,
```

---

### **Option 2 : Modifier le Frontend Flutter**

#### 1. Mettre à jour le modèle `Salary` :

```dart
class Salary {
  final int? id;
  final int? employeeId;
  final String? employeeName;
  final String? employeeEmail;
  final double baseSalary;
  final double? bonus; // Peut être null
  final double? deductions; // Peut être null
  final double netSalary;
  final String? period; // NOUVEAU - Format "YYYY-MM"
  final String? periodStart; // NOUVEAU
  final String? periodEnd; // NOUVEAU
  final String? salaryDate; // NOUVEAU - Date de paiement prévue
  final String? salaryNumber; // NOUVEAU
  final double? grossSalary; // NOUVEAU
  final double? totalAllowances; // NOUVEAU
  final double? totalDeductions; // NOUVEAU
  final double? totalTaxes; // NOUVEAU
  final double? totalSocialSecurity; // NOUVEAU
  final String? status; // 'draft', 'calculated', 'approved', 'paid', 'cancelled'
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? createdBy; // hr_id
  final int? approvedBy;
  final DateTime? approvedAt; // NOUVEAU - Format DateTime
  final DateTime? paidAt; // NOUVEAU - Format DateTime
  final int? paidBy; // NOUVEAU
  final String? rejectionReason; // notes si status = 'cancelled'
  final DateTime? calculatedAt; // NOUVEAU
}
```

#### 2. Corriger `SalaryService` :

```dart
// Utiliser les bonnes routes
final url = '$baseUrl/salaries-list$queryString'; // ✅ Correct
final url = '$baseUrl/salaries-show/$id'; // ✅ Correct
final url = '$baseUrl/salaries-create'; // ✅ Correct mais besoin de plus de champs
final url = '$baseUrl/salaries-update/$id'; // ✅ Correct
final url = '$baseUrl/salaries-validate/$id'; // ⚠️ Nécessite validateSalary() ou utiliser approve
final url = '$baseUrl/salaries-reject/$id'; // ⚠️ Nécessite reject()
final url = '$baseUrl/salaries-mark-paid/$id'; // ✅ Correct (pas /pay)
final url = '$baseUrl/salaries-statistics'; // ✅ Correct (pas /stats)
final url = '$baseUrl/salary-components'; // ✅ Correct
final url = '$baseUrl/employees'; // ✅ Correct (pas employees-list)
```

#### 3. Mettre à jour `createSalary()` :

```dart
Future<Salary> createSalary(Salary salary) async {
  // Le backend requiert period, period_start, period_end, salary_date
  if (salary.period == null || salary.periodStart == null || 
      salary.periodEnd == null || salary.salaryDate == null) {
    throw Exception('Les champs period, period_start, period_end et salary_date sont requis');
  }

  final response = await http.post(
    Uri.parse('$baseUrl/salaries-create'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: json.encode({
      'employee_id': salary.employeeId,
      'period': salary.period, // Format "YYYY-MM"
      'period_start': salary.periodStart, // Format "YYYY-MM-DD"
      'period_end': salary.periodEnd, // Format "YYYY-MM-DD"
      'salary_date': salary.salaryDate, // Format "YYYY-MM-DD"
      'base_salary': salary.baseSalary,
      'notes': salary.notes,
    }),
  );

  // ...
}
```

---

## 📝 CHECKLIST DE CORRECTION

### Backend (Laravel)

- [ ] Ajouter méthode `validateSalary()` dans `SalaryController`
- [ ] Ajouter méthode `reject()` dans `SalaryController`
- [ ] Ajouter méthode `pending()` dans `SalaryController`
- [ ] Ajouter route `/salaries-pending`
- [ ] Ajouter route `/salaries/{id}/pay` (alias)
- [ ] Ajouter route `/salaries/stats` (alias)
- [ ] Ajouter route `/employees-list` (alias)
- [ ] Modifier `statistics()` pour inclure les champs Flutter
- [ ] Modifier `index()` pour inclure les champs de compatibilité (month, year, bonus, etc.)
- [ ] Ajouter support pour status `rejected` (mapping vers `cancelled`)

### Frontend (Flutter)

- [ ] Ajouter champs manquants dans modèle `Salary` (period, period_start, period_end, salary_date, etc.)
- [ ] Corriger mapping des status (`pending` → `draft`, `rejected` → `cancelled`)
- [ ] Corriger routes API dans `SalaryService`
- [ ] Corriger `createSalary()` pour inclure tous les champs requis
- [ ] Corriger `SalaryStats.fromJson()` pour mapper les champs backend
- [ ] Gérer la pagination Laravel dans `getSalaries()`
- [ ] Corriger `SalaryComponent` pour inclure les champs backend

---

## 🔗 Références

- **Backend Model** : `app/Models/Salary.php`
- **Backend Controller** : `app/Http/Controllers/API/SalaryController.php`
- **Backend Routes** : `routes/api.php` (lignes 404-414)
- **Flutter Model** : `salary_model.dart`
- **Flutter Service** : `salary_service.dart`

---

## ⚠️ NOTES IMPORTANTES

1. **Les status doivent être alignés** : Le backend utilise un workflow plus complexe (`draft` → `calculated` → `approved` → `paid`) que Flutter qui utilise un workflow simplifié (`pending` → `approved` → `paid`).

2. **Le backend génère automatiquement** `salary_number` et `hr_id` lors de la création, le frontend ne doit pas les envoyer.

3. **Le calcul du salaire** se fait via `/salaries-calculate/{id}` et doit être appelé avant l'approbation.

4. **Les champs `bonus` et `deductions` dans Flutter** doivent être mappés vers `total_allowances` et `total_deductions` du backend.

5. **La période** est un concept important dans le backend : format "YYYY-MM" (ex: "2024-01"), pas juste un mois et une année séparés.

