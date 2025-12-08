# Guide de Configuration Backend Laravel pour EasyConnect

Ce document décrit les bonnes pratiques et configurations nécessaires pour que le backend Laravel fonctionne correctement avec l'application Flutter EasyConnect.

## 📋 Table des matières

1. [Configuration de base](#configuration-de-base)
2. [Gestion de l'authentification](#gestion-de-lauthentification)
3. [Format des réponses API](#format-des-réponses-api)
4. [Gestion des erreurs](#gestion-des-erreurs)
5. [CORS et sécurité](#cors-et-sécurité)
6. [Performance et cache](#performance-et-cache)
7. [Logs et débogage](#logs-et-débogage)

---

## 1. Configuration de base

### Variables d'environnement (.env)

```env
APP_NAME=Easykonect
APP_ENV=production
APP_KEY=base64:...
APP_DEBUG=false
APP_URL=https://easykonect.smil-app.com

# Base de données
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=your_database
DB_USERNAME=your_username
DB_PASSWORD=your_password

# Session (important pour l'authentification)
SESSION_DRIVER=database
SESSION_LIFETIME=120
SESSION_ENCRYPT=false
SESSION_PATH=/
SESSION_DOMAIN=null

# Cache
CACHE_DRIVER=file
CACHE_PREFIX=easyconnect_

# Sanctum (pour l'authentification API)
SANCTUM_STATEFUL_DOMAINS=easykonect.smil-app.com
```

### Configuration Sanctum (config/sanctum.php)

```php
'stateful' => explode(',', env('SANCTUM_STATEFUL_DOMAINS', sprintf(
    '%s%s',
    'localhost,localhost:3000,127.0.0.1,127.0.0.1:8000,::1',
    env('APP_URL') ? ','.parse_url(env('APP_URL'), PHP_URL_HOST) : ''
))),
```

---

## 2. Gestion de l'authentification

### Format de réponse pour `/api/login`

**✅ Format correct :**

```json
{
  "success": true,
  "message": "Connexion réussie",
  "data": {
    "token": "1|abc123...",
    "user": {
      "id": 1,
      "nom": "Dupont",
      "prenom": "Jean",
      "email": "jean@example.com",
      "role": 2,
      "role_name": "Commercial",
      "created_at": "2024-01-01 00:00:00",
      "updated_at": "2024-01-01 00:00:00"
    }
  }
}
```

**❌ Formats incorrects à éviter :**

```json
// ❌ Pas de wrapper "data"
{
  "token": "1|abc123...",
  "user": {...}
}

// ❌ Pas de champ "success"
{
  "user": {...},
  "token": "..."
}
```

### Exemple de contrôleur de login

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string|min:6',
        ]);

        if (!Auth::attempt($request->only('email', 'password'))) {
            return response()->json([
                'success' => false,
                'message' => 'Email ou mot de passe incorrect',
            ], 401);
        }

        $user = Auth::user();
        $token = $user->createToken('mobile-app')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Connexion réussie',
            'data' => [
                'token' => $token,
                'user' => [
                    'id' => $user->id,
                    'nom' => $user->nom,
                    'prenom' => $user->prenom,
                    'email' => $user->email,
                    'role' => $user->role,
                    'role_name' => $user->role_name ?? $this->getRoleName($user->role),
                    'created_at' => $user->created_at->format('Y-m-d H:i:s'),
                    'updated_at' => $user->updated_at->format('Y-m-d H:i:s'),
                ],
            ],
        ], 200);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Déconnexion réussie',
        ], 200);
    }

    private function getRoleName(int $role): string
    {
        $roles = [
            1 => 'Admin',
            2 => 'Commercial',
            3 => 'Comptable',
            4 => 'RH',
            5 => 'Technicien',
            6 => 'Patron',
        ];

        return $roles[$role] ?? 'Utilisateur';
    }
}
```

### Middleware d'authentification

Assurez-vous que toutes les routes API (sauf `/api/login`) sont protégées :

```php
// routes/api.php
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    // Toutes les autres routes API
    Route::get('/clients', [ClientController::class, 'index']);
    // ...
});
```

---

## 3. Format des réponses API

### Format standardisé pour toutes les réponses

**✅ Succès (200-299) :**

```json
{
  "success": true,
  "message": "Opération réussie",
  "data": {
    // Données de la réponse
  }
}
```

**✅ Erreur (400-499, 500-599) :**

```json
{
  "success": false,
  "message": "Message d'erreur explicite",
  "errors": {
    // Optionnel : erreurs de validation
    "email": ["Le champ email est requis"],
    "password": ["Le mot de passe doit contenir au moins 6 caractères"]
  },
  "statusCode": 422
}
```

### Traitement des erreurs de validation (422)

```php
use Illuminate\Validation\ValidationException;

