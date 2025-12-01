import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/services/devis_service.dart';
import 'package:easyconnect/services/bordereau_service.dart';
import 'package:easyconnect/services/invoice_service.dart';
import 'package:easyconnect/services/payment_service.dart';
import 'package:easyconnect/services/expense_service.dart';
import 'package:easyconnect/services/salary_service.dart';

class PatronReportsController extends GetxController {
  final DevisService _devisService = DevisService();
  final BordereauService _bordereauService = BordereauService();
  final InvoiceService _invoiceService = InvoiceService();
  final PaymentService _paymentService = PaymentService();
  final ExpenseService _expenseService = ExpenseService();
  final SalaryService _salaryService = SalaryService();

  // Période sélectionnée
  final startDate = DateTime.now().subtract(const Duration(days: 30)).obs;
  final endDate = DateTime.now().obs;

  // État de chargement
  final isLoading = false.obs;

  // Statistiques - Devis
  final devisCount = 0.obs;
  final devisTotal = 0.0.obs;

  // Statistiques - Bordereaux
  final bordereauxCount = 0.obs;
  final bordereauxTotal = 0.0.obs;

  // Statistiques - Factures
  final facturesCount = 0.obs;
  final facturesTotal = 0.0.obs;

  // Statistiques - Paiements
  final paiementsCount = 0.obs;
  final paiementsTotal = 0.0.obs;

  // Statistiques - Dépenses
  final depensesCount = 0.obs;
  final depensesTotal = 0.0.obs;

  // Statistiques - Salaires
  final salairesCount = 0.obs;
  final salairesTotal = 0.0.obs;

  // Bénéfice net
  final beneficeNet = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadReports();
  }

  Future<void> updateDateRange(DateTime start, DateTime end) async {
    startDate.value = start;
    endDate.value = end;
    await loadReports();
  }

  Future<void> loadReports() async {
    try {
      isLoading.value = true;

      // Charger les devis
      await _loadDevisStats();

      // Charger les bordereaux
      await _loadBordereauxStats();

      // Charger les factures
      await _loadFacturesStats();

      // Charger les paiements
      await _loadPaiementsStats();

      // Charger les dépenses
      await _loadDepensesStats();

      // Charger les salaires
      await _loadSalairesStats();

      // Calculer le bénéfice net
      beneficeNet.value =
          (facturesTotal.value + paiementsTotal.value) -
          (depensesTotal.value + salairesTotal.value);
    } catch (e) {
      // Ne pas afficher d'erreur pour les erreurs d'authentification (déjà gérées)
      final errorString = e.toString().toLowerCase();
      if (!errorString.contains('session expirée') &&
          !errorString.contains('401') &&
          !errorString.contains('unauthorized')) {
        // Les rapports peuvent partiellement charger, ne pas afficher d'erreur si certaines données sont disponibles
        // (les statistiques peuvent être partiellement chargées)
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadDevisStats() async {
    try {
      final devis = await _devisService.getDevis();

      // Filtrer par période
      final filteredDevis =
          devis.where((d) {
            final date = d.dateCreation;
            return date.isAfter(
                  startDate.value.subtract(const Duration(days: 1)),
                ) &&
                date.isBefore(endDate.value.add(const Duration(days: 1)));
          }).toList();

      devisCount.value = filteredDevis.length;
      devisTotal.value = filteredDevis.fold(0.0, (sum, d) => sum + d.totalTTC);
    } catch (e) {
      devisCount.value = 0;
      devisTotal.value = 0.0;
    }
  }

  Future<void> _loadBordereauxStats() async {
    try {
      final bordereaux = await _bordereauService.getBordereaux();

      // Filtrer par période
      final filteredBordereaux =
          bordereaux.where((b) {
            final date = b.dateCreation;
            return date.isAfter(
                  startDate.value.subtract(const Duration(days: 1)),
                ) &&
                date.isBefore(endDate.value.add(const Duration(days: 1)));
          }).toList();

      bordereauxCount.value = filteredBordereaux.length;
      bordereauxTotal.value = filteredBordereaux.fold(
        0.0,
        (sum, b) => sum + b.montantTTC,
      );
    } catch (e) {
      bordereauxCount.value = 0;
      bordereauxTotal.value = 0.0;
    }
  }

  Future<void> _loadFacturesStats() async {
    try {
      final factures = await _invoiceService.getAllInvoices(
        startDate: startDate.value,
        endDate: endDate.value,
      );

      facturesCount.value = factures.length;
      facturesTotal.value = factures.fold(0.0, (sum, f) => sum + f.totalAmount);
    } catch (e) {
      facturesCount.value = 0;
      facturesTotal.value = 0.0;
    }
  }

  Future<void> _loadPaiementsStats() async {
    try {
      final paiements = await _paymentService.getAllPayments(
        startDate: startDate.value,
        endDate: endDate.value,
      );

      paiementsCount.value = paiements.length;
      paiementsTotal.value = paiements.fold(0.0, (sum, p) => sum + p.amount);
    } catch (e) {
      paiementsCount.value = 0;
      paiementsTotal.value = 0.0;
    }
  }

  Future<void> _loadDepensesStats() async {
    try {
      final depenses = await _expenseService.getExpenses();

      // Filtrer par période
      final filteredDepenses =
          depenses.where((d) {
            final date = d.expenseDate;
            return date.isAfter(
                  startDate.value.subtract(const Duration(days: 1)),
                ) &&
                date.isBefore(endDate.value.add(const Duration(days: 1)));
          }).toList();

      depensesCount.value = filteredDepenses.length;
      depensesTotal.value = filteredDepenses.fold(
        0.0,
        (sum, d) => sum + d.amount,
      );
    } catch (e) {
      depensesCount.value = 0;
      depensesTotal.value = 0.0;
    }
  }

  Future<void> _loadSalairesStats() async {
    try {
      final salaires = await _salaryService.getSalaries();

      // Filtrer par période
      final filteredSalaires =
          salaires.where((s) {
            final date = s.createdAt ?? DateTime.now();
            return date.isAfter(
                  startDate.value.subtract(const Duration(days: 1)),
                ) &&
                date.isBefore(endDate.value.add(const Duration(days: 1)));
          }).toList();

      salairesCount.value = filteredSalaires.length;
      salairesTotal.value = filteredSalaires.fold(
        0.0,
        (sum, s) => sum + s.netSalary,
      );
    } catch (e) {
      salairesCount.value = 0;
      salairesTotal.value = 0.0;
    }
  }
}
