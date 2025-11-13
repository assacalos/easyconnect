# Documentation API Stock - Format Flutter

## 📋 Champs Requis pour Créer un Stock

Flutter doit envoyer les données suivantes à l'endpoint `POST /api/stocks` :

### ✅ Champs OBLIGATOIRES (Minimum requis)

| Champ Flutter | Type | Format | Description | Exemple |
|--------------|------|--------|-------------|---------|
| `name` | string | - | Nom du produit/article | `"Ordinateur Portable HP"` |
| `description` | string | TEXT | Description détaillée du produit | `"Ordinateur portable HP 15.6 pouces, 8GB RAM"` |
| `category` | string | - | Nom de la catégorie (sélection depuis la liste) | `"Informatique"`, `"Mobilier"` |
| `sku` | string | - | Code SKU unique (Stock Keeping Unit) | `"HP-LAPTOP-001"` |
| `unit` | string | - | Unité de mesure | `"unité"`, `"kg"`, `"L"`, `"m"` |
| `currentQuantity` ou `current_quantity` | double/float | - | Quantité actuelle en stock | `10.0` |
| `minimumQuantity` ou `minimum_quantity` | double/float | - | Quantité minimale (alerte) | `5.0` |
| `reorderPoint` ou `reorder_point` | double/float | - | Seuil de réapprovisionnement | `3.0` |
| `unitCost` ou `unit_cost` | double/float | - | Coût unitaire (en FCFA) | `150000.0` |
| `status` | string | enum | Statut du stock | `"active"`, `"inactive"`, `"discontinued"` |

### ⚪ Champs OPTIONNELS

| Champ Flutter | Type | Format | Description | Exemple |
|--------------|------|--------|-------------|---------|
| `barcode` | string | - | Code-barres (unique si fourni) | `"1234567890123"` |
| `brand` | string | - | Marque du produit | `"HP"`, `"Dell"` |
| `model` | string | - | Modèle du produit | `"Pavilion 15"` |
| `maximumQuantity` ou `maximum_quantity` | double/float | - | Quantité maximale | `100.0` |
| `sellingPrice` ou `selling_price` | double/float | - | Prix de vente (en FCFA) | `180000.0` |
| `supplier` | string | - | Nom du fournisseur | `"Entreprise ABC"` |
| `location` | string | - | Localisation/Emplacement | `"Entrepôt A - Étagère 3"` |
| `notes` | string | TEXT | Notes internes | `"Stock fragile, manipuler avec précaution"` |
| `specifications` | object/array | JSON | Spécifications techniques (JSON) | `{"cpu": "Intel i5", "ram": "8GB"}` |
| `attachments` | array | JSON | Pièces jointes (chemins de fichiers) | `["/uploads/file1.pdf"]` |

---

## 📤 Format JSON à Envoyer (Exemple)

### Format Minimal (Requis uniquement)

```json
{
  "name": "Ordinateur Portable HP",
  "description": "Ordinateur portable HP 15.6 pouces, 8GB RAM, 256GB SSD",
  "category": "Informatique",
  "sku": "HP-LAPTOP-001",
  "unit": "unité",
  "currentQuantity": 10.0,
  "minimumQuantity": 5.0,
  "reorderPoint": 3.0,
  "unitCost": 150000.0,
  "status": "active"
}
```

### Format Complet (Avec tous les champs)

```json
{
  "name": "Ordinateur Portable HP",
  "description": "Ordinateur portable HP 15.6 pouces, 8GB RAM, 256GB SSD",
  "category": "Informatique",
  "sku": "HP-LAPTOP-001",
  "barcode": "1234567890123",
  "brand": "HP",
  "model": "Pavilion 15",
  "unit": "unité",
  "currentQuantity": 10.0,
  "minimumQuantity": 5.0,
  "maximumQuantity": 100.0,
  "reorderPoint": 3.0,
  "unitCost": 150000.0,
  "sellingPrice": 180000.0,
  "supplier": "Entreprise ABC",
  "location": "Entrepôt A - Étagère 3",
  "status": "active",
  "notes": "Stock fragile, manipuler avec précaution",
  "specifications": {
    "cpu": "Intel Core i5",
    "ram": "8GB",
    "storage": "256GB SSD",
    "screen": "15.6 pouces"
  },
  "attachments": ["/uploads/specs.pdf"]
}
```

### Format avec snake_case (Alternative)

