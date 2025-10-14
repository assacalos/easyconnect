<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Employee;
use App\Models\EmployeeDocument;
use App\Models\EmployeeLeave;
use App\Models\EmployeePerformance;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class EmployeeController extends Controller
{
    /**
     * Afficher la liste des employés
     */
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            $query = Employee::with(['creator', 'updater', 'documents', 'leaves', 'performances']);

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filtrage par département
            if ($request->has('department')) {
                $query->where('department', $request->department);
            }

            // Filtrage par poste
            if ($request->has('position')) {
                $query->where('position', $request->position);
            }

            // Filtrage par genre
            if ($request->has('gender')) {
                $query->where('gender', $request->gender);
            }

            // Filtrage par type de contrat
            if ($request->has('contract_type')) {
                $query->where('contract_type', $request->contract_type);
            }

            // Filtrage par nom
            if ($request->has('name')) {
                $query->where(function ($q) use ($request) {
                    $q->where('first_name', 'like', '%' . $request->name . '%')
                      ->orWhere('last_name', 'like', '%' . $request->name . '%');
                });
            }

            // Filtrage par email
            if ($request->has('email')) {
                $query->where('email', 'like', '%' . $request->email . '%');
            }

            // Filtrage par contrat expirant
            if ($request->has('contract_expiring')) {
                if ($request->contract_expiring === 'true') {
                    $query->contractExpiring();
                }
            }

            // Filtrage par contrat expiré
            if ($request->has('contract_expired')) {
                if ($request->contract_expired === 'true') {
                    $query->contractExpired();
                }
            }

            // Filtrage par date d'embauche
            if ($request->has('hire_date_from')) {
                $query->where('hire_date', '>=', $request->hire_date_from);
            }

            if ($request->has('hire_date_to')) {
                $query->where('hire_date', '<=', $request->hire_date_to);
            }

            // Pagination
            $perPage = $request->get('per_page', 15);
            $employees = $query->orderBy('first_name')->paginate($perPage);

            // Transformer les données
            $employees->getCollection()->transform(function ($employee) {
                return [
                    'id' => $employee->id,
                    'first_name' => $employee->first_name,
                    'last_name' => $employee->last_name,
                    'full_name' => $employee->full_name,
                    'initials' => $employee->initials,
                    'email' => $employee->email,
                    'phone' => $employee->phone,
                    'address' => $employee->address,
                    'birth_date' => $employee->birth_date?->format('Y-m-d'),
                    'age' => $employee->age,
                    'gender' => $employee->gender,
                    'gender_libelle' => $employee->gender_libelle,
                    'marital_status' => $employee->marital_status,
                    'marital_status_libelle' => $employee->marital_status_libelle,
                    'nationality' => $employee->nationality,
                    'id_number' => $employee->id_number,
                    'social_security_number' => $employee->social_security_number,
                    'position' => $employee->position,
                    'department' => $employee->department,
                    'manager' => $employee->manager,
                    'hire_date' => $employee->hire_date?->format('Y-m-d'),
                    'contract_start_date' => $employee->contract_start_date?->format('Y-m-d'),
                    'contract_end_date' => $employee->contract_end_date?->format('Y-m-d'),
                    'contract_type' => $employee->contract_type,
                    'contract_type_libelle' => $employee->contract_type_libelle,
                    'salary' => $employee->salary,
                    'currency' => $employee->currency,
                    'formatted_salary' => $employee->formatted_salary,
                    'work_schedule' => $employee->work_schedule,
                    'status' => $employee->status,
                    'status_libelle' => $employee->status_libelle,
                    'profile_picture' => $employee->profile_picture,
                    'notes' => $employee->notes,
                    'created_by' => $employee->created_by,
                    'creator_name' => $employee->creator_name,
                    'updated_by' => $employee->updated_by,
                    'updater_name' => $employee->updater_name,
                    'is_contract_expiring' => $employee->is_contract_expiring,
                    'is_contract_expired' => $employee->is_contract_expired,
                    'is_active' => $employee->is_active,
                    'is_inactive' => $employee->is_inactive,
                    'is_terminated' => $employee->is_terminated,
                    'is_on_leave' => $employee->is_on_leave,
                    'documents' => $employee->documents->map(function ($document) {
                        return [
                            'id' => $document->id,
                            'name' => $document->name,
                            'type' => $document->type,
                            'type_libelle' => $document->type_libelle,
                            'description' => $document->description,
                            'file_path' => $document->file_path,
                            'file_size' => $document->file_size,
                            'formatted_file_size' => $document->formatted_file_size,
                            'expiry_date' => $document->expiry_date?->format('Y-m-d'),
                            'is_required' => $document->is_required,
                            'is_expiring' => $document->is_expiring,
                            'is_expired' => $document->is_expired,
                            'creator_name' => $document->creator_name,
                            'created_at' => $document->created_at->format('Y-m-d H:i:s')
                        ];
                    }),
                    'leaves' => $employee->leaves->map(function ($leave) {
                        return [
                            'id' => $leave->id,
                            'type' => $leave->type,
                            'type_libelle' => $leave->type_libelle,
                            'start_date' => $leave->start_date?->format('Y-m-d'),
                            'end_date' => $leave->end_date?->format('Y-m-d'),
                            'total_days' => $leave->total_days,
                            'duration' => $leave->duration,
                            'reason' => $leave->reason,
                            'status' => $leave->status,
                            'status_libelle' => $leave->status_libelle,
                            'approved_by' => $leave->approved_by,
                            'approver_name' => $leave->approver_name,
                            'approved_at' => $leave->approved_at?->format('Y-m-d H:i:s'),
                            'rejection_reason' => $leave->rejection_reason,
                            'is_pending' => $leave->is_pending,
                            'is_approved' => $leave->is_approved,
                            'is_rejected' => $leave->is_rejected,
                            'is_current' => $leave->is_current,
                            'is_upcoming' => $leave->is_upcoming,
                            'is_past' => $leave->is_past,
                            'creator_name' => $leave->creator_name,
                            'created_at' => $leave->created_at->format('Y-m-d H:i:s')
                        ];
                    }),
                    'performances' => $employee->performances->map(function ($performance) {
                        return [
                            'id' => $performance->id,
                            'period' => $performance->period,
                            'rating' => $performance->rating,
                            'formatted_rating' => $performance->formatted_rating,
                            'rating_text' => $performance->rating_text,
                            'rating_color' => $performance->rating_color,
                            'comments' => $performance->comments,
                            'goals' => $performance->goals,
                            'achievements' => $performance->achievements,
                            'areas_for_improvement' => $performance->areas_for_improvement,
                            'status' => $performance->status,
                            'status_libelle' => $performance->status_libelle,
                            'reviewed_by' => $performance->reviewed_by,
                            'reviewer_name' => $performance->reviewer_name,
                            'reviewed_at' => $performance->reviewed_at?->format('Y-m-d H:i:s'),
                            'is_draft' => $performance->is_draft,
                            'is_submitted' => $performance->is_submitted,
                            'is_reviewed' => $performance->is_reviewed,
                            'is_approved' => $performance->is_approved,
                            'is_excellent' => $performance->is_excellent,
                            'is_good' => $performance->is_good,
                            'is_average' => $performance->is_average,
                            'is_poor' => $performance->is_poor,
                            'needs_improvement' => $performance->needs_improvement,
                            'creator_name' => $performance->creator_name,
                            'created_at' => $performance->created_at->format('Y-m-d H:i:s')
                        ];
                    }),
                    'created_at' => $employee->created_at->format('Y-m-d H:i:s'),
                    'updated_at' => $employee->updated_at->format('Y-m-d H:i:s')
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $employees,
                'message' => 'Liste des employés récupérée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des employés: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Afficher un employé spécifique
     */
    public function show($id)
    {
        try {
            $employee = Employee::with(['creator', 'updater', 'documents', 'leaves', 'performances'])->find($id);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employé non trouvé'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => $employee,
                'message' => 'Employé récupéré avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération de l\'employé: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Créer un nouvel employé
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'first_name' => 'required|string|max:255',
                'last_name' => 'required|string|max:255',
                'email' => 'required|email|unique:employees,email',
                'phone' => 'nullable|string|max:20',
                'address' => 'nullable|string',
                'birth_date' => 'nullable|date',
                'gender' => 'nullable|in:male,female,other',
                'marital_status' => 'nullable|in:single,married,divorced,widowed',
                'nationality' => 'nullable|string|max:100',
                'id_number' => 'nullable|string|max:50',
                'social_security_number' => 'nullable|string|max:50',
                'position' => 'nullable|string|max:255',
                'department' => 'nullable|string|max:255',
                'manager' => 'nullable|string|max:255',
                'hire_date' => 'nullable|date',
                'contract_start_date' => 'nullable|date',
                'contract_end_date' => 'nullable|date|after:contract_start_date',
                'contract_type' => 'nullable|in:permanent,temporary,intern,consultant',
                'salary' => 'nullable|numeric|min:0',
                'currency' => 'nullable|string|max:10',
                'work_schedule' => 'nullable|string|max:255',
                'status' => 'required|in:active,inactive,terminated,on_leave',
                'profile_picture' => 'nullable|string|max:255',
                'notes' => 'nullable|string'
            ]);

            DB::beginTransaction();

            $employee = Employee::create([
                'first_name' => $validated['first_name'],
                'last_name' => $validated['last_name'],
                'email' => $validated['email'],
                'phone' => $validated['phone'] ?? null,
                'address' => $validated['address'] ?? null,
                'birth_date' => $validated['birth_date'] ?? null,
                'gender' => $validated['gender'] ?? null,
                'marital_status' => $validated['marital_status'] ?? null,
                'nationality' => $validated['nationality'] ?? null,
                'id_number' => $validated['id_number'] ?? null,
                'social_security_number' => $validated['social_security_number'] ?? null,
                'position' => $validated['position'] ?? null,
                'department' => $validated['department'] ?? null,
                'manager' => $validated['manager'] ?? null,
                'hire_date' => $validated['hire_date'] ?? null,
                'contract_start_date' => $validated['contract_start_date'] ?? null,
                'contract_end_date' => $validated['contract_end_date'] ?? null,
                'contract_type' => $validated['contract_type'] ?? null,
                'salary' => $validated['salary'] ?? null,
                'currency' => $validated['currency'] ?? 'FCFA',
                'work_schedule' => $validated['work_schedule'] ?? null,
                'status' => $validated['status'],
                'profile_picture' => $validated['profile_picture'] ?? null,
                'notes' => $validated['notes'] ?? null,
                'created_by' => $request->user()->id
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'data' => $employee->load(['creator']),
                'message' => 'Employé créé avec succès'
            ], 201);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création de l\'employé: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour un employé
     */
    public function update(Request $request, $id)
    {
        try {
            $employee = Employee::find($id);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employé non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'first_name' => 'sometimes|string|max:255',
                'last_name' => 'sometimes|string|max:255',
                'email' => 'sometimes|email|unique:employees,email,' . $id,
                'phone' => 'nullable|string|max:20',
                'address' => 'nullable|string',
                'birth_date' => 'nullable|date',
                'gender' => 'nullable|in:male,female,other',
                'marital_status' => 'nullable|in:single,married,divorced,widowed',
                'nationality' => 'nullable|string|max:100',
                'id_number' => 'nullable|string|max:50',
                'social_security_number' => 'nullable|string|max:50',
                'position' => 'nullable|string|max:255',
                'department' => 'nullable|string|max:255',
                'manager' => 'nullable|string|max:255',
                'hire_date' => 'nullable|date',
                'contract_start_date' => 'nullable|date',
                'contract_end_date' => 'nullable|date|after:contract_start_date',
                'contract_type' => 'nullable|in:permanent,temporary,intern,consultant',
                'salary' => 'nullable|numeric|min:0',
                'currency' => 'nullable|string|max:10',
                'work_schedule' => 'nullable|string|max:255',
                'status' => 'sometimes|in:active,inactive,terminated,on_leave',
                'profile_picture' => 'nullable|string|max:255',
                'notes' => 'nullable|string'
            ]);

            $employee->update(array_merge($validated, [
                'updated_by' => $request->user()->id
            ]));

            return response()->json([
                'success' => true,
                'data' => $employee->load(['creator', 'updater']),
                'message' => 'Employé mis à jour avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour de l\'employé: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer un employé
     */
    public function destroy($id)
    {
        try {
            $employee = Employee::find($id);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employé non trouvé'
                ], 404);
            }

            $employee->delete();

            return response()->json([
                'success' => true,
                'message' => 'Employé supprimé avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression de l\'employé: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Activer un employé
     */
    public function activate($id)
    {
        try {
            $employee = Employee::find($id);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employé non trouvé'
                ], 404);
            }

            $employee->activate();

            return response()->json([
                'success' => true,
                'message' => 'Employé activé avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'activation de l\'employé: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Désactiver un employé
     */
    public function deactivate($id)
    {
        try {
            $employee = Employee::find($id);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employé non trouvé'
                ], 404);
            }

            $employee->deactivate();

            return response()->json([
                'success' => true,
                'message' => 'Employé désactivé avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la désactivation de l\'employé: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Terminer un employé
     */
    public function terminate(Request $request, $id)
    {
        try {
            $employee = Employee::find($id);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employé non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'reason' => 'nullable|string|max:1000'
            ]);

            $employee->terminate($validated['reason']);

            return response()->json([
                'success' => true,
                'message' => 'Employé terminé avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la termination de l\'employé: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre en congé un employé
     */
    public function putOnLeave($id)
    {
        try {
            $employee = Employee::find($id);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employé non trouvé'
                ], 404);
            }

            $employee->putOnLeave();

            return response()->json([
                'success' => true,
                'message' => 'Employé mis en congé avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise en congé de l\'employé: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour le salaire
     */
    public function updateSalary(Request $request, $id)
    {
        try {
            $employee = Employee::find($id);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employé non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'salary' => 'required|numeric|min:0',
                'currency' => 'nullable|string|max:10'
            ]);

            $employee->updateSalary($validated['salary'], $request->user()->id);

            if (isset($validated['currency'])) {
                $employee->update(['currency' => $validated['currency']]);
            }

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
     * Mettre à jour le contrat
     */
    public function updateContract(Request $request, $id)
    {
        try {
            $employee = Employee::find($id);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employé non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'contract_start_date' => 'required|date',
                'contract_end_date' => 'required|date|after:contract_start_date',
                'contract_type' => 'required|in:permanent,temporary,intern,consultant'
            ]);

            $employee->updateContract(
                $validated['contract_start_date'],
                $validated['contract_end_date'],
                $validated['contract_type'],
                $request->user()->id
            );

            return response()->json([
                'success' => true,
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
     * Statistiques des employés
     */
    public function statistics(Request $request)
    {
        try {
            $stats = Employee::getEmployeeStats();

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
     * Récupérer les employés par département
     */
    public function byDepartment($department)
    {
        try {
            $employees = Employee::getEmployeesByDepartment($department);

            return response()->json([
                'success' => true,
                'data' => $employees,
                'message' => 'Employés du département récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des employés du département: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les employés par poste
     */
    public function byPosition($position)
    {
        try {
            $employees = Employee::getEmployeesByPosition($position);

            return response()->json([
                'success' => true,
                'data' => $employees,
                'message' => 'Employés du poste récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des employés du poste: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les employés avec contrat expirant
     */
    public function contractExpiring()
    {
        try {
            $employees = Employee::getContractExpiringEmployees();

            return response()->json([
                'success' => true,
                'data' => $employees,
                'message' => 'Employés avec contrat expirant récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des employés avec contrat expirant: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les employés avec contrat expiré
     */
    public function contractExpired()
    {
        try {
            $employees = Employee::getContractExpiredEmployees();

            return response()->json([
                'success' => true,
                'data' => $employees,
                'message' => 'Employés avec contrat expiré récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des employés avec contrat expiré: ' . $e->getMessage()
            ], 500);
        }
    }
}
