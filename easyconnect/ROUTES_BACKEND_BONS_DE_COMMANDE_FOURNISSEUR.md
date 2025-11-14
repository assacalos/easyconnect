# Routes API Backend - Bons de Commande Fournisseur

## Routes nécessaires pour le fonctionnement complet

### 1. **LISTER tous les bons de commande** ⚠️ MANQUANTE

**Route :** `GET /api/bons-de-commande-list` ou `GET /api/bons-de-commande`

**Autorisations :** Commercial (2), Comptable (3), Admin (1), Patron (6)

**Description :** Récupère la liste de tous les bons de commande fournisseur avec possibilité de filtrage.

**Paramètres de requête (optionnels) :**
- `status` : Filtrer par statut (en_attente, valide, en_cours, livre, annule)
- `fournisseur_id` : Filtrer par fournisseur
- `user_id` : Filtrer par créateur (pour les commerciaux)
- `date_debut` : Date de début pour filtrer
- `date_fin` : Date de fin pour filtrer

**Exemple de réponse :**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "fournisseur_id": 2,
      "numero_commande": "BC-2025-0001",
      "date_commande": "2025-01-15",
      "montant_total": "6105.00",
      "status": "en_attente",
      "fournisseur": {
        "id": 2,
        "nom": "Fournisseur Informatique SARL",
        "email": "contact@fournisseur-info.com"
      },
      "items": [...]
    }
  ],
  "message": "Bons de commande récupérés avec succès"
}
```

**OU format alternatif :**
```json
{
  "success": true,
  "bon_de_commandes": [...]
}
```

---

### 2. **Consulter un bon de commande**

**Route :** `GET /api/bons-de-commande-show/{id}` ✅ EXISTANTE

**Autorisations :** Commercial (2), Comptable (3), Admin (1), Patron (6)

**Description :** Récupère les détails d'un bon de commande spécifique avec ses relations.

**Paramètres :**
- `{id}` : ID du bon de commande

**Exemple de réponse :**
```json
{
  "success": true,
  "bon_de_commande": {
    "id": 1,
    "fournisseur_id": 2,
    "numero_commande": "BC-2025-0001",
    "date_commande": "2025-01-15",
    "montant_total": "6105.00",
    "status": "en_attente",
    "fournisseur": {...},
    "createur": {...},
    "items": [...]
  },
  "message": "Bon de commande récupéré avec succès"
}
```

---

### 3. **Créer un bon de commande**

**Route :** `POST /api/bons-de-commande-create` ✅ EXISTANTE

**Autorisations :** Commercial (2), Comptable (3), Admin (1), Patron (6)

**Description :** Crée un nouveau bon de commande fournisseur.

**Corps de la requête :**
```json
{
  "fournisseur_id": 2,
  "numero_commande": "BC-2025-0001",
  "date_commande": "2025-01-15",
  "date_livraison_prevue": "2025-01-30",
  "description": "Commande de matériel",
  "status": "en_attente",
  "items": [
    {
      "designation": "Article 1",
      "quantite": 5,
      "prix_unitaire": 100.00
    }
  ]
}
```

**Réponse :** `201 Created`

---

### 4. **Modifier un bon de commande**

**Route :** `PUT /api/bons-de-commande-update/{id}` ✅ EXISTANTE

**Autorisations :** Commercial (2), Comptable (3), Admin (1), Patron (6)

**Description :** Modifie un bon de commande existant. Ne peut être modifié que si le statut est `en_attente`.

**Paramètres :**
- `{id}` : ID du bon de commande

**Corps de la requête :** (Tous les champs sont optionnels)
```json
{
  "numero_commande": "BC-2025-0001",
  "date_commande": "2025-01-15",
  "description": "Description mise à jour",
  "items": [...]
}
```

---

### 5. **Valider un bon de commande**

**Route :** `POST /api/bons-de-commande-validate/{id}` ✅ EXISTANTE

**Autorisations :** Admin (1), Patron (6)

**Description :** Valide un bon de commande. Change le statut de `en_attente` à `valide`.

**Paramètres :**
- `{id}` : ID du bon de commande

**Réponse :**
```json
{
  "success": true,
  "bon_de_commande": {...},
  "message": "Bon de commande validé avec succès"
}
```

---

### 6. **Rejeter un bon de commande**

**Route :** `POST /api/bons-de-commande-reject/{id}` ✅ EXISTANTE

**Autorisations :** Admin (1), Patron (6)

**Description :** Rejette un bon de commande.

**Paramètres :**
- `{id}` : ID du bon de commande

**Corps de la requête :**
```json
{
  "commentaire": "Raison du rejet"
}
```

---

### 7. **Marquer comme en cours**

**Route :** `POST /api/mark-in-progress-bons-de-commande/{id}` ✅ EXISTANTE

**Autorisations :** Commercial (2), Comptable (3), Admin (1), Patron (6)

**Description :** Marque un bon de commande comme étant en cours de traitement. Le statut doit être `valide` avant de pouvoir être marqué comme `en_cours`.

**Paramètres :**
- `{id}` : ID du bon de commande

---

### 8. **Marquer comme livré**

**Route :** `POST /api/bons-de-commande-mark-delivered/{id}` ✅ EXISTANTE

**Autorisations :** Commercial (2), Comptable (3), Admin (1), Patron (6)

**Description :** Marque un bon de commande comme livré. Le statut doit être `en_cours` avant de pouvoir être marqué comme `livre`.

**Paramètres :**
- `{id}` : ID du bon de commande

---

### 9. **Annuler un bon de commande**

**Route :** `POST /api/bons-de-commande-cancel/{id}` ✅ EXISTANTE

**Autorisations :** Commercial (2), Comptable (3), Admin (1), Patron (6)

**Description :** Annule un bon de commande. Ne peut pas être annulé si déjà livré ou déjà annulé.

**Paramètres :**
- `{id}` : ID du bon de commande

**Corps de la requête :**
```json
{
  "commentaire": "Raison de l'annulation"
}
```

---

### 10. **Supprimer un bon de commande**

**Route :** `DELETE /api/bons-de-commande-destroy/{id}` ou `DELETE /api/bons-de-commande/{id}`

**Autorisations :** Commercial (2), Comptable (3), Admin (1), Patron (6)

**Description :** Supprime un bon de commande. Ne peut être supprimé que si le statut est `en_attente`.

**Paramètres :**
- `{id}` : ID du bon de commande

**Réponse :**
```json
{
  "success": true,
  "message": "Bon de commande supprimé avec succès"
}
```

---

### 11. **Rapports des bons de commande**

**Route :** `GET /api/bons-de-commande-reports` ✅ EXISTANTE

**Autorisations :** Commercial (2), Comptable (3), Admin (1), Patron (6)

**Description :** Génère un rapport détaillé des bons de commande avec statistiques.

**Paramètres de requête (optionnels) :**
- `date_debut` : Date de début pour filtrer
- `date_fin` : Date de fin pour filtrer

---

## Récapitulatif des routes nécessaires

### Routes utilisées par le code Flutter (OBLIGATOIRES)

| Méthode | Route | Statut | Priorité | Description | Utilisée dans |
|---------|-------|--------|----------|-------------|---------------|
| `GET` | `/api/bons-de-commande-list` | ⚠️ **MANQUANTE** | **CRITIQUE** | Lister tous les bons de commande | `BonDeCommandeFournisseurService.getBonDeCommandes()` |
| `GET` | `/api/bons-de-commande-show/{id}` | ✅ Existante | **CRITIQUE** | Consulter un bon de commande | `BonDeCommandeFournisseurService.getBonDeCommande()` |
| `POST` | `/api/bons-de-commande-create` | ✅ Existante | **CRITIQUE** | Créer un bon de commande | `BonDeCommandeFournisseurService.createBonDeCommande()` |
| `PUT` | `/api/bons-de-commande-update/{id}` | ✅ Existante | **CRITIQUE** | Modifier un bon de commande | `BonDeCommandeFournisseurService.updateBonDeCommande()` |
| `DELETE` | `/api/bons-de-commande-destroy/{id}` | ⚠️ À vérifier | Haute | Supprimer un bon de commande | `BonDeCommandeFournisseurService.deleteBonDeCommande()` |

### Routes supplémentaires (optionnelles pour fonctionnalités avancées)

| Méthode | Route | Statut | Priorité | Description |
|---------|-------|--------|----------|-------------|
| `POST` | `/api/bons-de-commande-validate/{id}` | ✅ Existante | Moyenne | Valider un bon de commande |
| `POST` | `/api/bons-de-commande-reject/{id}` | ✅ Existante | Moyenne | Rejeter un bon de commande |
| `POST` | `/api/mark-in-progress-bons-de-commande/{id}` | ✅ Existante | Moyenne | Marquer comme en cours |
| `POST` | `/api/bons-de-commande-mark-delivered/{id}` | ✅ Existante | Moyenne | Marquer comme livré |
| `POST` | `/api/bons-de-commande-cancel/{id}` | ✅ Existante | Moyenne | Annuler un bon de commande |
| `GET` | `/api/bons-de-commande-reports` | ✅ Existante | Basse | Générer un rapport |

---

## Route manquante critique

### Route de liste : `GET /api/bons-de-commande-list`

**Cette route est ABSOLUMENT NÉCESSAIRE** pour que la page de liste fonctionne.

**Spécifications requises :**

1. **Endpoint :** `GET /api/bons-de-commande-list`

2. **Paramètres de requête (optionnels) :**
   - `status` : string - Filtrer par statut (en_attente, valide, en_cours, livre, annule)
   - `fournisseur_id` : integer - Filtrer par fournisseur
   - `user_id` : integer - Filtrer par créateur (pour les commerciaux)
   - `date_debut` : date - Date de début (format: YYYY-MM-DD)
   - `date_fin` : date - Date de fin (format: YYYY-MM-DD)

3. **Format de réponse attendu :**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "fournisseur_id": 2,
      "numero_commande": "BC-2025-0001",
      "date_commande": "2025-01-15",
      "date_livraison_prevue": "2025-01-30",
      "montant_total": "6105.00",
      "description": "Commande de matériel",
      "status": "en_attente",
      "commentaire": null,
      "conditions_paiement": null,
      "delai_livraison": 15,
      "user_id": 1,
      "created_at": "2025-01-15T10:30:00.000000Z",
      "updated_at": "2025-01-15T10:30:00.000000Z",
      "fournisseur": {
        "id": 2,
        "nom": "Fournisseur Informatique SARL",
        "email": "contact@fournisseur-info.com",
        "telephone": "+33 1 23 45 67 89"
      },
      "createur": {
        "id": 1,
        "nom": "Dupont",
        "prenom": "Jean"
      },
      "items": [
        {
          "id": 1,
          "bon_de_commande_id": 1,
          "ref": "ORD-001",
          "designation": "Ordinateur portable HP EliteBook",
          "quantite": 5,
          "prix_unitaire": "1200.00",
          "description": "Intel Core i7, 16GB RAM, 512GB SSD"
        }
      ]
    }
  ],
  "message": "Bons de commande récupérés avec succès"
}
```