```json
{
  "name": "Ordinateur Portable HP",
  "description": "Ordinateur portable HP...",
  "category": "Informatique",
  "sku": "HP-LAPTOP-001",
  "current_quantity": 10.0,
  "minimum_quantity": 5.0,
  "reorder_point": 3.0,
  "unit_cost": 150000.0,
  "selling_price": 180000.0,
  "status": "active"
}
```

---

## 🔄 Normalisation Automatique du Backend

Le backend accepte les champs en camelCase et snake_case. Vous pouvez utiliser l'un ou l'autre :

- `currentQuantity` ou `current_quantity` → `current_quantity`
- `minimumQuantity` ou `minimum_quantity` → `minimum_quantity`
- `maximumQuantity` ou `maximum_quantity` → `maximum_quantity`
- `reorderPoint` ou `reorder_point` → `reorder_point`
- `unitCost` ou `unit_cost` → `unit_cost`
- `sellingPrice` ou `selling_price` → `selling_price`

---

## 📥 Format de Réponse (Success)

### Status Code : `201 Created`

```json
{
  "success": true,
  "message": "Stock créé avec succès",
  "data": {
    "id": 1,
    "name": "Ordinateur Portable HP",
    "description": "Ordinateur portable HP 15.6 pouces, 8GB RAM",
    "category": "Informatique",
    "sku": "HP-LAPTOP-001",
    "barcode": "1234567890123",
    "brand": "HP",
    "model": "Pavilion 15",
    "unit": "unité",
    "current_quantity": 10.0,
    "minimum_quantity": 5.0,
    "maximum_quantity": 100.0,
    "reorder_point": 3.0,
    "unit_cost": 150000.0,
    "selling_price": 180000.0,
    "supplier": "Entreprise ABC",
    "location": "Entrepôt A - Étagère 3",
    "status": "active",
    "notes": "Stock fragile",
    "specifications": {
      "cpu": "Intel Core i5",
      "ram": "8GB"
    },
    "attachments": ["/uploads/specs.pdf"],
    "created_by": 1,
    "updated_by": 1,
    "creator_name": "Jean Dupont",
    "updater_name": "Jean Dupont",
    "formatted_current_quantity": "10,000 unité",
    "formatted_minimum_quantity": "5,000 unité",
    "formatted_maximum_quantity": "100,000 unité",
    "formatted_reorder_point": "3,000 unité",
    "formatted_unit_cost": "150 000,00 €",
    "formatted_selling_price": "180 000,00 €",
    "stock_value": 1500000.0,
    "formatted_stock_value": "1 500 000,00 €",
    "is_low_stock": false,
    "is_out_of_stock": false,
    "is_overstock": false,
    "needs_reorder": false,
    "created_at": "2024-11-02 16:00:00",
    "updated_at": "2024-11-02 16:00:00"
  }
}
```

---

## 📊 Statuts des Stocks

Les statuts possibles pour un stock sont :

| Status Backend | Status Flutter (Recommandé) | Description |
|----------------|----------------------------|-------------|
| `active` | `active` | Actif - En vente/disponible |
| `inactive` | `inactive` | Inactif - Temporairement indisponible |
| `discontinued` | `discontinued` | Discontinué - Plus produit/vendu |

**Note importante :** Le statut par défaut à la création est `active`.

---

## 🔍 Validation des Champs

### `name`
- **Requis** : Oui
- **Type** : String
- **Max** : 255 caractères
- **Description** : Nom du produit/article
- **Exemple** : `"Ordinateur Portable HP"`

### `description`
- **Requis** : Oui
- **Type** : String (TEXT)
- **Description** : Description détaillée du produit
- **Exemple** : `"Ordinateur portable HP 15.6 pouces, 8GB RAM, 256GB SSD"`

### `category`
- **Requis** : Oui
- **Type** : String
- **Max** : 255 caractères
- **Description** : Nom de la catégorie de stock (libre choix ou sélection depuis la liste)
- **Exemple** : `"Informatique"`, `"Mobilier"`, `"Équipement"`, `"Fournitures"`
- **Note** : Utilisez `/api/stock-categories` pour obtenir la liste des catégories existantes dans les stocks (pour sélection), ou créez directement votre propre catégorie

### `sku`
- **Requis** : Oui
- **Type** : String
- **Max** : 255 caractères
- **Unicité** : Doit être unique dans la base de données
- **Description** : Code SKU (Stock Keeping Unit) - Identifiant unique du produit
- **Exemple** : `"HP-LAPTOP-001"`, `"DELL-001"`

