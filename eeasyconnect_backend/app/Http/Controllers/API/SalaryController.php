<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Salary;
use App\Models\SalaryComponent;
use App\Models\SalaryItem;
use App\Models\Payroll;
use App\Models\PayrollSetting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SalaryController extends Controller
{
    /**
     * Afficher la liste des salaires
     */
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            $query = Salary::with(['employee', 'hr', 'salaryItems.salaryComponent']);

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filtrage par employé
            if ($request->has('employee_id')) {
                $query->where('employee_id', $request->employee_id);
            }

            // Filtrage par période
            if ($request->has('period')) {
                $query->where('period', $request->period);
            }

            // Filtrage par date
            if ($request->has('date_debut')) {
                $query->where('salary_date', '>=', $request->date_debut);
            }

            if ($request->has('date_fin')) {
                $query->where('salary_date', '<=', $request->date_fin);
            }

            // Si employé → filtre ses propres salaires
            if ($user->role == 4) { // Employé
                $query->where('employee_id', $user->id);
            }

            // Pagination
            $perPage = $request->get('per_page', 15);
            $salaries = $query->orderBy('salary_date', 'desc')->paginate($perPage);

            // Transformer les données
            $salaries->getCollection()->transform(function ($salary) {
                return [
                    'id' => $salary->id,
                    'salary_number' => $salary->salary_number,
                    'employee_name' => $salary->employee_name,
                    'hr_name' => $salary->hr_name,
                    'period' => $salary->period,
                    'period_start' => $salary->period_start?->format('Y-m-d'),
                    'period_end' => $salary->period_end?->format('Y-m-d'),
                    'payment_date' => $salary->salary_date?->format('Y-m-d'),
                    'base_salary' => $salary->base_salary,
                    'gross_salary' => $salary->gross_salary,
                    'net_salary' => $salary->net_salary,
                    'total_allowances' => $salary->total_allowances,
                    'total_deductions' => $salary->total_deductions,
                    'total_taxes' => $salary->total_taxes,
                    'total_social_security' => $salary->total_social_security,
                    'formatted_base_salary' => $salary->formatted_base_salary,
                    'formatted_gross_salary' => $salary->formatted_gross_salary,
                    'formatted_net_salary' => $salary->formatted_net_salary,
                    'formatted_total_allowances' => $salary->formatted_total_allowances,
                    'formatted_total_deductions' => $salary->formatted_total_deductions,
                    'formatted_total_taxes' => $salary->formatted_total_taxes,
                    'formatted_total_social_security' => $salary->formatted_total_social_security,
                    'status' => $salary->status,
                    'status_libelle' => $salary->status_libelle,
                    'is_overdue' => $salary->is_overdue,
                    'days_since_payment' => $salary->days_since_payment,
                    'notes' => $salary->notes,
                    'calculated_at' => $salary->calculated_at?->format('Y-m-d H:i:s'),
                    'approved_at' => $salary->approved_at?->format('Y-m-d H:i:s'),
                    'approved_by' => $salary->approver_name,
                    'paid_at' => $salary->paid_at?->format('Y-m-d H:i:s'),
                    'paid_by' => $salary->payer_name,
                    'salary_items' => $salary->salaryItems->map(function ($item) {
                        return [
                            'id' => $item->id,
                            'name' => $item->name,
                            'type' => $item->type,
                            'type_libelle' => $item->type_libelle,
                            'amount' => $item->amount,
                            'formatted_amount' => $item->formatted_amount,
                            'rate' => $item->rate,
                            'unit' => $item->unit,
                            'formatted_rate' => $item->formatted_rate,
                            'quantity' => $item->quantity,
                            'description' => $item->description,
                            'is_taxable' => $item->is_taxable,
                            'is_social_security' => $item->is_social_security,
                            'tax_amount' => $item->getTaxAmount(),
                            'social_security_amount' => $item->getSocialSecurityAmount(),
                            'net_amount' => $item->getNetAmount()
                        ];
                    }),
                    'created_at' => $salary->created_at->format('Y-m-d H:i:s'),
                    'updated_at' => $salary->updated_at->format('Y-m-d H:i:s'),
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $salaries,
                'message' => 'Liste des salaires récupérée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des salaires: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Afficher un salaire spécifique
     */
    public function show($id)
    {
        try {
            $salary = Salary::with(['employee', 'hr', 'approver', 'payer', 'salaryItems.salaryComponent'])->find($id);

            if (!$salary) {
                return response()->json([
                    'success' => false,
                    'message' => 'Salaire non trouvé'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => $salary,
                'message' => 'Salaire récupéré avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération du salaire: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Créer un nouveau salaire
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'employee_id' => 'required|exists:users,id',
                'period' => 'required|string',
                'period_start' => 'required|date',
                'period_end' => 'required|date|after:period_start',
                'salary_date' => 'required|date|after:period_end',
                'base_salary' => 'required|numeric|min:0',
                'notes' => 'nullable|string|max:1000'
            ]);

            DB::beginTransaction();

            $salary = Salary::create([
                'employee_id' => $validated['employee_id'],
                'hr_id' => $request->user()->id,
                'salary_number' => Salary::generateSalaryNumber(),
                'period' => $validated['period'],
                'period_start' => $validated['period_start'],
                'period_end' => $validated['period_end'],
                'salary_date' => $validated['salary_date'],
                'base_salary' => $validated['base_salary'],
                'gross_salary' => 0,
                'net_salary' => 0,
                'status' => 'draft',
                'notes' => $validated['notes']
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'data' => $salary->load(['employee', 'hr']),
                'message' => 'Salaire créé avec succès'
            ], 201);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création du salaire: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour un salaire
     */
    public function update(Request $request, $id)
    {
        try {
            $salary = Salary::find($id);

            if (!$salary) {
                return response()->json([
                    'success' => false,
                    'message' => 'Salaire non trouvé'
                ], 404);
            }

            if (!$salary->canBeEdited()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce salaire ne peut plus être modifié'
                ], 400);
            }

            $validated = $request->validate([
                'base_salary' => 'sometimes|numeric|min:0',
                'salary_date' => 'sometimes|date',
                'notes' => 'nullable|string|max:1000'
            ]);

            $salary->update($validated);

            return response()->json([
                'success' => true,
                'data' => $salary->load(['employee', 'hr']),
                'message' => 'Salaire mis à jour avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour du salaire: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer un salaire
     */
    public function destroy($id)
    {
        try {
            $salary = Salary::find($id);

            if (!$salary) {
                return response()->json([
                    'success' => false,
                    'message' => 'Salaire non trouvé'
                ], 404);
            }

            if (!$salary->canBeEdited()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce salaire ne peut plus être supprimé'
                ], 400);
            }

            $salary->delete();

            return response()->json([
                'success' => true,
                'message' => 'Salaire supprimé avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression du salaire: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Calculer un salaire
     */
    public function calculate($id)
    {
        try {
            $salary = Salary::find($id);

            if (!$salary) {
                return response()->json([
                    'success' => false,
                    'message' => 'Salaire non trouvé'
                ], 404);
            }

            if ($salary->calculateSalary()) {
                return response()->json([
                    'success' => true,
                    'data' => $salary->load(['employee', 'hr', 'salaryItems.salaryComponent']),
                    'message' => 'Salaire calculé avec succès'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce salaire ne peut pas être calculé'
                ], 400);
            }

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du calcul du salaire: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Approuver un salaire
     */
    public function approve(Request $request, $id)
    {
        try {
            $salary = Salary::find($id);

            if (!$salary) {
                return response()->json([
                    'success' => false,
                    'message' => 'Salaire non trouvé'
                ], 404);
            }

            $notes = $request->get('notes');

            if ($salary->approve($request->user()->id, $notes)) {
                return response()->json([
                    'success' => true,
                    'message' => 'Salaire approuvé avec succès'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce salaire ne peut pas être approuvé'
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
     * Marquer un salaire comme payé
     */
    public function markAsPaid($id)
    {
        try {
            $salary = Salary::find($id);

            if (!$salary) {
                return response()->json([
                    'success' => false,
                    'message' => 'Salaire non trouvé'
                ], 404);
            }

            if ($salary->markAsPaid($request->user()->id)) {
                return response()->json([
                    'success' => true,
                    'message' => 'Salaire marqué comme payé'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce salaire ne peut pas être marqué comme payé'
                ], 400);
            }

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du marquage: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Statistiques des salaires
     */
    public function statistics(Request $request)
    {
        try {
            $startDate = $request->get('date_debut');
            $endDate = $request->get('date_fin');

            $stats = Salary::getSalaryStats($startDate, $endDate);

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
     * Récupérer les composants de salaire
     */
    public function components()
    {
        try {
            $components = SalaryComponent::getActiveComponents();

            return response()->json([
                'success' => true,
                'data' => $components,
                'message' => 'Composants de salaire récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des composants: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les paramètres de paie
     */
    public function settings()
    {
        try {
            $settings = PayrollSetting::getAllSettings();

            return response()->json([
                'success' => true,
                'data' => $settings,
                'message' => 'Paramètres de paie récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des paramètres: ' . $e->getMessage()
            ], 500);
        }
    }
}
