<?php

namespace App\Http\Controllers\API;

use App\Models\Announcement;
use App\Models\CatalogArticle;
use App\Models\Client;
use App\Models\ContactSetting;
use App\Models\Intervention;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ClientPortalController extends Controller
{
    protected NotificationService $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }

    /**
     * Liste des annonces publiées (annonces + promotions)
     */
    public function announcements(Request $request)
    {
        $type = $request->get('type'); // optional: announcement, promotion
        $query = Announcement::published()->orderByDesc('published_at');
        if ($type) {
            $query->where('type', $type);
        }
        $items = $query->get()->map(fn ($a) => [
            'id' => $a->id,
            'title' => $a->title,
            'content' => $a->content,
            'type' => $a->type,
            'image_url' => $a->image_url,
            'published_at' => $a->published_at?->toIso8601String(),
        ]);

        return response()->json([
            'success' => true,
            'data' => $items,
        ]);
    }

    /**
     * Catalogue des articles (avec prix)
     */
    public function catalog(Request $request)
    {
        $category = $request->get('category');
        $query = CatalogArticle::active()->orderBy('sort_order');
        if ($category) {
            $query->where('category', $category);
        }
        $items = $query->get()->map(fn ($a) => [
            'id' => $a->id,
            'name' => $a->name,
            'description' => $a->description,
            'price' => (float) $a->price,
            'image_url' => $a->image_url,
            'category' => $a->category,
            'is_offer' => $a->is_offer,
        ]);

        return response()->json([
            'success' => true,
            'data' => $items,
        ]);
    }

    /**
     * Offres (articles marqués comme offres)
     */
    public function offers(Request $request)
    {
        $items = CatalogArticle::active()->offers()->orderBy('sort_order')->get()->map(fn ($a) => [
            'id' => $a->id,
            'name' => $a->name,
            'description' => $a->description,
            'price' => (float) $a->price,
            'image_url' => $a->image_url,
            'category' => $a->category,
        ]);

        return response()->json([
            'success' => true,
            'data' => $items,
        ]);
    }

    /**
     * Coordonnées de contact (téléphone, email, adresse, etc.)
     */
    public function contact()
    {
        $items = ContactSetting::orderBy('sort_order')->get()->map(fn ($c) => [
            'key' => $c->key,
            'label' => $c->label ?? $c->key,
            'value' => $c->value,
        ]);

        return response()->json([
            'success' => true,
            'data' => $items,
        ]);
    }

    /**
     * Créer une demande d'intervention (ticket) depuis le portail client.
     * client_id et coordonnées client sont remplis à partir du Client (enregistré par le commercial) lié via portal_user_id.
     */
    public function storeInterventionRequest(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'type' => 'required|in:external,on_site',
            'priority' => 'required|in:low,medium,high,urgent',
            'scheduled_date' => 'required|date',
            'location' => 'nullable|string|max:255',
            'equipment' => 'nullable|string|max:255',
            'problem_description' => 'nullable|string',
        ]);

        $user = $request->user();
        $client = Client::where('portal_user_id', $user->id)->first();

        $clientId = null;
        $clientName = $user->nom . ' ' . trim($user->prenom ?? '');
        $clientPhone = null;
        $clientEmail = $user->email;

        if ($client) {
            $clientId = $client->id;
            $clientName = trim($client->nom . ' ' . ($client->prenom ?? ''));
            $clientPhone = $client->contact;
            $clientEmail = $client->email ?? $user->email;
        }

        try {
            DB::beginTransaction();

            $intervention = Intervention::create([
                'title' => $validated['title'],
                'description' => $validated['description'],
                'type' => $validated['type'],
                'priority' => $validated['priority'],
                'scheduled_date' => $validated['scheduled_date'],
                'location' => $validated['location'] ?? null,
                'client_id' => $clientId,
                'client_name' => $clientName,
                'client_phone' => $clientPhone,
                'client_email' => $clientEmail,
                'equipment' => $validated['equipment'] ?? null,
                'problem_description' => $validated['problem_description'] ?? null,
                'created_by' => $user->id,
                'status' => 'pending',
            ]);

            DB::commit();

            $this->notificationService->notifyNewIntervention($intervention);

            return response()->json([
                'success' => true,
                'data' => [
                    'id' => $intervention->id,
                    'title' => $intervention->title,
                    'status' => $intervention->status,
                    'scheduled_date' => $intervention->scheduled_date->format('Y-m-d H:i:s'),
                ],
                'message' => 'Demande d\'intervention envoyée avec succès.',
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'envoi de la demande: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Liste des demandes d'intervention du client connecté (pour voir le suivi)
     */
    public function myInterventions(Request $request)
    {
        $user = $request->user();
        $client = Client::where('portal_user_id', $user->id)->first();

        $query = Intervention::query()
            ->where('created_by', $user->id);

        if ($client) {
            $query->orWhere('client_id', $client->id);
        }

        $items = $query->orderByDesc('created_at')->get()->map(fn ($i) => [
            'id' => $i->id,
            'title' => $i->title,
            'status' => $i->status,
            'priority' => $i->priority,
            'scheduled_date' => $i->scheduled_date?->format('Y-m-d H:i:s'),
            'created_at' => $i->created_at->format('Y-m-d H:i:s'),
        ]);

        return response()->json([
            'success' => true,
            'data' => $items,
        ]);
    }
}
