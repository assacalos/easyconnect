<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use App\Models\PaymentSchedule;
use App\Models\PaymentInstallment;
use App\Models\PaymentTemplate;
use App\Models\Client;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class PaymentController extends Controller
{
    /**
     * Afficher la liste des paiements
     */
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            $query = Payment::with(['client', 'comptable', 'paymentSchedule']);

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filtrage par type
            if ($request->has('type')) {
                $query->where('type', $request->type);
            }

            // Filtrage par date
            if ($request->has('date_debut')) {
                $query->where('payment_date', '>=', $request->date_debut);
            }

            if ($request->has('date_fin')) {
                $query->where('payment_date', '<=', $request->date_fin);
            }

            // Filtrage par client
            if ($request->has('client_id')) {
                $query->where('client_id', $request->client_id);
            }

            // Filtrage par comptable
            if ($request->has('comptable_id')) {
                $query->where('comptable_id', $request->comptable_id);
            }

            // Si comptable → filtre ses propres paiements
            if ($user->role == 3) { // Comptable
                $query->where('comptable_id', $user->id);
            }

            // Pagination
            $perPage = $request->get('per_page', 15);
            $payments = $query->orderBy('payment_date', 'desc')->paginate($perPage);

            // Ajouter les informations client et comptable
            $payments->getCollection()->transform(function ($payment) {
                return [
                    'id' => $payment->id,
                    'payment_number' => $payment->payment_number,
                    'type' => $payment->type,
                    'client_id' => $payment->client_id,
                    'client_name' => $payment->client_name,
                    'client_email' => $payment->client_email,
                    'client_address' => $payment->client_address,
                    'comptable_id' => $payment->comptable_id,
                    'comptable_name' => $payment->comptable_name,
                    'payment_date' => $payment->payment_date->format('Y-m-d'),
                    'due_date' => $payment->due_date?->format('Y-m-d'),
                    'status' => $payment->status,
                    'amount' => $payment->amount,
                    'currency' => $payment->currency,
                    'payment_method' => $payment->payment_method,
                    'description' => $payment->description,
                    'notes' => $payment->notes,
                    'reference' => $payment->reference,
                    'submitted_at' => $payment->submitted_at?->format('Y-m-d H:i:s'),
                    'approved_at' => $payment->approved_at?->format('Y-m-d H:i:s'),
                    'paid_at' => $payment->paid_at?->format('Y-m-d H:i:s'),
                    'is_overdue' => $payment->is_overdue,
                    'days_until_due' => $payment->days_until_due,
                    'created_at' => $payment->created_at->format('Y-m-d H:i:s'),
                    'updated_at' => $payment->updated_at->format('Y-m-d H:i:s'),
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $payments,
                'message' => 'Liste des paiements récupérée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des paiements: ' . $e->getMessage()
            ], 500);
        }
    }
}
