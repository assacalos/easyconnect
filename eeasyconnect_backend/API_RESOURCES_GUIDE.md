# Guide d'utilisation des API Resources

## Bonnes pratiques

### 1. Collections pour les listes (`index()`)

Utilisez `Resource::collection()` pour transformer les listes :

```php
// ✅ CORRECT
public function index(Request $request)
{
    $query = Model::with(['relation1', 'relation2']);
    $items = $query->paginate(15);
    
    return response()->json([
        'success' => true,
        'data' => Resource::collection($items->items()),
        'pagination' => [...]
    ]);
}
```

### 2. Resource simple pour les détails (`show()`)

Utilisez `new Resource()` pour transformer un seul élément :

```php
// ✅ CORRECT
public function show($id)
{
    $item = Model::with(['relation1', 'relation2'])->findOrFail($id);
    
    return response()->json([
        'success' => true,
        'data' => new Resource($item)
    ]);
}
```

### 3. Utilisation de `whenLoaded()` pour les relations

**IMPORTANT** : N'incluez les relations dans le Resource que si elles ont été eager loaded avec `with()` :

```php
// ✅ CORRECT - Utilise whenLoaded()
public function toArray(Request $request): array
{
    return [
        'id' => $this->id,
        'name' => $this->name,
        'user' => $this->whenLoaded('user', function () {
            return [
                'id' => $this->user->id,
                'name' => $this->user->nom . ' ' . $this->user->prenom,
            ];
        }),
    ];
}
```

```php
// ❌ INCORRECT - Accède directement à la relation sans vérifier
public function toArray(Request $request): array
{
    return [
        'id' => $this->id,
        'name' => $this->name,
        'user' => [
            'id' => $this->user->id, // ❌ Erreur si user n'est pas chargé
        ],
    ];
}
```

## Exemple complet : SupplierResource

```php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SupplierResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'nom' => $this->nom,
            'email' => $this->email,
            // Relations chargées uniquement si eager loaded
            'created_by' => $this->whenLoaded('createdBy', function () {
                return [
                    'id' => $this->createdBy->id,
                    'name' => $this->createdBy->nom . ' ' . $this->createdBy->prenom,
                    'email' => $this->createdBy->email,
                ];
            }),
            'validated_by' => $this->whenLoaded('validatedBy', function () {
                return [
                    'id' => $this->validatedBy->id,
                    'name' => $this->validatedBy->nom . ' ' . $this->validatedBy->prenom,
                ];
            }),
        ];
    }
}
```

## Utilisation dans le contrôleur

```php
// index() - Liste avec Collection
public function index(Request $request)
{
    $query = Fournisseur::with(['createdBy', 'updatedBy', 'validatedBy', 'rejectedBy']);
    $suppliers = $query->paginate(15);
    
    return response()->json([
        'success' => true,
        'data' => SupplierResource::collection($suppliers->items()),
        'pagination' => [...]
    ]);
}

// show() - Détail avec Resource simple
public function show($id)
{
    $supplier = Fournisseur::with(['createdBy', 'updatedBy', 'validatedBy', 'rejectedBy'])
        ->findOrFail($id);
    
    return response()->json([
        'success' => true,
        'data' => new SupplierResource($supplier)
    ]);
}
```

## Avantages

1. **Séparation des responsabilités** : La transformation des données est centralisée dans les Resources
2. **Réutilisabilité** : Un même Resource peut être utilisé dans plusieurs contrôleurs
3. **Performance** : `whenLoaded()` évite les requêtes N+1
4. **Cohérence** : Format de réponse standardisé dans toute l'API
5. **Maintenabilité** : Facile de modifier le format de réponse

## État actuel du projet

✅ **FournisseurController** : Utilise correctement `SupplierResource::collection()` pour les listes et `new SupplierResource()` pour les détails

📝 **À faire** : Créer des Resources pour les autres modèles principaux (Client, Facture, Paiement, etc.) si nécessaire

