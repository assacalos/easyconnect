import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/services/invoice_service.dart';
import 'package:easyconnect/services/payment_service.dart';
import 'package:easyconnect/services/employee_service.dart';
import 'package:easyconnect/services/supplier_service.dart';
import 'package:easyconnect/services/stock_service.dart';

class GlobalSearchController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  final RxBool hasNoResults = false.obs;

  // Résultats de recherche
  final RxList<dynamic> clientsResults = <dynamic>[].obs;
  final RxList<dynamic> invoicesResults = <dynamic>[].obs;
  final RxList<dynamic> paymentsResults = <dynamic>[].obs;
  final RxList<dynamic> employeesResults = <dynamic>[].obs;
  final RxList<dynamic> suppliersResults = <dynamic>[].obs;
  final RxList<dynamic> stocksResults = <dynamic>[].obs;

  // Services
  final ClientService _clientService = Get.find<ClientService>();
  final InvoiceService _invoiceService = Get.find<InvoiceService>();
  final PaymentService _paymentService = Get.find<PaymentService>();
  final EmployeeService _employeeService = Get.find<EmployeeService>();
  final SupplierService _supplierService = Get.find<SupplierService>();
  final StockService _stockService = Get.find<StockService>();

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> performSearch(String query) async {
    if (query.trim().isEmpty) {
      clearResults();
      return;
    }

    isSearching.value = true;
    hasNoResults.value = false;

    try {
      // Recherche parallèle dans toutes les entités
      await Future.wait([
        _searchClients(query),
        _searchInvoices(query),
        _searchPayments(query),
        _searchEmployees(query),
        _searchSuppliers(query),
        _searchStocks(query),
      ]);

      // Vérifier s'il y a des résultats
      final totalResults =
          clientsResults.length +
          invoicesResults.length +
          paymentsResults.length +
          employeesResults.length +
          suppliersResults.length +
          stocksResults.length;

      hasNoResults.value = totalResults == 0;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la recherche: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> _searchClients(String query) async {
    try {
      final clients = await _clientService.getClients();
      final queryLower = query.toLowerCase();
      clientsResults.value =
          clients
              .where((client) {
                final nomEntreprise =
                    (client.nomEntreprise ?? '').toLowerCase();
                final nom = (client.nom ?? '').toLowerCase();
                final prenom = (client.prenom ?? '').toLowerCase();
                final email = (client.email ?? '').toLowerCase();
                final contact = (client.contact ?? '').toLowerCase();
                // Prioriser la recherche dans nom entreprise
                return nomEntreprise.contains(queryLower) ||
                    nom.contains(queryLower) ||
                    prenom.contains(queryLower) ||
                    email.contains(queryLower) ||
                    contact.contains(queryLower);
              })
              .take(10) // Limiter à 10 résultats
              .toList();
    } catch (e) {
      clientsResults.clear();
    }
  }

  Future<void> _searchInvoices(String query) async {
    try {
      final invoices = await _invoiceService.getAllInvoices();
      final queryLower = query.toLowerCase();
      invoicesResults.value =
          invoices
              .where((invoice) {
                final invoiceNumber = invoice.invoiceNumber.toLowerCase();
                final clientName = invoice.clientName.toLowerCase();
                return invoiceNumber.contains(queryLower) ||
                    clientName.contains(queryLower);
              })
              .take(10)
              .toList();
    } catch (e) {
      invoicesResults.clear();
    }
  }

  Future<void> _searchPayments(String query) async {
    try {
      final payments = await _paymentService.getAllPayments();
      final queryLower = query.toLowerCase();
      paymentsResults.value =
          payments
              .where((payment) {
                final reference = payment.reference?.toLowerCase() ?? '';
                final clientName = payment.clientName.toLowerCase();
                return reference.contains(queryLower) ||
                    clientName.contains(queryLower);
              })
              .take(10)
              .toList();
    } catch (e) {
      paymentsResults.clear();
    }
  }

  Future<void> _searchEmployees(String query) async {
    try {
      final employees = await _employeeService.getEmployees();
      final queryLower = query.toLowerCase();
      employeesResults.value =
          employees
              .where((employee) {
                final firstName = employee.firstName.toLowerCase();
                final lastName = employee.lastName.toLowerCase();
                final email = employee.email.toLowerCase();
                final fullName = '$firstName $lastName'.toLowerCase();
                return fullName.contains(queryLower) ||
                    email.contains(queryLower);
              })
              .take(10)
              .toList();
    } catch (e) {
      employeesResults.clear();
    }
  }

  Future<void> _searchSuppliers(String query) async {
    try {
      final suppliers = await _supplierService.getSuppliers();
      final queryLower = query.toLowerCase();
      suppliersResults.value =
          suppliers
              .where((supplier) {
                final nom = supplier.nom.toLowerCase();
                final email = supplier.email.toLowerCase();
                final telephone = supplier.telephone.toLowerCase();
                return nom.contains(queryLower) ||
                    email.contains(queryLower) ||
                    telephone.contains(queryLower);
              })
              .take(10)
              .toList();
    } catch (e) {
      suppliersResults.clear();
    }
  }

  Future<void> _searchStocks(String query) async {
    try {
      final stocks = await _stockService.getStocks();
      final queryLower = query.toLowerCase();
      stocksResults.value =
          stocks
              .where((stock) {
                final name = stock.name.toLowerCase();
                final sku = stock.sku.toLowerCase();
                final category = stock.category.toLowerCase();
                return name.contains(queryLower) ||
                    sku.contains(queryLower) ||
                    category.contains(queryLower);
              })
              .take(10)
              .toList();
    } catch (e) {
      stocksResults.clear();
    }
  }

  void clearResults() {
    clientsResults.clear();
    invoicesResults.clear();
    paymentsResults.clear();
    employeesResults.clear();
    suppliersResults.clear();
    stocksResults.clear();
    hasNoResults.value = false;
  }
}
