# Routes Backend Manquantes pour les Validations

Ce document liste toutes les routes backend manquantes qui empêchent le bon fonctionnement des validations dans l'application Flutter.

## ⚠️ PROBLÈMES IDENTIFIÉS

### Routes avec Incohérences

1. **Bordereaux - Rejet** :
   - Route dans routes.php : `POST /api/bordereaux/{id}/reject` (ligne 241)
   - Route utilisée par Flutter : `POST /api/bordereaux-reject/{id}`
   - **Solution** : Le service Flutter a été corrigé pour essayer les deux formats

2. **Paiements - Validation/Rejet** :
   - Routes dans routes.php : `POST /api/paiements-validate/{id}` et `POST /api/paiements-reject/{id}` (lignes 245-246)
   - Routes utilisées par Flutter : `PATCH /api/payments/{id}/approve` et `PATCH /api/payments/{id}/reject`
   - **Problème** : Incohérence entre les routes françaises et anglaises, et entre POST et PATCH
   - **Solution** : Vérifier quelle route fonctionne et aligner le service Flutter

3. **Factures - Validation/Rejet** :
   - Routes dans routes.php : `POST /api/factures-validate/{id}` et `POST /api/factures-reject/{id}` (lignes 249-250)
   - Routes utilisées par Flutter : `POST /api/factures-validate/{id}` et `POST /api/factures-reject/{id}`
   - **Statut** : ✅ Routes cohérentes

## Routes Manquantes

### 1. **Stock - Validation et Rejet** ⚠️ CRITIQUE

**Routes manquantes :**
- `POST /api/stocks/{id}/valider` - Valider un article de stock
- `POST /api/stocks/{id}/rejeter` - Rejeter un article de stock

**Autorisations requises :** Patron (6) et Admin (1)

**Exemple d'implémentation Laravel :**

```php
// Dans routes/api.php, ajouter dans le groupe middleware(['role:1,6'])
Route::post('/stocks/{id}/valider', [StockController::class, 'validateStock']);
Route::post('/stocks/{id}/rejeter', [StockController::class, 'rejectStock']);

// Dans StockController.php
public function validateStock($id)
{
    $stock = Stock::findOrFail($id);
    
    // Vérifier que le stock est en attente
    if ($stock->status !== 'en_attente' && $stock->status !== 'pending') {
        return response()->json([
            'success' => false,
            'message' => 'Ce stock ne peut pas être validé'
        ], 422);
    }
    
    $stock->status = 'valide';
    $stock->date_validation = now();
    $stock->validated_by = auth()->id();
    $stock->save();
    
    return response()->json([
        'success' => true,
        'message' => 'Stock validé avec succès',
        'data' => $stock
    ]);
}

public function rejectStock(Request $request, $id)
{
    $request->validate([
        'commentaire' => 'required|string|max:500'
    ]);
    
    $stock = Stock::findOrFail($id);
    
    // Vérifier que le stock est en attente
    if ($stock->status !== 'en_attente' && $stock->status !== 'pending') {
        return response()->json([
            'success' => false,
            'message' => 'Ce stock ne peut pas être rejeté'
        ], 422);
    }
    
    $stock->status = 'rejete';
    $stock->commentaire = $request->commentaire;
    $stock->rejected_by = auth()->id();
    $stock->rejected_at = now();
    $stock->save();
    
    return response()->json([
        'success' => true,
        'message' => 'Stock rejeté avec succès',
        'data' => $stock
    ]);
}
```

---

### 2. **Bon de Commande Fournisseur - Rejet** ⚠️ CRITIQUE

**Route manquante :**
- `POST /api/bons-de-commande-reject/{id}` - Rejeter un bon de commande fournisseur

**Note :** La route `/bons-de-commande-validate/{id}` existe mais est commentée dans le fichier routes (lignes 200-201). Elle doit être décommentée.

**Autorisations requises :** Patron (6) et Admin (1)

**Exemple d'implémentation Laravel :**

```php
// Dans routes/api.php, dans le groupe middleware(['role:1,6'])
// Décommenter cette ligne :
Route::post('/bons-de-commande-validate/{id}', [BonDeCommandeController::class, 'validateBon']);

// Ajouter cette route :
Route::post('/bons-de-commande-reject/{id}', [BonDeCommandeController::class, 'rejectBon']);

// Dans BonDeCommandeController.php
public function rejectBon(Request $request, $id)
{
    $request->validate([
        'commentaire' => 'required|string|max:500'
    ]);
    
    $bonDeCommande = BonDeCommande::findOrFail($id);
    
    // Vérifier que le bon de commande est en attente
    if ($bonDeCommande->statut !== 'en_attente') {
        return response()->json([
            'success' => false,
            'message' => 'Ce bon de commande ne peut pas être rejeté'
        ], 422);
    }
    
    $bonDeCommande->statut = 'rejete';
    $bonDeCommande->commentaire = $request->commentaire;
    $bonDeCommande->rejected_by = auth()->id();
    $bonDeCommande->rejected_at = now();
    $bonDeCommande->save();
    
    return response()->json([
        'success' => true,
        'message' => 'Bon de commande rejeté avec succès',
        'bon_de_commande' => $bonDeCommande
    ]);
}
```

