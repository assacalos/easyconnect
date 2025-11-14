# Routes Backend Ajoutées pour les Pages de Validation du Patron

## Résumé

Toutes les routes manquantes pour les pages de validation du Patron ont été ajoutées dans le fichier `routes/api.php`.

---

## Routes Ajoutées

### 1. Bordereaux ✅

**Route ajoutée** : `GET /api/bordereaux-list`

**Middleware** : `role:1,2,6` (Admin, Commercial, Patron)

**Controller** : `BordereauController::index`

**Emplacement** : Groupe de routes pour les commerciaux, admin et patron (ligne 164)

---

### 2. Dépenses ✅

**Routes ajoutées** :
- `GET /api/depenses-list` (français)
- `GET /api/expenses-list` (anglais - alias)

**Middleware** : `role:1,3,6` (Admin, Comptable, Patron)

**Controller** : `ExpenseController::index`

**Emplacement** : Groupe de routes pour les comptables, admin et patron (lignes 295-296)

**Import ajouté** : `use App\Http\Controllers\API\ExpenseController;` (ligne 13)

---

### 3. Salaires ✅

**Routes ajoutées** :
- `GET /api/salaires-list` (français)
- `GET /api/salaries-list` (anglais - alias)

**Middleware** : `role:1,3,6` (Admin, Comptable, Patron)

**Controller** : `SalaryController::index`

**Emplacement** : Groupe de routes pour les comptables, admin et patron (lignes 275-276)

---

### 4. Taxes ✅

**Route ajoutée** : `GET /api/taxes-list`

**Middleware** : `role:1,3,6` (Admin, Comptable, Patron)

**Controller** : `TaxController::index`

**Emplacement** : Groupe de routes pour les comptables, admin et patron (ligne 265)

---

### 5. Stock ✅

**Routes ajoutées** :
- `GET /api/stocks`
- `GET /api/stocks-list` (alias)

**Middleware** : `role:1,3,6` (Admin, Comptable, Patron)

**Controller** : `StockController::index`

**Emplacement** : Groupe de routes pour les comptables, admin et patron (lignes 299-300)

---

## Routes qui Fonctionnent Déjà (Non Modifiées)

- ✅ `/api/factures-list` - Existe déjà (ligne 114)
- ✅ `/api/paiements-list` - Existe déjà (ligne 238)
- ✅ `/api/attendances` - Existe déjà (pour les pointages)

---

## Structure des Routes par Groupe de Middleware

### Groupe `role:1,2,6` (Admin, Commercial, Patron)

```php
Route::middleware(['role:1,2,6'])->group(function () {
    // ...
    Route::get('/bordereaux-list', [BordereauController::class, 'index']);
    // ...
});
```

### Groupe `role:1,3,6` (Admin, Comptable, Patron)

```php
Route::middleware(['role:1,3,6'])->group(function () {
    // ...
    Route::get('/taxes-list', [TaxController::class, 'index']);
    Route::get('/salaires-list', [SalaryController::class, 'index']);
    Route::get('/salaries-list', [SalaryController::class, 'index']); // Alias
    // ...
    Route::get('/depenses-list', [ExpenseController::class, 'index']);
    Route::get('/expenses-list', [ExpenseController::class, 'index']); // Alias
    Route::get('/stocks', [StockController::class, 'index']);
    Route::get('/stocks-list', [StockController::class, 'index']); // Alias
    // ...
});
```

---

## Format de Réponse Attendu

Toutes les routes `index` doivent retourner un format JSON standardisé :

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      // ... autres champs
    }
  ]
}
```

**Avec pagination** (si applicable) :

```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 1,
        // ... autres champs
      }
    ],
    "total": 50,
    "per_page": 15,
    "last_page": 4
  }
}
```

**Sans pagination** (si `per_page` ou `limit` n'est pas fourni) :

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      // ... autres champs
    }
  ]
}
```

---

## Paramètres de Requête Supportés

Toutes les routes `index` doivent supporter au minimum :

- `status` : Filtrer par statut (ex: `pending`, `approved`, `rejected`)
- `search` : Recherche textuelle
- `per_page` : Nombre d'éléments par page (pagination)
- `limit` : Limite de résultats (alternative à `per_page`)
- `page` : Numéro de page (pour pagination)

