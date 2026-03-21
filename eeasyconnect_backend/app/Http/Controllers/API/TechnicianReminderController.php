<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Models\TechnicianReminder;
use Illuminate\Http\Request;

class TechnicianReminderController extends Controller
{
    /**
     * Liste des rappels personnels : technicien = les siens uniquement.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Non authentifié'], 401);
        }

        $query = TechnicianReminder::with(['client', 'user'])
            ->where('user_id', $user->id)
            ->orderBy('due_date')
            ->orderByDesc('created_at');

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        $perPage = min((int) $request->get('per_page', 50), 100);
        $items = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $items->items(),
            'pagination' => [
                'current_page' => $items->currentPage(),
                'last_page' => $items->lastPage(),
                'per_page' => $items->perPage(),
                'total' => $items->total(),
                'from' => $items->firstItem(),
                'to' => $items->lastItem(),
            ],
        ], 200, [], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Créer un rappel personnel (technicien).
     */
    public function store(Request $request)
    {
        $user = $request->user();
        if (!$user || $user->role != 5) {
            return response()->json(['success' => false, 'message' => 'Réservé au technicien'], 403);
        }

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'notes' => 'nullable|string',
            'client_id' => 'nullable|exists:clients,id',
            'company_name' => 'nullable|string|max:255',
            'due_date' => 'required|date|after_or_equal:today',
            'remind_days_before' => 'required|in:1,2,3',
        ]);

        $reminder = TechnicianReminder::create([
            'user_id' => $user->id,
            'title' => $validated['title'],
            'notes' => $validated['notes'] ?? null,
            'client_id' => $validated['client_id'] ?? null,
            'company_name' => $validated['company_name'] ?? null,
            'due_date' => $validated['due_date'],
            'remind_days_before' => (int) $validated['remind_days_before'],
            'status' => 'pending',
        ]);

        return response()->json([
            'success' => true,
            'data' => $reminder->load(['client', 'user']),
            'message' => 'Rappel enregistré. Vous serez notifié ' . $reminder->remind_days_before . ' jour(s) avant la date limite.',
        ], 201, [], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Détail d'un rappel.
     */
    public function show(Request $request, $id)
    {
        $user = $request->user();
        $reminder = TechnicianReminder::with(['client', 'user'])->find($id);
        if (!$reminder) {
            return response()->json(['success' => false, 'message' => 'Rappel introuvable'], 404);
        }
        if ($reminder->user_id != $user->id && !in_array($user->role, [1, 6])) {
            return response()->json(['success' => false, 'message' => 'Accès non autorisé'], 403);
        }
        return response()->json(['success' => true, 'data' => $reminder], 200, [], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Mettre à jour un rappel (propriétaire uniquement).
     */
    public function update(Request $request, $id)
    {
        $user = $request->user();
        $reminder = TechnicianReminder::find($id);
        if (!$reminder) {
            return response()->json(['success' => false, 'message' => 'Rappel introuvable'], 404);
        }
        if ($reminder->user_id != $user->id) {
            return response()->json(['success' => false, 'message' => 'Accès non autorisé'], 403);
        }

        $validated = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'notes' => 'nullable|string',
            'client_id' => 'nullable|exists:clients,id',
            'company_name' => 'nullable|string|max:255',
            'due_date' => 'sometimes|required|date',
            'remind_days_before' => 'sometimes|in:1,2,3',
            'status' => 'sometimes|in:pending,done,cancelled',
        ]);

        $reminder->update(array_filter($validated, fn ($v) => $v !== null));

        return response()->json([
            'success' => true,
            'data' => $reminder->fresh(['client', 'user']),
            'message' => 'Rappel mis à jour.',
        ], 200, [], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Supprimer un rappel (propriétaire ou admin/patron).
     */
    public function destroy(Request $request, $id)
    {
        $user = $request->user();
        $reminder = TechnicianReminder::find($id);
        if (!$reminder) {
            return response()->json(['success' => false, 'message' => 'Rappel introuvable'], 404);
        }
        if ($reminder->user_id != $user->id && !in_array($user->role, [1, 6])) {
            return response()->json(['success' => false, 'message' => 'Accès non autorisé'], 403);
        }
        $reminder->delete();
        return response()->json(['success' => true, 'message' => 'Rappel supprimé.'], 200, [], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Marquer comme fait (propriétaire).
     */
    public function markDone(Request $request, $id)
    {
        $user = $request->user();
        $reminder = TechnicianReminder::find($id);
        if (!$reminder) {
            return response()->json(['success' => false, 'message' => 'Rappel introuvable'], 404);
        }
        if ($reminder->user_id != $user->id) {
            return response()->json(['success' => false, 'message' => 'Accès non autorisé'], 403);
        }
        $reminder->update(['status' => 'done']);
        return response()->json([
            'success' => true,
            'data' => $reminder->fresh(['client', 'user']),
            'message' => 'Rappel marqué comme fait.',
        ], 200, [], JSON_UNESCAPED_UNICODE);
    }
}
