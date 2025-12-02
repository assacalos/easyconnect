<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Models\Invoice;
use App\Models\InvoiceItem;
use App\Models\InvoiceTemplate;
use App\Models\Client;
use App\Models\User;
use App\Http\Resources\InvoiceResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class InvoiceController extends Controller
{
    /**
     * Afficher la liste des factures
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
            
            $query = Invoice::with(['client', 'commercial', 'items']);

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filtrage par date
            if ($request->has('date_debut')) {
                $query->where('invoice_date', '>=', $request->date_debut);
            }

            if ($request->has('date_fin')) {
                $query->where('invoice_date', '<=', $request->date_fin);
            }

            // Filtrage par client
            if ($request->has('client_id')) {
                $query->where('client_id', $request->client_id);
            }

            // Filtrage par commercial
            if ($request->has('commercial_id')) {
                $query->where('commercial_id', $request->commercial_id);
            }

            // Si commercial → filtre ses propres factures
            if ($user->role == 2) { // Commercial
                $query->where('commercial_id', $user->id);
            }

            // Pagination
            $perPage = $request->get('per_page', 15);
            $invoices = $query->orderBy('invoice_date', 'desc')->paginate($perPage);

            return response()->json([
                'success' => true,
                'data' => InvoiceResource::collection($invoices->items()),
                'pagination' => [
                    'current_page' => $invoices->currentPage(),
                    'last_page' => $invoices->lastPage(),
                    'per_page' => $invoices->perPage(),
                    'total' => $invoices->total(),
                ],
                'message' => 'Liste des factures récupérée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des factures: ' . $e->getMessage()
            ], 500);
        }
    }
}
