<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\API\UserController;
use App\Http\Controllers\API\ClientController;
use App\Http\Controllers\API\FactureController;
use App\Http\Controllers\API\PaiementController;
use App\Http\Controllers\API\PointageController;
use App\Http\Controllers\API\BordereauController;
use App\Http\Controllers\API\BonDeCommandeController;
use App\Http\Controllers\API\DevisController;
use App\Http\Controllers\API\FournisseurController;
use App\Http\Controllers\API\TaxController;
use App\Http\Controllers\API\ExpenseController;
use App\Http\Controllers\API\SalaryController;
use App\Http\Controllers\API\InterventionController;
use App\Http\Controllers\API\EquipmentController;
use App\Http\Controllers\API\StockController;
use App\Http\Controllers\API\EmployeeController;
use App\Http\Controllers\API\RecruitmentController;
use App\Http\Controllers\API\ContractController;
use App\Http\Controllers\API\ReportingController;
use App\Http\Controllers\API\UserReportingController;
use App\Http\Controllers\API\AttendanceController;
use App\Http\Controllers\API\HRController;
use App\Http\Controllers\API\TechnicalController;
use App\Http\Controllers\API\CongeController;
use App\Http\Controllers\API\EvaluationController;
use App\Http\Controllers\API\NotificationController;
use App\Http\Controllers\API\WebSocketController;


/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

  /* -------------------------------------------------------------- */
    /* -------------------------------------------------------------- */
    /* ROUTES POUR TOUS LES UTILISATEURS */
    /* -------------------------------------------------------------- */

// Routes publiques (sans authentification)
Route::post('/login', [UserController::class, 'login']);

// Route de test temporaire
Route::get('/test-auth', function() {
    return response()->json([
        'message' => 'Route publique accessible',
        'timestamp' => now()
    ]);
});

// Route de debug pour les rôles
Route::middleware(['auth:sanctum'])->get('/debug-role', function() {
    $user = auth()->user();
    return response()->json([
        'user_id' => $user->id,
        'user_role' => $user->role,
        'role_type' => gettype($user->role),
        'role_comparison' => [
            'role == 2' => $user->role == 2,
            'role === 2' => $user->role === 2,
            'role == "2"' => $user->role == "2",
            'role === "2"' => $user->role === "2",
            'in_array(role, [1,2,6])' => in_array($user->role, [1,2,6]),
            'in_array(role, ["1","2","6"])' => in_array($user->role, ["1","2","6"])
        ]
    ]);
});

// Route de test simple pour les headers
/* Route::middleware(['auth:sanctum'])->get('/test-headers', function() {
    return response()->json([
        'message' => 'Test headers OK',
        'timestamp' => now()->toISOString()
    ]);
}); */

