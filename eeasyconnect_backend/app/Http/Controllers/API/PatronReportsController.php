<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use Illuminate\Http\Request;
use App\Models\Facture;
use App\Models\Paiement;
use App\Models\Expense;
use App\Models\Salary;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

/**
 * Rapports patron : trésorerie (encaissements / décaissements) et âge des créances.
 * Accessible par Patron et Admin (role 1, 6).
 */
class PatronReportsController extends Controller
{
    /**
     * GET /patron-reports?start_date=...&end_date=...
     * Retourne trésorerie sur la période et âge des créances (toutes factures non soldées).
     */
    public function reports(Request $request)
    {
        try {
            $user = $request->user();
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié',
                ], 401);
            }

            $start = $request->get('start_date')
                ? Carbon::parse($request->start_date)->startOfDay()
                : Carbon::today()->subDays(30)->startOfDay();
            $end = $request->get('end_date')
                ? Carbon::parse($request->end_date)->endOfDay()
                : Carbon::today()->endOfDay();

            if ($start->gt($end)) {
                return response()->json([
                    'success' => false,
                    'message' => 'La date de début doit être antérieure à la date de fin.',
                ], 422);
            }

            $tresorerie = $this->computeTresorerie($start, $end);
            $receivablesAging = $this->computeReceivablesAging();

            return response()->json([
                'success' => true,
                'data' => [
                    'period' => [
                        'start_date' => $start->format('Y-m-d'),
                        'end_date' => $end->format('Y-m-d'),
                    ],
                    'tresorerie' => $tresorerie,
                    'receivables_aging' => $receivablesAging,
                ],
                'message' => 'Rapports patron récupérés avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);
        } catch (\Exception $e) {
            Log::error('PatronReportsController::reports', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la génération des rapports: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Encaissements = paiements (payés ou approuvés) sur la période.
     * Décaissements = dépenses + salaires sur la période.
     */
    private function computeTresorerie(Carbon $start, Carbon $end): array
    {
        $startDate = $start->copy()->startOfDay()->format('Y-m-d');
        $endDate = $end->copy()->endOfDay()->format('Y-m-d');

        $encaissements = (float) Paiement::query()
            ->whereBetween('date_paiement', [$startDate, $endDate])
            ->whereIn('status', ['paid', 'approved'])
            ->sum('montant');

        $depensesTotal = (float) Expense::query()
            ->whereBetween('expense_date', [$startDate, $endDate])
            ->sum('amount');

        $salairesTotal = (float) Salary::query()
            ->whereBetween('salary_date', [$startDate, $endDate])
            ->sum('net_salary');

        $decaissements = $depensesTotal + $salairesTotal;
        $solde = $encaissements - $decaissements;

        return [
            'encaissements' => round($encaissements, 2),
            'decaissements' => round($decaissements, 2),
            'solde_tresorerie' => round($solde, 2),
        ];
    }

    /**
     * Âge des créances : factures non soldées (montant restant dû) par tranche
     * 0-30 j, 31-60 j, 61-90 j, >90 j depuis l'échéance.
     */
    private function computeReceivablesAging(): array
    {
        $r0_30 = 0.0;
        $r31_60 = 0.0;
        $r61_90 = 0.0;
        $rOver90 = 0.0;

        $factures = Facture::with('paiements')
            ->where('status', '!=', 'rejete')
            ->get();

        $today = Carbon::today()->startOfDay();

        foreach ($factures as $facture) {
            $totalTtc = (float) $facture->montant_ttc;
            $paidAmount = (float) $facture->paiements
                ->whereIn('status', ['paid', 'approved'])
                ->sum('montant');
            $amountDue = $totalTtc - $paidAmount;
            if ($amountDue <= 0) {
                continue;
            }

            $dueDate = Carbon::parse($facture->date_echeance)->startOfDay();
            $daysPastDue = $dueDate->isPast()
                ? (int) $today->diffInDays($dueDate)
                : 0;

            if ($daysPastDue <= 30) {
                $r0_30 += $amountDue;
            } elseif ($daysPastDue <= 60) {
                $r31_60 += $amountDue;
            } elseif ($daysPastDue <= 90) {
                $r61_90 += $amountDue;
            } else {
                $rOver90 += $amountDue;
            }
        }

        return [
            'receivables_0_30' => round($r0_30, 2),
            'receivables_31_60' => round($r31_60, 2),
            'receivables_61_90' => round($r61_90, 2),
            'receivables_over_90' => round($rOver90, 2),
        ];
    }
}
