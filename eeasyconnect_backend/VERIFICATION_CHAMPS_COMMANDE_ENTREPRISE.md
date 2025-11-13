# Vérification des champs - Commande Entreprise

## ✅ Vérification complète effectuée

### Champs envoyés par Flutter vs Backend

| Champ Flutter | Champ Backend | Statut | Migration | Modèle | Contrôleur |
|---------------|---------------|--------|-----------|--------|------------|
| `reference` | `reference` | ✅ | ✅ | ✅ | ✅ |
| `client_id` | `client_id` | ✅ | ✅ | ✅ | ✅ |
| `user_id` | `user_id` | ✅ | ✅ | ✅ | ✅ |
| `date_creation` | `date_creation` | ✅ | ✅ | ✅ | ✅ |
| `date_livraison_prevue` | `date_livraison_prevue` | ✅ | ✅ | ✅ | ✅ |
| `adresse_livraison` | `adresse_livraison` | ✅ | ✅ | ✅ | ✅ |
| `notes` | `notes` | ✅ | ✅ | ✅ | ✅ |
| `items` | `items` | ✅ | ✅ | ✅ | ✅ |
| `items[].designation` | `designation` | ✅ | ✅ | ✅ | ✅ |
| `items[].unite` | `unite` | ✅ | ✅ | ✅ | ✅ |
| `items[].quantite` | `quantite` | ✅ | ✅ | ✅ | ✅ |
| `items[].prix_unitaire` | `prix_unitaire` | ✅ | ✅ | ✅ | ✅ |
| `items[].description` | `description` | ✅ | ✅ | ✅ | ✅ |
| `items[].date_livraison` | `date_livraison` | ✅ | ✅ | ✅ | ✅ |
| `remise_globale` | `remise_globale` | ✅ | ✅ | ✅ | ✅ |
| `tva` | `tva` | ✅ | ✅ | ✅ | ✅ |
| `conditions` | `conditions` | ✅ | ✅ | ✅ | ✅ |

## Détails de validation

### Commande principale

```php
// Validation dans CommandeEntrepriseController::store()
'reference' => 'nullable|string|unique:commandes_entreprise,reference',
'client_id' => 'required|exists:clients,id',
'user_id' => 'nullable|exists:users,id',
'date_creation' => 'nullable|date',
'date_livraison_prevue' => 'nullable|date',
'adresse_livraison' => 'nullable|string',
'notes' => 'nullable|string',
'remise_globale' => 'nullable|numeric|min:0|max:100',
'tva' => 'nullable|numeric|min:0|max:100',
'conditions' => 'nullable|string',
```

### Items

```php
'items' => 'required|array|min:1',
'items.*.designation' => 'required|string',
'items.*.unite' => 'required|string',
'items.*.quantite' => 'required|integer|min:1',
'items.*.prix_unitaire' => 'required|numeric|min:0',
'items.*.description' => 'nullable|string',
'items.*.date_livraison' => 'nullable|date',
```

## Format des dates

Les dates envoyées par Flutter au format ISO 8601 avec timezone (`2024-01-15T10:30:00.000Z`) sont correctement gérées par Laravel :

- La validation `'date'` accepte les formats ISO 8601
- Le cast `'datetime'` dans le modèle convertit automatiquement en Carbon
- Les dates sont stockées en `dateTime` dans la base de données

## Exemple de payload Flutter

```json
{
  "reference": "BC-2024-001",
  "client_id": 5,
  "user_id": 12,
  "date_creation": "2024-01-15T10:30:00.000Z",
  "date_livraison_prevue": "2024-01-20T00:00:00.000Z",
  "adresse_livraison": "123 Rue Example, Paris",
  "notes": "Livraison urgente",
  "items": [
    {
      "designation": "Produit A",
      "unite": "unité",
      "quantite": 10,
      "prix_unitaire": 25.50,
      "description": "Description optionnelle",
      "date_livraison": "2024-01-20T00:00:00.000Z"
    }
  ],
  "remise_globale": 5.0,
  "tva": 20.0,
  "conditions": "Paiement à 30 jours"
}
```

## ✅ Conclusion

**Tous les champs sont correctement implémentés :**
- ✅ Aucune erreur d'orthographe
- ✅ Tous les champs sont présents dans les migrations
- ✅ Tous les champs sont dans les modèles (fillable)
- ✅ Tous les champs sont validés dans le contrôleur
- ✅ Les formats de données sont corrects
- ✅ Les relations sont bien configurées

**Le système est prêt à recevoir les données de Flutter !**