### `barcode`
- **Requis** : Non
- **Type** : String
- **Max** : 255 caractères
- **Unicité** : Doit être unique si fourni
- **Description** : Code-barres EAN/UPC
- **Exemple** : `"1234567890123"`

### `brand`
- **Requis** : Non
- **Type** : String
- **Max** : 255 caractères
- **Exemple** : `"HP"`, `"Dell"`, `"Lenovo"`

### `model`
- **Requis** : Non
- **Type** : String
- **Max** : 255 caractères
- **Exemple** : `"Pavilion 15"`, `"XPS 13"`

### `unit`
- **Requis** : Oui
- **Type** : String
- **Max** : 50 caractères
- **Description** : Unité de mesure
- **Exemples** : `"unité"`, `"kg"`, `"L"`, `"m"`, `"m²"`, `"m³"`

### `currentQuantity` / `current_quantity`
- **Requis** : Oui
- **Type** : Nombre (double/float)
- **Min** : 0
- **Précision** : 3 décimales
- **Description** : Quantité actuelle en stock
- **Exemple** : `10.0`, `5.5`, `100.250`

### `minimumQuantity` / `minimum_quantity`
- **Requis** : Oui
- **Type** : Nombre (double/float)
- **Min** : 0
- **Précision** : 3 décimales
- **Description** : Quantité minimale avant alerte
- **Exemple** : `5.0`

### `maximumQuantity` / `maximum_quantity`
- **Requis** : Non
- **Type** : Nombre (double/float)
- **Min** : 0
- **Précision** : 3 décimales
- **Description** : Quantité maximale autorisée (pour détecter les surstocks)
- **Exemple** : `100.0`

### `reorderPoint` / `reorder_point`
- **Requis** : Oui
- **Type** : Nombre (double/float)
- **Min** : 0
- **Précision** : 3 décimales
- **Description** : Seuil de réapprovisionnement (alerte)
- **Exemple** : `3.0`
- **Note** : Généralement inférieur ou égal à `minimum_quantity`

### `unitCost` / `unit_cost`
- **Requis** : Oui
- **Type** : Nombre (double/float)
- **Min** : 0
- **Précision** : 2 décimales
- **Description** : Coût unitaire d'achat (en FCFA)
- **Exemple** : `150000.0`, `75000.50`

### `sellingPrice` / `selling_price`
- **Requis** : Non
- **Type** : Nombre (double/float)
- **Min** : 0
- **Précision** : 2 décimales
- **Description** : Prix de vente unitaire (en FCFA)
- **Exemple** : `180000.0`, `90000.00`

### `supplier`
- **Requis** : Non
- **Type** : String
- **Max** : 255 caractères
- **Description** : Nom du fournisseur
- **Exemple** : `"Entreprise ABC"`

### `location`
- **Requis** : Non
- **Type** : String
- **Max** : 255 caractères
- **Description** : Localisation/Emplacement physique
- **Exemple** : `"Entrepôt A - Étagère 3"`, `"Bureau - Armoire 2"`

### `status`
- **Requis** : Oui
- **Type** : String (enum)
- **Valeurs** : `"active"`, `"inactive"`, `"discontinued"`
- **Description** : Statut du stock
- **Exemple** : `"active"`

### `notes`
- **Requis** : Non
- **Type** : String (TEXT)
- **Description** : Notes internes
- **Exemple** : `"Stock fragile, manipuler avec précaution"`

### `specifications`
- **Requis** : Non
- **Type** : Object/Array (JSON)
- **Description** : Spécifications techniques en JSON
- **Exemple** : 
```json
{
  "cpu": "Intel Core i5",
  "ram": "8GB",
  "storage": "256GB SSD",
  "screen": "15.6 pouces"
}
```

### `attachments`
- **Requis** : Non
- **Type** : Array (JSON)
- **Description** : Liste des chemins de fichiers attachés
- **Exemple** : `["/uploads/specs.pdf", "/uploads/image.jpg"]`

---

## 📝 Exemples de Code Flutter

### Exemple 1 : Création Simple

```dart
final stock = Stock(
  name: "Ordinateur Portable HP",
  description: "Ordinateur portable HP 15.6 pouces, 8GB RAM",
  category: "Informatique",
  sku: "HP-LAPTOP-001",
  unit: "unité",
  currentQuantity: 10.0,
  minimumQuantity: 5.0,
  reorderPoint: 3.0,
  unitCost: 150000.0,
  status: "active",
);

final result = await stockService.createStock(stock);
```

