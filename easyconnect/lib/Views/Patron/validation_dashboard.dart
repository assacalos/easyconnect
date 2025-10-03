import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/bindings/app_bindings.dart';
import 'package:easyconnect/Views/Patron/client_validation_page.dart';
import 'package:easyconnect/Views/Patron/bordereau_validation_page.dart';
import 'package:easyconnect/Views/Patron/bon_commande_validation_page.dart';
import 'package:easyconnect/Views/Patron/devis_validation_page.dart';
import 'package:easyconnect/Views/Patron/facture_validation_page.dart';
import 'package:easyconnect/Views/Patron/paiement_validation_page.dart';
import 'package:easyconnect/Views/Patron/stock_validation_page.dart';
import 'package:easyconnect/Views/Patron/intervention_validation_page.dart';
import 'package:easyconnect/Views/Patron/salaire_validation_page.dart';
import 'package:easyconnect/Views/Patron/recruitment_validation_page.dart';
import 'package:easyconnect/Views/Patron/pointage_validation_page.dart';
import 'package:easyconnect/Views/Patron/taxe_validation_page.dart';
import 'package:easyconnect/Views/Patron/reporting_validation_page.dart';

class ValidationDashboard extends StatelessWidget {
  const ValidationDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord des Validations'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildValidationCard(
              title: 'Clients',
              icon: Icons.people,
              color: Colors.blue,
              onTap: () => Get.to(() => ClientValidationPage()),
            ),
            _buildValidationCard(
              title: 'Devis',
              icon: Icons.description,
              color: Colors.green,
              onTap: () => Get.to(() => const BordereauValidationPage()),
            ),

            _buildValidationCard(
              title: 'Bordereaux',
              icon: Icons.description,
              color: Colors.green,
              onTap: () => Get.to(() => const BordereauValidationPage()),
            ),
            _buildValidationCard(
              title: 'Bons de Commande',
              icon: Icons.shopping_cart,
              color: Colors.orange,
              onTap: () => Get.to(() => const BonCommandeValidationPage()),
            ),

            _buildValidationCard(
              title: 'Factures',
              icon: Icons.receipt,
              color: Colors.red,
              onTap: () => Get.to(() => const FactureValidationPage()),
            ),
            _buildValidationCard(
              title: 'Paiements',
              icon: Icons.payment,
              color: Colors.teal,
              onTap: () => Get.to(() => const PaiementValidationPage()),
            ),
            _buildValidationCard(
              title: 'Stock',
              icon: Icons.inventory,
              color: Colors.deepPurple,
              onTap: () => Get.to(() => const StockValidationPage()),
            ),
            _buildValidationCard(
              title: 'Interventions',
              icon: Icons.build,
              color: Colors.indigo,
              onTap: () => Get.to(() => const InterventionValidationPage()),
            ),
            _buildValidationCard(
              title: 'Salaires',
              icon: Icons.account_balance_wallet,
              color: Colors.amber,
              onTap: () => Get.to(() => const SalaireValidationPage()),
            ),
            _buildValidationCard(
              title: 'Recrutement',
              icon: Icons.person_add,
              color: Colors.cyan,
              onTap: () => Get.to(() => const RecruitmentValidationPage()),
            ),
            _buildValidationCard(
              title: 'Pointage',
              icon: Icons.access_time,
              color: Colors.brown,
              onTap: () => Get.to(() => const PointageValidationPage()),
            ),
            _buildValidationCard(
              title: 'Taxes et Impôts',
              icon: Icons.account_balance,
              color: Colors.deepOrange,
              onTap: () => Get.to(() => const TaxeValidationPage()),
            ),
            _buildValidationCard(
              title: 'Reporting',
              icon: Icons.analytics,
              color: Colors.pink,
              onTap: () => Get.to(() => const ReportingValidationPage()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Validation',
                style: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
