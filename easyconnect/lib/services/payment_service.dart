import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/payment_model.dart';
import 'package:easyconnect/utils/constant.dart';

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

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===== MÉTHODES PRINCIPALES DES PAIEMENTS =====

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

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          List<dynamic> data = [];

          // Gérer différents formats de réponse
          if (responseData is List) {
            data = responseData;
          } else if (responseData['data'] != null) {
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentModel.fromJson(data['data'] ?? data);
      } else {
        throw Exception(
          'Erreur lors de la récupération du paiement: ${response.statusCode}',
        );
      }
    } catch (e) {
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

      if (response.statusCode == 200) {
        try {
          // Nettoyer la réponse JSON avant de la parser
          String cleanedBody = response.body.trim();

          // Vérifier si la réponse se termine correctement
          if (!cleanedBody.endsWith('}') && !cleanedBody.endsWith(']')) {
            // Essayer de corriger en ajoutant les caractères manquants
            if (cleanedBody.contains('"data":[') &&
                !cleanedBody.endsWith(']')) {
              cleanedBody += ']';
            }
            if (cleanedBody.contains('"paiements":[') &&
                !cleanedBody.endsWith(']')) {
              cleanedBody += ']';
            }
            if (!cleanedBody.endsWith('}')) {
              cleanedBody += '}';
            }
          }

          final responseData = jsonDecode(cleanedBody);

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

      print(
        '🔵 [PAYMENT_SERVICE] Tentative d\'approbation avec route française: $url',
      );
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
        print(
          '🔵 [PAYMENT_SERVICE] Réponse route française - Status: ${response.statusCode}',
        );
      } catch (e) {
        print(
          '⚠️ [PAYMENT_SERVICE] Route française échouée, essai route anglaise: $e',
        );
        // Si la route française échoue, essayer la route anglaise (PATCH)
        url = '$baseUrl/payments/$paymentId/approve';
        print('🔵 [PAYMENT_SERVICE] Tentative avec route anglaise: $url');
        response = await http.patch(
          Uri.parse(url),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: comments != null ? jsonEncode({'comments': comments}) : null,
        );
        print(
          '🔵 [PAYMENT_SERVICE] Réponse route anglaise - Status: ${response.statusCode}',
        );
      }

      print(
        '🔵 [PAYMENT_SERVICE] Réponse finale - Status: ${response.statusCode}, Body: ${response.body}',
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 500) {
        // Erreur 500 : problème serveur
        final responseData = jsonDecode(response.body);
        final message =
            responseData['message'] ?? 'Erreur serveur lors de l\'approbation';
        throw Exception('Erreur serveur: $message');
      } else {
        // Autres erreurs (400, 401, 403, 422, etc.)
        final responseData = jsonDecode(response.body);
        final message =
            responseData['message'] ?? 'Erreur lors de l\'approbation';
        throw Exception('Erreur ${response.statusCode}: $message');
      }
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

      print(
        '🔵 [PAYMENT_SERVICE] Tentative de rejet avec route française: $url',
      );
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
        print(
          '🔵 [PAYMENT_SERVICE] Réponse route française - Status: ${response.statusCode}',
        );
      } catch (e) {
        print(
          '⚠️ [PAYMENT_SERVICE] Route française échouée, essai route anglaise: $e',
        );
        // Si la route française échoue, essayer la route anglaise (PATCH)
        url = '$baseUrl/payments/$paymentId/reject';
        print('🔵 [PAYMENT_SERVICE] Tentative avec route anglaise: $url');
        response = await http.patch(
          Uri.parse(url),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: reason != null ? jsonEncode({'reason': reason}) : null,
        );
        print(
          '🔵 [PAYMENT_SERVICE] Réponse route anglaise - Status: ${response.statusCode}',
        );
      }

      print(
        '🔵 [PAYMENT_SERVICE] Réponse finale - Status: ${response.statusCode}, Body: ${response.body}',
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 500) {
        // Erreur 500 : problème serveur
        final responseData = jsonDecode(response.body);
        final message =
            responseData['message'] ?? 'Erreur serveur lors du rejet';
        throw Exception('Erreur serveur: $message');
      } else {
        // Autres erreurs (400, 401, 403, 422, etc.)
        final responseData = jsonDecode(response.body);
        final message = responseData['message'] ?? 'Erreur lors du rejet';
        throw Exception('Erreur ${response.statusCode}: $message');
      }
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

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors du marquage: ${response.statusCode}');
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

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la réactivation: ${response.statusCode}',
        );
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['schedules'] ?? []);
      } else {
        throw Exception(
          'Erreur lors de la récupération des plannings: ${response.statusCode}',
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

      // Préparer les données à envoyer en nettoyant les valeurs null et vides
      final Map<String, dynamic> requestData = {
        'client_name': clientName.trim(),
        'client_email': clientEmail.trim(),
        'client_address': clientAddress.trim(),
        'comptable_id': comptableId,
        'comptable_name': comptableName.trim(),
        'type': type,
        'payment_date': paymentDate.toIso8601String(),
        'amount': amount,
        'payment_method': paymentMethod,
      };

      // Ajouter client_id seulement s'il est > 0 (certains backends ne acceptent pas 0)
      if (clientId > 0) {
        requestData['client_id'] = clientId;
      }

      // Ajouter les champs optionnels seulement s'ils ne sont pas null ou vides
      if (dueDate != null) {
        requestData['due_date'] = dueDate.toIso8601String();
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

      // Ajouter le schedule seulement s'il existe
      if (schedule != null) {
        try {
          requestData['schedule'] = schedule.toJson();
        } catch (e) {
          // Ne pas inclure le schedule s'il y a une erreur
        }
      }

      // Log des données avant envoi

      final jsonBody = jsonEncode(requestData);
      final response = await http.post(
        Uri.parse('$baseUrl/payments'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonBody,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseBody = jsonDecode(response.body);
          return responseBody;
        } catch (e) {
          throw Exception('Erreur de format de réponse: ${response.body}');
        }
      } else {
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
}
