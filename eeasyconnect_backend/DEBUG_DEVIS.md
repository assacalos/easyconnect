# Guide de Debug - Problème "Aucun devis affiché"

## 🔍 Vérifications Backend

### 1. Endpoint de Debug
Un nouvel endpoint a été ajouté pour diagnostiquer le problème :

```bash
GET /api/devis-debug
```

**Réponse attendue :**
```json
{
  "success": true,
  "debug": {
    "user": {
      "id": 1,
      "role": 2,
      "nom": "Dupont",
      "prenom": "Jean"
    },
    "statistics": {
      "total_devis": 10,
      "devis_by_status": {
        "0": 2,
        "1": 5,
        "2": 3
      },
      "devis_by_user": {
        "1": 5,
        "2": 5
      },
      "user_devis_count": 5
    },
    "last_devis": [...]
  }
}
```

### 2. Logs Backend
Les logs sont maintenant activés dans `storage/logs/laravel.log`. Vérifiez :
- Les requêtes arrivant au serveur
- Les paramètres de filtrage appliqués
- Le nombre de devis trouvés
- Les erreurs éventuelles

### 3. Vérifications à faire

#### A. Vérifier que des devis existent en base
```sql
SELECT COUNT(*) FROM devis;
SELECT * FROM devis LIMIT 5;
```

#### B. Vérifier les permissions utilisateur
```sql
SELECT id, role, nom, prenom FROM users WHERE id = [USER_ID];
```

#### C. Vérifier les devis par utilisateur
```sql
SELECT user_id, COUNT(*) as count 
FROM devis 
GROUP BY user_id;
```

#### D. Vérifier les devis par statut
```sql
SELECT status, COUNT(*) as count 
FROM devis 
GROUP BY status;
```

## 🔍 Vérifications Frontend

### 1. URL et Endpoint
Vérifiez que le frontend appelle bien :
- `GET /api/devis` (avec pagination)
- OU `GET /api/devis-list` (sans pagination)

### 2. Paramètres de requête
Vérifiez les paramètres envoyés :
```javascript
// Exemple de requête
GET /api/devis?page=1&per_page=15&status=1
```

**Paramètres possibles :**
- `page` : Numéro de page (défaut: 1)
- `per_page` : Nombre d'éléments par page (défaut: 15)
- `status` : Filtre par statut (0, 1, 2, 3)
- `user_id` : Filtre par commercial
- `search` : Recherche par référence

### 3. Authentification
Vérifiez que le token est bien envoyé :
```javascript
headers: {
  'Authorization': 'Bearer ' + token,
  'Accept': 'application/json'
}
```

### 4. Format de réponse attendu
Le backend retourne maintenant :
```json
{
  "success": true,
  "data": [...],
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

### 5. Gestion des erreurs
Vérifiez comment le frontend gère :
- Les réponses vides (`data: []`)
- Les erreurs 401 (non authentifié)
- Les erreurs 500 (erreur serveur)
- Les réponses avec `success: false`

### 6. Filtrage par rôle
Si l'utilisateur est un commercial (role == 2), vérifiez que :
- Le filtre `user_id` est appliqué automatiquement
- Seuls les devis du commercial sont retournés

## 🧪 Tests à effectuer

### Test 1: Endpoint de debug
```bash
curl -X GET "http://votre-api/api/devis-debug" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer VOTRE_TOKEN"
```

### Test 2: Endpoint principal
```bash
curl -X GET "http://votre-api/api/devis?page=1&per_page=15" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer VOTRE_TOKEN"
```

### Test 3: Avec filtre status
```bash
curl -X GET "http://votre-api/api/devis?status=1&page=1&per_page=15" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer VOTRE_TOKEN"
```

### Test 4: Endpoint fallback
```bash
curl -X GET "http://votre-api/api/devis-list" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer VOTRE_TOKEN"
```

## 🐛 Problèmes courants et solutions

### Problème 1: Tableau vide `[]`
**Causes possibles :**
- Aucun devis en base de données
- Filtres trop restrictifs
- Permissions insuffisantes

**Solutions :**
1. Vérifier avec `/api/devis-debug` qu'il y a des devis
2. Vérifier les filtres appliqués (status, user_id)
3. Vérifier le rôle de l'utilisateur

### Problème 2: Erreur 401
**Cause :** Token invalide ou expiré

**Solution :**
- Vérifier que le token est bien envoyé
- Vérifier que le token n'est pas expiré
- Reconnecter l'utilisateur

### Problème 3: Erreur 500
**Cause :** Erreur serveur

**Solution :**
- Vérifier les logs dans `storage/logs/laravel.log`
- Vérifier que les relations (client, commercial, items) existent
- Vérifier que les champs requis sont présents

### Problème 4: Format de réponse incorrect
**Cause :** Le frontend attend un format différent

**Solution :**
- Vérifier le format attendu par le frontend
- Vérifier que `meta` est bien présent (pas `pagination`)
- Vérifier que `data` est un tableau

## 📋 Checklist de vérification

### Backend
- [ ] Des devis existent en base de données
- [ ] L'endpoint `/api/devis` fonctionne
- [ ] L'endpoint `/api/devis-debug` retourne des données
- [ ] Les logs montrent que les requêtes arrivent
- [ ] Aucune erreur 500 dans les logs
- [ ] Les relations (client, commercial, items) sont chargées
- [ ] Le format de réponse est correct

### Frontend
- [ ] L'URL appelée est correcte (`/api/devis` ou `/api/devis-list`)
- [ ] Le token d'authentification est envoyé
- [ ] Les paramètres de requête sont corrects
- [ ] Le format de réponse est bien parsé
- [ ] Les erreurs sont bien gérées
- [ ] Le filtre par rôle est bien appliqué (si commercial)
- [ ] La pagination est bien gérée

## 🔧 Commandes utiles

### Voir les logs en temps réel
```bash
tail -f storage/logs/laravel.log
```

### Vérifier les routes
```bash
php artisan route:list | grep devis
```

### Tester une requête directement
```bash
php artisan tinker
>>> $user = App\Models\User::first();
>>> $devis = App\Models\Devis::with(['client', 'commercial', 'items'])->get();
>>> $devis->count();
```

## 📞 Informations à collecter pour le debug

Si le problème persiste, collectez :
1. La réponse complète de `/api/devis-debug`
2. La réponse complète de `/api/devis` (avec tous les paramètres)
3. Les logs du serveur (dernières 50 lignes)
4. Le code frontend qui fait l'appel API
5. Les paramètres envoyés par le frontend
6. Le code de statut HTTP reçu
7. Le nombre de devis en base de données

