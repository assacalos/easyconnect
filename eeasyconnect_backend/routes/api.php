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
use App\Http\Controllers\API\ReportingController;
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

// Routes publiques (sans authentification)
Route::post('/login', [UserController::class, 'login']);

// Routes protégées par authentification
Route::middleware(['auth:sanctum'])->group(function () {
    
    // Routes d'authentification
    Route::post('/logout', [UserController::class, 'logout']);
    Route::get('/me', [UserController::class, 'me']);
    
    // Routes pour tous les utilisateurs authentifiés
    Route::get('/list-clients', [ClientController::class, 'getAllClients']);
    Route::get('/clients-show/{id}', [ClientController::class, 'read']);
    Route::get('/clients', [ClientController::class, 'index']);
    
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
    
    // Routes pour les congés (tous les utilisateurs)
    Route::get('/my-conges', [CongeController::class, 'index']);
    Route::post('/my-conges', [CongeController::class, 'store']);
    Route::get('/my-conges/{id}', [CongeController::class, 'show']);
    Route::put('/my-conges/{id}', [CongeController::class, 'update']);
    Route::delete('/my-conges/{id}', [CongeController::class, 'destroy']);
    
    // Routes pour les évaluations (tous les utilisateurs)
    Route::get('/my-evaluations', [EvaluationController::class, 'index']);
    Route::get('/my-evaluations/{id}', [EvaluationController::class, 'show']);
    Route::post('/my-evaluations/{id}/employee-comments', [EvaluationController::class, 'addEmployeeComments']);
    Route::post('/my-evaluations/{id}/sign-employee', [EvaluationController::class, 'signByEmployee']);
    
    // Routes pour les commerciaux (role: 2) et admin (role: 1)
    Route::middleware(['role:1,2'])->group(function () {
        Route::post('/clients', [ClientController::class, 'creat']);
        Route::post('/clients-update/{id}', [ClientController::class, 'update']);
        Route::get('/clients-destroy/{id}', [ClientController::class, 'destroy']);
        
        // Routes pour les bons de commande
        Route::get('/bons-de-commande', [BonDeCommandeController::class, 'index']);
        Route::get('/bons-de-commande/{id}', [BonDeCommandeController::class, 'show']);
        Route::post('/bons-de-commande', [BonDeCommandeController::class, 'store']);
        Route::put('/bons-de-commande/{id}', [BonDeCommandeController::class, 'update']);
        Route::get('/bons-de-commande-reports', [BonDeCommandeController::class, 'reports']);
        
        // Routes pour les devis
        Route::get('/list-devis', [DevisController::class, 'index']);
        Route::get('/devis/{id}', [DevisController::class, 'show']);
        Route::post('/create-devis', [DevisController::class, 'store']);
        Route::put('/devis/{id}', [DevisController::class, 'update']);
        Route::post('/devis/{id}/validate', [DevisController::class, 'validate']);
        Route::post('/devis/{id}/reject', [DevisController::class, 'reject']);

         // Routes pour les bordereaux
         Route::get('/bordereaux', [BordereauController::class, 'index']);
         Route::post('/bordereaux', [BordereauController::class, 'store']);
         Route::get('/bordereaux/{id}', [BordereauController::class, 'show']);
         Route::put('/bordereaux/{id}', [BordereauController::class, 'update']);
         Route::delete('/bordereaux/{id}', [BordereauController::class, 'destroy']);
         Route::post('/bordereaux/{id}/validate', [BordereauController::class, 'validateBordereau']);
         
         // Routes pour les bons de commande
         Route::post('/bons-de-commande/{id}/validate', [BonDeCommandeController::class, 'validate']);
         Route::post('/bons-de-commande/{id}/mark-in-progress', [BonDeCommandeController::class, 'markInProgress']);
         Route::post('/bons-de-commande/{id}/mark-delivered', [BonDeCommandeController::class, 'markDelivered']);
         Route::post('/bons-de-commande/{id}/cancel', [BonDeCommandeController::class, 'cancel']);
         
         // Routes supplémentaires pour les bons de commande
         Route::get('/bons-de-commande-dashboard', [BonDeCommandeController::class, 'dashboard']);
         Route::get('/bons-de-commande-statistics', [BonDeCommandeController::class, 'statistics']);
         Route::get('/bons-de-commande-search', [BonDeCommandeController::class, 'search']);
         Route::post('/bons-de-commande/{id}/duplicate', [BonDeCommandeController::class, 'duplicate']);
         Route::get('/bons-de-commande-export', [BonDeCommandeController::class, 'export']);
         
    });
    
    // Routes pour le patron (role: 6) et admin (role: 1)
    Route::middleware(['role:1,6'])->group(function () {
        Route::post('/clients/{id}/approve', [ClientController::class, 'approve']);
        Route::post('/clients/{id}/reject', [ClientController::class, 'reject']);
        Route::get('/factures-reports', [FactureController::class, 'reports']);
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
    
    // Routes pour les comptables (role: 3) et admin (role: 1)
    Route::middleware(['role:1,3'])->group(function () {
        // Routes pour la gestion financière
        Route::get('/factures', [FactureController::class, 'index']);
        Route::get('/factures/{id}', [FactureController::class, 'show']);
        Route::post('/factures', [FactureController::class, 'store']);
        Route::put('/factures/{id}', [FactureController::class, 'update']);
        Route::post('/factures/{id}/mark-paid', [FactureController::class, 'markAsPaid']);
        Route::get('/factures-reports', [FactureController::class, 'reports']);
        
        // Routes pour les paiements
        Route::get('/paiements', [PaiementController::class, 'index']);
        Route::get('/paiements/{id}', [PaiementController::class, 'show']);
        Route::post('/paiements', [PaiementController::class, 'store']);
        Route::put('/paiements/{id}', [PaiementController::class, 'update']);
        Route::post('/paiements/{id}/validate', [PaiementController::class, 'validate']);
        Route::post('/paiements/{id}/reject', [PaiementController::class, 'reject']);
        Route::get('/paiements-reports', [PaiementController::class, 'reports']);
        
       
        // Routes pour les fournisseurs
        Route::get('/fournisseurs', [FournisseurController::class, 'index']);
        Route::get('/fournisseurs/{id}', [FournisseurController::class, 'show']);
        Route::post('/fournisseurs', [FournisseurController::class, 'store']);
        Route::put('/fournisseurs/{id}', [FournisseurController::class, 'update']);
        Route::post('/fournisseurs/{id}/activate', [FournisseurController::class, 'activate']);
        Route::post('/fournisseurs/{id}/deactivate', [FournisseurController::class, 'deactivate']);
        Route::post('/fournisseurs/{id}/suspend', [FournisseurController::class, 'suspend']);
        Route::get('/fournisseurs/{id}/statistics', [FournisseurController::class, 'statistics']);
        Route::get('/fournisseurs-reports', [FournisseurController::class, 'reports']);
    });
    
    // Routes pour les RH (role: 4) et admin (role: 1)
    Route::middleware(['role:1,4'])->group(function () {
        // Routes pour la gestion des ressources humaines
        Route::get('/pointages', [PointageController::class, 'index']);
        Route::get('/pointages/{id}', [PointageController::class, 'show']);
        Route::post('/pointages', [PointageController::class, 'store']);
        Route::put('/pointages/{id}', [PointageController::class, 'update']);
        Route::post('/pointages/{id}/validate', [PointageController::class, 'validate']);
        Route::post('/pointages/{id}/reject', [PointageController::class, 'reject']);
        Route::get('/pointages-reports', [PointageController::class, 'reports']);
        
        // Routes pour la gestion des employés
        Route::get('/hr/employees', [HRController::class, 'employees']);
        Route::get('/hr/employees/{id}', [HRController::class, 'employee']);
        Route::post('/hr/employees', [HRController::class, 'createEmployee']);
        Route::put('/hr/employees/{id}', [HRController::class, 'updateEmployee']);
        Route::post('/hr/employees/{id}/deactivate', [HRController::class, 'deactivateEmployee']);
        
        // Routes pour les rapports RH
        Route::get('/hr/presence-report', [HRController::class, 'presenceReport']);
        Route::get('/hr/statistics', [HRController::class, 'hrStatistics']);
        
        // Routes pour la gestion des congés
        Route::get('/hr/leave-management', [HRController::class, 'leaveManagement']);
        Route::get('/hr/employee-evaluations', [HRController::class, 'employeeEvaluations']);
        
        // Routes pour les congés
        Route::get('/conges', [CongeController::class, 'index']);
        Route::get('/conges/{id}', [CongeController::class, 'show']);
        Route::post('/conges', [CongeController::class, 'store']);
        Route::put('/conges/{id}', [CongeController::class, 'update']);
        Route::post('/conges/{id}/approve', [CongeController::class, 'approve']);
        Route::post('/conges/{id}/reject', [CongeController::class, 'reject']);
        Route::get('/conges-statistics', [CongeController::class, 'statistics']);
        
        // Routes pour les évaluations
        Route::get('/evaluations', [EvaluationController::class, 'index']);
        Route::get('/evaluations/{id}', [EvaluationController::class, 'show']);
        Route::post('/evaluations', [EvaluationController::class, 'store']);
        Route::put('/evaluations/{id}', [EvaluationController::class, 'update']);
        Route::post('/evaluations/{id}/employee-comments', [EvaluationController::class, 'addEmployeeComments']);
        Route::post('/evaluations/{id}/sign-employee', [EvaluationController::class, 'signByEmployee']);
        Route::post('/evaluations/{id}/sign-evaluator', [EvaluationController::class, 'signByEvaluator']);
        Route::post('/evaluations/{id}/finalize', [EvaluationController::class, 'finalize']);
        Route::get('/evaluations-statistics', [EvaluationController::class, 'statistics']);
    });
    
    // Routes pour les techniciens (role: 5) et admin (role: 1)
    Route::middleware(['role:1,5'])->group(function () {
        // Routes pour la gestion technique
        Route::post('/pointages/arrivee', [PointageController::class, 'pointerArrivee']);
        Route::post('/pointages/depart', [PointageController::class, 'pointerDepart']);
        Route::get('/pointages/today', [PointageController::class, 'today']);
        
        // Routes pour le tableau de bord technique
        Route::get('/technical/dashboard', [TechnicalController::class, 'dashboard']);
        Route::get('/technical/pointage-history', [TechnicalController::class, 'pointageHistory']);
        Route::get('/technical/personal-statistics', [TechnicalController::class, 'personalStatistics']);
        
        // Routes pour le pointage rapide
        Route::post('/technical/quick-pointage', [TechnicalController::class, 'quickPointage']);
        Route::get('/technical/pause-management', [TechnicalController::class, 'pauseManagement']);
        
        // Routes pour les rapports techniques
        Route::get('/technical/reports', [TechnicalController::class, 'technicalReports']);
    });
    
    // Routes admin uniquement
    Route::middleware(['role:1'])->group(function () {
        // Routes d'administration
        Route::delete('/factures/{id}', [FactureController::class, 'destroy']);
        Route::delete('/paiements/{id}', [PaiementController::class, 'destroy']);
        Route::delete('/bordereaux/{id}', [BordereauController::class, 'destroy']);
        Route::delete('/pointages/{id}', [PointageController::class, 'destroy']);
        Route::delete('/bons-de-commande/{id}', [BonDeCommandeController::class, 'destroy']);
        Route::delete('/fournisseurs/{id}', [FournisseurController::class, 'destroy']);
        Route::delete('/conges/{id}', [CongeController::class, 'destroy']);
        Route::delete('/evaluations/{id}', [EvaluationController::class, 'destroy']);
        Route::delete('/notifications/{id}', [NotificationController::class, 'destroy']);
        
        // Routes pour la gestion des notifications
        Route::post('/notifications', [NotificationController::class, 'store']);
        Route::post('/notifications/cleanup', [NotificationController::class, 'cleanup']);
        Route::delete('/notifications/destroy-archived', [NotificationController::class, 'destroyArchived']);
    });

    // Routes WebSocket (tous les utilisateurs authentifiés)
    Route::middleware(['auth:sanctum'])->group(function () {
        Route::get('/websocket/info', [WebSocketController::class, 'getWebSocketInfo']);
        Route::post('/websocket/test', [WebSocketController::class, 'testNotification']);
    });

    // Routes WebSocket pour RH et Admin
    Route::middleware(['auth:sanctum', 'role:1,4'])->group(function () {
        Route::post('/websocket/notify-rh', [WebSocketController::class, 'notifyRH']);
    });

    // Routes WebSocket pour Admin uniquement
    Route::middleware(['auth:sanctum', 'role:1'])->group(function () {
        Route::post('/websocket/notify-admins', [WebSocketController::class, 'notifyAdmins']);
    });

    // Routes pour les reportings utilisateur
    Route::middleware(['auth:sanctum'])->group(function () {
        Route::get('/user-reportings', [UserReportingController::class, 'index']);
        Route::get('/user-reportings/{id}', [UserReportingController::class, 'show']);
        Route::post('/user-reportings', [UserReportingController::class, 'store']);
        Route::put('/user-reportings/{id}', [UserReportingController::class, 'update']);
        Route::delete('/user-reportings/{id}', [UserReportingController::class, 'destroy']);
        Route::post('/user-reportings/{id}/submit', [UserReportingController::class, 'submit']);
        Route::post('/user-reportings/{id}/approve', [UserReportingController::class, 'approve']);
        Route::post('/user-reportings/generate', [UserReportingController::class, 'generate']);
        Route::get('/user-reportings-statistics', [UserReportingController::class, 'statistics']);
    });

    // Routes pour le pointage
    Route::middleware(['auth:sanctum'])->group(function () {
        Route::get('/attendances', [AttendanceController::class, 'index']);
        Route::get('/attendances/{id}', [AttendanceController::class, 'show']);
        Route::post('/attendances/check-in', [AttendanceController::class, 'checkIn']);
        Route::post('/attendances/check-out', [AttendanceController::class, 'checkOut']);
        Route::put('/attendances/{id}', [AttendanceController::class, 'update']);
        Route::delete('/attendances/{id}', [AttendanceController::class, 'destroy']);
        Route::get('/attendances/current-status', [AttendanceController::class, 'currentStatus']);
        Route::get('/attendances-statistics', [AttendanceController::class, 'statistics']);
        Route::get('/attendance-settings', [AttendanceController::class, 'settings']);
    });

    // Routes pour les factures
    Route::middleware(['auth:sanctum'])->group(function () {
        Route::get('/invoices', [InvoiceController::class, 'index']);
        Route::get('/invoices/{id}', [InvoiceController::class, 'show']);
        Route::post('/invoices', [InvoiceController::class, 'store']);
        Route::put('/invoices/{id}', [InvoiceController::class, 'update']);
        Route::delete('/invoices/{id}', [InvoiceController::class, 'destroy']);
        Route::post('/invoices/{id}/send', [InvoiceController::class, 'send']);
        Route::post('/invoices/{id}/mark-paid', [InvoiceController::class, 'markAsPaid']);
        Route::post('/invoices/{id}/cancel', [InvoiceController::class, 'cancel']);
        Route::get('/invoices-statistics', [InvoiceController::class, 'statistics']);
        Route::post('/invoices/update-overdue', [InvoiceController::class, 'updateOverdue']);
    });

    // Routes pour les paiements
    Route::middleware(['auth:sanctum'])->group(function () {
        Route::get('/payments', [PaymentController::class, 'index']);
        Route::get('/payments/{id}', [PaymentController::class, 'show']);
        Route::post('/payments', [PaymentController::class, 'store']);
        Route::put('/payments/{id}', [PaymentController::class, 'update']);
        Route::delete('/payments/{id}', [PaymentController::class, 'destroy']);
        Route::post('/payments/{id}/submit', [PaymentController::class, 'submit']);
        Route::post('/payments/{id}/approve', [PaymentController::class, 'approve']);
        Route::post('/payments/{id}/reject', [PaymentController::class, 'reject']);
        Route::post('/payments/{id}/mark-paid', [PaymentController::class, 'markAsPaid']);
        Route::get('/payments-statistics', [PaymentController::class, 'statistics']);
        Route::post('/payments/update-overdue', [PaymentController::class, 'updateOverdue']);
    });
});

