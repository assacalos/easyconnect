import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/payment_model.dart';
import 'package:easyconnect/Models/pagination_response.dart';
import 'package:easyconnect/utils/constant.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';
import 'package:easyconnect/utils/pagination_helper.dart';

class PaymentService extends GetxService {
  static PaymentService get to => Get.find();
  final storage = GetStorage();

  // ===== MÉTHODES DE CONNECTIVITÉ =====

  // Tester la connectivité à l'API pour les paiements
  Future<bool> testPaymentConnection() async {
    try {
      final token = storage.read('token');

      final response = await http
          .get(
            Uri.parse('$baseUrl/payments'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      final result = ApiService.parseResponse(response);
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // ===== MÉTHODES PRINCIPALES DES PAIEMENTS =====

  /// Récupérer les paiements avec pagination côté serveur (pour le patron)
  Future<PaginationResponse<PaymentModel>> getAllPaymentsPaginated({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? type,
    int page = 1,
    int perPage = 15,
    String? search,
  }) async {
    try {
      final token = storage.read('token');
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
      if (search != null && search.isNotEmpty) {
        params.add('search=$search');
      }
      // Ajouter la pagination
      params.add('page=$page');
      params.add('per_page=$perPage');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      AppLogger.httpRequest('GET', url, tag: 'PAYMENT_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => http.get(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
            ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'PAYMENT_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PaginationHelper.parseResponse<PaymentModel>(
          json: data,
          fromJsonT: (json) => PaymentModel.fromJson(json),
        );
      } else {
        throw Exception(
          'Erreur lors de la récupération paginée des paiements: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Erreur dans getAllPaymentsPaginated: $e',
        tag: 'PAYMENT_SERVICE',
      );
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
      final token = storage.read('token');

      // Essayer d'abord /paiements-list, puis /payments en fallback
      String url = '$baseUrl/paiements-list';
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

      http.Response response;
      try {
        response = await http.get(
          Uri.parse(url),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (e) {
        // Si /paiements-list échoue, essayer /payments
        url = url.replaceAll('/paiements-list', '/payments');
        response = await http.get(
          Uri.parse(url),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        try {
          final responseData = result['data'];
          List<dynamic> data = [];

          // Gérer différents formats de réponse
          if (responseData is List) {
            data = responseData;
          } else if (responseData is Map && responseData['data'] != null) {
            if (responseData['data'] is List) {
              data = responseData['data'];
            } else if (responseData['data']['data'] != null &&
                responseData['data']['data'] is List) {
              data = responseData['data']['data'];
            }
          } else if (responseData['paiements'] != null) {
            if (responseData['paiements'] is List) {
              data = responseData['paiements'];
            }
          } else if (responseData['payments'] != null) {
            if (responseData['payments'] is List) {
              data = responseData['payments'];
            }
          } else if (responseData['success'] == true) {
            if (responseData['data'] != null && responseData['data'] is List) {
              data = responseData['data'];
            } else if (responseData['paiements'] != null &&
                responseData['paiements'] is List) {
              data = responseData['paiements'];
            } else if (responseData['payments'] != null &&
                responseData['payments'] is List) {
              data = responseData['payments'];
            }
          }

          return data.map((json) => PaymentModel.fromJson(json)).toList();
        } catch (e) {
          return [];
        }
      } else {
        throw Exception(
          'Erreur lors de la récupération des paiements: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer un paiement par ID
  Future<PaymentModel> getPaymentById(int paymentId) async {
    try {
      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/payments/$paymentId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return PaymentModel.fromJson(result['data']);
      } else {
        throw Exception(
          result['message'] ?? 'Erreur lors de la récupération du paiement',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Récupérer les paiements d'un comptable avec pagination
  Future<PaginationResponse<PaymentModel>> getComptablePaymentsPaginated({
    required int comptableId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? type,
    int page = 1,
    int perPage = 15,
    String? search,
  }) async {
    try {
      final token = storage.read('token');
      String url = '$baseUrl/payments';
      List<String> params = [];

      params.add('comptable_id=$comptableId');
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
      if (search != null && search.isNotEmpty) {
        params.add('search=$search');
      }
      // Ajouter la pagination
      params.add('page=$page');
      params.add('per_page=$perPage');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      AppLogger.httpRequest('GET', url, tag: 'PAYMENT_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => http.get(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
            ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'PAYMENT_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PaginationHelper.parseResponse<PaymentModel>(
          json: data,
          fromJsonT: (json) => PaymentModel.fromJson(json),
        );
      } else {
        throw Exception(
          'Erreur lors de la récupération paginée des paiements comptable: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Erreur dans getComptablePaymentsPaginated: $e',
        tag: 'PAYMENT_SERVICE',
      );
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
      final token = storage.read('token');

      // Utiliser la nouvelle route organisée
      String url = '$baseUrl/payments';
      List<String> params = [];

      params.add('comptable_id=$comptableId');
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
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        try {
          final responseData = result['data'];

          // Gérer différents formats de réponse de l'API Laravel
          List<dynamic> data = [];

          // Essayer d'abord le format standard Laravel
          if (responseData['data'] != null) {
            if (responseData['data'] is List) {
              data = responseData['data'];
            } else if (responseData['data']['data'] != null) {
              data = responseData['data']['data'];
            }
          }
          // Essayer le format spécifique aux paiements
          else if (responseData['paiements'] != null) {
            if (responseData['paiements'] is List) {
              data = responseData['paiements'];
            }
          }
          // Essayer le format avec success
          else if (responseData['success'] == true &&
              responseData['paiements'] != null) {
            if (responseData['paiements'] is List) {
              data = responseData['paiements'];
            }
          }
          if (data.isEmpty) {
            // Retourner une liste vide au lieu de lever une exception
            return [];
          }

          try {
            return data.map((json) {
              return PaymentModel.fromJson(json);
            }).toList();
          } catch (e) {
            rethrow;
          }
        } catch (e) {
          // Essayer de nettoyer les caractères invalides
          try {
            String cleanedBody =
                response.body
                    .replaceAll(
                      RegExp(r'[\x00-\x1F\x7F-\x9F]'),
                      '',
                    ) // Supprimer les caractères de contrôle
                    .replaceAll(
                      RegExp(r'\\[^"\\/bfnrt]'),
                      '',
                    ) // Supprimer les échappements invalides
                    .replaceAll(
                      RegExp(r'[^\x20-\x7E]'),
                      '',
                    ) // Supprimer tous les caractères non-ASCII
                    .trim();
            // Vérifier si le JSON nettoyé est valide
            if (cleanedBody.isEmpty) {
              return [];
            }

            final responseData = jsonDecode(cleanedBody);

            // Continuer avec le parsing normal
            List<dynamic> data = [];
            if (responseData['data'] != null) {
              if (responseData['data'] is List) {
                data = responseData['data'];
              } else if (responseData['data']['data'] != null) {
                data = responseData['data']['data'];
              }
            } else if (responseData['paiements'] != null) {
              if (responseData['paiements'] is List) {
                data = responseData['paiements'];
              }
            } else if (responseData['success'] == true &&
                responseData['paiements'] != null) {
              if (responseData['paiements'] is List) {
                data = responseData['paiements'];
              }
            }

            if (data.isEmpty) {
              return [];
            }

            return data.map((json) => PaymentModel.fromJson(json)).toList();
          } catch (cleanError) {
            // Dernière tentative : essayer de parser seulement une partie de la réponse
            try {
              // Essayer de trouver le début d'un JSON valide
              int startIndex = response.body.indexOf('{');
              int endIndex = response.body.lastIndexOf('}');

              if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
                String partialJson = response.body.substring(
                  startIndex,
                  endIndex + 1,
                );

                final responseData = jsonDecode(partialJson);

                // Essayer de récupérer les données
                List<dynamic> data = [];
                if (responseData['data'] != null &&
                    responseData['data'] is List) {
                  data = responseData['data'];
                } else if (responseData['paiements'] != null &&
                    responseData['paiements'] is List) {
                  data = responseData['paiements'];
                }

                if (data.isNotEmpty) {
                  return data
                      .map((json) => PaymentModel.fromJson(json))
                      .toList();
                }
              }

              return [];
            } catch (partialError) {
              throw Exception('Erreur de format des données: $e');
            }
          }
        }
      } else {
        throw Exception(
          'Erreur lors de la récupération des paiements: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // ===== ACTIONS SUR LES PAIEMENTS =====

  // Approuver un paiement
  Future<Map<String, dynamic>> approvePayment(
    int paymentId, {
    String? comments,
  }) async {
    try {
      final token = storage.read('token');

      // Essayer d'abord la route française (POST)
      String url = '$baseUrl/paiements-validate/$paymentId';
      http.Response response;

      try {
        response = await http.post(
          Uri.parse(url),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: comments != null ? jsonEncode({'comments': comments}) : '{}',
        );
      } catch (e) {
        // Si la route française échoue, essayer la route anglaise (PATCH)
        url = '$baseUrl/payments/$paymentId/approve';
        response = await http.patch(
          Uri.parse(url),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: comments != null ? jsonEncode({'comments': comments}) : null,
        );
      }
      // Si le status code est 200 ou 201, considérer comme succès
      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = ApiService.parseResponse(response);
        // Si le parseResponse retourne success:false mais le status code est 200/201,
        // forcer success:true car le backend a validé
        if (result['success'] == true) {
          return result['data'] ?? {};
        } else {
          // Status code 200/201 mais success:false dans le body -> considérer comme succès
          return {'success': true, 'message': 'Paiement approuvé avec succès'};
        }
      }

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return result['data'] ?? {};
      }

      throw Exception(result['message'] ?? 'Erreur lors de l\'approbation');
    } catch (e) {
      rethrow;
    }
  }

  // Rejeter un paiement
  Future<Map<String, dynamic>> rejectPayment(
    int paymentId, {
    String? reason,
  }) async {
    try {
      final token = storage.read('token');

      // Essayer d'abord la route française (POST)
      String url = '$baseUrl/paiements-reject/$paymentId';
      http.Response response;

      try {
        response = await http.post(
          Uri.parse(url),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: reason != null ? jsonEncode({'reason': reason}) : '{}',
        );
      } catch (e) {
        // Si la route française échoue, essayer la route anglaise (PATCH)
        url = '$baseUrl/payments/$paymentId/reject';
        response = await http.patch(
          Uri.parse(url),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: reason != null ? jsonEncode({'reason': reason}) : null,
        );
      }
      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return result['data'] ?? {};
      }

      throw Exception(result['message'] ?? 'Erreur lors du rejet');
    } catch (e) {
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
      final token = storage.read('token');
      final response = await http.patch(
        Uri.parse('$baseUrl/payments/$paymentId/mark-paid'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'payment_reference': paymentReference,
          'notes': notes,
        }),
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return result['data'] ?? {};
      } else {
        throw Exception(result['message'] ?? 'Erreur lors du marquage');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Réactiver un paiement rejeté
  Future<Map<String, dynamic>> reactivatePayment(int paymentId) async {
    try {
      final token = storage.read('token');
      final response = await http.patch(
        Uri.parse('$baseUrl/payments/$paymentId/reactivate'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return result['data'] ?? {};
      } else {
        throw Exception(result['message'] ?? 'Erreur lors de la réactivation');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ===== MÉTHODES POUR LES PLANNINGS DE PAIEMENT =====

  // Récupérer les plannings de paiement
  Future<List<Map<String, dynamic>>> getPaymentSchedules() async {
    try {
      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/payment-schedules'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        final data = result['data'];
        if (data is Map && data['schedules'] != null) {
          return List<Map<String, dynamic>>.from(data['schedules']);
        }
        return [];
      } else {
        throw Exception(
          result['message'] ?? 'Erreur lors de la récupération des plannings',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Mettre en pause un planning
  Future<Map<String, dynamic>> pauseSchedule(int scheduleId) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/payment-schedules/$scheduleId/pause'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors de la pause: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Reprendre un planning
  Future<Map<String, dynamic>> resumeSchedule(int scheduleId) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/payment-schedules/$scheduleId/resume'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors de la reprise: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Annuler un planning
  Future<Map<String, dynamic>> cancelSchedule(int scheduleId) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/payment-schedules/$scheduleId/cancel'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors de l\'annulation: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Marquer une échéance comme payée
  Future<Map<String, dynamic>> markInstallmentPaid(
    int scheduleId,
    int installmentId,
  ) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse(
          '$baseUrl/payment-schedules/$scheduleId/installments/$installmentId/mark-paid',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors du marquage de l\'échéance: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // ===== MÉTHODES POUR LES STATISTIQUES =====

  // Récupérer les statistiques des plannings
  Future<Map<String, dynamic>> getScheduleStats() async {
    try {
      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/payment-stats/schedules'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la récupération des statistiques des plannings: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les paiements à venir
  Future<List<Map<String, dynamic>>> getUpcomingPayments() async {
    try {
      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/payment-stats/upcoming'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['payments'] ?? []);
      } else {
        throw Exception(
          'Erreur lors de la récupération des paiements à venir: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les paiements en retard
  Future<List<Map<String, dynamic>>> getOverduePayments() async {
    try {
      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/payment-stats/overdue'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['payments'] ?? []);
      } else {
        throw Exception(
          'Erreur lors de la récupération des paiements en retard: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // ===== MÉTHODES COMPATIBILITÉ =====

  // Créer un paiement
  Future<Map<String, dynamic>> createPayment({
    required int clientId,
    required String clientName,
    required String clientEmail,
    required String clientAddress,
    required int comptableId,
    required String comptableName,
    required String type,
    required DateTime paymentDate,
    DateTime? dueDate,
    required double amount,
    required String paymentMethod,
    String? description,
    String? notes,
    String? reference,
    PaymentSchedule? schedule,
  }) async {
    try {
      final token = storage.read('token');

      // Validation des données avant envoi
      if (clientName.trim().isEmpty) {
        throw Exception('Le nom du client est requis');
      }
      if (clientEmail.trim().isEmpty) {
        throw Exception('L\'email du client est requis');
      }
      if (amount <= 0) {
        throw Exception('Le montant doit être supérieur à 0');
      }
      if (paymentMethod.isEmpty) {
        throw Exception('La méthode de paiement est requise');
      }

      // Fonction pour formater les dates au format YYYY-MM-DD (format attendu par Laravel)
      String formatDate(DateTime date) {
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }

      // Préparer les données à envoyer en nettoyant les valeurs null et vides
      final Map<String, dynamic> requestData = {
        'client_name': clientName.trim(),
        'client_email': clientEmail.trim(),
        'client_address': clientAddress.trim(),
        'comptable_id': comptableId,
        'comptable_name': comptableName.trim(),
        'type': type,
        'payment_date': formatDate(paymentDate), // Format YYYY-MM-DD
        'amount': amount.toDouble(), // S'assurer que c'est un double
        'payment_method': paymentMethod,
      };

      // Ajouter client_id seulement s'il est > 0 (certains backends ne acceptent pas 0)
      if (clientId > 0) {
        requestData['client_id'] = clientId;
      }

      // Ajouter les champs optionnels seulement s'ils ne sont pas null ou vides
      if (dueDate != null) {
        requestData['due_date'] = formatDate(dueDate); // Format YYYY-MM-DD
      }

      if (description != null && description.trim().isNotEmpty) {
        requestData['description'] = description.trim();
      }

      if (notes != null && notes.trim().isNotEmpty) {
        requestData['notes'] = notes.trim();
      }

      if (reference != null && reference.trim().isNotEmpty) {
        requestData['reference'] = reference.trim();
      }

      // Ajouter le schedule seulement s'il existe et pour les paiements mensuels
      if (schedule != null && type == 'monthly') {
        try {
          // Créer un schedule selon le format attendu par Laravel
          // Laravel attend : start_date, end_date (optionnel), frequency, total_installments, installment_amount
          final scheduleData = <String, dynamic>{
            'start_date': formatDate(schedule.startDate),
            'frequency': schedule.frequency,
            'total_installments': schedule.totalInstallments,
            'installment_amount': schedule.installmentAmount,
          };

          // end_date est optionnel selon la documentation Laravel
          // Note: schedule.endDate est non-nullable dans PaymentSchedule, mais on peut l'omettre si nécessaire
          scheduleData['end_date'] = formatDate(schedule.endDate);

          // Ajouter created_by si disponible (nécessaire pour certains backends Laravel)
          // Utiliser comptable_id comme created_by pour le schedule
          if (comptableId > 0) {
            scheduleData['created_by'] = comptableId;
          }

          // Note: status et next_payment_date ne sont pas envoyés lors de la création
          // Ils seront générés par Laravel

          requestData['schedule'] = scheduleData;

          AppLogger.debug(
            'Schedule ajouté: $scheduleData',
            tag: 'PAYMENT_SERVICE',
          );

          // Validation supplémentaire des données du schedule
          final startDateStr = scheduleData['start_date'] as String?;
          final endDateStr = scheduleData['end_date'] as String?; // Optionnel
          final frequencyValue = scheduleData['frequency'] as int?;
          final totalInstallmentsValue =
              scheduleData['total_installments'] as int?;
          final installmentAmountValue =
              scheduleData['installment_amount'] as double?;

          if (startDateStr == null) {
            throw Exception('La date de début du planning est requise');
          }

          if (frequencyValue == null || frequencyValue <= 0) {
            throw Exception('La fréquence doit être supérieure à 0');
          }

          if (totalInstallmentsValue == null || totalInstallmentsValue <= 0) {
            throw Exception('Le nombre d\'échéances doit être supérieur à 0');
          }

          if (installmentAmountValue == null || installmentAmountValue <= 0) {
            throw Exception('Le montant par échéance doit être supérieur à 0');
          }

          // Vérifier que la date de fin est après la date de début (si fournie)
          if (endDateStr != null) {
            final startDate = DateTime.parse('${startDateStr}T00:00:00');
            final endDate = DateTime.parse('${endDateStr}T00:00:00');
            if (endDate.isBefore(startDate) ||
                endDate.isAtSameMomentAs(startDate)) {
              throw Exception(
                'La date de fin doit être postérieure à la date de début',
              );
            }
          }
        } catch (e) {
          AppLogger.error(
            'Erreur lors de la préparation du schedule: $e',
            tag: 'PAYMENT_SERVICE',
          );
          // Propager l'erreur pour que l'utilisateur soit informé
          throw Exception(
            'Erreur dans les données du planning: ${e.toString().replaceAll('Exception: ', '')}',
          );
        }
      }

      // Log des données avant envoi (print pour être sûr de voir dans la console)
      print('📤 [PAYMENT_SERVICE] Données du paiement à envoyer: $requestData');
      AppLogger.debug(
        'Données du paiement à envoyer: $requestData',
        tag: 'PAYMENT_SERVICE',
      );

      // Log spécifique pour les paiements mensuels
      if (type == 'monthly' && schedule != null) {
        AppLogger.debug(
          'Paiement mensuel - Schedule: ${schedule.toJson()}',
          tag: 'PAYMENT_SERVICE',
        );
      }

      final jsonBody = jsonEncode(requestData);

      // Log du JSON final pour le débogage (print pour être sûr de voir dans la console)
      print('📤 [PAYMENT_SERVICE] JSON final à envoyer: $jsonBody');
      AppLogger.debug(
        'JSON final à envoyer: $jsonBody',
        tag: 'PAYMENT_SERVICE',
      );

      AppLogger.httpRequest(
        'POST',
        '$baseUrl/payments',
        tag: 'PAYMENT_SERVICE',
      );

      final response = await RetryHelper.retryNetwork(
        operation:
            () => http.post(
              Uri.parse('$baseUrl/payments'),
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonBody,
            ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(
        response.statusCode,
        '$baseUrl/payments',
        tag: 'PAYMENT_SERVICE',
      );

      // Gérer les erreurs d'authentification
      await AuthErrorHandler.handleHttpResponse(response);

      // Gérer l'erreur 422 (Erreur de validation)
      if (response.statusCode == 422) {
        try {
          final errorData = jsonDecode(response.body);
          String errorMessage = 'Erreur de validation';

          // Extraire le message principal
          if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          }

          // Extraire les erreurs de validation par champ
          if (errorData['errors'] != null && errorData['errors'] is Map) {
            final errors = errorData['errors'] as Map<String, dynamic>;
            final List<String> validationErrors = [];

            errors.forEach((field, messages) {
              if (messages is List) {
                for (var msg in messages) {
                  validationErrors.add('${_formatFieldName(field)}: $msg');
                }
              } else {
                validationErrors.add('${_formatFieldName(field)}: $messages');
              }
            });

            if (validationErrors.isNotEmpty) {
              errorMessage = validationErrors.join('\n');
            }
          }

          print('❌ [PAYMENT_SERVICE] Erreur 422 - Validation: $errorMessage');
          AppLogger.error(
            'Erreur 422 - Validation: $errorMessage',
            tag: 'PAYMENT_SERVICE',
          );
          throw Exception(errorMessage);
        } catch (e) {
          // Si le parsing de l'erreur échoue, utiliser le message par défaut
          AppLogger.error(
            'Erreur 422 - Impossible de parser: ${response.body}',
            tag: 'PAYMENT_SERVICE',
          );
          throw Exception(
            'Erreur de validation. Veuillez vérifier les données saisies.',
          );
        }
      }

      // Gérer l'erreur 500 (Erreur serveur)
      if (response.statusCode == 500) {
        try {
          final errorData = jsonDecode(response.body);
          String errorMessage =
              'Erreur serveur lors de la création du paiement';

          // Extraire le message d'erreur du serveur
          if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'].toString();
          } else if (errorData['exception'] != null) {
            errorMessage = 'Erreur: ${errorData['exception']}';
          }

          // Logger les détails pour le débogage
          print('❌ [PAYMENT_SERVICE] Erreur 500 - Serveur: $errorMessage');
          print('❌ [PAYMENT_SERVICE] Réponse complète: ${response.body}');
          print('❌ [PAYMENT_SERVICE] Données envoyées: $requestData');
          AppLogger.error(
            'Erreur 500 - Serveur: $errorMessage',
            tag: 'PAYMENT_SERVICE',
          );
          AppLogger.error(
            'Réponse complète: ${response.body}',
            tag: 'PAYMENT_SERVICE',
          );
          AppLogger.error(
            'Données envoyées: $requestData',
            tag: 'PAYMENT_SERVICE',
          );

          throw Exception(
            'Erreur serveur: $errorMessage\nVeuillez contacter le support si le problème persiste.',
          );
        } catch (e) {
          // Si le parsing de l'erreur échoue, utiliser le message par défaut
          AppLogger.error(
            'Erreur 500 - Impossible de parser: ${response.body}',
            tag: 'PAYMENT_SERVICE',
          );
          AppLogger.error(
            'Données envoyées: $requestData',
            tag: 'PAYMENT_SERVICE',
          );
          throw Exception(
            'Erreur serveur (500). Veuillez vérifier les données et réessayer.\n'
            'Si le problème persiste, contactez le support technique.',
          );
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseBody = jsonDecode(response.body);
          AppLogger.debug(
            '✅ Paiement créé avec succès: $responseBody',
            tag: 'PAYMENT_SERVICE',
          );
          return responseBody;
        } catch (e) {
          AppLogger.error(
            'Erreur de format de réponse: ${response.body}',
            tag: 'PAYMENT_SERVICE',
          );
          throw Exception('Erreur de format de réponse: ${response.body}');
        }
      } else {
        // Logger la réponse complète pour le débogage
        AppLogger.error(
          'Erreur HTTP ${response.statusCode}: ${response.body}',
          tag: 'PAYMENT_SERVICE',
        );
        AppLogger.error(
          'Données envoyées: $requestData',
          tag: 'PAYMENT_SERVICE',
        );

        // Pour les autres erreurs, essayer d'extraire un message
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage =
              errorBody['message'] ??
              errorBody['error'] ??
              'Erreur lors de la création: ${response.statusCode}';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception(
            'Erreur lors de la création: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Soumettre un paiement au patron
  Future<Map<String, dynamic>> submitPaymentToPatron(int paymentId) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/payments/$paymentId/submit'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors de la soumission: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Supprimer un paiement
  Future<Map<String, dynamic>> deletePayment(int paymentId) async {
    try {
      final token = storage.read('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/payments/$paymentId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la suppression: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Basculer un planning de paiement
  Future<Map<String, dynamic>> togglePaymentSchedule(
    int paymentId, {
    required String action,
    String? reason,
  }) async {
    try {
      final token = storage.read('token');
      String url = '$baseUrl/payment-schedules/$paymentId';

      switch (action) {
        case 'pause':
          url += '/pause';
          break;
        case 'resume':
          url += '/resume';
          break;
        case 'cancel':
          url += '/cancel';
          break;
        default:
          throw Exception('Action non supportée: $action');
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: reason != null ? jsonEncode({'reason': reason}) : null,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors de l\'action: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les statistiques (compatibilité)
  Future<Map<String, dynamic>> getPaymentStats({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
  }) async {
    try {
      final token = storage.read('token');
      String url = '$baseUrl/payment-stats';
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
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la récupération des statistiques: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Helper pour formater les noms de champs de manière lisible
  String _formatFieldName(String field) {
    // Traduire les noms de champs courants
    final translations = {
      'client_id': 'Client',
      'nom': 'Nom',
      'email': 'Email',
      'adresse': 'Adresse',
      'comptable_id': 'Comptable',
      'comptable_name': 'Nom du comptable',
      'type': 'Type de paiement',
      'payment_date': 'Date de paiement',
      'due_date': 'Date d\'échéance',
      'amount': 'Montant',
      'payment_method': 'Méthode de paiement',
      'description': 'Description',
      'notes': 'Notes',
      'reference': 'Référence',
      'schedule': 'Planification',
    };

    // Si on a une traduction, l'utiliser
    if (translations.containsKey(field)) {
      return translations[field]!;
    }

    // Sinon, formater le nom du champ (remplacer _ par des espaces et capitaliser)
    return field
        .split('_')
        .map(
          (word) =>
              word.isEmpty
                  ? ''
                  : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }
}
