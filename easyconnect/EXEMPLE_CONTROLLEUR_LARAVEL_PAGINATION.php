<?php

/**
 * EXEMPLE DE CONTRÔLEUR LARAVEL AVEC PAGINATION
 * 
 * Ce fichier montre comment implémenter la pagination côté serveur
 * pour que Flutter puisse gérer correctement les liens next/prev et le total.
 * 
 * IMPORTANT: Ce fichier est un EXEMPLE. Vous devez adapter vos contrôleurs
 * existants pour utiliser cette structure.
 */

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Employee; // Remplacez par votre modèle
use Illuminate\Http\JsonResponse;

class EmployeeController extends Controller
{
    /**
     * Récupérer la liste des employés avec pagination
     * 
     * @param Request $request
     * @return JsonResponse
     */
    public function index(Request $request): JsonResponse
    {
        try {
            // Récupérer les paramètres de pagination
            $perPage = $request->input('per_page', 15); // Par défaut 15 items par page
            $page = $request->input('page', 1);
            
            // Construire la requête avec les filtres
            $query = Employee::query();
            
            // Filtre par recherche
            if ($request->has('search') && $request->search) {
                $search = $request->search;
                $query->where(function($q) use ($search) {
                    $q->where('first_name', 'like', "%{$search}%")
                      ->orWhere('last_name', 'like', "%{$search}%")
                      ->orWhere('email', 'like', "%{$search}%");
                });
            }
            
            // Filtre par département
            if ($request->has('department') && $request->department) {
                $query->where('department', $request->department);
            }
            
            // Filtre par poste
            if ($request->has('position') && $request->position) {
                $query->where('position', $request->position);
            }
            
            // Filtre par statut
            if ($request->has('status') && $request->status) {
                $query->where('status', $request->status);
            }
            
            // Appliquer la pagination
            // Laravel retourne automatiquement les métadonnées de pagination
            $employees = $query->paginate($perPage);
            
            // Retourner la réponse au format attendu par Flutter
            return response()->json([
                'success' => true,
                'data' => $employees->items(), // Les données
                'current_page' => $employees->currentPage(),
                'last_page' => $employees->lastPage(),
                'per_page' => $employees->perPage(),
                'total' => $employees->total(),
                'from' => $employees->firstItem(),
                'to' => $employees->lastItem(),
                'first_page_url' => $employees->url(1),
                'last_page_url' => $employees->url($employees->lastPage()),
                'next_page_url' => $employees->nextPageUrl(),
                'prev_page_url' => $employees->previousPageUrl(),
                'path' => $employees->path(),
            ], 200);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des employés: ' . $e->getMessage(),
            ], 500);
        }
    }
    
    /**
     * ALTERNATIVE: Utiliser la méthode paginate() qui retourne directement
     * un objet LengthAwarePaginator avec toutes les métadonnées
     */
    public function indexAlternative(Request $request): JsonResponse
    {
        try {
            $perPage = $request->input('per_page', 15);
            
            $query = Employee::query();
            
            // Appliquer les filtres...
            // (même logique que ci-dessus)
            
            // Laravel retourne automatiquement toutes les métadonnées
            $employees = $query->paginate($perPage);
            
            // Retourner directement l'objet paginé
            // Laravel le sérialise automatiquement avec toutes les métadonnées
            return response()->json([
                'success' => true,
                'data' => $employees, // Laravel inclut automatiquement toutes les métadonnées
            ], 200);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur: ' . $e->getMessage(),
            ], 500);
        }
    }
    
    /**
     * EXEMPLE pour d'autres modèles (Clients, Stocks, etc.)
     */
    public function getClients(Request $request): JsonResponse
    {
        try {
            $perPage = $request->input('per_page', 15);
            $page = $request->input('page', 1);
            
            $query = \App\Models\Client::query();
            
            // Filtres
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }
            
            if ($request->has('search')) {
                $query->where(function($q) use ($request) {
                    $q->where('nom', 'like', "%{$request->search}%")
                      ->orWhere('email', 'like', "%{$request->search}%");
                });
            }
            
            // Pagination
            $clients = $query->paginate($perPage);
            
            return response()->json([
                'success' => true,
                'data' => $clients->items(),
                'current_page' => $clients->currentPage(),
                'last_page' => $clients->lastPage(),
                'per_page' => $clients->perPage(),
                'total' => $clients->total(),
                'from' => $clients->firstItem(),
                'to' => $clients->lastItem(),
                'first_page_url' => $clients->url(1),
                'last_page_url' => $clients->url($clients->lastPage()),
                'next_page_url' => $clients->nextPageUrl(),
                'prev_page_url' => $clients->previousPageUrl(),
                'path' => $clients->path(),
            ], 200);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur: ' . $e->getMessage(),
            ], 500);
        }
    }
}

/**
 * ROUTES À AJOUTER DANS routes/api.php :
 * 
 * Route::middleware('auth:sanctum')->group(function () {
 *     Route::get('/employees', [EmployeeController::class, 'index']);
 *     Route::get('/clients', [ClientController::class, 'getClients']);
 *     // ... autres routes
 * });
 * 
 * IMPORTANT:
 * 1. Utilisez toujours ->paginate(15) au lieu de ->get() pour les listes
 * 2. Retournez les métadonnées de pagination (current_page, last_page, total, etc.)
 * 3. Le paramètre 'per_page' peut être passé dans la requête pour personnaliser
 * 4. Le paramètre 'page' permet de naviguer entre les pages
 */

