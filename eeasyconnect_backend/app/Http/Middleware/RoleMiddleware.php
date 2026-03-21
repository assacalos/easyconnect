<?php

namespace App\Http\Middleware;

use App\Enums\UserRole;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RoleMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next, ...$roles): Response
    {
        if (!auth()->check()) {
            return response()->json(['message' => 'Non authentifié'], 401);
        }

        $user = auth()->user();
        
        // Parser les rôles: si c'est une chaîne comme "1,2,6", la diviser en tableau
        $allowedRoles = [];
        foreach ($roles as $role) {
            // Si le rôle contient une virgule, c'est une chaîne de plusieurs rôles
            if (strpos($role, ',') !== false) {
                $allowedRoles = array_merge($allowedRoles, array_map('intval', explode(',', $role)));
            } else {
                $allowedRoles[] = (int)$role;
            }
        }
        
        // Convertir le rôle de l'utilisateur en entier (gère string "6" ou int 6)
        $userRole = is_numeric($user->role) ? (int) $user->role : 0;

        // Ne garder que des IDs de rôles connus (UserRole)
        $allowedRoles = array_values(array_unique(array_filter(
            $allowedRoles,
            static fn (int $id) => UserRole::tryFrom($id) !== null
        )));

        // Règle métier conservée : admin et patron peuvent passer outre la liste de la route
        $isAllowed = in_array($userRole, $allowedRoles, true)
            || $user->hasAnyRole(UserRole::Admin, UserRole::Patron);
        
        if (!$isAllowed) {
            return response()->json([
                'message' => 'Accès refusé. Rôle insuffisant.',
                'required_roles' => array_values($allowedRoles), // array_values pour réindexer
                'user_role' => $userRole,
                'route' => $request->path() // Ajout du chemin pour debug
            ], 403);
        }

        return $next($request);
    }
}
