<?php

require_once 'vendor/autoload.php';

use Illuminate\Support\Facades\DB;
use App\Models\Payment;
use App\Models\PaymentSchedule;
use App\Models\PaymentInstallment;
use App\Models\PaymentTemplate;
use App\Models\Client;
use App\Models\User;

// Bootstrap Laravel
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "=== Test du système de paiement ===\n\n";

// 1. Vérifier les données existantes
echo "1. Vérification des données existantes:\n";
echo "   - Clients: " . Client::count() . "\n";
echo "   - Utilisateurs: " . User::count() . "\n";
echo "   - Paiements: " . Payment::count() . "\n";
echo "   - Échéanciers: " . PaymentSchedule::count() . "\n";
echo "   - Échéances: " . PaymentInstallment::count() . "\n";
echo "   - Templates: " . PaymentTemplate::count() . "\n\n";

// 2. Tester les statistiques
echo "2. Statistiques des paiements:\n";
$stats = Payment::getPaymentStats();
foreach ($stats as $key => $value) {
    echo "   - $key: $value\n";
}
echo "\n";

// 3. Tester les paiements par statut
echo "3. Paiements par statut:\n";
$statuses = ['draft', 'submitted', 'approved', 'rejected', 'paid', 'overdue'];
foreach ($statuses as $status) {
    $count = Payment::where('status', $status)->count();
    echo "   - $status: $count\n";
}
echo "\n";

// 4. Tester les paiements par type
echo "4. Paiements par type:\n";
$oneTimeCount = Payment::where('type', 'one_time')->count();
$monthlyCount = Payment::where('type', 'monthly')->count();
echo "   - Paiements ponctuels: $oneTimeCount\n";
echo "   - Paiements mensuels: $monthlyCount\n\n";

// 5. Tester les méthodes de paiement
echo "5. Méthodes de paiement:\n";
$methods = ['bank_transfer', 'check', 'cash', 'card', 'direct_debit'];
foreach ($methods as $method) {
    $count = Payment::where('payment_method', $method)->count();
    echo "   - $method: $count\n";
}
echo "\n";

// 6. Tester les échéanciers
echo "6. Échéanciers:\n";
$activeSchedules = PaymentSchedule::where('status', 'active')->count();
$completedSchedules = PaymentSchedule::where('status', 'completed')->count();
$cancelledSchedules = PaymentSchedule::where('status', 'cancelled')->count();
echo "   - Actifs: $activeSchedules\n";
echo "   - Terminés: $completedSchedules\n";
echo "   - Annulés: $cancelledSchedules\n\n";

// 7. Tester les échéances
echo "7. Échéances:\n";
$pendingInstallments = PaymentInstallment::where('status', 'pending')->count();
$paidInstallments = PaymentInstallment::where('status', 'paid')->count();
$overdueInstallments = PaymentInstallment::where('status', 'overdue')->count();
echo "   - En attente: $pendingInstallments\n";
echo "   - Payées: $paidInstallments\n";
echo "   - En retard: $overdueInstallments\n\n";

// 8. Tester les templates
echo "8. Templates de paiement:\n";
$templates = PaymentTemplate::all();
foreach ($templates as $template) {
    echo "   - {$template->name} ({$template->type}): " . ($template->is_default ? 'Défaut' : 'Standard') . "\n";
}
echo "\n";

// 9. Tester la génération de numéros
echo "9. Test de génération de numéros:\n";
$newNumber = Payment::generatePaymentNumber();
echo "   - Nouveau numéro généré: $newNumber\n\n";

// 10. Tester les relations
echo "10. Test des relations:\n";
$payment = Payment::with(['client', 'comptable', 'paymentSchedule.installments'])->first();
if ($payment) {
    echo "   - Premier paiement: {$payment->payment_number}\n";
    echo "   - Client: {$payment->client_name}\n";
    echo "   - Comptable: {$payment->comptable_name}\n";
    if ($payment->paymentSchedule) {
        echo "   - Échéancier: {$payment->paymentSchedule->total_installments} échéances\n";
        echo "   - Échéances payées: {$payment->paymentSchedule->paid_installments}\n";
    }
}
echo "\n";

echo "=== Test terminé ===\n";
