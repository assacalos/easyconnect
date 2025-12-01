<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Expense;
use App\Models\ExpenseCategory;
use App\Models\ExpenseApproval;
use App\Models\ExpenseBudget;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ExpenseController extends Controller
{
    /**
     * Afficher la liste des dépenses
     */
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            $query = Expense::with(['expenseCategory', 'employee', 'comptable', 'approvals.approver']);

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Si employé → filtre ses propres dépenses
            if ($user->role == 4) { // Employé
                $query->where('employee_id', $user->id);
            }

            // Pagination
            $perPage = $request->get('per_page', 15);
            $expenses = $query->orderBy('expense_date', 'desc')->paginate($perPage);

            return response()->json([
                'success' => true,
                'data' => $expenses,
                'message' => 'Liste des dépenses récupérée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des dépenses: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Créer une nouvelle dépense
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'expense_category_id' => 'required|exists:expense_categories,id',
                'expense_date' => 'required|date',
                'amount' => 'required|numeric|min:0',
                'currency' => 'required|string|max:3',
                'description' => 'required|string|max:1000',
                'justification' => 'nullable|string|max:1000',
                'receipt' => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:10240'
            ]);

            DB::beginTransaction();

            $expense = Expense::create([
                'expense_category_id' => $validated['expense_category_id'],
                'employee_id' => $request->user()->id,
                'expense_number' => Expense::generateExpenseNumber(),
                'expense_date' => $validated['expense_date'],
                'submission_date' => now()->toDateString(),
                'amount' => $validated['amount'],
                'currency' => $validated['currency'],
                'description' => $validated['description'],
                'justification' => $validated['justification'],
                'status' => 'draft'
            ]);

            // Upload du justificatif si fourni
            if ($request->hasFile('receipt')) {
                $expense->uploadReceipt($request->file('receipt'));
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'data' => $expense->load(['expenseCategory', 'employee']),
                'message' => 'Dépense créée avec succès'
            ], 201);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création de la dépense: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Afficher une dépense spécifique
     */
    public function show($id)
    {
        try {
            $expense = Expense::with(['expenseCategory', 'employee', 'comptable', 'approvals.approver'])->find($id);

            if (!$expense) {
                return response()->json([
                    'success' => false,
                    'message' => 'Dépense non trouvée'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => $expense,
                'message' => 'Dépense récupérée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération de la dépense: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour une dépense
     */
    public function update(Request $request, $id)
    {
        try {
            $expense = Expense::find($id);

            if (!$expense) {
                return response()->json([
                    'success' => false,
                    'message' => 'Dépense non trouvée'
                ], 404);
            }

            if (!$expense->canBeEdited()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette dépense ne peut plus être modifiée'
                ], 400);
            }

            $validated = $request->validate([
                'expense_date' => 'sometimes|date',
                'amount' => 'sometimes|numeric|min:0',
                'description' => 'sometimes|string|max:1000',
                'justification' => 'nullable|string|max:1000'
            ]);

            $expense->update($validated);

            return response()->json([
                'success' => true,
                'data' => $expense->load(['expenseCategory', 'employee']),
                'message' => 'Dépense mise à jour avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour de la dépense: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer une dépense
     */
    public function destroy($id)
    {
        try {
            $expense = Expense::find($id);

            if (!$expense) {
                return response()->json([
                    'success' => false,
                    'message' => 'Dépense non trouvée'
                ], 404);
            }

            if (!$expense->canBeEdited()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette dépense ne peut plus être supprimée'
                ], 400);
            }

            $expense->delete();

            return response()->json([
                'success' => true,
                'message' => 'Dépense supprimée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression de la dépense: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Soumettre une dépense pour approbation
     */
    public function submit($id)
    {
        try {
            $expense = Expense::find($id);

            if (!$expense) {
                return response()->json([
                    'success' => false,
                    'message' => 'Dépense non trouvée'
                ], 404);
            }

            if ($expense->submit()) {
                return response()->json([
                    'success' => true,
                    'message' => 'Dépense soumise pour approbation'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette dépense ne peut pas être soumise'
                ], 400);
            }

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la soumission: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Approuver une dépense
     */
    public function approve(Request $request, $id)
    {
        try {
            $expense = Expense::find($id);

            if (!$expense) {
                return response()->json([
                    'success' => false,
                    'message' => 'Dépense non trouvée'
                ], 404);
            }

            $comments = $request->get('comments');

            if ($expense->approve($request->user()->id, $comments)) {
                return response()->json([
                    'success' => true,
                    'message' => 'Dépense approuvée avec succès'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette dépense ne peut pas être approuvée'
                ], 400);
            }

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'approbation: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Rejeter une dépense
     */
    public function reject(Request $request, $id)
    {
        try {
            $expense = Expense::find($id);

            if (!$expense) {
                return response()->json([
                    'success' => false,
                    'message' => 'Dépense non trouvée'
                ], 404);
            }

            $validated = $request->validate([
                'reason' => 'required|string|max:1000'
            ]);

            if ($expense->reject($request->user()->id, $validated['reason'])) {
                return response()->json([
                    'success' => true,
                    'message' => 'Dépense rejetée'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette dépense ne peut pas être rejetée'
                ], 400);
            }

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du rejet: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Statistiques des dépenses
     */
    public function statistics(Request $request)
    {
        try {
            $startDate = $request->get('date_debut');
            $endDate = $request->get('date_fin');

            $stats = Expense::getExpenseStats($startDate, $endDate);

            return response()->json([
                'success' => true,
                'data' => $stats,
                'message' => 'Statistiques récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des statistiques: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les catégories de dépenses
     */
    public function categories()
    {
        try {
            $categories = ExpenseCategory::active()->orderBy('name')->get();

            return response()->json([
                'success' => true,
                'data' => $categories,
                'message' => 'Catégories de dépenses récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des catégories: ' . $e->getMessage()
            ], 500);
        }
    }
}