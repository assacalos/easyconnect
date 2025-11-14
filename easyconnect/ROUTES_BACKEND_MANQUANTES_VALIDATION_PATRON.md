# Routes Backend Manquantes pour les Pages de Validation du Patron

## Problème

Certaines pages de validation du Patron affichent des erreurs 404 car les routes backend correspondantes n'existent pas.

## Routes Manquantes

### 1. Bordereaux
**Route Frontend utilisée** : `GET /bordereaux-list`

**Route Backend actuelle** : Aucune route pour lister les bordereaux (seulement `/bordereaux-show/{id}`)

**Route à ajouter** :
```php
Route::get('/bordereaux-list', [BordereauController::class, 'index']);
```

**Middleware** : `role:1,2,6` (Admin, Commercial, Patron)

**Réponse attendue** :
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "numero": "BOR-2024-001",
      "client_id": 1,
      "client_name": "Nom du client",
      "date": "2024-01-15",
      "montant_total": 500000.00,
      "status": "pending",
      "created_at": "2024-01-15T10:00:00Z",
      "updated_at": "2024-01-15T10:00:00Z"
    }
  ]
}
```

---

### 2. Dépenses
**Route Frontend utilisée** : `GET /depenses-list` ou `GET /expenses-list`

**Route Backend actuelle** : Aucune route pour lister les dépenses

**Route à ajouter** :
```php
Route::get('/depenses-list', [ExpenseController::class, 'index']);
Route::get('/expenses-list', [ExpenseController::class, 'index']); // Alias en anglais
```

**Middleware** : `role:1,3,6` (Admin, Comptable, Patron)

**Réponse attendue** :
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "numero": "DEP-2024-001",
      "description": "Description de la dépense",
      "montant": 100000.00,
      "category": "Fournitures",
      "status": "pending",
      "created_at": "2024-01-15T10:00:00Z",
      "updated_at": "2024-01-15T10:00:00Z"
    }
  ]
}
```

---

### 3. Salaires
**Route Frontend utilisée** : `GET /salaires-list` ou `GET /salaries-list`

**Route Backend actuelle** : Routes existent mais pas de route de liste (`/salaries-*` pour autres opérations)

**Route à ajouter** :
```php
Route::get('/salaires-list', [SalaryController::class, 'index']);
Route::get('/salaries-list', [SalaryController::class, 'index']); // Alias en anglais
```

**Middleware** : `role:1,3,6` (Admin, Comptable, Patron)

**Réponse attendue** :
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "employee_id": 1,
      "employee_name": "Jean Dupont",
      "month": "2024-01",
      "gross_salary": 500000.00,
      "net_salary": 400000.00,
      "status": "pending",
      "created_at": "2024-01-15T10:00:00Z",
      "updated_at": "2024-01-15T10:00:00Z"
    }
  ]
}
```

---

### 4. Taxes
**Route Frontend utilisée** : `GET /taxes-list`

**Route Backend actuelle** : Aucune route pour lister les taxes

**Route à ajouter** :
```php
Route::get('/taxes-list', [TaxController::class, 'index']);
```

**Middleware** : `role:1,3,6` (Admin, Comptable, Patron)

**Réponse attendue** :
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "numero": "TAX-2024-001",
      "type": "TVA",
      "montant": 50000.00,
      "period": "2024-01",
      "status": "pending",
      "due_date": "2024-02-15",
      "created_at": "2024-01-15T10:00:00Z",
      "updated_at": "2024-01-15T10:00:00Z"
    }
  ]
}
```

---

### 5. Stock
**Route Frontend utilisée** : `GET /stocks`

**Route Backend actuelle** : Aucune route pour le stock

**Route à ajouter** :
```php
Route::get('/stocks', [StockController::class, 'index']);
Route::get('/stocks-list', [StockController::class, 'index']); // Alias
```

**Middleware** : `role:1,3,5,6` (Admin, Comptable, Technicien, Patron)

