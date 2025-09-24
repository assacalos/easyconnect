<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Payment;
use App\Models\PaymentSchedule;
use App\Models\PaymentInstallment;
use App\Models\PaymentTemplate;
use App\Models\Client;
use App\Models\User;
use Faker\Factory as Faker;
use Carbon\Carbon;

class PaymentSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $faker = Faker::create('fr_FR');
        $clients = Client::all();
        $comptables = User::where('role', 3)->get(); // Comptables

        if ($clients->isEmpty() || $comptables->isEmpty()) {
            $this->command->warn('Clients ou comptables manquants. Veuillez d\'abord exécuter leurs seeders.');
            return;
        }

        // Créer des templates de paiement
        $this->createPaymentTemplates();

        $statuses = ['draft', 'submitted', 'approved', 'rejected', 'paid', 'overdue'];
        $types = ['one_time', 'monthly'];
        $paymentMethods = ['bank_transfer', 'check', 'cash', 'card', 'direct_debit'];
        $currencies = ['EUR', 'USD', 'XOF'];

        // Créer des paiements ponctuels
        for ($i = 0; $i < 30; $i++) {
            $client = $clients->random();
            $comptable = $comptables->random();
            $status = $statuses[array_rand($statuses)];
            $paymentMethod = $paymentMethods[array_rand($paymentMethods)];
            $currency = $currencies[array_rand($currencies)];

            $paymentDate = $faker->dateTimeBetween('-6 months', 'now');
            $dueDate = $faker->dateTimeBetween($paymentDate, '+2 months');
            
            $amount = $faker->randomFloat(2, 500, 25000);

            $payment = Payment::create([
                'payment_number' => Payment::generatePaymentNumber(),
                'type' => 'one_time',
                'client_id' => $client->id,
                'comptable_id' => $comptable->id,
                'payment_date' => $paymentDate->format('Y-m-d'),
                'due_date' => $dueDate->format('Y-m-d'),
                'status' => $status,
                'amount' => $amount,
                'currency' => $currency,
                'payment_method' => $paymentMethod,
                'description' => $this->getRandomDescription($paymentMethod),
                'notes' => $faker->sentence(),
                'reference' => $faker->unique()->numerify('REF-######'),
                'submitted_at' => in_array($status, ['submitted', 'approved', 'paid', 'overdue']) ? $faker->dateTimeBetween($paymentDate, 'now') : null,
                'approved_at' => in_array($status, ['approved', 'paid', 'overdue']) ? $faker->dateTimeBetween($paymentDate, 'now') : null,
                'paid_at' => $status === 'paid' ? $faker->dateTimeBetween($paymentDate, 'now') : null,
            ]);
        }

        // Créer des paiements mensuels avec échéanciers
        for ($i = 0; $i < 10; $i++) {
            $client = $clients->random();
            $comptable = $comptables->random();
            $status = $statuses[array_rand($statuses)];
            $paymentMethod = $paymentMethods[array_rand($paymentMethods)];
            $currency = $currencies[array_rand($currencies)];

            $startDate = $faker->dateTimeBetween('-3 months', 'now');
            $endDate = $faker->dateTimeBetween($startDate, '+6 months');
            $frequency = $faker->randomElement([7, 14, 30]); // 1 semaine, 2 semaines, 1 mois
            $amount = $faker->randomFloat(2, 1000, 10000);

            // Créer l'échéancier
            $schedule = PaymentSchedule::createSchedule(
                $client->id,
                $comptable->id,
                $startDate->format('Y-m-d'),
                $endDate->format('Y-m-d'),
                $frequency,
                $amount,
                'Paiement mensuel pour services'
            );

            $payment = Payment::create([
                'payment_number' => Payment::generatePaymentNumber(),
                'type' => 'monthly',
                'client_id' => $client->id,
                'comptable_id' => $comptable->id,
                'payment_date' => $startDate->format('Y-m-d'),
                'due_date' => $endDate->format('Y-m-d'),
                'status' => $status,
                'amount' => $amount,
                'currency' => $currency,
                'payment_method' => $paymentMethod,
                'description' => 'Paiement mensuel pour services',
                'notes' => $faker->sentence(),
                'reference' => $faker->unique()->numerify('REF-######'),
                'payment_schedule_id' => $schedule->id,
                'submitted_at' => in_array($status, ['submitted', 'approved', 'paid', 'overdue']) ? $faker->dateTimeBetween($startDate, 'now') : null,
                'approved_at' => in_array($status, ['approved', 'paid', 'overdue']) ? $faker->dateTimeBetween($startDate, 'now') : null,
                'paid_at' => $status === 'paid' ? $faker->dateTimeBetween($startDate, 'now') : null,
            ]);

            // Marquer quelques échéances comme payées
            $this->markSomeInstallmentsAsPaid($schedule);
        }

        $this->command->info('Paiements créés avec succès.');
    }

    /**
     * Créer des templates de paiement
     */
    private function createPaymentTemplates()
    {
        $templates = [
            [
                'name' => 'Template Paiement Ponctuel',
                'description' => 'Template pour paiements ponctuels',
                'type' => 'one_time',
                'default_amount' => 1000.00,
                'default_payment_method' => 'bank_transfer',
                'template' => $this->getOneTimeTemplate(),
                'is_default' => true
            ],
            [
                'name' => 'Template Paiement Mensuel',
                'description' => 'Template pour paiements mensuels',
                'type' => 'monthly',
                'default_amount' => 500.00,
                'default_payment_method' => 'direct_debit',
                'default_frequency' => 30,
                'template' => $this->getMonthlyTemplate(),
                'is_default' => false
            ],
            [
                'name' => 'Template Paiement Espèces',
                'description' => 'Template pour paiements en espèces',
                'type' => 'one_time',
                'default_amount' => 500.00,
                'default_payment_method' => 'cash',
                'template' => $this->getCashTemplate(),
                'is_default' => false
            ]
        ];

        foreach ($templates as $template) {
            PaymentTemplate::create($template);
        }
    }

    /**
     * Marquer quelques échéances comme payées
     */
    private function markSomeInstallmentsAsPaid($schedule)
    {
        $installments = $schedule->installments()->orderBy('installment_number')->get();
        $paidCount = rand(0, min(3, $installments->count()));

        for ($i = 0; $i < $paidCount; $i++) {
            $installment = $installments[$i];
            $installment->markAsPaid('Paiement effectué');
        }
    }

    /**
     * Générer une description aléatoire selon la méthode de paiement
     */
    private function getRandomDescription($paymentMethod)
    {
        $descriptions = [
            'bank_transfer' => [
                'Virement bancaire pour services',
                'Paiement par virement',
                'Transfert bancaire'
            ],
            'check' => [
                'Paiement par chèque',
                'Chèque en règlement',
                'Paiement chèque'
            ],
            'cash' => [
                'Paiement en espèces',
                'Règlement comptant',
                'Espèces reçues'
            ],
            'card' => [
                'Paiement par carte bancaire',
                'Transaction carte',
                'Paiement CB'
            ],
            'direct_debit' => [
                'Prélèvement automatique',
                'Paiement par prélèvement',
                'Débit automatique'
            ]
        ];

        $methodDescriptions = $descriptions[$paymentMethod] ?? ['Paiement standard'];
        return $methodDescriptions[array_rand($methodDescriptions)];
    }

    /**
     * Template paiement ponctuel
     */
    private function getOneTimeTemplate()
    {
        return '
        <div class="payment-receipt">
            <h1>REÇU DE PAIEMENT</h1>
            <div class="payment-info">
                <p><strong>Numéro:</strong> {{payment_number}}</p>
                <p><strong>Date:</strong> {{payment_date}}</p>
                <p><strong>Montant:</strong> {{amount}} {{currency}}</p>
                <p><strong>Méthode:</strong> {{payment_method}}</p>
            </div>
            <div class="client-info">
                <h3>Client: {{client_name}}</h3>
                <p>Email: {{client_email}}</p>
                <p>Adresse: {{client_address}}</p>
            </div>
            <div class="comptable-info">
                <p>Comptable: {{comptable_name}}</p>
            </div>
            <div class="description">
                <p>{{description}}</p>
            </div>
            <div class="notes">
                <p>{{notes}}</p>
            </div>
        </div>';
    }

    /**
     * Template paiement mensuel
     */
    private function getMonthlyTemplate()
    {
        return '
        <div class="monthly-payment-receipt">
            <h1>REÇU DE PAIEMENT MENSUEL</h1>
            <div class="payment-info">
                <p><strong>Numéro:</strong> {{payment_number}}</p>
                <p><strong>Date:</strong> {{payment_date}}</p>
                <p><strong>Montant:</strong> {{amount}} {{currency}}</p>
                <p><strong>Méthode:</strong> {{payment_method}}</p>
                <p><strong>Type:</strong> Paiement mensuel</p>
            </div>
            <div class="client-info">
                <h3>Client: {{client_name}}</h3>
                <p>Email: {{client_email}}</p>
                <p>Adresse: {{client_address}}</p>
            </div>
            <div class="comptable-info">
                <p>Comptable: {{comptable_name}}</p>
            </div>
            <div class="description">
                <p>{{description}}</p>
            </div>
            <div class="notes">
                <p>{{notes}}</p>
            </div>
        </div>';
    }

    /**
     * Template paiement espèces
     */
    private function getCashTemplate()
    {
        return '
        <div class="cash-payment-receipt">
            <h1>REÇU DE PAIEMENT EN ESPÈCES</h1>
            <div class="payment-info">
                <p><strong>Numéro:</strong> {{payment_number}}</p>
                <p><strong>Date:</strong> {{payment_date}}</p>
                <p><strong>Montant:</strong> {{amount}} {{currency}}</p>
                <p><strong>Méthode:</strong> Espèces</p>
            </div>
            <div class="client-info">
                <h3>Client: {{client_name}}</h3>
                <p>Email: {{client_email}}</p>
                <p>Adresse: {{client_address}}</p>
            </div>
            <div class="comptable-info">
                <p>Comptable: {{comptable_name}}</p>
            </div>
            <div class="description">
                <p>{{description}}</p>
            </div>
            <div class="notes">
                <p>{{notes}}</p>
            </div>
            <div class="signature">
                <p>Signature du comptable: _________________</p>
            </div>
        </div>';
    }
}