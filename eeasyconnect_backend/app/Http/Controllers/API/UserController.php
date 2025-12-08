<?php

namespace App\Http\Controllers\API;

use App\Http\Requests\LoginRequest;
use Illuminate\Http\Request;
use App\Http\Controllers\API\Controller;
use App\Http\Resources\UserResource;
use Illuminate\Support\Facades\Auth;

class UserController extends Controller
{
    public function login(LoginRequest $request)
    {
        try {
            $credentials = $request->only('email', 'password');

            if (!Auth::attempt($credentials)) {
                return $this->errorResponse('Email ou mot de passe incorrect', 401);
            }

            $user = Auth::user();
            
            if (!$user) {
                return $this->errorResponse('Utilisateur non trouvé', 404);
            }

            // Vérifier si l'utilisateur est actif
            if (!$user->is_active) {
                return $this->errorResponse('Votre compte a été désactivé. Contactez l\'administrateur.', 403);
            }

            $token = $user->createToken('mobile-app')->plainTextToken;

            return $this->successResponse([
                'token' => $token,
                'user' => new UserResource($user),
            ], 'Connexion réussie');
        } catch (\Illuminate\Validation\ValidationException $e) {
            return $this->handleValidationException($e);
        } catch (\Exception $e) {
            \Log::error('Erreur API - Login', [
                'endpoint' => $request->path(),
                'method' => $request->method(),
                'email' => $request->input('email'),
                'error' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString(),
            ]);

            return $this->errorResponse('Une erreur est survenue. Veuillez réessayer plus tard.', 500);
        }
    }

    public function logout(Request $request)
    {
        try {
            $request->user()->currentAccessToken()->delete();
            
            return $this->successResponse(null, 'Déconnexion réussie');
        } catch (\Exception $e) {
            \Log::error('Erreur API - Logout', [
                'endpoint' => $request->path(),
                'method' => $request->method(),
                'user_id' => $request->user()?->id,
                'error' => $e->getMessage(),
            ]);

            return $this->errorResponse('Une erreur est survenue lors de la déconnexion', 500);
        }
    }