---

### 3. **Fournisseurs - Rejet** ⚠️ CRITIQUE

**Route manquante :**
- `POST /api/fournisseurs-reject/{id}` - Rejeter un fournisseur

**Note :** La route `/fournisseurs-validate/{id}` existe (ligne 400) mais appelle la méthode `activate` au lieu d'une méthode de validation dédiée. Il serait préférable d'avoir une méthode `validate` séparée.

**Autorisations requises :** Patron (6) et Admin (1)

**Exemple d'implémentation Laravel :**

```php
// Dans routes/api.php, dans le groupe middleware(['role:1,6'])
Route::post('/fournisseurs-reject/{id}', [FournisseurController::class, 'reject']);

// Dans FournisseurController.php
public function reject(Request $request, $id)
{
    $request->validate([
        'rejection_reason' => 'required|string|max:500',
        'rejection_comment' => 'nullable|string|max:1000'
    ]);
    
    $fournisseur = Fournisseur::findOrFail($id);
    
    // Vérifier que le fournisseur est en attente
    if ($fournisseur->statut !== 'en_attente' && $fournisseur->statut !== 'pending') {
        return response()->json([
            'success' => false,
            'message' => 'Ce fournisseur ne peut pas être rejeté'
        ], 422);
    }
    
    $fournisseur->statut = 'rejete';
    $fournisseur->rejection_reason = $request->rejection_reason;
    $fournisseur->rejection_comment = $request->rejection_comment;
    $fournisseur->rejected_by = auth()->id();
    $fournisseur->rejected_at = now();
    $fournisseur->save();
    
    return response()->json([
        'success' => true,
        'message' => 'Fournisseur rejeté avec succès',
        'data' => $fournisseur
    ]);
}
```

---

### 4. **Dépenses - Validation et Rejet** ⚠️ CRITIQUE

**Routes manquantes :**
- `POST /api/expenses-validate/{id}` - Approuver une dépense
- `POST /api/expenses-reject/{id}` - Rejeter une dépense

**Autorisations requises :** Patron (6) et Admin (1)

**Note :** Le service Flutter utilise ces routes exactes, elles doivent être ajoutées au backend.

**Exemple d'implémentation Laravel :**

```php
// Dans routes/api.php, dans le groupe middleware(['role:1,6'])
Route::post('/expenses-approve/{id}', [ExpenseController::class, 'approve']);
Route::post('/expenses-reject/{id}', [ExpenseController::class, 'reject']);

// Dans ExpenseController.php
public function approve(Request $request, $id)
{
    $expense = Expense::findOrFail($id);
    
    if ($expense->status !== 'pending') {
        return response()->json([
            'success' => false,
            'message' => 'Cette dépense ne peut pas être approuvée'
        ], 422);
    }
    
    $expense->status = 'approved';
    $expense->approved_by = auth()->id();
    $expense->approved_at = now();
    if ($request->has('notes')) {
        $expense->approval_notes = $request->notes;
    }
    $expense->save();
    
    return response()->json([
        'success' => true,
        'message' => 'Dépense approuvée avec succès',
        'data' => $expense
    ]);
}

public function reject(Request $request, $id)
{
    $request->validate([
        'reason' => 'required|string|max:500'
    ]);
    
    $expense = Expense::findOrFail($id);
    
    if ($expense->status !== 'pending') {
        return response()->json([
            'success' => false,
            'message' => 'Cette dépense ne peut pas être rejetée'
        ], 422);
    }
    
    $expense->status = 'rejected';
    $expense->rejection_reason = $request->reason;
    $expense->rejected_by = auth()->id();
    $expense->rejected_at = now();
    $expense->save();
    
    return response()->json([
        'success' => true,
        'message' => 'Dépense rejetée avec succès',
        'data' => $expense
    ]);
}
```

---

### 5. **Salaires - Rejet** ⚠️ CRITIQUE

**Route manquante :**
- `POST /api/salaries-reject/{id}` - Rejeter un salaire

**Note :** La route `/salaries-validate/{id}` existe (ligne 395) et appelle `approve`. Le service Flutter utilise `/salaries-reject/{id}` pour le rejet.

**Autorisations requises :** Patron (6) et Admin (1)

**Exemple d'implémentation Laravel :**

