<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Contract;
use App\Models\ContractClause;
use App\Models\ContractAttachment;
use App\Models\ContractTemplate;
use App\Models\ContractAmendment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ContractController extends Controller
{
    /**
     * Afficher la liste des contrats
     */
    public function index(Request $request)
    {
        try {
            $query = Contract::with(['employee', 'creator', 'approver', 'clauses', 'attachments', 'amendments']);

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filtrage par type de contrat
            if ($request->has('contract_type')) {
                $query->where('contract_type', $request->contract_type);
            }

            // Filtrage par département
            if ($request->has('department')) {
                $query->where('department', $request->department);
            }

            // Filtrage par employé
            if ($request->has('employee_id')) {
                $query->where('employee_id', $request->employee_id);
            }

            // Filtrage par numéro de contrat
            if ($request->has('contract_number')) {
                $query->where('contract_number', 'like', '%' . $request->contract_number . '%');
            }

            // Filtrage par date de début
            if ($request->has('start_date_from')) {
                $query->where('start_date', '>=', $request->start_date_from);
            }

            if ($request->has('start_date_to')) {
                $query->where('start_date', '<=', $request->start_date_to);
            }

            // Filtrage par date de fin
            if ($request->has('end_date_from')) {
                $query->where('end_date', '>=', $request->end_date_from);
            }

            if ($request->has('end_date_to')) {
                $query->where('end_date', '<=', $request->end_date_to);
            }

            // Filtrage par expirant
            if ($request->has('expiring_soon')) {
                if ($request->expiring_soon === 'true') {
                    $query->expiringSoon();
                }
            }

            // Filtrage par expiré
            if ($request->has('expired')) {
                if ($request->expired === 'true') {
                    $query->expired();
                }
            }

            // Pagination
            $perPage = $request->get('per_page', 15);
            $contracts = $query->orderBy('created_at', 'desc')->paginate($perPage);

            // Transformer les données
            $contracts->getCollection()->transform(function ($contract) {
                return [
                    'id' => $contract->id,
                    'contract_number' => $contract->contract_number,
                    'employee_id' => $contract->employee_id,
                    'employee_name' => $contract->employee_name,
                    'employee_email' => $contract->employee_email,
                    'contract_type' => $contract->contract_type,
                    'contract_type_libelle' => $contract->contract_type_libelle,
                    'position' => $contract->position,
                    'department' => $contract->department,
                    'job_title' => $contract->job_title,
                    'job_description' => $contract->job_description,
                    'gross_salary' => $contract->gross_salary,
                    'net_salary' => $contract->net_salary,
                    'formatted_gross_salary' => $contract->formatted_gross_salary,
                    'formatted_net_salary' => $contract->formatted_net_salary,
                    'salary_currency' => $contract->salary_currency,
                    'payment_frequency' => $contract->payment_frequency,
                    'payment_frequency_libelle' => $contract->payment_frequency_libelle,
                    'start_date' => $contract->start_date?->format('Y-m-d'),
                    'end_date' => $contract->end_date?->format('Y-m-d'),
                    'duration_months' => $contract->duration_months,
                    'duration_in_months' => $contract->duration_in_months,
                    'remaining_days' => $contract->remaining_days,
                    'work_location' => $contract->work_location,
                    'work_schedule' => $contract->work_schedule,
                    'work_schedule_libelle' => $contract->work_schedule_libelle,
                    'weekly_hours' => $contract->weekly_hours,
                    'probation_period' => $contract->probation_period,
                    'probation_period_libelle' => $contract->probation_period_libelle,
                    'status' => $contract->status,
                    'status_libelle' => $contract->status_libelle,
                    'termination_reason' => $contract->termination_reason,
                    'termination_date' => $contract->termination_date?->format('Y-m-d'),
                    'notes' => $contract->notes,
                    'contract_template' => $contract->contract_template,
                    'approved_at' => $contract->approved_at?->format('Y-m-d H:i:s'),
                    'approved_by' => $contract->approved_by,
                    'approver_name' => $contract->approver_name,
                    'rejection_reason' => $contract->rejection_reason,
                    'created_by' => $contract->created_by,
                    'creator_name' => $contract->creator_name,
                    'updated_by' => $contract->updated_by,
                    'updater_name' => $contract->updater_name,
                    'is_draft' => $contract->is_draft,
                    'is_pending' => $contract->is_pending,
                    'is_active' => $contract->is_active,
                    'is_expired' => $contract->is_expired,
                    'is_terminated' => $contract->is_terminated,
                    'is_cancelled' => $contract->is_cancelled,
                    'can_edit' => $contract->can_edit,
                    'can_submit' => $contract->can_submit,
                    'can_approve' => $contract->can_approve,
                    'can_reject' => $contract->can_reject,
                    'can_terminate' => $contract->can_terminate,
                    'can_cancel' => $contract->can_cancel,
                    'is_expiring_soon' => $contract->is_expiring_soon,
                    'has_expired' => $contract->has_expired,
                    'clauses' => $contract->clauses->map(function ($clause) {
                        return [
                            'id' => $clause->id,
                            'title' => $clause->title,
                            'content' => $clause->content,
                            'type' => $clause->type,
                            'type_libelle' => $clause->type_libelle,
                            'is_mandatory' => $clause->is_mandatory,
                            'order' => $clause->order,
                            'created_at' => $clause->created_at->format('Y-m-d H:i:s')
                        ];
                    }),
                    'attachments' => $contract->attachments->map(function ($attachment) {
                        return [
                            'id' => $attachment->id,
                            'file_name' => $attachment->file_name,
                            'file_path' => $attachment->file_path,
                            'file_type' => $attachment->file_type,
                            'file_size' => $attachment->file_size,
                            'formatted_file_size' => $attachment->formatted_file_size,
                            'attachment_type' => $attachment->attachment_type,
                            'attachment_type_libelle' => $attachment->attachment_type_libelle,
                            'description' => $attachment->description,
                            'uploaded_at' => $attachment->uploaded_at->format('Y-m-d H:i:s'),
                            'uploaded_by' => $attachment->uploaded_by,
                            'uploader_name' => $attachment->uploader_name
                        ];
                    }),
                    'amendments' => $contract->amendments->map(function ($amendment) {
                        return [
                            'id' => $amendment->id,
                            'amendment_type' => $amendment->amendment_type,
                            'amendment_type_libelle' => $amendment->amendment_type_libelle,
                            'reason' => $amendment->reason,
                            'description' => $amendment->description,
                            'changes' => $amendment->changes,
                            'effective_date' => $amendment->effective_date?->format('Y-m-d'),
                            'status' => $amendment->status,
                            'status_libelle' => $amendment->status_libelle,
                            'approval_notes' => $amendment->approval_notes,
                            'approved_at' => $amendment->approved_at?->format('Y-m-d H:i:s'),
                            'approved_by' => $amendment->approved_by,
                            'approver_name' => $amendment->approver_name,
                            'is_pending' => $amendment->is_pending,
                            'is_approved' => $amendment->is_approved,
                            'is_rejected' => $amendment->is_rejected,
                            'can_approve' => $amendment->can_approve,
                            'can_reject' => $amendment->can_reject,
                            'creator_name' => $amendment->creator_name,
                            'created_at' => $amendment->created_at->format('Y-m-d H:i:s')
                        ];
                    }),
                    'created_at' => $contract->created_at->format('Y-m-d H:i:s'),
                    'updated_at' => $contract->updated_at->format('Y-m-d H:i:s')
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $contracts,
                'message' => 'Liste des contrats récupérée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des contrats: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Afficher un contrat spécifique
     */
    public function show($id)
    {
        try {
            $contract = Contract::with(['employee', 'creator', 'approver', 'clauses', 'attachments', 'amendments'])->find($id);

            if (!$contract) {
                return response()->json([
                    'success' => false,
                    'message' => 'Contrat non trouvé'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => $contract,
                'message' => 'Contrat récupéré avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération du contrat: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Créer un nouveau contrat
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'employee_id' => 'required|exists:employees,id',
                'contract_type' => 'required|in:permanent,fixed_term,temporary,internship,consultant',
                'position' => 'required|string|max:255',
                'department' => 'required|string|max:255',
                'job_title' => 'required|string|max:255',
                'job_description' => 'required|string',
                'gross_salary' => 'required|numeric|min:0',
                'net_salary' => 'required|numeric|min:0',
                'salary_currency' => 'nullable|string|max:10',
                'payment_frequency' => 'required|in:monthly,weekly,daily,hourly',
                'start_date' => 'required|date',
                'end_date' => 'nullable|date|after:start_date',
                'duration_months' => 'nullable|integer|min:1',
                'work_location' => 'required|string|max:255',
                'work_schedule' => 'required|in:full_time,part_time,flexible',
                'weekly_hours' => 'required|integer|min:1|max:168',
                'probation_period' => 'required|in:none,1_month,3_months,6_months',
                'notes' => 'nullable|string',
                'contract_template' => 'nullable|string|max:255'
            ]);

            DB::beginTransaction();

            // Générer le numéro de contrat
            $contractNumber = 'CTR-' . date('Y') . '-' . str_pad(Contract::count() + 1, 6, '0', STR_PAD_LEFT);

            // Récupérer les informations de l'employé
            $employee = \App\Models\Employee::find($validated['employee_id']);

            $contract = Contract::create([
                'contract_number' => $contractNumber,
                'employee_id' => $validated['employee_id'],
                'employee_name' => $employee->full_name,
                'employee_email' => $employee->email,
                'contract_type' => $validated['contract_type'],
                'position' => $validated['position'],
                'department' => $validated['department'],
                'job_title' => $validated['job_title'],
                'job_description' => $validated['job_description'],
                'gross_salary' => $validated['gross_salary'],
                'net_salary' => $validated['net_salary'],
                'salary_currency' => $validated['salary_currency'] ?? 'FCFA',
                'payment_frequency' => $validated['payment_frequency'],
                'start_date' => $validated['start_date'],
                'end_date' => $validated['end_date'],
                'duration_months' => $validated['duration_months'],
                'work_location' => $validated['work_location'],
                'work_schedule' => $validated['work_schedule'],
                'weekly_hours' => $validated['weekly_hours'],
                'probation_period' => $validated['probation_period'],
                'status' => 'draft',
                'notes' => $validated['notes'],
                'contract_template' => $validated['contract_template'],
                'created_by' => $request->user()->id
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'data' => $contract->load(['employee', 'creator']),
                'message' => 'Contrat créé avec succès'
            ], 201);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création du contrat: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour un contrat
     */
    public function update(Request $request, $id)
    {
        try {
            $contract = Contract::find($id);

            if (!$contract) {
                return response()->json([
                    'success' => false,
                    'message' => 'Contrat non trouvé'
                ], 404);
            }

            if (!$contract->can_edit) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce contrat ne peut pas être modifié'
                ], 403);
            }

            $validated = $request->validate([
                'contract_type' => 'sometimes|in:permanent,fixed_term,temporary,internship,consultant',
                'position' => 'sometimes|string|max:255',
                'department' => 'sometimes|string|max:255',
                'job_title' => 'sometimes|string|max:255',
                'job_description' => 'sometimes|string',
                'gross_salary' => 'sometimes|numeric|min:0',
                'net_salary' => 'sometimes|numeric|min:0',
                'salary_currency' => 'nullable|string|max:10',
                'payment_frequency' => 'sometimes|in:monthly,weekly,daily,hourly',
                'start_date' => 'sometimes|date',
                'end_date' => 'nullable|date|after:start_date',
                'duration_months' => 'nullable|integer|min:1',
                'work_location' => 'sometimes|string|max:255',
                'work_schedule' => 'sometimes|in:full_time,part_time,flexible',
                'weekly_hours' => 'sometimes|integer|min:1|max:168',
                'probation_period' => 'sometimes|in:none,1_month,3_months,6_months',
                'notes' => 'nullable|string',
                'contract_template' => 'nullable|string|max:255'
            ]);

            $contract->update(array_merge($validated, [
                'updated_by' => $request->user()->id
            ]));

            return response()->json([
                'success' => true,
                'data' => $contract->load(['employee', 'creator', 'updater']),
                'message' => 'Contrat mis à jour avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour du contrat: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer un contrat
     */
    public function destroy($id)
    {
        try {
            $contract = Contract::find($id);

            if (!$contract) {
                return response()->json([
                    'success' => false,
                    'message' => 'Contrat non trouvé'
                ], 404);
            }

            if (!$contract->can_edit) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce contrat ne peut pas être supprimé'
                ], 403);
            }

            $contract->delete();

            return response()->json([
                'success' => true,
                'message' => 'Contrat supprimé avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression du contrat: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Soumettre un contrat
     */
    public function submit($id)
    {
        try {
            $contract = Contract::find($id);

            if (!$contract) {
                return response()->json([
                    'success' => false,
                    'message' => 'Contrat non trouvé'
                ], 404);
            }

            if (!$contract->can_submit) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce contrat ne peut pas être soumis'
                ], 403);
            }

            $contract->submit();

            return response()->json([
                'success' => true,
                'message' => 'Contrat soumis avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la soumission du contrat: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Approuver un contrat
     */
    public function approve($id)
    {
        try {
            $contract = Contract::find($id);

            if (!$contract) {
                return response()->json([
                    'success' => false,
                    'message' => 'Contrat non trouvé'
                ], 404);
            }

            if (!$contract->can_approve) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce contrat ne peut pas être approuvé'
                ], 403);
            }

            $contract->approve(request()->user()->id);

            return response()->json([
                'success' => true,
                'message' => 'Contrat approuvé avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'approbation du contrat: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Rejeter un contrat
     */
    public function reject(Request $request, $id)
    {
        try {
            $contract = Contract::find($id);

            if (!$contract) {
                return response()->json([
                    'success' => false,
                    'message' => 'Contrat non trouvé'
                ], 404);
            }

            if (!$contract->can_reject) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce contrat ne peut pas être rejeté'
                ], 403);
            }

            $validated = $request->validate([
                'reason' => 'required|string|max:1000'
            ]);

            $contract->reject(request()->user()->id, $validated['reason']);

            return response()->json([
                'success' => true,
                'message' => 'Contrat rejeté avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du rejet du contrat: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Résilier un contrat
     */
    public function terminate(Request $request, $id)
    {
        try {
            $contract = Contract::find($id);

            if (!$contract) {
                return response()->json([
                    'success' => false,
                    'message' => 'Contrat non trouvé'
                ], 404);
            }

            if (!$contract->can_terminate) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce contrat ne peut pas être résilié'
                ], 403);
            }

            $validated = $request->validate([
                'reason' => 'required|string|max:1000',
                'termination_date' => 'nullable|date'
            ]);

            $contract->terminate(request()->user()->id, $validated['reason'], $validated['termination_date']);

            return response()->json([
                'success' => true,
                'message' => 'Contrat résilié avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la résiliation du contrat: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Annuler un contrat
     */
    public function cancel(Request $request, $id)
    {
        try {
            $contract = Contract::find($id);

            if (!$contract) {
                return response()->json([
                    'success' => false,
                    'message' => 'Contrat non trouvé'
                ], 404);
            }

            if (!$contract->can_cancel) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce contrat ne peut pas être annulé'
                ], 403);
            }

            $validated = $request->validate([
                'reason' => 'nullable|string|max:1000'
            ]);

            $contract->cancel(request()->user()->id, $validated['reason']);

            return response()->json([
                'success' => true,
                'message' => 'Contrat annulé avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'annulation du contrat: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour le salaire
     */
    public function updateSalary(Request $request, $id)
    {
        try {
            $contract = Contract::find($id);

            if (!$contract) {
                return response()->json([
                    'success' => false,
                    'message' => 'Contrat non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'gross_salary' => 'required|numeric|min:0',
                'net_salary' => 'required|numeric|min:0'
            ]);

            $contract->updateSalary($validated['gross_salary'], $validated['net_salary'], $request->user()->id);

            return response()->json([
                'success' => true,
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
     * Prolonger un contrat
     */
    public function extend(Request $request, $id)
    {
        try {
            $contract = Contract::find($id);

            if (!$contract) {
                return response()->json([
                    'success' => false,
                    'message' => 'Contrat non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'end_date' => 'required|date|after:today'
            ]);

            $contract->extendContract($validated['end_date'], $request->user()->id);

            return response()->json([
                'success' => true,
                'message' => 'Contrat prolongé avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la prolongation du contrat: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Statistiques des contrats
     */
    public function statistics(Request $request)
    {
        try {
            $stats = Contract::getContractStats();

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
     * Récupérer les contrats par employé
     */
    public function byEmployee($employeeId)
    {
        try {
            $contracts = Contract::getContractsByEmployee($employeeId);

            return response()->json([
                'success' => true,
                'data' => $contracts,
                'message' => 'Contrats de l\'employé récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des contrats de l\'employé: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les contrats par département
     */
    public function byDepartment($department)
    {
        try {
            $contracts = Contract::getContractsByDepartment($department);

            return response()->json([
                'success' => true,
                'data' => $contracts,
                'message' => 'Contrats du département récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des contrats du département: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les contrats par type
     */
    public function byType($contractType)
    {
        try {
            $contracts = Contract::getContractsByType($contractType);

            return response()->json([
                'success' => true,
                'data' => $contracts,
                'message' => 'Contrats du type récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des contrats du type: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les contrats expirant
     */
    public function expiringSoon()
    {
        try {
            $contracts = Contract::getExpiringContracts();

            return response()->json([
                'success' => true,
                'data' => $contracts,
                'message' => 'Contrats expirant récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des contrats expirant: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les contrats expirés
     */
    public function expired()
    {
        try {
            $contracts = Contract::getExpiredContracts();

            return response()->json([
                'success' => true,
                'data' => $contracts,
                'message' => 'Contrats expirés récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des contrats expirés: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les contrats actifs
     */
    public function active()
    {
        try {
            $contracts = Contract::getActiveContracts();

            return response()->json([
                'success' => true,
                'data' => $contracts,
                'message' => 'Contrats actifs récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des contrats actifs: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les contrats en attente
     */
    public function pending()
    {
        try {
            $contracts = Contract::getPendingContracts();

            return response()->json([
                'success' => true,
                'data' => $contracts,
                'message' => 'Contrats en attente récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des contrats en attente: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les contrats brouillons
     */
    public function drafts()
    {
        try {
            $contracts = Contract::getDraftContracts();

            return response()->json([
                'success' => true,
                'data' => $contracts,
                'message' => 'Contrats brouillons récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des contrats brouillons: ' . $e->getMessage()
            ], 500);
        }
    }
}
