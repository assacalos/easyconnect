<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use Illuminate\Http\Request;
use App\Models\PaymentTemplate;
use App\Models\Paiement;
use Illuminate\Support\Facades\Validator;

class PaymentTemplateController extends Controller
{
    /**
     * Liste des modèles de paiement
     */
    public function index(Request $request)
    {
        $query = PaymentTemplate::with(['creator', 'updater']);

        // Filtrage par type
        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        // Filtrage par statut actif
        if ($request->has('active')) {
            $query->where('is_active', $request->boolean('active'));
        }

        // Filtrage par défaut
        if ($request->has('default')) {
            $query->where('is_default', $request->boolean('default'));
        }

        $templates = $query->orderBy('is_default', 'desc')
                          ->orderBy('created_at', 'desc')
                          ->paginate($request->get('per_page', 15));

        return response()->json([
            'success' => true,
            'templates' => $templates,
            'message' => 'Liste des modèles récupérée avec succès'
        ]);
    }

    /**
     * Détails d'un modèle
     */
    public function show($id)
    {
        $template = PaymentTemplate::with(['creator', 'updater'])->findOrFail($id);

        return response()->json([
            'success' => true,
            'template' => $template,
            'message' => 'Modèle récupéré avec succès'
        ]);
    }

    /**
     * Créer un modèle de paiement
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'type' => 'required|in:one_time,monthly',
            'default_amount' => 'required|numeric|min:0.01',
            'default_payment_method' => 'required|in:especes,virement,cheque,carte_bancaire,mobile_money',
            'default_frequency' => 'nullable|integer|min:1|required_if:type,monthly',
            'template' => 'nullable|array',
            'is_default' => 'boolean'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $validator->errors()
            ], 422);
        }

        $template = PaymentTemplate::create([
            'name' => $request->name,
            'description' => $request->description,
            'type' => $request->type,
            'default_amount' => $request->default_amount,
            'default_payment_method' => $request->default_payment_method,
            'default_frequency' => $request->default_frequency,
            'template' => $request->template ?? [],
            'is_default' => $request->is_default ?? false,
            'created_by' => auth()->id()
        ]);

        // Si c'est marqué comme défaut, retirer le statut des autres
        if ($template->is_default) {
            $template->setAsDefault();
        }

        return response()->json([
            'success' => true,
            'template' => $template,
            'message' => 'Modèle créé avec succès'
        ], 201);
    }

    /**
     * Modifier un modèle
     */
    public function update(Request $request, $id)
    {
        $template = PaymentTemplate::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'type' => 'sometimes|in:one_time,monthly',
            'default_amount' => 'sometimes|numeric|min:0.01',
            'default_payment_method' => 'sometimes|in:especes,virement,cheque,carte_bancaire,mobile_money',
            'default_frequency' => 'nullable|integer|min:1',
            'template' => 'nullable|array',
            'is_active' => 'boolean',
            'is_default' => 'boolean'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $validator->errors()
            ], 422);
        }

        $template->update(array_merge($request->only([
            'name', 'description', 'type', 'default_amount', 
            'default_payment_method', 'default_frequency', 'template', 'is_active'
        ]), [
            'updated_by' => auth()->id()
        ]));

        // Gérer le statut par défaut
        if ($request->has('is_default') && $request->is_default) {
            $template->setAsDefault();
        }

        return response()->json([
            'success' => true,
            'template' => $template,
            'message' => 'Modèle modifié avec succès'
        ]);
    }

    /**
     * Supprimer un modèle
     */
    public function destroy($id)
    {
        $template = PaymentTemplate::findOrFail($id);

        // Vérifier qu'il n'est pas utilisé
        $usageCount = Paiement::where('type', $template->type)->count();
        if ($usageCount > 0) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de supprimer un modèle en cours d\'utilisation'
            ], 400);
        }

        $template->delete();

        return response()->json([
            'success' => true,
            'message' => 'Modèle supprimé avec succès'
        ]);
    }

    /**
     * Définir comme modèle par défaut
     */
    public function setAsDefault($id)
    {
        $template = PaymentTemplate::findOrFail($id);

        if ($template->setAsDefault()) {
            return response()->json([
                'success' => true,
                'message' => 'Modèle défini comme défaut avec succès'
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Impossible de définir ce modèle comme défaut'
        ], 400);
    }

    /**
     * Créer un paiement à partir d'un modèle
     */
    public function createPaymentFromTemplate(Request $request, $id)
    {
        $template = PaymentTemplate::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'facture_id' => 'required|exists:factures,id',
            'montant' => 'sometimes|numeric|min:0.01',
            'date_paiement' => 'sometimes|date',
            'due_date' => 'nullable|date|after:date_paiement',
            'description' => 'nullable|string',
            'notes' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $validator->errors()
            ], 422);
        }

        $paymentData = [
            'payment_number' => Paiement::generatePaymentNumber(),
            'type' => $template->type,
            'facture_id' => $request->facture_id,
            'montant' => $request->montant ?? $template->default_amount,
            'date_paiement' => $request->date_paiement ?? now()->toDateString(),
            'due_date' => $request->due_date,
            'currency' => 'FCFA',
            'type_paiement' => $template->default_payment_method,
            'status' => 'draft',
            'description' => $request->description,
            'commentaire' => $request->notes,
            'user_id' => auth()->id()
        ];

        $payment = Paiement::create($paymentData);

        return response()->json([
            'success' => true,
            'payment' => $payment,
            'message' => 'Paiement créé à partir du modèle avec succès'
        ], 201);
    }

    /**
     * Dupliquer un modèle
     */
    public function duplicate($id)
    {
        $originalTemplate = PaymentTemplate::findOrFail($id);

        $newTemplate = PaymentTemplate::create([
            'name' => $originalTemplate->name . ' (Copie)',
            'description' => $originalTemplate->description,
            'type' => $originalTemplate->type,
            'default_amount' => $originalTemplate->default_amount,
            'default_payment_method' => $originalTemplate->default_payment_method,
            'default_frequency' => $originalTemplate->default_frequency,
            'template' => $originalTemplate->template,
            'is_default' => false,
            'is_active' => true,
            'created_by' => auth()->id()
        ]);

        return response()->json([
            'success' => true,
            'template' => $newTemplate,
            'message' => 'Modèle dupliqué avec succès'
        ], 201);
    }
}