```php
// Dans routes/api.php, dans le groupe middleware(['role:1,6'])
Route::post('/salaries-reject/{id}', [SalaryController::class, 'reject']);

// Dans SalaryController.php
public function reject(Request $request, $id)
{
    $request->validate([
        'reason' => 'required|string|max:500'
    ]);
    
    $salary = Salary::findOrFail($id);
    
    if ($salary->status !== 'pending') {
        return response()->json([
            'success' => false,
            'message' => 'Ce salaire ne peut pas être rejeté'
        ], 422);
    }
    
    $salary->status = 'rejected';
    $salary->rejection_reason = $request->reason;
    $salary->rejected_by = auth()->id();
    $salary->rejected_at = now();
    $salary->save();
    
    return response()->json([
        'success' => true,
        'message' => 'Salaire rejeté avec succès',
        'data' => $salary
    ]);
}
```

---

## Routes Existantes mais Commentées

### Bon de Commande Fournisseur - Validation

**Route commentée :**
- `POST /api/bons-de-commande-validate/{id}` (lignes 200-201)

**Action requise :** Décommenter cette route dans `routes/api.php`

```php
// Décommenter ces lignes :
Route::post('/bons-de-commande-validate/{id}', [BonDeCommandeController::class, 'validateBon']);
// Route::post('/bons-de-commande-reject/{id}', [BonDeCommandeController::class, 'reject']);
```

---

## Routes Existantes mais à Vérifier

### Fournisseurs - Validation

**Route existante :**
- `POST /api/fournisseurs-validate/{id}` (ligne 400)

**Problème potentiel :** Cette route appelle `activate` au lieu d'une méthode de validation dédiée. Vérifier que la méthode `activate` dans `FournisseurController` gère correctement la validation (changement de statut de `en_attente` à `valide`).

**Recommandation :** Créer une méthode `validate` dédiée pour plus de clarté :

```php
// Dans routes/api.php
Route::post('/fournisseurs-validate/{id}', [FournisseurController::class, 'validate']);

// Dans FournisseurController.php
public function validate(Request $request, $id)
{
    $fournisseur = Fournisseur::findOrFail($id);
    
    if ($fournisseur->statut !== 'en_attente' && $fournisseur->statut !== 'pending') {
        return response()->json([
            'success' => false,
            'message' => 'Ce fournisseur ne peut pas être validé'
        ], 422);
    }
    
    $fournisseur->statut = 'valide';
    $fournisseur->validated_by = auth()->id();
    $fournisseur->validated_at = now();
    if ($request->has('validation_comment')) {
        $fournisseur->validation_comment = $request->validation_comment;
    }
    $fournisseur->save();
    
    return response()->json([
        'success' => true,
        'message' => 'Fournisseur validé avec succès',
        'data' => $fournisseur
    ]);
}
```

---

## Résumé des Actions Requises

### Actions Critiques (Doivent être implémentées)

1. ✅ **Stock** : Ajouter les routes `/stocks/{id}/valider` et `/stocks/{id}/rejeter`
2. ✅ **Bon de Commande Fournisseur** : 
   - Décommenter `/bons-de-commande-validate/{id}`
   - Ajouter `/bons-de-commande-reject/{id}`
3. ✅ **Fournisseurs** : Ajouter la route `/fournisseurs-reject/{id}`
4. ✅ **Dépenses** : Ajouter les routes `/expenses-validate/{id}` et `/expenses-reject/{id}`
5. ✅ **Salaires** : Ajouter la route `/salaries-reject/{id}`

### Actions Recommandées

1. **Fournisseurs** : Créer une méthode `validate` dédiée au lieu d'utiliser `activate`

---

## Format de Réponse Standard

Toutes les routes de validation/rejet doivent retourner un format JSON cohérent :

**Succès (200) :**
```json
{
    "success": true,
    "message": "Message de succès",
    "data": { /* Objet mis à jour */ }
}
```

**Erreur de validation (422) :**
```json
{
    "success": false,
    "message": "Message d'erreur",
    "errors": { /* Erreurs de validation */ }
}
```

**Erreur serveur (500) :**
```json
{
    "success": false,
    "message": "Message d'erreur"
}
```

---

## Notes Importantes

1. **Autorisations** : Toutes les routes de validation/rejet doivent être protégées par le middleware `['role:1,6']` (Admin et Patron uniquement).

2. **Vérification de statut** : Avant de valider ou rejeter, toujours vérifier que l'élément est dans un statut approprié (généralement `en_attente` ou `pending`).

3. **Historique** : Enregistrer qui a validé/rejeté et quand (`validated_by`, `validated_at`, `rejected_by`, `rejected_at`).

4. **Notifications** : Considérer l'envoi de notifications aux utilisateurs concernés lors des validations/rejets.

---

## Date de Création

Ce document a été créé le : **2025-01-XX**

## Dernière Mise à Jour

Dernière mise à jour le : **2025-01-XX**