try {
    $validated = $request->validate([
        'email' => 'required|email',
        'name' => 'required|string|max:255',
    ]);
} catch (ValidationException $e) {
    return response()->json([
        'success' => false,
        'message' => 'Erreur de validation',
        'errors' => $e->errors(),
        'statusCode' => 422,
    ], 422);
}
```

### Traitement des erreurs serveur (500)

```php
try {
    // Code métier
} catch (\Exception $e) {
    \Log::error('Erreur dans ClientController@store', [
        'error' => $e->getMessage(),
        'trace' => $e->getTraceAsString(),
    ]);

    return response()->json([
        'success' => false,
        'message' => 'Une erreur est survenue. Veuillez réessayer plus tard.',
        'statusCode' => 500,
    ], 500);
}
```

---

## 4. Gestion des erreurs

### Codes de statut HTTP à utiliser

- **200** : Succès (GET, PUT, PATCH)
- **201** : Créé avec succès (POST)
- **400** : Requête invalide (données malformées)
- **401** : Non autorisé (token manquant ou invalide)
- **403** : Accès refusé (permissions insuffisantes)
- **404** : Ressource non trouvée
- **422** : Erreur de validation
- **429** : Trop de requêtes (rate limiting)
- **500** : Erreur serveur interne

### Gestion des erreurs 401 (Token expiré)

L'application Flutter gère automatiquement les erreurs 401 en déconnectant l'utilisateur. Assurez-vous que votre middleware Sanctum retourne bien un 401 :

```php
// app/Http/Middleware/EnsureTokenIsValid.php (si personnalisé)
public function handle($request, Closure $next)
{
    if (!$request->user()) {
        return response()->json([
            'success' => false,
            'message' => 'Token invalide ou expiré',
            'statusCode' => 401,
        ], 401);
    }

    return $next($request);
}
```

---

## 5. CORS et sécurité

### Configuration CORS (config/cors.php)

```php
<?php

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'],

    'allowed_origins' => [
        'https://easykonect.smil-app.com',
        // Ajouter d'autres domaines si nécessaire
    ],

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => true,
];
```

### Headers de sécurité

L'application Flutter envoie automatiquement ces headers :
- `Accept: application/json`
- `Content-Type: application/json` (pour POST/PUT)
- `Authorization: Bearer {token}` (pour les routes protégées)
- `User-Agent: Mozilla/5.0...` (pour contourner Tiger Protect)

**Important :** Ne bloquez pas les requêtes avec un User-Agent personnalisé.

---

## 6. Performance et cache

### Pagination

Pour les listes importantes (clients, devis, etc.), utilisez la pagination :

```php
public function index(Request $request)
{
    $perPage = $request->get('per_page', 15);
    $page = $request->get('page', 1);

    $clients = Client::paginate($perPage, ['*'], 'page', $page);

    return response()->json([
        'success' => true,
        'data' => [
            'data' => $clients->items(),
            'current_page' => $clients->currentPage(),
            'last_page' => $clients->lastPage(),
            'per_page' => $clients->perPage(),
            'total' => $clients->total(),
        ],
    ], 200);
}
```

### Cache des requêtes fréquentes

Pour les données qui changent peu (statistiques, listes de référence), utilisez le cache :

```php
use Illuminate\Support\Facades\Cache;

public function getStats()
{
    $stats = Cache::remember('client_stats', 300, function () {
        return [
            'total' => Client::count(),
            'pending' => Client::where('status', 0)->count(),
            'approved' => Client::where('status', 1)->count(),
        ];
    });

    return response()->json([
        'success' => true,
        'data' => $stats,
    ], 200);
}
```

---

## 7. Logs et débogage

### Configuration des logs (config/logging.php)

```php
'channels' => [
    'daily' => [
        'driver' => 'daily',
        'path' => storage_path('logs/laravel.log'),
        'level' => env('LOG_LEVEL', 'error'),
        'days' => 14,
    ],
],
```

### Logging des erreurs API

```php
use Illuminate\Support\Facades\Log;

