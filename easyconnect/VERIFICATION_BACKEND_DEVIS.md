# Vérifications Backend - Problème "Aucun devis"

## Endpoints utilisés par le Frontend

### 1. Endpoint principal avec pagination
- **URL**: `GET /devis`
- **Paramètres possibles**:
  - `status` (optionnel): 1=En attente, 2=Validé, 3=Rejeté
  - `user_id` (optionnel): Filtré automatiquement si `userRole == 2` (commercial)
  - `search` (optionnel): Recherche par référence
  - `page` (requis): Numéro de page (défaut: 1)
  - `per_page` (requis): Nombre d'éléments par page (défaut: 15)

**Exemple d'appel**:
```
GET /devis?page=1&per_page=15
GET /devis?status=1&page=1&per_page=15&user_id=5
```

**Format de réponse attendu** (pagination Laravel):
```json
{
  "data": [
    {
      "id": 1,
      "reference": "DEV-001",
      "client_id": 5,
      "commercial_id": 3,
      "status": 1,
      "date_creation": "2024-01-15",
      "date_validite": "2024-02-15",
      "total_ht": 100000,
      "tva": 18000,
      "total_ttc": 118000,
      "items": [...],
      ...
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 15,
    "total": 5,
    "has_next_page": false,
    "has_previous_page": false
  }
}
```

### 2. Endpoint fallback (sans pagination)
- **URL**: `GET /devis-list`
- **Paramètres possibles**:
  - `status` (optionnel): 1=En attente, 2=Validé, 3=Rejeté
  - `user_id` (optionnel): Filtré automatiquement si `userRole == 2` (commercial)

**Exemple d'appel**:
```
GET /devis-list
GET /devis-list?status=1&user_id=5
```

**Format de réponse attendu**:
```json
{
  "data": [
    {
      "id": 1,
      "reference": "DEV-001",
      ...
    }
  ]
}
```

OU directement un tableau:
```json
[
  {
    "id": 1,
    "reference": "DEV-001",
    ...
  }
]
```

## Points à vérifier côté Backend

### ✅ 1. Vérifier que l'endpoint `/devis` existe et fonctionne
- [ ] L'endpoint est bien défini dans les routes
- [ ] L'endpoint accepte les paramètres de pagination (`page`, `per_page`)
- [ ] L'endpoint retourne le format de pagination Laravel standard

### ✅ 2. Vérifier le filtrage par `user_id` pour les commerciaux
- [ ] Si `userRole == 2` (commercial), le filtre `user_id` est appliqué automatiquement
- [ ] Les devis retournés appartiennent bien au commercial connecté
- [ ] Les patrons (role != 2) voient tous les devis

### ✅ 3. Vérifier le filtrage par `status`
- [ ] Le paramètre `status` fonctionne correctement
- [ ] Les valeurs acceptées sont: 1 (En attente), 2 (Validé), 3 (Rejeté)
- [ ] Si `status` n'est pas fourni, tous les devis sont retournés

### ✅ 4. Vérifier les permissions d'accès
- [ ] L'utilisateur a bien les permissions pour voir les devis
- [ ] Le token d'authentification est valide
- [ ] Les middlewares d'authentification sont bien appliqués

### ✅ 5. Vérifier le format de réponse
- [ ] La réponse contient bien un champ `data` avec un tableau
- [ ] La réponse contient bien un champ `meta` pour la pagination (endpoint `/devis`)
- [ ] Les champs requis du modèle Devis sont présents dans la réponse

### ✅ 6. Vérifier les données en base
- [ ] Il existe bien des devis en base de données
- [ ] Les devis ont bien un `commercial_id` associé (pour les commerciaux)
- [ ] Les statuts des devis sont corrects (1, 2, ou 3)

### ✅ 7. Vérifier les logs serveur
- [ ] Les requêtes arrivent bien au serveur
- [ ] Aucune erreur 500, 404, ou 403 n'est retournée
- [ ] Les requêtes sont bien authentifiées

### ✅ 8. Vérifier la structure de la réponse
- [ ] Le format JSON est valide
- [ ] Les dates sont au bon format
- [ ] Les nombres sont bien des nombres (pas des strings)

## Tests à effectuer

### Test 1: Endpoint avec pagination (sans filtre)
```bash
curl -X GET "http://votre-api/devis?page=1&per_page=15" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer VOTRE_TOKEN"
```

### Test 2: Endpoint avec filtre status
```bash
curl -X GET "http://votre-api/devis?status=1&page=1&per_page=15" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer VOTRE_TOKEN"
```

### Test 3: Endpoint avec filtre user_id (commercial)
```bash
curl -X GET "http://votre-api/devis?user_id=5&page=1&per_page=15" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer VOTRE_TOKEN_COMMERCIAL"
```

### Test 4: Endpoint fallback
```bash
curl -X GET "http://votre-api/devis-list" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer VOTRE_TOKEN"
```

## Problèmes courants

1. **Endpoint retourne un tableau vide `[]`**
   - Vérifier qu'il y a bien des devis en base
   - Vérifier que les filtres ne sont pas trop restrictifs
   - Vérifier les permissions de l'utilisateur

2. **Erreur 404**
   - Vérifier que la route est bien définie
   - Vérifier que l'URL de base est correcte

3. **Erreur 401/403**
   - Vérifier l'authentification
   - Vérifier les permissions de l'utilisateur

4. **Format de réponse incorrect**
   - Vérifier que la réponse suit le format attendu
   - Vérifier que les champs requis sont présents

5. **Pagination non fonctionnelle**
   - Vérifier que le champ `meta` est présent
   - Vérifier que les valeurs de pagination sont correctes

## Informations de debug

Le frontend envoie les informations suivantes dans les logs:
- URL complète appelée
- Paramètres envoyés
- Code de statut HTTP reçu
- Corps de la réponse (en cas d'erreur)
- Nombre de devis chargés

Vérifiez les logs du frontend pour voir exactement ce qui est envoyé et reçu.