### Exemples de Requêtes

```
GET /api/bordereaux-list?status=pending&search=client1
GET /api/depenses-list?status=approved&per_page=20
GET /api/salaires-list?status=pending&page=2
GET /api/taxes-list?search=TVA
GET /api/stocks?status=pending
```

---

## Vérification des Controllers

Tous les controllers ont été vérifiés et possèdent bien une méthode `index` :

- ✅ `BordereauController::index` - Existe
- ✅ `ExpenseController::index` - Existe
- ✅ `SalaryController::index` - Existe
- ✅ `TaxController::index` - Existe
- ✅ `StockController::index` - Existe

---

## Tests Recommandés

Après l'ajout des routes, tester chaque endpoint :

### 1. Bordereaux
```bash
curl -X GET "http://localhost:8000/api/bordereaux-list?status=pending" \
  -H "Authorization: Bearer {token}"
```

### 2. Dépenses
```bash
curl -X GET "http://localhost:8000/api/depenses-list?status=pending" \
  -H "Authorization: Bearer {token}"

curl -X GET "http://localhost:8000/api/expenses-list?status=pending" \
  -H "Authorization: Bearer {token}"
```

### 3. Salaires
```bash
curl -X GET "http://localhost:8000/api/salaires-list?status=pending" \
  -H "Authorization: Bearer {token}"

curl -X GET "http://localhost:8000/api/salaries-list?status=pending" \
  -H "Authorization: Bearer {token}"
```

### 4. Taxes
```bash
curl -X GET "http://localhost:8000/api/taxes-list?status=pending" \
  -H "Authorization: Bearer {token}"
```

### 5. Stock
```bash
curl -X GET "http://localhost:8000/api/stocks?status=pending" \
  -H "Authorization: Bearer {token}"

curl -X GET "http://localhost:8000/api/stocks-list?status=pending" \
  -H "Authorization: Bearer {token}"
```

---

## Checklist de Vérification

- [x] Route `/api/bordereaux-list` ajoutée
- [x] Routes `/api/depenses-list` et `/api/expenses-list` ajoutées
- [x] Routes `/api/salaires-list` et `/api/salaries-list` ajoutées
- [x] Route `/api/taxes-list` ajoutée
- [x] Routes `/api/stocks` et `/api/stocks-list` ajoutées
- [x] Import `ExpenseController` ajouté
- [x] Toutes les routes sont dans les bons groupes de middleware
- [x] Tous les controllers ont une méthode `index`
- [ ] Tester chaque route avec Postman ou un client HTTP
- [ ] Vérifier que les réponses JSON correspondent au format attendu par le frontend

---

## Notes Importantes

1. **Alias** : Des alias en anglais ont été ajoutés pour compatibilité avec le frontend Flutter qui pourrait utiliser les noms en anglais.

2. **Middleware** : Toutes les routes respectent les permissions selon les rôles :
   - Bordereaux : Admin (1), Commercial (2), Patron (6)
   - Dépenses, Salaires, Taxes, Stock : Admin (1), Comptable (3), Patron (6)

3. **Format de réponse** : Les controllers doivent retourner un format JSON standardisé avec `success: true` et un tableau `data`.

4. **Pagination** : Les méthodes `index` doivent supporter la pagination optionnelle (retourner un tableau direct si `per_page`/`limit` n'est pas fourni, sinon retourner un objet paginé).

---

## Prochaines Étapes

1. **Tester les routes** : Vérifier que chaque route fonctionne correctement
2. **Vérifier les formats de réponse** : S'assurer que les réponses correspondent au format attendu par le frontend
3. **Ajouter la pagination** : Si les méthodes `index` ne supportent pas encore la pagination optionnelle, les mettre à jour
4. **Ajouter le filtrage** : S'assurer que le filtrage par `status` et la recherche par `search` fonctionnent

---

## Conclusion

Toutes les routes manquantes ont été ajoutées avec succès. Les pages de validation du Patron devraient maintenant pouvoir récupérer les listes de bordereaux, dépenses, salaires, taxes et stock sans erreur 404.

