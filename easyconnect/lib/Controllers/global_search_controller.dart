import 'package:flutter/material.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/services/invoice_service.dart';
import 'package:easyconnect/services/payment_service.dart';
import 'package:easyconnect/services/employee_service.dart';
import 'package:easyconnect/services/supplier_service.dart';
import 'package:easyconnect/services/stock_service.dart';
import 'package:easyconnect/utils/error_helper.dart';

class GlobalSearchController {
  static final GlobalSearchController _instance = GlobalSearchController._();
  static GlobalSearchController get to => _instance;
  factory GlobalSearchController() => _instance;
  GlobalSearchController._();

  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool isSearching = false;
  bool hasNoResults = false;

  final List<dynamic> clientsResults = [];
  final List<dynamic> invoicesResults = [];
  final List<dynamic> paymentsResults = [];
  final List<dynamic> employeesResults = [];
  final List<dynamic> suppliersResults = [];
  final List<dynamic> stocksResults = [];

  final ClientService _clientService = ClientService();
  final InvoiceService _invoiceService = InvoiceService.to;
  final PaymentService _paymentService = PaymentService.to;
  final EmployeeService _employeeService = EmployeeService.to;
  final SupplierService _supplierService = SupplierService.to;
  final StockService _stockService = StockService.to;

  void dispose() {
    searchController.dispose();
  }

  Future<void> performSearch(String query) async {
    if (query.trim().isEmpty) {
      clearResults();
      return;
    }

    isSearching = true;
    hasNoResults = false;

    try {
      await Future.wait([
        _searchClients(query),
        _searchInvoices(query),
        _searchPayments(query),
        _searchEmployees(query),
        _searchSuppliers(query),
        _searchStocks(query),
      ]);

      final totalResults =
          clientsResults.length +
          invoicesResults.length +
          paymentsResults.length +
          employeesResults.length +
          suppliersResults.length +
          stocksResults.length;

      hasNoResults = totalResults == 0;
    } catch (e) {
      ErrorHelper.showError('Erreur lors de la recherche: $e', title: 'Erreur');
    } finally {
      isSearching = false;
    }
  }

  Future<void> _searchClients(String query) async {
    try {
      final clients = await _clientService.getClients();
      final queryLower = query.toLowerCase();
      clientsResults.clear();
      clientsResults.addAll(
          clients
              .where((client) {
                final nomEntreprise =
                    (client.nomEntreprise ?? '').toLowerCase();
                final nom = (client.nom ?? '').toLowerCase();
                final prenom = (client.prenom ?? '').toLowerCase();
                final email = (client.email ?? '').toLowerCase();
                final contact = (client.contact ?? '').toLowerCase();
                return nomEntreprise.contains(queryLower) ||
                    nom.contains(queryLower) ||
                    prenom.contains(queryLower) ||
                    email.contains(queryLower) ||
                    contact.contains(queryLower);
              })
              .take(10)
              .toList());
    } catch (e) {
      clientsResults.clear();
    }
  }

  Future<void> _searchInvoices(String query) async {
    try {
      final invoices = await _invoiceService.getAllInvoices();
      final queryLower = query.toLowerCase();
      invoicesResults.clear();
      invoicesResults.addAll(
          invoices
              .where((invoice) {
                final invoiceNumber = invoice.invoiceNumber.toLowerCase();
                final clientName = invoice.clientName.toLowerCase();
                return invoiceNumber.contains(queryLower) ||
                    clientName.contains(queryLower);
              })
              .take(10)
              .toList());
    } catch (e) {
      invoicesResults.clear();
    }
  }

  Future<void> _searchPayments(String query) async {
    try {
      final payments = await _paymentService.getAllPayments();
      final queryLower = query.toLowerCase();
      paymentsResults.clear();
      paymentsResults.addAll(
          payments
              .where((payment) {
                final reference = payment.reference?.toLowerCase() ?? '';
                final clientName = payment.clientName.toLowerCase();
                return reference.contains(queryLower) ||
                    clientName.contains(queryLower);
              })
              .take(10)
              .toList());
    } catch (e) {
      paymentsResults.clear();
    }
  }

  Future<void> _searchEmployees(String query) async {
    try {
      final employees = await _employeeService.getEmployees();
      final queryLower = query.toLowerCase();
      employeesResults.clear();
      employeesResults.addAll(
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
              .toList());
    } catch (e) {
      employeesResults.clear();
    }
  }

  Future<void> _searchSuppliers(String query) async {
    try {
      final suppliers = await _supplierService.getSuppliers();
      final queryLower = query.toLowerCase();
      suppliersResults.clear();
      suppliersResults.addAll(
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
              .toList());
    } catch (e) {
      suppliersResults.clear();
    }
  }

  Future<void> _searchStocks(String query) async {
    try {
      final stocks = await _stockService.getStocks();
      final queryLower = query.toLowerCase();
      stocksResults.clear();
      stocksResults.addAll(
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
              .toList());
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
    hasNoResults = false;
  }
}
