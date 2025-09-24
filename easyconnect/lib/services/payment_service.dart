import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:easyconnect/Models/payment_model.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/constant.dart';

class PaymentService extends GetxService {
  static PaymentService get to => Get.find();

  // Créer un paiement
  Future<Map<String, dynamic>> createPayment({
    required int clientId,
    required String clientName,
    required String clientEmail,
    required String clientAddress,
    required int comptableId,
    required String comptableName,
    required String type, // 'one_time' ou 'monthly'
    required DateTime paymentDate,
    DateTime? dueDate,
    required double amount,
    required String paymentMethod,
    String? description,
    String? notes,
    String? reference,
    PaymentSchedule? schedule, // Pour les paiements mensuels
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'client_id': clientId,
          'client_name': clientName,
          'client_email': clientEmail,
          'client_address': clientAddress,
          'comptable_id': comptableId,
          'comptable_name': comptableName,
          'type': type,
          'payment_date': paymentDate.toIso8601String(),
          'due_date': dueDate?.toIso8601String(),
          'amount': amount,
          'payment_method': paymentMethod,
          'description': description,
          'notes': notes,
          'reference': reference,
          'schedule': schedule?.toJson(),
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la création du paiement: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur PaymentService.createPayment: $e');
      rethrow;
    }
  }

  // Récupérer les paiements d'un comptable
  Future<List<PaymentModel>> getComptablePayments({
    required int comptableId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? type,
  }) async {
    try {
      String url = '$baseUrl/payments/comptable/$comptableId';
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
      if (type != null) {
        params.add('type=$type');
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
            .map((json) => PaymentModel.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des paiements: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur PaymentService.getComptablePayments: $e');
      rethrow;
    }
  }

  // Récupérer tous les paiements (pour le patron)
  Future<List<PaymentModel>> getAllPayments({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? type,
  }) async {
    try {
      String url = '$baseUrl/payments';
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
      if (type != null) {
        params.add('type=$type');
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
            .map((json) => PaymentModel.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des paiements: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur PaymentService.getAllPayments: $e');
      rethrow;
    }
  }

  // Récupérer un paiement par ID
  Future<PaymentModel> getPaymentById(int paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payments/$paymentId'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentModel.fromJson(data['data']);
      } else {
        throw Exception(
          'Erreur lors de la récupération du paiement: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur PaymentService.getPaymentById: $e');
      rethrow;
    }
  }

  // Mettre à jour un paiement
  Future<Map<String, dynamic>> updatePayment({
    required int paymentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/payments/$paymentId'),
        headers: ApiService.headers(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la mise à jour du paiement: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur PaymentService.updatePayment: $e');
      rethrow;
    }
  }

  // Soumettre un paiement au patron
  Future<Map<String, dynamic>> submitPaymentToPatron(int paymentId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/payments/$paymentId/submit'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la soumission du paiement: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur PaymentService.submitPaymentToPatron: $e');
      rethrow;
    }
  }

  // Approuver un paiement (pour le patron)
  Future<Map<String, dynamic>> approvePayment(
    int paymentId, {
    String? comments,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/payments/$paymentId/approve'),
        headers: ApiService.headers(),
        body: jsonEncode({'comments': comments}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'approbation du paiement: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur PaymentService.approvePayment: $e');
      rethrow;
    }
  }

  // Rejeter un paiement (pour le patron)
  Future<Map<String, dynamic>> rejectPayment(
    int paymentId, {
    required String reason,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/payments/$paymentId/reject'),
        headers: ApiService.headers(),
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors du rejet du paiement: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur PaymentService.rejectPayment: $e');
      rethrow;
    }
  }

  // Marquer un paiement comme payé
  Future<Map<String, dynamic>> markAsPaid(
    int paymentId, {
    String? paymentReference,
    String? notes,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/payments/$paymentId/mark-paid'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'payment_reference': paymentReference,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors du marquage du paiement: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur PaymentService.markAsPaid: $e');
      rethrow;
    }
  }

  // Supprimer un paiement
  Future<Map<String, dynamic>> deletePayment(int paymentId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/payments/$paymentId'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la suppression du paiement: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur PaymentService.deletePayment: $e');
      rethrow;
    }
  }

  // Récupérer les statistiques de paiements
  Future<PaymentStats> getPaymentStats({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
  }) async {
    try {
      String url = '$baseUrl/payments/stats';
      List<String> params = [];

      if (startDate != null) {
        params.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        params.add('end_date=${endDate.toIso8601String()}');
      }
      if (type != null) {
        params.add('type=$type');
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
        return PaymentStats.fromJson(data);
      } else {
        throw Exception(
          'Erreur lors de la récupération des statistiques: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur PaymentService.getPaymentStats: $e');
      rethrow;
    }
  }

  // Récupérer les paiements en attente d'approbation
  Future<List<PaymentModel>> getPendingPayments() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payments/pending'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((json) => PaymentModel.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des paiements en attente: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur PaymentService.getPendingPayments: $e');
      rethrow;
    }
  }

  // Générer un numéro de paiement
  Future<String> generatePaymentNumber() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payments/generate-number'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['payment_number'];
      } else {
        throw Exception(
          'Erreur lors de la génération du numéro: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur PaymentService.generatePaymentNumber: $e');
      rethrow;
    }
  }

  // Récupérer les modèles de paiement
  Future<List<PaymentTemplate>> getPaymentTemplates() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payments/templates'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((json) => PaymentTemplate.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des modèles: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur PaymentService.getPaymentTemplates: $e');
      rethrow;
    }
  }

  // Pause/Reprendre un paiement mensuel
  Future<Map<String, dynamic>> togglePaymentSchedule(
    int paymentId, {
    required String action, // 'pause', 'resume', 'cancel'
    String? reason,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/payments/$paymentId/schedule'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'action': action,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la modification du planning: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur PaymentService.togglePaymentSchedule: $e');
      rethrow;
    }
  }
}