**Réponse attendue** :
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Article 1",
      "category": "Catégorie",
      "quantity": 100,
      "unit_price": 5000.00,
      "status": "pending",
      "created_at": "2024-01-15T10:00:00Z",
      "updated_at": "2024-01-15T10:00:00Z"
    }
  ]
}
```

---

## Routes qui fonctionnent (ne pas modifier)

- ✅ `/factures-list` - Existe déjà (mais vérifier le format de réponse)
- ✅ `/paiements-list` - Existe déjà (mais vérifier le format de réponse)
- ✅ `/attendances` - Existe déjà (pour les pointages)

**Note importante sur les factures et paiements** : 
Les routes `/factures-list` et `/paiements-list` existent dans le backend, mais elles peuvent retourner 404 si :
1. Le format de réponse ne correspond pas à ce que le frontend attend
2. Le middleware de rôle n'est pas correctement configuré
3. La méthode `index` du contrôleur ne retourne pas les données dans le bon format

**Format de réponse attendu par le frontend** :
```json
{
  "success": true,
  "data": [...]
}
```
ou
```json
{
  "data": [...]
}
```
ou directement un tableau :
```json
[...]
```

**Note sur les pointages** : La route `/attendances` existe dans le backend. Si elle retourne 404, vérifier :
1. Que le middleware `role:1,2,3,5,6` est correctement appliqué
2. Que la méthode `index` du `AttendanceController` retourne bien les données
3. Que le format de réponse correspond à ce que le frontend attend

---

## Implémentation Recommandée

### Exemple de méthode `index` pour BordereauController

```php
public function index(Request $request)
{
    try {
        $query = Bordereau::query();
        
        // Filtrage par statut
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }
        
        // Recherche
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('numero', 'like', "%{$search}%")
                  ->orWhereHas('client', function($q) use ($search) {
                      $q->where('name', 'like', "%{$search}%");
                  });
            });
        }
        
        // Pagination
        $perPage = $request->get('per_page', 15);
        $bordereaux = $query->with('client')
                           ->orderBy('created_at', 'desc')
                           ->paginate($perPage);
        
        return response()->json([
            'success' => true,
            'data' => $bordereaux->items(),
            'pagination' => [
                'current_page' => $bordereaux->currentPage(),
                'last_page' => $bordereaux->lastPage(),
                'per_page' => $bordereaux->perPage(),
                'total' => $bordereaux->total(),
            ]
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'message' => 'Erreur lors de la récupération des bordereaux',
            'error' => $e->getMessage()
        ], 500);
    }
}
```

---

## Checklist d'Implémentation

- [ ] Ajouter `GET /bordereaux-list` dans `BordereauController`
- [ ] Ajouter `GET /depenses-list` et `GET /expenses-list` dans `ExpenseController`
- [ ] Ajouter `GET /salaires-list` et `GET /salaries-list` dans `SalaryController`
- [ ] Ajouter `GET /taxes-list` dans `TaxController`
- [ ] Ajouter `GET /stocks` et `GET /stocks-list` dans `StockController`
- [ ] Vérifier que toutes les routes sont dans le bon middleware group
- [ ] Tester chaque route avec Postman ou un client HTTP
- [ ] Vérifier que les réponses JSON correspondent au format attendu par le frontend

---

## Notes Importantes

1. **Format de réponse** : Toutes les routes doivent retourner un JSON avec `success: true` et un tableau `data` contenant les éléments.

2. **Pagination** : Si la liste est paginée, inclure les informations de pagination dans la réponse.

3. **Filtrage** : Toutes les routes doivent supporter au minimum le filtrage par `status` (pending, approved, rejected, etc.) et la recherche par `search`.

4. **Relations** : Inclure les relations nécessaires (client, employé, etc.) dans la réponse pour éviter les requêtes supplémentaires.

5. **Permissions** : Vérifier que les middlewares de rôle sont correctement configurés pour chaque route.

---

## Test des Routes

Après implémentation, tester chaque route avec :

```bash
# Bordereaux
curl -X GET "http://localhost:8000/api/bordereaux-list?status=pending" \
  -H "Authorization: Bearer {token}"

# Dépenses
curl -X GET "http://localhost:8000/api/depenses-list?status=pending" \
  -H "Authorization: Bearer {token}"

# Salaires
curl -X GET "http://localhost:8000/api/salaires-list?status=pending" \
  -H "Authorization: Bearer {token}"

# Taxes
curl -X GET "http://localhost:8000/api/taxes-list?status=pending" \
  -H "Authorization: Bearer {token}"

# Stock
curl -X GET "http://localhost:8000/api/stocks?status=pending" \
  -H "Authorization: Bearer {token}"
```

