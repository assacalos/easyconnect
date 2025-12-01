<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Paiement;
use App\Models\PaymentSchedule;
use App\Models\PaymentInstallment;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class PaymentStatsController extends Controller
{
    /**
     * Statistiques générales des paiements
     */
    public function index(Request $request)
    {
        $startDate = $request->get('start_date', now()->startOfMonth());
        $endDate = $request->get('end_date', now()->endOfMonth());

        // Statistiques de base
        $totalPayments = Paiement::whereBetween('created_at', [$startDate, $endDate])->count();
        $oneTimePayments = Paiement::oneTime()->whereBetween('created_at', [$startDate, $endDate])->count();
        $monthlyPayments = Paiement::monthly()->whereBetween('created_at', [$startDate, $endDate])->count();

        // Statistiques par statut
        $pendingPayments = Paiement::submitted()->whereBetween('created_at', [$startDate, $endDate])->count();
        $approvedPayments = Paiement::approved()->whereBetween('created_at', [$startDate, $endDate])->count();
        $paidPayments = Paiement::paid()->whereBetween('created_at', [$startDate, $endDate])->count();
        $overduePayments = Paiement::overdue()->whereBetween('created_at', [$startDate, $endDate])->count();

        // Montants
        $totalAmount = Paiement::whereBetween('created_at', [$startDate, $endDate])->sum('montant');
        $pendingAmount = Paiement::submitted()->whereBetween('created_at', [$startDate, $endDate])->sum('montant');
        $paidAmount = Paiement::paid()->whereBetween('created_at', [$startDate, $endDate])->sum('montant');
        $overdueAmount = Paiement::overdue()->whereBetween('created_at', [$startDate, $endDate])->sum('montant');

        // Paiements récents
        $recentPayments = Paiement::with(['facture.client', 'user'])
            ->whereBetween('created_at', [$startDate, $endDate])
            ->orderBy('created_at', 'desc')
            ->limit(10)
            ->get();

        // Statistiques mensuelles
        $monthlyStats = Paiement::select(
                DB::raw('DATE_FORMAT(created_at, "%Y-%m") as month'),
                DB::raw('COUNT(*) as count'),
                DB::raw('SUM(montant) as amount')
            )
            ->whereBetween('created_at', [$startDate, $endDate])
            ->groupBy('month')
            ->orderBy('month')
            ->get()
            ->pluck('amount', 'month')
            ->toArray();

        // Statistiques par méthode de paiement
        $paymentMethodStats = Paiement::select('type_paiement', DB::raw('COUNT(*) as count'))
            ->whereBetween('created_at', [$startDate, $endDate])
            ->groupBy('type_paiement')
            ->pluck('count', 'type_paiement')
            ->toArray();

        $stats = [
            'total_payments' => $totalPayments,
            'one_time_payments' => $oneTimePayments,
            'monthly_payments' => $monthlyPayments,
            'pending_payments' => $pendingPayments,
            'approved_payments' => $approvedPayments,
            'paid_payments' => $paidPayments,
            'overdue_payments' => $overduePayments,
            'total_amount' => $totalAmount,
            'pending_amount' => $pendingAmount,
            'paid_amount' => $paidAmount,
            'overdue_amount' => $overdueAmount,
            'recent_payments' => $recentPayments,
            'monthly_stats' => $monthlyStats,
            'payment_method_stats' => $paymentMethodStats
        ];

        return response()->json([
            'success' => true,
            'stats' => $stats,
            'message' => 'Statistiques récupérées avec succès'
        ]);
    }

    /**
     * Statistiques des plannings de paiement
     */
    public function schedules(Request $request)
    {
        $startDate = $request->get('start_date', now()->startOfMonth());
        $endDate = $request->get('end_date', now()->endOfMonth());

        $totalSchedules = PaymentSchedule::whereBetween('created_at', [$startDate, $endDate])->count();
        $activeSchedules = PaymentSchedule::active()->whereBetween('created_at', [$startDate, $endDate])->count();
        $completedSchedules = PaymentSchedule::completed()->whereBetween('created_at', [$startDate, $endDate])->count();
        $cancelledSchedules = PaymentSchedule::cancelled()->whereBetween('created_at', [$startDate, $endDate])->count();

        $totalInstallments = PaymentInstallment::whereBetween('created_at', [$startDate, $endDate])->count();
        $paidInstallments = PaymentInstallment::paid()->whereBetween('created_at', [$startDate, $endDate])->count();
        $pendingInstallments = PaymentInstallment::pending()->whereBetween('created_at', [$startDate, $endDate])->count();
        $overdueInstallments = PaymentInstallment::overdue()->whereBetween('created_at', [$startDate, $endDate])->count();

        $totalInstallmentAmount = PaymentInstallment::whereBetween('created_at', [$startDate, $endDate])->sum('amount');
        $paidInstallmentAmount = PaymentInstallment::paid()->whereBetween('created_at', [$startDate, $endDate])->sum('amount');
        $pendingInstallmentAmount = PaymentInstallment::pending()->whereBetween('created_at', [$startDate, $endDate])->sum('amount');
        $overdueInstallmentAmount = PaymentInstallment::overdue()->whereBetween('created_at', [$startDate, $endDate])->sum('amount');

        $stats = [
            'total_schedules' => $totalSchedules,
            'active_schedules' => $activeSchedules,
            'completed_schedules' => $completedSchedules,
            'cancelled_schedules' => $cancelledSchedules,
            'total_installments' => $totalInstallments,
            'paid_installments' => $paidInstallments,
            'pending_installments' => $pendingInstallments,
            'overdue_installments' => $overdueInstallments,
            'total_installment_amount' => $totalInstallmentAmount,
            'paid_installment_amount' => $paidInstallmentAmount,
            'pending_installment_amount' => $pendingInstallmentAmount,
            'overdue_installment_amount' => $overdueInstallmentAmount
        ];

        return response()->json([
            'success' => true,
            'stats' => $stats,
            'message' => 'Statistiques des plannings récupérées avec succès'
        ]);
    }

    /**
     * Échéances à venir
     */
    public function upcoming(Request $request)
    {
        $days = $request->get('days', 7);
        $date = Carbon::now()->addDays($days);

        $upcomingInstallments = PaymentInstallment::with(['schedule.payment.facture.client'])
            ->where('status', 'pending')
            ->where('due_date', '<=', $date)
            ->orderBy('due_date')
            ->get();

        return response()->json([
            'success' => true,
            'upcoming_installments' => $upcomingInstallments,
            'message' => 'Échéances à venir récupérées avec succès'
        ]);
    }

    /**
     * Échéances en retard
     */
    public function overdue()
    {
        $overdueInstallments = PaymentInstallment::with(['schedule.payment.facture.client'])
            ->where('status', 'overdue')
            ->orWhere(function($query) {
                $query->where('status', 'pending')
                      ->where('due_date', '<', Carbon::today());
            })
            ->orderBy('due_date')
            ->get();

        return response()->json([
            'success' => true,
            'overdue_installments' => $overdueInstallments,
            'message' => 'Échéances en retard récupérées avec succès'
        ]);
    }

    /**
     * Rapport de performance
     */
    public function performance(Request $request)
    {
        $startDate = $request->get('start_date', now()->startOfMonth());
        $endDate = $request->get('end_date', now()->endOfMonth());

        // Taux de paiement
        $totalPayments = Paiement::whereBetween('created_at', [$startDate, $endDate])->count();
        $paidPayments = Paiement::paid()->whereBetween('created_at', [$startDate, $endDate])->count();
        $paymentRate = $totalPayments > 0 ? ($paidPayments / $totalPayments) * 100 : 0;

        // Taux d'échéances
        $totalInstallments = PaymentInstallment::whereBetween('created_at', [$startDate, $endDate])->count();
        $paidInstallments = PaymentInstallment::paid()->whereBetween('created_at', [$startDate, $endDate])->count();
        $installmentRate = $totalInstallments > 0 ? ($paidInstallments / $totalInstallments) * 100 : 0;

        // Temps moyen de paiement
        $avgPaymentTime = Paiement::whereBetween('created_at', [$startDate, $endDate])
            ->whereNotNull('paid_at')
            ->selectRaw('AVG(DATEDIFF(paid_at, created_at)) as avg_days')
            ->value('avg_days');

        // Top clients par montant
        $topClients = Paiement::join('factures', 'paiements.facture_id', '=', 'factures.id')
            ->join('clients', 'factures.client_id', '=', 'clients.id')
            ->whereBetween('paiements.created_at', [$startDate, $endDate])
            ->select('clients.nom', 'clients.prenom', DB::raw('SUM(paiements.montant) as total_amount'))
            ->groupBy('clients.id', 'clients.nom', 'clients.prenom')
            ->orderBy('total_amount', 'desc')
            ->limit(10)
            ->get();

        $performance = [
            'payment_rate' => round($paymentRate, 2),
            'installment_rate' => round($installmentRate, 2),
            'avg_payment_time_days' => round($avgPaymentTime ?? 0, 2),
            'top_clients' => $topClients
        ];

        return response()->json([
            'success' => true,
            'performance' => $performance,
            'message' => 'Rapport de performance généré avec succès'
        ]);
    }
}