### Exemple 2 : Création avec Tous les Champs

```dart
final stock = Stock(
  name: "Ordinateur Portable HP",
  description: "Ordinateur portable HP 15.6 pouces, 8GB RAM, 256GB SSD",
  category: "Informatique",
  sku: "HP-LAPTOP-001",
  barcode: "1234567890123",
  brand: "HP",
  model: "Pavilion 15",
  unit: "unité",
  currentQuantity: 10.0,
  minimumQuantity: 5.0,
  maximumQuantity: 100.0,
  reorderPoint: 3.0,
  unitCost: 150000.0,
  sellingPrice: 180000.0,
  supplier: "Entreprise ABC",
  location: "Entrepôt A - Étagère 3",
  status: "active",
  notes: "Stock fragile",
  specifications: {
    "cpu": "Intel Core i5",
    "ram": "8GB",
    "storage": "256GB SSD"
  },
  attachments: ["/uploads/specs.pdf"],
);

final result = await stockService.createStock(stock);
```

### Exemple 3 : Envoi Direct via HTTP

```dart
final response = await http.post(
  Uri.parse('$baseUrl/stocks'),
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body: json.encode({
    'name': 'Ordinateur Portable HP',
    'description': 'Ordinateur portable HP 15.6 pouces, 8GB RAM',
    'category': 'Informatique',
    'sku': 'HP-LAPTOP-001',
    'unit': 'unité',
    'currentQuantity': 10.0,
    'minimumQuantity': 5.0,
    'reorderPoint': 3.0,
    'unitCost': 150000.0,
    'status': 'active',
  }),
);
```

---

## 🔗 Endpoints Disponibles

### CRUD de Base

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/stocks` | Liste des stocks (avec pagination et filtres) |
| `GET` | `/api/stocks/{id}` | Détails d'un stock |
| `POST` | `/api/stocks` | Créer un nouveau stock |
| `PUT` | `/api/stocks/{id}` | Mettre à jour un stock |
| `DELETE` | `/api/stocks/{id}` | Supprimer un stock |

### Actions sur les Stocks

| Méthode | Endpoint | Description | Body Requis |
|---------|----------|-------------|-------------|
| `POST` | `/api/stocks/{id}/add-stock` | Ajouter du stock (entrée) | `{"quantity": 10.0, "reason": "purchase", ...}` |
| `POST` | `/api/stocks/{id}/remove-stock` | Retirer du stock (sortie) | `{"quantity": 5.0, "reason": "sale", ...}` |
| `POST` | `/api/stocks/{id}/adjust-stock` | Ajuster le stock | `{"new_quantity": 15.0, "reason": "adjustment", ...}` |
| `POST` | `/api/stocks/{id}/transfer-stock` | Transférer du stock | `{"quantity": 2.0, "location_to": "...", ...}` |
| `POST` | `/api/stocks/{id}/rejeter` | Rejeter un stock | `{"commentaire": "..."}` |

### Utilitaires

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/stocks-statistics` | Statistiques des stocks |
| `GET` | `/api/stock-categories` | Liste des catégories de stocks |
| `GET` | `/api/stocks-low-stock` | Stocks en quantité faible |
| `GET` | `/api/stocks-out-of-stock` | Stocks épuisés |
| `GET` | `/api/stocks-overstock` | Surstocks |
| `GET` | `/api/stocks-needs-reorder` | Stocks nécessitant un réapprovisionnement |

---

## 📊 Format de Réponse - Liste des Stocks

### GET `/api/stocks`

