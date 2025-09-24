import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:easyconnect/Models/invoice_model.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/constant.dart';

class InvoiceService extends GetxService {
  static InvoiceService get to => Get.find();

  // Créer une facture
  Future<Map<String, dynamic>> createInvoice({
    required int clientId,
    required String clientName,
    required String clientEmail,
    required String clientAddress,
    required int commercialId,
    required String commercialName,
    required DateTime invoiceDate,
    required DateTime dueDate,
    required List<InvoiceItem> items,
    required double taxRate,
    String? notes,
    String? terms,
  }) async {
    try {
      // Calculer les montants
      final subtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
      final taxAmount = subtotal * (taxRate / 100);
      final totalAmount = subtotal + taxAmount;

      final response = await http.post(
        Uri.parse('$baseUrl/invoices'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'client_id': clientId,
          'client_name': clientName,
          'client_email': clientEmail,
          'client_address': clientAddress,
          'commercial_id': commercialId,
          'commercial_name': commercialName,
          'invoice_date': invoiceDate.toIso8601String(),
          'due_date': dueDate.toIso8601String(),
          'items': items.map((item) => item.toJson()).toList(),
          'subtotal': subtotal,
          'tax_rate': taxRate,
          'tax_amount': taxAmount,
          'total_amount': totalAmount,
          'notes': notes,
          'terms': terms,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la création de la facture: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur InvoiceService.createInvoice: $e');
      rethrow;
    }
  }

  // Récupérer les factures d'un comptable
  Future<List<InvoiceModel>> getCommercialInvoices({
    required int commercialId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      String url = '$baseUrl/invoices/comptable/$commercialId';
      List<String> params = [];

      if (startDate != null) {
        params.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        params.add('end_date=${endDate.toIso8601String()}');
      }
      if (status != null) {
        params.add('status=$status');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((json) => InvoiceModel.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des factures: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur InvoiceService.getCommercialInvoices: $e');
      rethrow;
    }
  }

  // Récupérer toutes les factures (pour le patron)
  Future<List<InvoiceModel>> getAllInvoices({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int? commercialId,
    int? clientId,
  }) async {
    try {
      String url = '$baseUrl/invoices';
      List<String> params = [];

      if (startDate != null) {
        params.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        params.add('end_date=${endDate.toIso8601String()}');
      }
      if (status != null) {
        params.add('status=$status');
      }
      if (commercialId != null) {
        params.add('commercial_id=$commercialId');
      }
      if (clientId != null) {
        params.add('client_id=$clientId');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((json) => InvoiceModel.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des factures: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur InvoiceService.getAllInvoices: $e');
      rethrow;
    }
  }

  // Récupérer une facture par ID
  Future<InvoiceModel> getInvoiceById(int invoiceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/invoices/$invoiceId'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return InvoiceModel.fromJson(data['data']);
      } else {
        throw Exception(
          'Erreur lors de la récupération de la facture: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur InvoiceService.getInvoiceById: $e');
      rethrow;
    }
  }

  // Mettre à jour une facture
  Future<Map<String, dynamic>> updateInvoice({
    required int invoiceId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/invoices/$invoiceId'),
        headers: ApiService.headers(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la mise à jour de la facture: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur InvoiceService.updateInvoice: $e');
      rethrow;
    }
  }

  // Soumettre une facture au patron
  Future<Map<String, dynamic>> submitInvoiceToPatron(int invoiceId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/invoices/$invoiceId/submit'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la soumission de la facture: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur InvoiceService.submitInvoiceToPatron: $e');
      rethrow;
    }
  }

  // Approuver une facture (pour le patron)
  Future<Map<String, dynamic>> approveInvoice({
    required int invoiceId,
    String? comments,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/invoices/$invoiceId/approve'),
        headers: ApiService.headers(),
        body: jsonEncode({'comments': comments}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'approbation de la facture: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur InvoiceService.approveInvoice: $e');
      rethrow;
    }
  }

  // Rejeter une facture (pour le patron)
  Future<Map<String, dynamic>> rejectInvoice({
    required int invoiceId,
    required String reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/invoices/$invoiceId/reject'),
        headers: ApiService.headers(),
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors du rejet de la facture: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur InvoiceService.rejectInvoice: $e');
      rethrow;
    }
  }

  // Envoyer une facture par email
  Future<Map<String, dynamic>> sendInvoiceByEmail({
    required int invoiceId,
    required String email,
    String? message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/invoices/$invoiceId/send'),
        headers: ApiService.headers(),
        body: jsonEncode({'email': email, 'message': message}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'envoi de la facture: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur InvoiceService.sendInvoiceByEmail: $e');
      rethrow;
    }
  }

  // Marquer une facture comme payée
  Future<Map<String, dynamic>> markInvoiceAsPaid({
    required int invoiceId,
    required PaymentInfo paymentInfo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/invoices/$invoiceId/pay'),
        headers: ApiService.headers(),
        body: jsonEncode(paymentInfo.toJson()),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors du paiement de la facture: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur InvoiceService.markInvoiceAsPaid: $e');
      rethrow;
    }
  }

  // Supprimer une facture
  Future<Map<String, dynamic>> deleteInvoice(int invoiceId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/invoices/$invoiceId'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la suppression de la facture: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur InvoiceService.deleteInvoice: $e');
      rethrow;
    }
  }

  // Récupérer les statistiques de facturation
  Future<InvoiceStats> getInvoiceStats({
    DateTime? startDate,
    DateTime? endDate,
    int? commercialId,
  }) async {
    try {
      String url = '$baseUrl/invoices/stats';
      List<String> params = [];

      if (startDate != null) {
        params.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        params.add('end_date=${endDate.toIso8601String()}');
      }
      if (commercialId != null) {
        params.add('commercial_id=$commercialId');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return InvoiceStats.fromJson(data);
      } else {
        throw Exception(
          'Erreur lors de la récupération des statistiques: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur InvoiceService.getInvoiceStats: $e');
      rethrow;
    }
  }

  // Récupérer les factures en attente d'approbation (pour le patron)
  Future<List<InvoiceModel>> getPendingInvoices() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/invoices/pending'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((json) => InvoiceModel.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des factures en attente: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur InvoiceService.getPendingInvoices: $e');
      rethrow;
    }
  }

  // Générer un numéro de facture
  Future<String> generateInvoiceNumber() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/invoices/generate-number'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['invoice_number'];
      } else {
        throw Exception(
          'Erreur lors de la génération du numéro: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur InvoiceService.generateInvoiceNumber: $e');
      rethrow;
    }
  }

  // Récupérer les modèles de facture
  Future<List<InvoiceTemplate>> getInvoiceTemplates() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/invoices/templates'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((json) => InvoiceTemplate.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des modèles: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur InvoiceService.getInvoiceTemplates: $e');
      rethrow;
    }
  }
}