// Routes protégées par authentification
Route::middleware(['auth:sanctum'])->group(function () {

  
    
    // Routes d'authentification
    Route::post('/logout', [UserController::class, 'logout']);
    Route::get('/me', [UserController::class, 'me']);
    
    
    
    // Routes pour les notifications (tous les utilisateurs)
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::get('/notifications/{id}', [NotificationController::class, 'show']);
    Route::post('/notifications/{id}/mark-read', [NotificationController::class, 'markAsRead']);
    Route::post('/notifications/mark-all-read', [NotificationController::class, 'markAllAsRead']);
    Route::post('/notifications/{id}/archive', [NotificationController::class, 'archive']);
    Route::post('/notifications/archive-all-read', [NotificationController::class, 'archiveAllRead']);
    Route::get('/notifications/unread', [NotificationController::class, 'unread']);
    Route::get('/notifications/urgent', [NotificationController::class, 'urgent']);
    Route::get('/notifications-statistics', [NotificationController::class, 'statistics']);


    // Routes pour les Reportings (tous les utilisateurs)
    Route::get('/user-reportings-list', [UserReportingController::class, 'index']);
    Route::get('/user-reportings-show/{id}', [UserReportingController::class, 'show']);
    Route::post('/user-reportings-create', [UserReportingController::class, 'store']);
    Route::put('/user-reportings-update/{id}', [UserReportingController::class, 'update']);
    Route::delete('/user-reportings-destroy/{id}', [UserReportingController::class, 'destroy']);
    Route::post('/user-reportings-submit/{id}', [UserReportingController::class, 'submit']);
    Route::post('/user-reportings-validate/{id}', [UserReportingController::class, 'approve']);
    Route::post('/user-reportings-reject/{id}', [UserReportingController::class, 'reject']);
    Route::post('/user-reportings-generate', [UserReportingController::class, 'generate']);
    Route::get('/user-reportings-stats', [UserReportingController::class, 'statistics']);
    
    

     // Routes pour les évaluations (tous les utilisateurs)
     Route::get('/my-evaluations', [EvaluationController::class, 'index']);
     Route::get('/my-evaluations/{id}', [EvaluationController::class, 'show']);
     Route::post('/my-evaluations/{id}/employee-comments', [EvaluationController::class, 'addEmployeeComments']);
     Route::post('/my-evaluations/{id}/sign-employee', [EvaluationController::class, 'signByEmployee']);
    
     /* -------------------------------------------------------------- */
     /* ROUTES POUR LES CLIENTS TOUS LES UTILISATEURS */
     /* -------------------------------------------------------------- */
     Route::get('/clients-list', [ClientController::class, 'index']);
     Route::get('/clients-show/{id}', [ClientController::class, 'show']);

     /* -------------------------------------------------------------- */
     /* ROUTES POUR LES FOURNISSEURS TOUS LES UTILISATEURS */
     /* -------------------------------------------------------------- */
     Route::get('/fournisseurs-list', [FournisseurController::class, 'index']);
     Route::get('/fournisseurs-show/{id}', [FournisseurController::class, 'show']);

     /* -------------------------------------------------------------- */
     /* ROUTES POUR LES POINTAGES TOUS LES UTILISATEURS */
     /* -------------------------------------------------------------- */
     Route::get('/attendances', [AttendanceController::class, 'index']);
     Route::get('/attendances/{id}', [AttendanceController::class, 'show']);
     Route::post('/attendances/check-in', [AttendanceController::class, 'checkIn']);
     Route::post('/attendances/check-out', [AttendanceController::class, 'checkOut']);
     Route::put('/attendances/{id}', [AttendanceController::class, 'update']);
     Route::delete('/attendances/{id}', [AttendanceController::class, 'destroy']);
     Route::get('/attendances/current-status', [AttendanceController::class, 'currentStatus']);
     Route::get('/attendances-statistics', [AttendanceController::class, 'statistics']);
     Route::get('/attendance-settings', [AttendanceController::class, 'settings']);
    
   
    /* -------------------------------------------------------------- */
    /* -------------------------------------------------------------- */
    /* ROUTES POUR LES COMMERCIAUX, ADMIN ET PATRON */
    /* -------------------------------------------------------------- */

    // Routes pour les commerciaux (role: 2) et admin (role: 1)
    Route::middleware(['role:1,2, 6'])->group(function () {

        // Routes pour les clients
        Route::get('/clients-list', [ClientController::class, 'index']);
        Route::get('/clients-show/{id}', [ClientController::class, 'show']);
        Route::post('/clients-create', [ClientController::class, 'store']);
        Route::post('/clients-update/{id}', [ClientController::class, 'update']);
        Route::get('/clients-destroy/{id}', [ClientController::class, 'destroy']);
        Route::get('/clients-statistics', [ClientController::class, 'stats']);
      

        // Routes pour les bons de commande 
        Route::get('/bons-de-commande-list', [BonDeCommandeController::class, 'index']);
        Route::get('/bons-de-commande-show/{id}', [BonDeCommandeController::class, 'show']);
        Route::post('/bons-de-commande-create', [BonDeCommandeController::class, 'store']);
        Route::put('/bons-de-commande-update/{id}', [BonDeCommandeController::class, 'update']);
        Route::post('/bons-de-commande-validate/{id}', [BonDeCommandeController::class, 'validateBon']);
        Route::post('/mark-in-progress-bons-de-commande/{id}', [BonDeCommandeController::class, 'markInProgress']);
        Route::post('/bons-de-commande-mark-delivered/{id}', [BonDeCommandeController::class, 'markDelivered']);
        Route::post('/bons-de-commande-cancel/{id}', [BonDeCommandeController::class, 'cancel']);
        Route::get('/bons-de-commande-reports', [BonDeCommandeController::class, 'reports']);
        
        // Routes pour les devis
        Route::get('/devis-list', [DevisController::class, 'index']);
        Route::get('/devis-show/{id}', [DevisController::class, 'show']);
        Route::post('/devis-create', [DevisController::class, 'store']);
        Route::put('/devis-update/{id}', [DevisController::class, 'update']);
        // Routes de validation des devis réservées aux patrons

         // Routes pour les bordereaux
         Route::get('/bordereaux-list', [BordereauController::class, 'index']);
         Route::post('/bordereaux-create', [BordereauController::class, 'store']);
         Route::get('/bordereaux-show/{id}', [BordereauController::class, 'show']);
         Route::get('/bordereaux-update/{id}', [BordereauController::class, 'update']);
         Route::delete('/bordereaux/{id}', [BordereauController::class, 'destroy']);
         Route::post('/bordereaux-validate/{id}', [BordereauController::class, 'validateBordereau']);
         Route::post('/bordereaux/{id}/reject', [BordereauController::class, 'reject']);
    });


    /* -------------------------------------------------------------- */
    /* -------------------------------------------------------------- */
    /* ROUTES POUR LES PATRON, ADMIN ET PATRON */
    /* -------------------------------------------------------------- */
    
    // Routes pour le patron (role: 6) et admin (role: 1)
    Route::middleware(['role:1,6'])->group(function () {
        // Routes pour la gestion des utilisateurs (Admin uniquement)
        Route::get('/users-list', [UserController::class, 'index']);
        Route::get('/users-show/{id}', [UserController::class, 'show']);
        Route::post('/users-create', [UserController::class, 'store']);
        Route::put('/users-update/{id}', [UserController::class, 'update']);
        Route::delete('/users-destroy/{id}', [UserController::class, 'destroy']);
        Route::post('/users-activate/{id}', [UserController::class, 'activate']);
        Route::post('/users-deactivate/{id}', [UserController::class, 'deactivate']);
        Route::get('/users-statistics', [UserController::class, 'statistics']);
        
        // Routes pour les clients
        Route::post('/client-validate/{id}', [ClientController::class, 'approve']);
        Route::post('/client-reject/{id}', [ClientController::class, 'reject']);

        // Routes pour les devis
        Route::post('/devis-validate/{id}', [DevisController::class, 'accept']);
        Route::post('/devis-reject/{id}', [DevisController::class, 'reject']);
        
         // Routes pour les bordereaux
         Route::post('/bordereaux-validate/{id}', [BordereauController::class, 'accept']);
         Route::post('/bordereaux-reject/{id}', [BordereauController::class, 'reject']);
 
         // Routes pour les bons de commande
         Route::post('/bons-de-commande-validate/{id}', [BonDeCommandeController::class, 'validateBon']);
         Route::post('/bons-de-commande-reject/{id}', [BonDeCommandeController::class, 'reject']);
 

        // Routes pour les paiements
        Route::post('/paiements-validate/{id}', [PaiementController::class, 'validatePaiement']);
        Route::post('/paiements-reject/{id}', [PaiementController::class, 'reject']);

        // Routes pour les impôts et taxes
        Route::post('/taxes-validate/{id}', [TaxController::class, 'validateTax']);
        Route::post('/taxes-reject/{id}', [TaxController::class, 'reject']);

        // Routes pour les dépenses
        Route::post('/expenses-validate/{id}', [ExpenseController::class, 'validateExpense']);
        Route::post('/expenses-reject/{id}', [ExpenseController::class, 'reject']);

        // Routes pour les salaires
        Route::post('/salaries-validate/{id}', [SalaryController::class, 'validateSalary']);
        Route::post('/salaries-reject/{id}', [SalaryController::class, 'reject']);

        // Routes pour les fournisseurs
        Route::post('/fournisseurs-validate/{id}', [FournisseurController::class, 'validateFournisseur']);
        Route::post('/fournisseurs-reject/{id}', [FournisseurController::class, 'reject']);

        // Routes pour les factures
        Route::post('/factures-validate/{id}', [FactureController::class, 'validateFacture']);
        Route::post('/factures-reject/{id}', [FactureController::class, 'reject']);

        // Routes pour les interventions
        Route::post('/interventions-validate/{id}', [InterventionController::class, 'validateIntervention']);
        Route::post('/interventions-reject/{id}', [InterventionController::class, 'reject']);

        // Routes pour les pointages
        Route::post('/pointages-validate/{id}', [PointageController::class, 'validatePointage']);
        Route::post('/pointages-reject/{id}', [PointageController::class, 'reject']);

        // Routes pour les factures
        Route::get('/factures-reports', [FactureController::class, 'reports']);

        // Routes pour les paiements
        Route::get('/paiements-reports', [PaiementController::class, 'reports']);
        Route::get('/bordereaux-reports', [BordereauController::class, 'reports']);
        Route::get('/pointages-reports', [PointageController::class, 'reports']);
        Route::get('/bons-de-commande-reports', [BonDeCommandeController::class, 'reports']);
        Route::get('/fournisseurs-reports', [FournisseurController::class, 'reports']);
        
        // Routes pour les rapports généraux
        Route::get('/dashboard', [ReportingController::class, 'dashboard']);
        Route::get('/reports/financial', [ReportingController::class, 'financial']);
        Route::get('/reports/hr', [ReportingController::class, 'hr']);
        Route::get('/reports/commercial', [ReportingController::class, 'commercial']);
        
        // Routes pour la gestion RH (Patron)
        Route::get('/hr/employees', [HRController::class, 'employees']);
        Route::get('/hr/employees/{id}', [HRController::class, 'employee']);
        Route::get('/hr/presence-report', [HRController::class, 'presenceReport']);
        Route::get('/hr/statistics', [HRController::class, 'hrStatistics']);
        
        // Routes pour la gestion technique (Patron)
        Route::get('/technical/dashboard', [TechnicalController::class, 'dashboard']);
        Route::get('/technical/reports', [TechnicalController::class, 'technicalReports']);
    });
    

    /* -------------------------------------------------------------- */
    /* -------------------------------------------------------------- */
    /* ROUTES POUR LES COMPTABLES, ADMIN ET PATRON */
    /* -------------------------------------------------------------- */
    // Routes pour les comptables (role: 3) et admin (role: 1)
    Route::middleware(['role:1,3, 6'])->group(function () {
        // Routes pour la gestion financière
        Route::get('/factures-list', [FactureController::class, 'index']);
        Route::get('/factures-show/{id}', [FactureController::class, 'show']);
        Route::post('/factures-create', [FactureController::class, 'store']);
        Route::put('/factures-update/{id}', [FactureController::class, 'update']);
        Route::post('/factures-validate/{id}', [FactureController::class, 'validateFacture']);
        Route::post('/factures-reject/{id}', [FactureController::class, 'reject']);
        Route::post('/factures-cancel-rejection/{id}', [FactureController::class, 'cancelRejection']);
        Route::get('/factures-validation-history/{id}', [FactureController::class, 'validationHistory']);
        Route::post('/factures/{id}/mark-paid', [FactureController::class, 'markAsPaid']);
        Route::get('/factures-reports', [FactureController::class, 'reports']);
        
        // Routes pour les paiements
        Route::get('/paiements-list', [PaiementController::class, 'index']);
        Route::get('/paiements-show/{id}', [PaiementController::class, 'show']);
        Route::post('/paiements-create', [PaiementController::class, 'store']);
        Route::post('/paiements-create-with-number', [PaiementController::class, 'createWithNumber']);
        Route::put('/paiements-update/{id}', [PaiementController::class, 'update']);
        Route::post('/paiements-submit/{id}', [PaiementController::class, 'submit']);
        Route::post('/paiements-approve/{id}', [PaiementController::class, 'approve']);
        Route::post('/paiements-mark-paid/{id}', [PaiementController::class, 'markAsPaid']);
        Route::post('/paiements-mark-overdue/{id}', [PaiementController::class, 'markAsOverdue']);
        Route::post('/paiements-validate/{id}', [PaiementController::class, 'validatePaiement']);
        Route::post('/paiements-reject/{id}', [PaiementController::class, 'reject']);
        Route::get('/paiements-reports', [PaiementController::class, 'reports']);
        
        // Routes pour les plannings de paiement
        Route::get('/payment-schedules', [PaymentScheduleController::class, 'index']);
        Route::get('/payment-schedules/{id}', [PaymentScheduleController::class, 'show']);
        Route::post('/payment-schedules', [PaymentScheduleController::class, 'store']);
        Route::put('/payment-schedules/{id}', [PaymentScheduleController::class, 'update']);
        Route::post('/payment-schedules/{id}/pause', [PaymentScheduleController::class, 'pause']);
        Route::post('/payment-schedules/{id}/resume', [PaymentScheduleController::class, 'resume']);
        Route::post('/payment-schedules/{id}/cancel', [PaymentScheduleController::class, 'cancel']);
        Route::post('/payment-schedules/{id}/installments/{installmentId}/mark-paid', [PaymentScheduleController::class, 'markInstallmentPaid']);
        Route::get('/payment-schedules-stats', [PaymentScheduleController::class, 'stats']);
        
        // Routes pour les modèles de paiement
        Route::get('/payment-templates', [PaymentTemplateController::class, 'index']);
        Route::get('/payment-templates/{id}', [PaymentTemplateController::class, 'show']);
        Route::post('/payment-templates', [PaymentTemplateController::class, 'store']);
        Route::put('/payment-templates/{id}', [PaymentTemplateController::class, 'update']);
        Route::delete('/payment-templates/{id}', [PaymentTemplateController::class, 'destroy']);
        Route::post('/payment-templates/{id}/set-default', [PaymentTemplateController::class, 'setAsDefault']);
        Route::post('/payment-templates/{id}/create-payment', [PaymentTemplateController::class, 'createPaymentFromTemplate']);
        Route::post('/payment-templates/{id}/duplicate', [PaymentTemplateController::class, 'duplicate']);
        
        // Routes pour les statistiques de paiement
        Route::get('/payment-stats', [PaymentStatsController::class, 'index']);
        Route::get('/payment-stats/schedules', [PaymentStatsController::class, 'schedules']);
        Route::get('/payment-stats/upcoming', [PaymentStatsController::class, 'upcoming']);
        Route::get('/payment-stats/overdue', [PaymentStatsController::class, 'overdue']);
        Route::get('/payment-stats/performance', [PaymentStatsController::class, 'performance']);
        
        // Routes pour les impôts et taxes
        Route::get('/taxes-list', [TaxController::class, 'index']);
        Route::get('/taxes-show/{id}', [TaxController::class, 'show']);
        Route::post('/taxes-create', [TaxController::class, 'store']);
        Route::put('/taxes-update/{id}', [TaxController::class, 'update']);
        Route::delete('/taxes-destroy/{id}', [TaxController::class, 'destroy']);
        Route::post('/taxes/{id}/calculate', [TaxController::class, 'calculate']);
        Route::post('/taxes/{id}/declare', [TaxController::class, 'declare']);
        Route::post('/taxes/{id}/mark-paid', [TaxController::class, 'markAsPaid']);
        Route::get('/taxes-statistics', [TaxController::class, 'statistics']);
        Route::get('/tax-categories', [TaxController::class, 'categories']);
        
        // Routes pour les dépenses
        Route::get('/expenses-list', [ExpenseController::class, 'index']);
        Route::get('/expenses-show/{id}', [ExpenseController::class, 'show']);
        Route::post('/expenses-create', [ExpenseController::class, 'store']);
        Route::put('/expenses-update/{id}', [ExpenseController::class, 'update']);
        Route::delete('/expenses-destroy/{id}', [ExpenseController::class, 'destroy']);
        Route::post('/expenses-submit/{id}', [ExpenseController::class, 'submit']);
        Route::post('/expenses-validate/{id}', [ExpenseController::class, 'approve']);
        Route::post('/expenses-reject/{id}', [ExpenseController::class, 'reject']);
        Route::get('/expenses-statistics', [ExpenseController::class, 'statistics']);
        Route::get('/expense-categories', [ExpenseController::class, 'categories']);
        
        // Routes pour les salaires
        Route::get('/salaries-list', [SalaryController::class, 'index']);
        Route::get('/salaries-show/{id}', [SalaryController::class, 'show']);
        Route::post('/salaries-create', [SalaryController::class, 'store']);
        Route::put('/salaries-update/{id}', [SalaryController::class, 'update']);
        Route::delete('/salaries-destroy/{id}', [SalaryController::class, 'destroy']);
        Route::post('/salaries-calculate/{id}', [SalaryController::class, 'calculate']);
        Route::post('/salaries-validate/{id}', [SalaryController::class, 'approve']);
        Route::post('/salaries-mark-paid/{id}', [SalaryController::class, 'markAsPaid']);
        Route::get('/salaries-statistics', [SalaryController::class, 'statistics']);
        Route::get('/salary-components', [SalaryController::class, 'components']);
        Route::get('/payroll-settings', [SalaryController::class, 'settings']);
        
        // Routes pour les fournisseurs
        Route::get('/fournisseurs-list', [FournisseurController::class, 'index']);
        Route::get('/fournisseurs/{id}', [FournisseurController::class, 'show']);
        Route::post('/fournisseurs-create', [FournisseurController::class, 'store']);
        Route::put('/fournisseurs-update/{id}', [FournisseurController::class, 'update']);
        Route::post('/fournisseurs-validate/{id}', [FournisseurController::class, 'activate']);
        Route::post('/fournisseurs-deactivate/{id}', [FournisseurController::class, 'deactivate']);
        Route::post('/fournisseurs-reject/{id}', [FournisseurController::class, 'suspend']);
        Route::get('/fournisseurs/{id}/statistics', [FournisseurController::class, 'statistics']);
        Route::get('/fournisseurs-reports', [FournisseurController::class, 'reports']);

        // Routes pour les stocks
        Route::get('/stocks', [StockController::class, 'index']);
        Route::get('/stocks/{id}', [StockController::class, 'show']);
        Route::post('/stocks', [StockController::class, 'store']);
        Route::put('/stocks/{id}', [StockController::class, 'update']);
        Route::delete('/stocks/{id}', [StockController::class, 'destroy']);
        Route::post('/stocks/{id}/add-stock', [StockController::class, 'addStock']);
        Route::post('/stocks/{id}/remove-stock', [StockController::class, 'removeStock']);
        Route::post('/stocks/{id}/adjust-stock', [StockController::class, 'adjustStock']);
        Route::post('/stocks/{id}/transfer-stock', [StockController::class, 'transferStock']);
        Route::post('/stocks/{id}/rejeter', [StockController::class, 'rejeter']);
        Route::get('/stocks-statistics', [StockController::class, 'statistics']);
        Route::get('/stock-categories', [StockController::class, 'categories']);
        Route::get('/stocks-low-stock', [StockController::class, 'lowStock']);
        Route::get('/stocks-out-of-stock', [StockController::class, 'outOfStock']);
        Route::get('/stocks-overstock', [StockController::class, 'overstock']);
        Route::get('/stocks-needs-reorder', [StockController::class, 'needsReorder']);
    });


    /* -------------------------------------------------------------- */
    /* -------------------------------------------------------------- */
    /* ROUTES POUR LES TECHNICIEN, ADMIN ET PATRON */
    /* -------------------------------------------------------------- */
    
    // Routes pour les techniciens (role: 5) et admin (role: 1)
    Route::middleware(['role:1,5, 6'])->group(function () {
        
        // Routes pour les interventions
        Route::get('/interventions', [InterventionController::class, 'index']);
        Route::get('/interventions/{id}', [InterventionController::class, 'show']);
        Route::post('/interventions', [InterventionController::class, 'store']);
        Route::put('/interventions/{id}', [InterventionController::class, 'update']);
        Route::delete('/interventions/{id}', [InterventionController::class, 'destroy']);
        Route::post('/interventions/{id}/approve', [InterventionController::class, 'approve']);
        Route::post('/interventions/{id}/reject', [InterventionController::class, 'reject']);
        Route::post('/interventions/{id}/start', [InterventionController::class, 'start']);
        Route::post('/interventions/{id}/complete', [InterventionController::class, 'complete']);
        Route::get('/interventions-statistics', [InterventionController::class, 'statistics']);
        Route::get('/interventions-overdue', [InterventionController::class, 'overdue']);
        Route::get('/interventions-due-soon', [InterventionController::class, 'dueSoon']);
        Route::get('/intervention-types', [InterventionController::class, 'types']);
        Route::get('/equipment', [InterventionController::class, 'equipment']);
        
        // Routes pour les équipements
        Route::get('/equipment', [EquipmentController::class, 'index']);
        Route::get('/equipment/{id}', [EquipmentController::class, 'show']);
        Route::post('/equipment', [EquipmentController::class, 'store']);
        Route::put('/equipment/{id}', [EquipmentController::class, 'update']);
        Route::delete('/equipment/{id}', [EquipmentController::class, 'destroy']);
        Route::post('/equipment/{id}/assign', [EquipmentController::class, 'assign']);
        Route::post('/equipment/{id}/return', [EquipmentController::class, 'return']);
        Route::post('/equipment/{id}/schedule-maintenance', [EquipmentController::class, 'scheduleMaintenance']);
        Route::get('/equipment-statistics', [EquipmentController::class, 'statistics']);
        Route::get('/equipment-categories', [EquipmentController::class, 'categories']);
        Route::get('/equipment-needs-maintenance', [EquipmentController::class, 'needsMaintenance']);
        Route::get('/equipment-warranty-expired', [EquipmentController::class, 'warrantyExpired']);
        Route::get('/equipment-warranty-expiring-soon', [EquipmentController::class, 'warrantyExpiringSoon']);
        
        
        
       
    });


    /* -------------------------------------------------------------- */
    /* -------------------------------------------------------------- */
    /* ROUTES POUR LES RH, ADMIN ET PATRON */
    /* -------------------------------------------------------------- */

    Route::middleware(['role:1,4, 6'])->group(function () {

     // Routes pour les employés
     Route::get('/employees', [EmployeeController::class, 'index']);
     Route::get('/employees/{id}', [EmployeeController::class, 'show']);
     Route::post('/employees', [EmployeeController::class, 'store']);
     Route::put('/employees/{id}', [EmployeeController::class, 'update']);
     Route::delete('/employees/{id}', [EmployeeController::class, 'destroy']);
     Route::post('/employees/{id}/activate', [EmployeeController::class, 'activate']);
     Route::post('/employees/{id}/deactivate', [EmployeeController::class, 'deactivate']);
     Route::post('/employees/{id}/terminate', [EmployeeController::class, 'terminate']);
     Route::post('/employees/{id}/put-on-leave', [EmployeeController::class, 'putOnLeave']);
     Route::post('/employees/{id}/update-salary', [EmployeeController::class, 'updateSalary']);
     Route::post('/employees/{id}/update-contract', [EmployeeController::class, 'updateContract']);
     Route::get('/employees-statistics', [EmployeeController::class, 'statistics']);
     Route::get('/employees-by-department/{department}', [EmployeeController::class, 'byDepartment']);
     Route::get('/employees-by-position/{position}', [EmployeeController::class, 'byPosition']);
     Route::get('/employees-contract-expiring', [EmployeeController::class, 'contractExpiring']);
     Route::get('/employees-contract-expired', [EmployeeController::class, 'contractExpired']);
     
     // Routes pour les recrutements
     Route::get('/recruitment-requests', [RecruitmentController::class, 'index']);
     Route::get('/recruitment-requests/{id}', [RecruitmentController::class, 'show']);
     Route::post('/recruitment-requests', [RecruitmentController::class, 'store']);
     Route::put('/recruitment-requests/{id}', [RecruitmentController::class, 'update']);
     Route::delete('/recruitment-requests/{id}', [RecruitmentController::class, 'destroy']);
     Route::post('/recruitment-requests/{id}/publish', [RecruitmentController::class, 'publish']);
     Route::post('/recruitment-requests/{id}/close', [RecruitmentController::class, 'close']);
     Route::post('/recruitment-requests/{id}/cancel', [RecruitmentController::class, 'cancel']);
     Route::post('/recruitment-requests/{id}/approve', [RecruitmentController::class, 'approve']);
     Route::get('/recruitment-statistics', [RecruitmentController::class, 'statistics']);
     Route::get('/recruitment-requests-by-department/{department}', [RecruitmentController::class, 'byDepartment']);
     Route::get('/recruitment-requests-by-position/{position}', [RecruitmentController::class, 'byPosition']);
     Route::get('/recruitment-requests-expiring', [RecruitmentController::class, 'expiring']);
     Route::get('/recruitment-requests-expired', [RecruitmentController::class, 'expired']);
     Route::get('/recruitment-requests-published', [RecruitmentController::class, 'published']);
     Route::get('/recruitment-requests-drafts', [RecruitmentController::class, 'drafts']);
     
     // Routes pour les contrats
     Route::get('/contracts', [ContractController::class, 'index']);
     Route::get('/contracts/{id}', [ContractController::class, 'show']);
     Route::post('/contracts', [ContractController::class, 'store']);
     Route::put('/contracts/{id}', [ContractController::class, 'update']);
     Route::delete('/contracts/{id}', [ContractController::class, 'destroy']);
     Route::post('/contracts/{id}/submit', [ContractController::class, 'submit']);
     Route::post('/contracts/{id}/approve', [ContractController::class, 'approve']);
     Route::post('/contracts/{id}/reject', [ContractController::class, 'reject']);
     Route::post('/contracts/{id}/terminate', [ContractController::class, 'terminate']);
     Route::post('/contracts/{id}/cancel', [ContractController::class, 'cancel']);
     Route::post('/contracts/{id}/update-salary', [ContractController::class, 'updateSalary']);
     Route::post('/contracts/{id}/extend', [ContractController::class, 'extend']);
     Route::get('/contract-statistics', [ContractController::class, 'statistics']);
     Route::get('/contracts-by-employee/{employeeId}', [ContractController::class, 'byEmployee']);
     Route::get('/contracts-by-department/{department}', [ContractController::class, 'byDepartment']);
     Route::get('/contracts-by-type/{contractType}', [ContractController::class, 'byType']);
     Route::get('/contracts-expiring-soon', [ContractController::class, 'expiringSoon']);
     Route::get('/contracts-expired', [ContractController::class, 'expired']);
     Route::get('/contracts-active', [ContractController::class, 'active']);
     Route::get('/contracts-pending', [ContractController::class, 'pending']);
     Route::get('/contracts-drafts', [ContractController::class, 'drafts']);    

    // Routes pour les taxes
    Route::prefix('taxes')->group(function () {
        Route::get('/', [App\Http\Controllers\API\TaxController::class, 'index']);
        Route::get('/statistics', [App\Http\Controllers\API\TaxController::class, 'statistics']);
        Route::post('/{id}/validate', [App\Http\Controllers\API\TaxController::class, 'validateTax']);
        Route::post('/{id}/reject', [App\Http\Controllers\API\TaxController::class, 'reject']);
    });

});

});