```json
{
  "success": true,
  "message": "Liste des stocks récupérée avec succès",
  "data": {
    "data": [
      {
        "id": 1,
        "name": "Ordinateur Portable HP",
        "description": "Ordinateur portable HP...",
        "category": "Informatique",
        "sku": "HP-LAPTOP-001",
        "barcode": "1234567890123",
        "brand": "HP",
        "model": "Pavilion 15",
        "unit": "unité",
        "current_quantity": 10.0,
        "minimum_quantity": 5.0,
        "maximum_quantity": 100.0,
        "reorder_point": 3.0,
        "unit_cost": 150000.0,
        "selling_price": 180000.0,
        "supplier": "Entreprise ABC",
        "location": "Entrepôt A - Étagère 3",
        "status": "active",
        "status_libelle": "Actif",
        "notes": "Stock fragile",
        "specifications": {
          "cpu": "Intel Core i5",
          "ram": "8GB"
        },
        "attachments": ["/uploads/specs.pdf"],
        "is_low_stock": false,
        "is_out_of_stock": false,
        "is_overstock": false,
        "needs_reorder": false,
        "stock_value": 1500000.0,
        "formatted_stock_value": "1 500 000,00 €",
        "created_at": "2024-11-02 16:00:00",
        "updated_at": "2024-11-02 16:00:00"
      }
    ],
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
| `status` | string | Filtrer par statut | `?status=active` |
| `category` | string | Filtrer par catégorie | `?category=Informatique` |
| `supplier` | string | Filtrer par fournisseur | `?supplier=Entreprise ABC` |
| `location` | string | Filtrer par localisation | `?location=Entrepôt A` |
| `brand` | string | Filtrer par marque | `?brand=HP` |
| `sku` | string | Recherche par SKU | `?sku=HP-LAPTOP` |
| `barcode` | string | Recherche par code-barres | `?barcode=123456` |
| `low_stock` | boolean | Stocks en quantité faible | `?low_stock=true` |
| `out_of_stock` | boolean | Stocks épuisés | `?out_of_stock=true` |
| `overstock` | boolean | Surstocks | `?overstock=true` |
| `needs_reorder` | boolean | Nécessite réapprovisionnement | `?needs_reorder=true` |
| `per_page` | int | Nombre d'éléments par page | `?per_page=20` |

---

## 📊 Format de Réponse - Statistiques

### GET `/api/stocks-statistics`

```json
{
  "success": true,
  "data": {
    "total_stocks": 150,
    "active_stocks": 120,
    "inactive_stocks": 20,
    "discontinued_stocks": 10,
    "low_stock": 15,
    "out_of_stock": 5,
    "overstock": 3,
    "needs_reorder": 12,
    "total_value": 50000000.0,
    "average_value": 333333.33,
    "stocks_by_category": {
      "Informatique": 50,
      "Mobilier": 40,
      "Équipement": 30,
      "Fournitures": 30
    },
    "stocks_by_status": {
      "active": 120,
      "inactive": 20,
      "discontinued": 10
    },
    "stocks_by_supplier": {
      "Entreprise ABC": 60,
      "Fournisseur XYZ": 40,
      "Autre": 50
    }
  },
  "message": "Statistiques récupérées avec succès"
}
```

---

## 📊 Format de Réponse - Catégories de Stocks

### GET `/api/stock-categories`

Retourne la liste des catégories distinctes utilisées dans les stocks existants. Cette liste est dynamique et se met à jour automatiquement selon les stocks créés.

```json
{
  "success": true,
  "data": [
    {
      "name": "Informatique",
      "value": "Informatique"
    },
    {
      "name": "Mobilier",
      "value": "Mobilier"
    },
    {
      "name": "Équipement",
      "value": "Équipement"
    },
    {
      "name": "Fournitures",
      "value": "Fournitures"
    }
  ],
  "message": "Catégories récupérées avec succès"
}
```

**Note importante :** 
- Cette liste contient uniquement les catégories déjà utilisées dans les stocks existants
- Vous pouvez créer un nouveau stock avec une catégorie qui n'existe pas encore
- La nouvelle catégorie apparaîtra automatiquement dans cette liste après création du stock

---

## 🔄 Actions sur les Stocks

### Ajouter du Stock (Entrée)

**Endpoint** : `POST /api/stocks/{id}/add-stock`

**Body** :
```json
{
  "quantity": 10.0,
  "unit_cost": 150000.0,
  "reason": "purchase",
  "reference": "CMD-2024-001",
  "notes": "Réception de commande"
}
```

**Raisons possibles** : `purchase`, `sale`, `transfer`, `adjustment`, `return`, `loss`, `damage`, `expired`, `other`

**Réponse** :
```json
{
  "success": true,
  "data": {
    "id": 1,
    "stock_id": 1,
    "type": "in",
    "quantity": 10.0,
    "unit_cost": 150000.0,
    "total_cost": 1500000.0,
    "reason": "purchase",
    "reference": "CMD-2024-001",
    "notes": "Réception de commande",
    "created_at": "2024-11-02 16:00:00"
  },
  "message": "Stock ajouté avec succès"
}
```

### Retirer du Stock (Sortie)

**Endpoint** : `POST /api/stocks/{id}/remove-stock`

**Body** :
```json
{
  "quantity": 5.0,
  "reason": "sale",
  "reference": "VENTE-2024-001",
  "notes": "Vente au client"
}
```

### Ajuster le Stock

**Endpoint** : `POST /api/stocks/{id}/adjust-stock`

**Body** :
```json
{
  "new_quantity": 15.0,
  "reason": "adjustment",
  "notes": "Inventaire physique"
}
```

### Transférer du Stock

**Endpoint** : `POST /api/stocks/{id}/transfer-stock`

**Body** :
```json
{
  "quantity": 2.0,
  "location_to": "Bureau - Armoire 2",
  "notes": "Transfert vers nouveau local"
}
```

---

## ❌ Format de Réponse (Erreur)

### Status Code : `422 Validation Error`

```json
{
  "success": false,
  "message": "The given data was invalid.",
  "errors": {
    "name": ["The name field is required."],
    "sku": ["The sku has already been taken."],
    "current_quantity": ["The current quantity must be at least 0."]
  }
}
```

### Status Code : `500 Server Error`

```json
{
  "success": false,
  "message": "Erreur lors de la création du stock: [détails de l'erreur]"
}
```

---

## ⚠️ Notes Importantes

1. **SKU Unique** : 
   - Le SKU doit être unique dans la base de données
   - Si un stock avec le même SKU existe déjà, vous recevrez une erreur 422

2. **Code-barres Unique** :
   - Si fourni, le code-barres doit être unique
   - Optionnel mais recommandé pour la gestion par scanner

3. **Catégorie** :
   - Vous pouvez utiliser une catégorie existante (récupérée via `/api/stock-categories`) OU créer une nouvelle catégorie
   - Le champ `category` est un string libre, pas un ID
   - Exemples : `"Informatique"`, `"Mobilier"`, `"Équipement"`, `"Fournitures"` ou toute autre catégorie de votre choix

4. **Quantités** :
   - `current_quantity` : quantité actuelle en stock
   - `minimum_quantity` : seuil d'alerte stock faible
   - `reorder_point` : seuil de réapprovisionnement (≤ `minimum_quantity`)
   - `maximum_quantity` : seuil d'alerte surstock (optionnel)

5. **Unités de Mesure** :
   - Exemples : `"unité"`, `"kg"`, `"L"`, `"m"`, `"m²"`, `"m³"`, `"pièce"`, `"paquet"`

6. **Statut** :
   - `active` : En vente/disponible (par défaut)
   - `inactive` : Temporairement indisponible
   - `discontinued` : Plus produit/vendu

7. **Alertes Automatiques** :
   - Les alertes sont générées automatiquement :
     - Stock épuisé si `current_quantity == 0`
     - Stock faible si `current_quantity <= minimum_quantity`
     - Surstock si `current_quantity > maximum_quantity` (si défini)
     - Réapprovisionnement si `current_quantity <= reorder_point`

8. **Valeur du Stock** :
   - Calculée automatiquement : `current_quantity * unit_cost`
   - Disponible dans les réponses via `stock_value`

---

## ✅ Checklist pour Flutter

Avant d'envoyer la requête, vérifiez :

- [ ] `name` est fourni et non vide
- [ ] `description` est fourni
- [ ] `category` est un nom de catégorie valide
- [ ] `sku` est unique et non vide
- [ ] `unit` est fourni (ex: "unité", "kg")
- [ ] `currentQuantity` est un nombre ≥ 0
- [ ] `minimumQuantity` est un nombre ≥ 0
- [ ] `reorderPoint` est un nombre ≥ 0 (généralement ≤ `minimumQuantity`)
- [ ] `unitCost` est un nombre ≥ 0
- [ ] `status` est `active`, `inactive` ou `discontinued`
- [ ] `barcode` est unique si fourni
- [ ] Token d'authentification est présent dans les headers
- [ ] Headers `Content-Type: application/json` et `Accept: application/json`

---

## 📋 Mapping des Champs Flutter ↔ Backend

| Flutter (camelCase) | Backend (snake_case) | Description |
|---------------------|---------------------|-------------|
| `name` | `name` | Nom (identique) |
| `description` | `description` | Description (identique) |
| `category` | `category` | Catégorie (identique) |
| `sku` | `sku` | SKU (identique) |
| `barcode` | `barcode` | Code-barres (identique) |
| `brand` | `brand` | Marque (identique) |
| `model` | `model` | Modèle (identique) |
| `unit` | `unit` | Unité (identique) |
| `currentQuantity` | `current_quantity` | Quantité actuelle |
| `minimumQuantity` | `minimum_quantity` | Quantité minimale |
| `maximumQuantity` | `maximum_quantity` | Quantité maximale |
| `reorderPoint` | `reorder_point` | Seuil réapprovisionnement |
| `unitCost` | `unit_cost` | Coût unitaire |
| `sellingPrice` | `selling_price` | Prix de vente |
| `supplier` | `supplier` | Fournisseur (identique) |
| `location` | `location` | Localisation (identique) |
| `status` | `status` | Statut (identique) |
| `notes` | `notes` | Notes (identique) |
| `specifications` | `specifications` | Spécifications (identique) |
| `attachments` | `attachments` | Pièces jointes (identique) |

---

## 📝 Exemples d'Utilisation Complète

### 1. Créer un Stock

```dart
// Option 1 : Utiliser une catégorie existante
final categories = await stockService.getCategories();
final stock = Stock(
  name: "Ordinateur Portable HP",
  description: "Ordinateur portable HP 15.6 pouces, 8GB RAM",
  category: categories[0].name, // Nom de la première catégorie (si disponible)
  // ... autres champs
);

