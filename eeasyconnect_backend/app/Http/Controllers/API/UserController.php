<?php

namespace App\Http\Controllers\API;

use App\Http\Requests\LoginRequest;
use Illuminate\Http\Request;
use App\Http\Controllers\API\Controller;
use Illuminate\Support\Facades\Auth;

class UserController extends Controller
{
    public function login(LoginRequest $request)
    {
        try {
            $credentials = $request->only('email', 'password');

            if (!Auth::attempt($credentials)) {
                return $this->errorResponse('Identifiants incorrects', 401);
            }

            $user = Auth::user();
            
            if (!$user) {
                return $this->errorResponse('Utilisateur non trouvé', 404);
            }

            $token = $user->createToken('API Token')->plainTextToken;

            // Vérifier si getRoleName existe, sinon utiliser une valeur par défaut
            $roleName = method_exists($user, 'getRoleName') ? $user->getRoleName() : 'Utilisateur';

            return $this->successResponse([
                'token' => $token,
                'user' => [
                    'id' => $user->id,
                    'nom' => $user->nom ?? '',
                    'prenom' => $user->prenom ?? '',
                    'email' => $user->email,
                    'role' => $user->role,
                    'role_name' => $roleName
                ],
            ], 'Connexion réussie');
        } catch (\Exception $e) {
            \Log::error('Login error', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString(),
            ]);

            // En mode debug, retourner l'erreur détaillée
            if (config('app.debug')) {
                return $this->errorResponse(
                    'Erreur lors de la connexion: ' . $e->getMessage(),
                    500
                );
            }

            return $this->errorResponse('Erreur lors de la connexion', 500);
        }
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        
        return $this->successResponse(null, 'Déconnexion réussie');
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
            
            return $this->successResponse([
                'id' => $user->id,
                'nom' => $user->nom ?? '',
                'prenom' => $user->prenom ?? '',
                'email' => $user->email,
                'role' => $user->role,
                'role_name' => $roleName
            ]);
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

            $users = $query->orderBy('created_at', 'desc')->get();

            return response()->json([
                'success' => true,
                'data' => $users,
                'count' => $users->count()
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
               /*  'telephone' => $validated['telephone'],
                'adresse' => $validated['adresse'],
                'date_embauche' => $validated['date_embauche'],
                'salaire' => $validated['salaire'],
                'departement' => $validated['departement'],
                'poste' => $validated['poste'], */
                'is_active' => true
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