**OU format alternatif accepté :**
```json
{
  "success": true,
  "bon_de_commandes": [...]
}
```

4. **Filtrage par rôle :**
   - **Commercial (role: 2)** : Ne voir que ses propres bons de commande (filtrer par `user_id`)
   - **Comptable (role: 3)** : Voir tous les bons de commande
   - **Admin (role: 1)** : Voir tous les bons de commande
   - **Patron (role: 6)** : Voir tous les bons de commande

5. **Codes de réponse :**
   - `200` : Succès
   - `401` : Non autorisé (token invalide ou expiré)
   - `403` : Accès refusé (permissions insuffisantes)
   - `500` : Erreur serveur

---

## Exemple d'implémentation Laravel

```php
// Dans routes/api.php
Route::middleware(['auth:sanctum'])->group(function () {
    // Route de liste (À CRÉER)
    Route::get('/bons-de-commande-list', [BonDeCommandeController::class, 'index'])
        ->middleware('role:1,2,3,6');
    
    // Autres routes existantes...
    Route::get('/bons-de-commande-show/{id}', [BonDeCommandeController::class, 'show'])
        ->middleware('role:1,2,3,6');
    Route::post('/bons-de-commande-create', [BonDeCommandeController::class, 'store'])
        ->middleware('role:1,2,3,6');
    // etc.
});
```