// Option 2 : Créer directement avec une nouvelle catégorie
final stock = Stock(
  name: "Ordinateur Portable HP",
  description: "Ordinateur portable HP 15.6 pouces, 8GB RAM",
  category: "Informatique", // Catégorie libre (nouvelle ou existante)
  sku: "HP-LAPTOP-001",
  unit: "unité",
  currentQuantity: 10.0,
  minimumQuantity: 5.0,
  reorderPoint: 3.0,
  unitCost: 150000.0,
  status: "active",
);

final createdStock = await stockService.createStock(stock);
```

### 2. Ajouter du Stock

```dart
// Ajouter 10 unités au stock
final movement = await stockService.addStock(
  stockId: createdStock.id,
  quantity: 10.0,
  unitCost: 150000.0,
  reason: "purchase",
  reference: "CMD-2024-001",
  notes: "Réception de commande"
);
// current_quantity passe de 10.0 à 20.0
```

### 3. Retirer du Stock

```dart
// Retirer 5 unités du stock
final movement = await stockService.removeStock(
  stockId: createdStock.id,
  quantity: 5.0,
  reason: "sale",
  reference: "VENTE-2024-001",
  notes: "Vente au client"
);
// current_quantity passe de 20.0 à 15.0
```

### 4. Ajuster le Stock (Inventaire)

```dart
// Ajuster la quantité à 12.0 (inventaire physique)
final movement = await stockService.adjustStock(
  stockId: createdStock.id,
  newQuantity: 12.0,
  reason: "adjustment",
  notes: "Inventaire physique effectué"
);
// current_quantity passe à 12.0
```

### 5. Transférer du Stock

```dart
// Transférer 2 unités vers un autre emplacement
final movement = await stockService.transferStock(
  stockId: createdStock.id,
  quantity: 2.0,
  locationTo: "Bureau - Armoire 2",
  notes: "Transfert vers nouveau local"
);
// current_quantity diminue de 2.0
```

---

## 🎯 Résumé Rapide

### Champs Minimaux Requis pour Créer un Stock :

```json
{
  "name": "Ordinateur Portable HP",
  "description": "Ordinateur portable HP 15.6 pouces, 8GB RAM",
  "category": "Informatique",
  "sku": "HP-LAPTOP-001",
  "unit": "unité",
  "currentQuantity": 10.0,
  "minimumQuantity": 5.0,
  "reorderPoint": 3.0,
  "unitCost": 150000.0,
  "status": "active"
}
```

### Workflow Minimal :

1. **Créer** : `POST /stocks` → Stock créé avec `status` = `active`
2. **Ajouter** : `POST /stocks/{id}/add-stock` → Augmente `current_quantity`
3. **Retirer** : `POST /stocks/{id}/remove-stock` → Diminue `current_quantity`
4. **Ajuster** : `POST /stocks/{id}/adjust-stock` → Fixe `current_quantity` à une valeur précise

---

Cette documentation contient toutes les informations nécessaires pour intégrer la gestion de stock dans Flutter sans problèmes de concordance avec le backend.

