<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Invoice;
use App\Models\InvoiceItem;
use App\Models\InvoiceTemplate;
use App\Models\Client;
use App\Models\User;
use Faker\Factory as Faker;
use Carbon\Carbon;

class InvoiceSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $faker = Faker::create('fr_FR');
        $clients = Client::all();
        $commercials = User::where('role', 2)->get(); // Commercials

        if ($clients->isEmpty() || $commercials->isEmpty()) {
            $this->command->warn('Clients ou commerciaux manquants. Veuillez d\'abord exécuter leurs seeders.');
            return;
        }

        // Créer des templates de facture
        $this->createInvoiceTemplates();

        $statuses = ['draft', 'sent', 'paid', 'overdue', 'cancelled'];
        $currencies = ['EUR', 'USD', 'XOF'];

        for ($i = 0; $i < 50; $i++) {
            $client = $clients->random();
            $commercial = $commercials->random();
            $status = $statuses[array_rand($statuses)];
            $currency = $currencies[array_rand($currencies)];

            $invoiceDate = $faker->dateTimeBetween('-6 months', 'now');
            $dueDate = $faker->dateTimeBetween($invoiceDate, '+2 months');
            
            $subtotal = $faker->randomFloat(2, 1000, 50000);
            $taxRate = 18.0;
            $taxAmount = $subtotal * ($taxRate / 100);
            $totalAmount = $subtotal + $taxAmount;

            $invoice = Invoice::create([
                'invoice_number' => Invoice::generateInvoiceNumber(),
                'client_id' => $client->id,
                'commercial_id' => $commercial->id,
                'invoice_date' => $invoiceDate->format('Y-m-d'),
                'due_date' => $dueDate->format('Y-m-d'),
                'status' => $status,
                'subtotal' => $subtotal,
                'tax_rate' => $taxRate,
                'tax_amount' => $taxAmount,
                'total_amount' => $totalAmount,
                'currency' => $currency,
                'notes' => $faker->sentence(),
                'terms' => 'Paiement à 30 jours',
                'payment_info' => $status === 'paid' ? [
                    'method' => $faker->randomElement(['bank_transfer', 'check', 'cash', 'card']),
                    'reference' => 'PAY-' . $faker->unique()->numerify('######'),
                    'amount' => $totalAmount,
                    'notes' => 'Paiement reçu'
                ] : null,
                'sent_at' => in_array($status, ['sent', 'paid', 'overdue']) ? $faker->dateTimeBetween($invoiceDate, 'now') : null,
                'paid_at' => $status === 'paid' ? $faker->dateTimeBetween($invoiceDate, 'now') : null,
            ]);

            // Créer des items pour la facture
            $this->createInvoiceItems($invoice, $faker);
        }

        $this->command->info('50 factures créées avec succès.');
    }

    /**
     * Créer des templates de facture
     */
    private function createInvoiceTemplates()
    {
        $templates = [
            [
                'name' => 'Template Standard',
                'description' => 'Template de facture standard',
                'template' => $this->getStandardTemplate(),
                'is_default' => true
            ],
            [
                'name' => 'Template Moderne',
                'description' => 'Template de facture moderne',
                'template' => $this->getModernTemplate(),
                'is_default' => false
            ],
            [
                'name' => 'Template Minimaliste',
                'description' => 'Template de facture minimaliste',
                'template' => $this->getMinimalTemplate(),
                'is_default' => false
            ]
        ];

        foreach ($templates as $template) {
            InvoiceTemplate::create($template);
        }
    }

    /**
     * Créer des items pour une facture
     */
    private function createInvoiceItems($invoice, $faker)
    {
        $itemsCount = rand(1, 5);
        $items = [
            ['description' => 'Consultation technique', 'unit' => 'heure'],
            ['description' => 'Développement logiciel', 'unit' => 'jour'],
            ['description' => 'Formation utilisateur', 'unit' => 'session'],
            ['description' => 'Maintenance système', 'unit' => 'mois'],
            ['description' => 'Support technique', 'unit' => 'ticket'],
            ['description' => 'Licence logiciel', 'unit' => 'unité'],
            ['description' => 'Installation matériel', 'unit' => 'pièce'],
            ['description' => 'Audit sécurité', 'unit' => 'projet']
        ];

        for ($i = 0; $i < $itemsCount; $i++) {
            $item = $items[array_rand($items)];
            $quantity = rand(1, 10);
            $unitPrice = $faker->randomFloat(2, 50, 2000);
            $totalPrice = $quantity * $unitPrice;

            InvoiceItem::create([
                'invoice_id' => $invoice->id,
                'description' => $item['description'],
                'quantity' => $quantity,
                'unit_price' => $unitPrice,
                'total_price' => $totalPrice,
                'unit' => $item['unit']
            ]);
        }
    }

    /**
     * Template standard
     */
    private function getStandardTemplate()
    {
        return '
        <div class="invoice">
            <h1>FACTURE {{invoice_number}}</h1>
            <div class="client-info">
                <h3>Client: {{client_name}}</h3>
                <p>Email: {{client_email}}</p>
                <p>Adresse: {{client_address}}</p>
            </div>
            <div class="invoice-details">
                <p>Date: {{invoice_date}}</p>
                <p>Échéance: {{due_date}}</p>
                <p>Commercial: {{commercial_name}}</p>
            </div>
            <div class="items">
                <!-- Items will be inserted here -->
            </div>
            <div class="totals">
                <p>Sous-total: {{subtotal}} {{currency}}</p>
                <p>TVA ({{tax_rate}}%): {{tax_amount}} {{currency}}</p>
                <p><strong>Total: {{total_amount}} {{currency}}</strong></p>
            </div>
            <div class="notes">
                <p>{{notes}}</p>
            </div>
            <div class="terms">
                <p>{{terms}}</p>
            </div>
        </div>';
    }

    /**
     * Template moderne
     */
    private function getModernTemplate()
    {
        return '
        <div class="modern-invoice">
            <header>
                <h1>FACTURE</h1>
                <div class="invoice-number">{{invoice_number}}</div>
            </header>
            <div class="client-section">
                <h2>Facturé à:</h2>
                <p><strong>{{client_name}}</strong></p>
                <p>{{client_email}}</p>
                <p>{{client_address}}</p>
            </div>
            <div class="invoice-info">
                <div class="date-info">
                    <p><strong>Date:</strong> {{invoice_date}}</p>
                    <p><strong>Échéance:</strong> {{due_date}}</p>
                </div>
                <div class="commercial-info">
                    <p><strong>Commercial:</strong> {{commercial_name}}</p>
                </div>
            </div>
            <!-- Items table will be inserted here -->
            <div class="summary">
                <div class="subtotal">Sous-total: {{subtotal}} {{currency}}</div>
                <div class="tax">TVA ({{tax_rate}}%): {{tax_amount}} {{currency}}</div>
                <div class="total"><strong>Total: {{total_amount}} {{currency}}</strong></div>
            </div>
            <footer>
                <div class="notes">{{notes}}</div>
                <div class="terms">{{terms}}</div>
            </footer>
        </div>';
    }

    /**
     * Template minimaliste
     */
    private function getMinimalTemplate()
    {
        return '
        <div class="minimal-invoice">
            <h1>{{invoice_number}}</h1>
            <p><strong>{{client_name}}</strong></p>
            <p>{{client_email}}</p>
            <p>{{client_address}}</p>
            <p>Date: {{invoice_date}} | Échéance: {{due_date}}</p>
            <p>Commercial: {{commercial_name}}</p>
            <!-- Items will be inserted here -->
            <hr>
            <p>Sous-total: {{subtotal}} {{currency}}</p>
            <p>TVA: {{tax_amount}} {{currency}}</p>
            <p><strong>Total: {{total_amount}} {{currency}}</strong></p>
            <p>{{notes}}</p>
            <p>{{terms}}</p>
        </div>';
    }
}