try {
    // Code métier
} catch (\Exception $e) {
    Log::error('Erreur API', [
        'endpoint' => $request->path(),
        'method' => $request->method(),
        'user_id' => $request->user()?->id,
        'error' => $e->getMessage(),
        'trace' => $e->getTraceAsString(),
    ]);

    return response()->json([
        'success' => false,
        'message' => 'Une erreur est survenue',
        'statusCode' => 500,
    ], 500);
}
```

### Commandes utiles

```bash
# Vider le cache
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Voir les logs en temps réel
tail -f storage/logs/laravel.log

# Tester une route API
curl -X POST https://easykonect.smil-app.com/api/login \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"email":"admin@easyconnect.com","password":"admin123"}'
```

---

## 8. Checklist de vérification

Avant de déployer en production, vérifiez :

- [ ] `APP_DEBUG=false` dans `.env`
- [ ] `APP_URL` est correctement configuré
- [ ] Toutes les routes API (sauf `/api/login`) sont protégées par `auth:sanctum`
- [ ] Le format de réponse `/api/login` inclut `success`, `message`, et `data`
- [ ] Les erreurs retournent le format standardisé avec `success: false`
- [ ] CORS est correctement configuré
- [ ] Les logs sont activés et accessibles
- [ ] Le cache est configuré (file ou redis)
- [ ] La pagination est implémentée pour les grandes listes
- [ ] Les tokens Sanctum ont une durée de vie appropriée

---

## 9. Support et dépannage

### Problèmes courants

**1. Erreur 503 "Service indisponible"**
- Vérifier que le serveur Laravel est démarré
- Vérifier les logs : `tail -f storage/logs/laravel.log`
- Vérifier la configuration PHP-FPM/Nginx

**2. Erreur 401 "Non autorisé"**
- Vérifier que le token est bien envoyé dans le header `Authorization: Bearer {token}`
- Vérifier que le token n'est pas expiré
- Vérifier la configuration Sanctum

**3. Erreur 500 "Erreur serveur"**
- Activer `APP_DEBUG=true` temporairement
- Vérifier les logs Laravel
- Vérifier la connexion à la base de données

**4. Format de réponse incorrect**
- Vérifier que toutes les réponses suivent le format standardisé
- Vérifier que `/api/login` retourne bien `data.token` et `data.user`

---

## 10. Exemple complet de contrôleur

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Client;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class ClientController extends Controller
{
    public function index(Request $request)
    {
        try {
            $perPage = $request->get('per_page', 15);
            $page = $request->get('page', 1);
            $status = $request->get('status');
            $search = $request->get('search');

            $query = Client::query();

            if ($status !== null) {
                $query->where('status', $status);
            }

            if ($search) {
                $query->where(function ($q) use ($search) {
                    $q->where('nom', 'like', "%{$search}%")
                      ->orWhere('prenom', 'like', "%{$search}%")
                      ->orWhere('email', 'like', "%{$search}%");
                });
            }

            $clients = $query->paginate($perPage, ['*'], 'page', $page);

            return response()->json([
                'success' => true,
                'message' => 'Clients récupérés avec succès',
                'data' => [
                    'data' => $clients->items(),
                    'current_page' => $clients->currentPage(),
                    'last_page' => $clients->lastPage(),
                    'per_page' => $clients->perPage(),
                    'total' => $clients->total(),
                ],
            ], 200);
        } catch (\Exception $e) {
            Log::error('Erreur dans ClientController@index', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des clients',
                'statusCode' => 500,
            ], 500);
        }
    }

    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'nom' => 'required|string|max:255',
                'prenom' => 'required|string|max:255',
                'email' => 'required|email|unique:clients,email',
                'telephone' => 'nullable|string|max:20',
            ]);

            $client = Client::create($validated);

            return response()->json([
                'success' => true,
                'message' => 'Client créé avec succès',
                'data' => $client,
            ], 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $e->errors(),
                'statusCode' => 422,
            ], 422);
        } catch (\Exception $e) {
            Log::error('Erreur dans ClientController@store', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création du client',
                'statusCode' => 500,
            ], 500);
        }
    }
}
```

---

**Dernière mise à jour :** 2024-12-02