    public function me(Request $request)
    {
        try {
            $user = $request->user();
            
            if (!$user) {
                return $this->unauthorizedResponse('Utilisateur non authentifié');
            }

            // Vérifier si getRoleName existe, sinon utiliser une valeur par défaut
            $roleName = method_exists($user, 'getRoleName') ? $user->getRoleName() : 'Utilisateur';
            
            return $this->successResponse(new UserResource($user));
        } catch (\Exception $e) {
            \Log::error('Me endpoint error', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            if (config('app.debug')) {
                return $this->errorResponse('Erreur: ' . $e->getMessage(), 500);
            }

            return $this->errorResponse('Erreur lors de la récupération des informations utilisateur', 500);
        }
    }
    /**
     * Liste des utilisateurs (Admin uniquement)
     */
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié'
                ], 401);
            }
            
            $role = $request->query('role');
            $status = $request->query('status');
            $search = $request->query('search');

            $query = \App\Models\User::query();

            // Filtre par rôle
            if ($role !== null) {
                $query->where('role', $role);
            }

            // Filtre par statut (actif/inactif)
            if ($status !== null) {
                $query->where('is_active', $status);
            }

            // Recherche par nom, prénom ou email
            if ($search) {
                $query->where(function($q) use ($search) {
                    $q->where('nom', 'like', "%{$search}%")
                      ->orWhere('prenom', 'like', "%{$search}%")
                      ->orWhere('email', 'like', "%{$search}%");
                });
            }

            $perPage = $request->get('per_page', 15);
            $users = $query->orderBy('created_at', 'desc')->paginate($perPage);

            return response()->json([
                'success' => true,
                'data' => UserResource::collection($users->items()),
                'pagination' => [
                    'current_page' => $users->currentPage(),
                    'last_page' => $users->lastPage(),
                    'per_page' => $users->perPage(),
                    'total' => $users->total(),
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des utilisateurs: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Créer un nouvel utilisateur (Admin uniquement)
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'nom' => 'required|string|max:255',
                'prenom' => 'required|string|max:255',
                'email' => 'required|string|email|max:255|unique:users',
                'password' => 'required|string|min:6',
                'role' => 'required|integer|in:1,2,3,4,5,6',
                /* 'telephone' => 'nullable|string|max:20',
                'adresse' => 'nullable|string|max:255',
                'date_embauche' => 'nullable|date',
                'salaire' => 'nullable|numeric|min:0',
                'departement' => 'nullable|string|max:100',
                'poste' => 'nullable|string|max:100' */
            ]);

            $user = \App\Models\User::create([
                'nom' => $validated['nom'],
                'prenom' => $validated['prenom'],
                'email' => $validated['email'],
                'password' => bcrypt($validated['password']),
                'role' => $validated['role'],
                'is_active' => true,
               /*  'telephone' => $validated['telephone'],
                'adresse' => $validated['adresse'],
                'date_embauche' => $validated['date_embauche'],
                'salaire' => $validated['salaire'],
                'departement' => $validated['departement'],
                'poste' => $validated['poste'], */
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Utilisateur créé avec succès',
                'data' => $user
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création de l\'utilisateur: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Afficher un utilisateur spécifique (Admin uniquement)
     */
    public function show($id)
    {
        try {
            $user = \App\Models\User::findOrFail($id);
            
            return response()->json([
                'success' => true,
                'data' => $user
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Utilisateur non trouvé: ' . $e->getMessage()
            ], 404);
        }
    }

    /**
     * Modifier un utilisateur (Admin uniquement)
     */
    public function update(Request $request, $id)
    {
        try {
            $user = \App\Models\User::findOrFail($id);

            $validated = $request->validate([
                'nom' => 'required|string|max:255',
                'prenom' => 'required|string|max:255',
                'email' => 'required|email|unique:users,email,' . $user->id,
                'password' => 'nullable|string|min:6',
                'role' => 'required|integer|in:1,2,3,4,5,6',
               /*  'telephone' => 'nullable|string|max:20',
                'adresse' => 'nullable|string|max:255',
                'date_embauche' => 'nullable|date',
                'salaire' => 'nullable|numeric|min:0',
                'departement' => 'nullable|string|max:100',
                'poste' => 'nullable|string|max:100' */
            ]);

            $updateData = $validated;
            if (!empty($validated['password'])) {
                $updateData['password'] = bcrypt($validated['password']);
            } else {
                unset($updateData['password']);
            }

            $user->update($updateData);

            return response()->json([
                'success' => true,
                'message' => 'Utilisateur modifié avec succès',
                'data' => $user
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la modification: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer un utilisateur (Admin uniquement)
     */
    public function destroy($id)
    {
        try {
            $user = \App\Models\User::findOrFail($id);
            
            // Empêcher la suppression de l'utilisateur connecté
            if ($user->id === auth()->id()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Impossible de supprimer votre propre compte'
                ], 403);
            }

            $user->delete();

            return response()->json([
                'success' => true,
                'message' => 'Utilisateur supprimé avec succès'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Activer un utilisateur (Admin uniquement)
     */
    public function activate($id)
    {
        try {
            $user = \App\Models\User::findOrFail($id);
            $user->update(['is_active' => true]);

            return response()->json([
                'success' => true,
                'message' => 'Utilisateur activé avec succès',
                'data' => $user
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'activation: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Désactiver un utilisateur (Admin uniquement)
     */
    public function deactivate($id)
    {
        try {
            $user = \App\Models\User::findOrFail($id);
            
            // Empêcher la désactivation de l'utilisateur connecté
            if ($user->id === auth()->id()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Impossible de désactiver votre propre compte'
                ], 403);
            }

            $user->update(['is_active' => false]);

            return response()->json([
                'success' => true,
                'message' => 'Utilisateur désactivé avec succès',
                'data' => $user
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la désactivation: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Statistiques des utilisateurs (Admin uniquement)
     */
    public function statistics()
    {
        try {
            $totalUsers = \App\Models\User::count();
            $activeUsers = \App\Models\User::where('is_active', true)->count();
            $inactiveUsers = \App\Models\User::where('is_active', false)->count();

            // Répartition par rôle
            $usersByRole = \App\Models\User::selectRaw('role, COUNT(*) as total')
                ->groupBy('role')
                ->get();

            // Utilisateurs créés par mois (derniers 12 mois)
            $usersByMonth = \App\Models\User::selectRaw('DATE_FORMAT(created_at, "%Y-%m") as mois, COUNT(*) as total')
                ->where('created_at', '>=', now()->subMonths(12))
                ->groupBy('mois')
                ->orderBy('mois')
                ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'total_users' => $totalUsers,
                    'active_users' => $activeUsers,
                    'inactive_users' => $inactiveUsers,
                    'users_by_role' => $usersByRole,
                    'users_by_month' => $usersByMonth,
                    'activation_rate' => $totalUsers > 0 ? round(($activeUsers / $totalUsers) * 100, 2) : 0
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la génération des statistiques: ' . $e->getMessage()
            ], 500);
        }
    }
}