```php
// Dans BonDeCommandeController.php
public function index(Request $request)
{
    $query = BonDeCommande::with(['fournisseur', 'createur', 'items']);
    
    // Filtrage par rôle
    if (auth()->user()->role == 2) { // Commercial
        $query->where('user_id', auth()->id());
    }
    
    // Filtrage par statut
    if ($request->has('status')) {
        $query->where('status', $request->status);
    }
    
    // Filtrage par fournisseur
    if ($request->has('fournisseur_id')) {
        $query->where('fournisseur_id', $request->fournisseur_id);
    }
    
    // Filtrage par dates
    if ($request->has('date_debut')) {
        $query->where('date_commande', '>=', $request->date_debut);
    }
    if ($request->has('date_fin')) {
        $query->where('date_commande', '<=', $request->date_fin);
    }
    
    $bonsDeCommande = $query->orderBy('created_at', 'desc')->get();
    
    return response()->json([
        'success' => true,
        'data' => $bonsDeCommande,
        'message' => 'Bons de commande récupérés avec succès'
    ]);
}
```

---

## Checklist pour le backend

- [ ] **CRITIQUE** : Créer la route `GET /api/bons-de-commande-list`
- [ ] Implémenter le filtrage par statut
- [ ] Implémenter le filtrage par fournisseur
- [ ] Implémenter le filtrage par créateur (pour commerciaux)
- [ ] Implémenter le filtrage par dates
- [ ] Retourner les relations (fournisseur, createur, items)
- [ ] Gérer les permissions par rôle
- [ ] Vérifier que la colonne s'appelle `status` (pas `statut`)
- [ ] Tester avec différents rôles utilisateurs

---

## Notes importantes

1. **Colonne `status`** : La colonne dans la base de données s'appelle `status` (en anglais), pas `statut` (en français).

2. **Format des dates** : Les dates doivent être au format `YYYY-MM-DD` ou ISO 8601.

3. **Format des montants** : Les montants peuvent être retournés comme strings ou numbers, le code Flutter gère les deux.

4. **Relations** : Il est important de retourner les relations (`fournisseur`, `createur`, `items`) pour éviter des requêtes supplémentaires.

5. **Pagination** : Si le nombre de bons de commande devient important, envisager d'ajouter la pagination.

