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
  
  // Protection contre les appels multiples
  bool _isLoadingData = false;

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
    // Protection contre les appels multiples
    if (_isLoadingData || isLoading.value) {
      return;
    }
    
    _isLoadingData = true;
    isLoading.value = true;

    try {
      // Charger toutes les statistiques en parallèle (non-bloquant)
      await Future.wait([
        _loadDevisStats(),
        _loadBordereauxStats(),
        _loadFacturesStats(),
        _loadPaiementsStats(),
        _loadDepensesStats(),
        _loadSalairesStats(),
      ], eagerError: false);

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
      _isLoadingData = false;
    }
  }

  Future<void> _loadDevisStats() async {
    try {
      // OPTIMISATION : Utiliser la pagination avec filtres de date
      // Charger par batch pour éviter la saturation mémoire
      int page = 1;
      const perPage = 100;
      int totalCount = 0;
      double totalAmount = 0.0;
      int maxPages = 50; // Limiter à 5000 devis max
      
      while (page <= maxPages) {
        try {
          final paginated = await _devisService.getDevisPaginated(
            page: page,
            perPage: perPage,
          );
          
          // Filtrer par période côté client (en attendant le support backend)
          final filtered = paginated.data.where((d) {
            final date = d.dateCreation;
            return date.isAfter(
                  startDate.value.subtract(const Duration(days: 1)),
                ) &&
                date.isBefore(endDate.value.add(const Duration(days: 1)));
          }).toList();
          
          totalCount += filtered.length;
          totalAmount += filtered.fold(0.0, (sum, d) => sum + d.totalTTC);
          
          if (!paginated.hasNextPage) break;
          page++;
        } catch (e) {
          // Si erreur, essayer fallback
          if (page == 1) {
            final devis = await _devisService.getDevis();
            final filtered = devis.where((d) {
              final date = d.dateCreation;
              return date.isAfter(
                    startDate.value.subtract(const Duration(days: 1)),
                  ) &&
                  date.isBefore(endDate.value.add(const Duration(days: 1)));
            }).toList();
            devisCount.value = filtered.length;
            devisTotal.value = filtered.fold(0.0, (sum, d) => sum + d.totalTTC);
            return;
          }
          break;
        }
      }
      
      devisCount.value = totalCount;
      devisTotal.value = totalAmount;
    } catch (e) {
      devisCount.value = 0;
      devisTotal.value = 0.0;
    }
  }

  Future<void> _loadBordereauxStats() async {
    try {
      // OPTIMISATION : Utiliser la pagination avec filtres de date
      int page = 1;
      const perPage = 100;
      int totalCount = 0;
      double totalAmount = 0.0;
      int maxPages = 50; // Limiter à 5000 bordereaux max
      
      while (page <= maxPages) {
        try {
          final paginated = await _bordereauService.getBordereauxPaginated(
            page: page,
            perPage: perPage,
          );
          
          // Filtrer par période côté client (en attendant le support backend)
          final filtered = paginated.data.where((b) {
            final date = b.dateCreation;
            return date.isAfter(
                  startDate.value.subtract(const Duration(days: 1)),
                ) &&
                date.isBefore(endDate.value.add(const Duration(days: 1)));
          }).toList();
          
          totalCount += filtered.length;
          totalAmount += filtered.fold(0.0, (sum, b) => sum + b.montantTTC);
          
          if (!paginated.hasNextPage) break;
          page++;
        } catch (e) {
          // Si erreur, essayer fallback
          if (page == 1) {
            final bordereaux = await _bordereauService.getBordereaux();
            final filtered = bordereaux.where((b) {
              final date = b.dateCreation;
              return date.isAfter(
                    startDate.value.subtract(const Duration(days: 1)),
                  ) &&
                  date.isBefore(endDate.value.add(const Duration(days: 1)));
            }).toList();
            bordereauxCount.value = filtered.length;
            bordereauxTotal.value = filtered.fold(0.0, (sum, b) => sum + b.montantTTC);
            return;
          }
          break;
        }
      }
      
      bordereauxCount.value = totalCount;
      bordereauxTotal.value = totalAmount;
    } catch (e) {
      bordereauxCount.value = 0;
      bordereauxTotal.value = 0.0;
    }
  }

  Future<void> _loadFacturesStats() async {
    try {
      // OPTIMISATION : Utiliser la pagination avec filtres de date
      int page = 1;
      const perPage = 100;
      int totalCount = 0;
      double totalAmount = 0.0;
      int maxPages = 50; // Limiter à 5000 factures max
      
      while (page <= maxPages) {
        try {
          final paginated = await _invoiceService.getInvoicesPaginated(
            startDate: startDate.value,
            endDate: endDate.value,
            page: page,
            perPage: perPage,
          );
          
          totalCount += paginated.data.length;
          totalAmount += paginated.data.fold(0.0, (sum, f) => sum + f.totalAmount);
          
          if (!paginated.hasNextPage) break;
          page++;
        } catch (e) {
          // Si erreur, essayer fallback
          if (page == 1) {
            final factures = await _invoiceService.getAllInvoices(
              startDate: startDate.value,
              endDate: endDate.value,
            );
            facturesCount.value = factures.length;
            facturesTotal.value = factures.fold(0.0, (sum, f) => sum + f.totalAmount);
            return;
          }
          break;
        }
      }
      
      facturesCount.value = totalCount;
      facturesTotal.value = totalAmount;
    } catch (e) {
      facturesCount.value = 0;
      facturesTotal.value = 0.0;
    }
  }

  Future<void> _loadPaiementsStats() async {
    try {
      // OPTIMISATION : Utiliser la pagination avec filtres de date
      int page = 1;
      const perPage = 100;
      int totalCount = 0;
      double totalAmount = 0.0;
      int maxPages = 50; // Limiter à 5000 paiements max
      
      while (page <= maxPages) {
        try {
          final paginated = await _paymentService.getAllPaymentsPaginated(
            startDate: startDate.value,
            endDate: endDate.value,
            page: page,
            perPage: perPage,
          );
          
          totalCount += paginated.data.length;
          totalAmount += paginated.data.fold(0.0, (sum, p) => sum + p.amount);
          
          if (!paginated.hasNextPage) break;
          page++;
        } catch (e) {
          // Si erreur, essayer fallback
          if (page == 1) {
            final paiements = await _paymentService.getAllPayments(
              startDate: startDate.value,
              endDate: endDate.value,
            );
            paiementsCount.value = paiements.length;
            paiementsTotal.value = paiements.fold(0.0, (sum, p) => sum + p.amount);
            return;
          }
          break;
        }
      }
      
      paiementsCount.value = totalCount;
      paiementsTotal.value = totalAmount;
    } catch (e) {
      paiementsCount.value = 0;
      paiementsTotal.value = 0.0;
    }
  }

  Future<void> _loadDepensesStats() async {
    try {
      // OPTIMISATION : Utiliser la pagination avec filtres de date
      int page = 1;
      const perPage = 100;
      int totalCount = 0;
      double totalAmount = 0.0;
      int maxPages = 50; // Limiter à 5000 dépenses max
      
      while (page <= maxPages) {
        try {
          final paginated = await _expenseService.getExpensesPaginated(
            page: page,
            perPage: perPage,
          );
          
          // Filtrer par période côté client (en attendant le support backend)
          final filtered = paginated.data.where((d) {
            final date = d.expenseDate;
            return date.isAfter(
                  startDate.value.subtract(const Duration(days: 1)),
                ) &&
                date.isBefore(endDate.value.add(const Duration(days: 1)));
          }).toList();
          
          totalCount += filtered.length;
          totalAmount += filtered.fold(0.0, (sum, d) => sum + d.amount);
          
          if (!paginated.hasNextPage) break;
          page++;
        } catch (e) {
          // Si erreur, essayer fallback
          if (page == 1) {
            final depenses = await _expenseService.getExpenses();
            final filtered = depenses.where((d) {
              final date = d.expenseDate;
              return date.isAfter(
                    startDate.value.subtract(const Duration(days: 1)),
                  ) &&
                  date.isBefore(endDate.value.add(const Duration(days: 1)));
            }).toList();
            depensesCount.value = filtered.length;
            depensesTotal.value = filtered.fold(0.0, (sum, d) => sum + d.amount);
            return;
          }
          break;
        }
      }
      
      depensesCount.value = totalCount;
      depensesTotal.value = totalAmount;
    } catch (e) {
      depensesCount.value = 0;
      depensesTotal.value = 0.0;
    }
  }

  Future<void> _loadSalairesStats() async {
    try {
      // OPTIMISATION : Utiliser la pagination avec filtres de date
      int page = 1;
      const perPage = 100;
      int totalCount = 0;
      double totalAmount = 0.0;
      int maxPages = 50; // Limiter à 5000 salaires max
      
      while (page <= maxPages) {
        try {
          final paginated = await _salaryService.getSalariesPaginated(
            page: page,
            perPage: perPage,
          );
          
          // Filtrer par période côté client (en attendant le support backend)
          final filtered = paginated.data.where((s) {
            final date = s.createdAt ?? DateTime.now();
            return date.isAfter(
                  startDate.value.subtract(const Duration(days: 1)),
                ) &&
                date.isBefore(endDate.value.add(const Duration(days: 1)));
          }).toList();
          
          totalCount += filtered.length;
          totalAmount += filtered.fold(0.0, (sum, s) => sum + s.netSalary);
          
          if (!paginated.hasNextPage) break;
          page++;
        } catch (e) {
          // Si erreur, essayer fallback
          if (page == 1) {
            final salaires = await _salaryService.getSalaries();
            final filtered = salaires.where((s) {
              final date = s.createdAt ?? DateTime.now();
              return date.isAfter(
                    startDate.value.subtract(const Duration(days: 1)),
                  ) &&
                  date.isBefore(endDate.value.add(const Duration(days: 1)));
            }).toList();
            salairesCount.value = filtered.length;
            salairesTotal.value = filtered.fold(0.0, (sum, s) => sum + s.netSalary);
            return;
          }
          break;
        }
      }
      
      salairesCount.value = totalCount;
      salairesTotal.value = totalAmount;
    } catch (e) {
      salairesCount.value = 0;
      salairesTotal.value = 0.0;
    }
  }
}
