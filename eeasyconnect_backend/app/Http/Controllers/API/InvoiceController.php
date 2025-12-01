<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Models\Invoice;
use App\Models\InvoiceItem;
use App\Models\InvoiceTemplate;
use App\Models\Client;
use App\Models\User;
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

            // Ajouter les informations client et commercial
            $invoices->getCollection()->transform(function ($invoice) {
                return [
                    'id' => $invoice->id,
                    'invoice_number' => $invoice->invoice_number,
                    'client_id' => $invoice->client_id,
                    'client_name' => $invoice->client_name,
                    'client_email' => $invoice->client_email,
                    'client_address' => $invoice->client_address,
                    'commercial_id' => $invoice->commercial_id,
                    'commercial_name' => $invoice->commercial_name,
                    'invoice_date' => $invoice->invoice_date->format('Y-m-d'),
                    'due_date' => $invoice->due_date->format('Y-m-d'),
                    'status' => $invoice->status,
                    'subtotal' => $invoice->subtotal,
                    'tax_rate' => $invoice->tax_rate,
                    'tax_amount' => $invoice->tax_amount,
                    'total_amount' => $invoice->total_amount,
                    'currency' => $invoice->currency,
                    'notes' => $invoice->notes,
                    'terms' => $invoice->terms,
                    'payment_info' => $invoice->payment_info,
                    'items' => $invoice->items->map(function ($item) {
                        return [
                            'id' => $item->id,
                            'description' => $item->description,
                            'quantity' => $item->quantity,
                            'unit_price' => $item->unit_price,
                            'total_price' => $item->total_price,
                            'unit' => $item->unit,
                        ];
                    }),
                    'sent_at' => $invoice->sent_at?->format('Y-m-d H:i:s'),
                    'paid_at' => $invoice->paid_at?->format('Y-m-d H:i:s'),
                    'is_overdue' => $invoice->is_overdue,
                    'days_until_due' => $invoice->days_until_due,
                    'created_at' => $invoice->created_at->format('Y-m-d H:i:s'),
                    'updated_at' => $invoice->updated_at->format('Y-m-d H:i:s'),
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $invoices,
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
