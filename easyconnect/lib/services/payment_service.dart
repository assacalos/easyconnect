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
      print('🧪 PaymentService: Test de connectivité à l\'API...');
      print('🌐 PaymentService: URL de base: $baseUrl');

      final token = storage.read('token');
      print(
        '🔑 PaymentService: Token disponible: ${token != null ? "✅" : "❌"}',
      );

      final response = await http
          .get(
            Uri.parse('$baseUrl/payments'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      print(
        '📡 PaymentService: Test de connectivité - Status: ${response.statusCode}',
      );
      print('📄 PaymentService: Test de connectivité - Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ PaymentService: Erreur de connectivité: $e');
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
      print('🌐 PaymentService: getAllPayments() appelé');
      print(
        '📊 PaymentService: startDate=$startDate, endDate=$endDate, status=$status, type=$type',
      );

      final token = storage.read('token');
      print('🔑 PaymentService: Token récupéré: ${token != null ? "✅" : "❌"}');

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

      print('🔗 PaymentService: URL complète appelée: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
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

          return data.map((json) => PaymentModel.fromJson(json)).toList();
        } catch (e) {
          print('❌ PaymentService: Erreur de parsing JSON: $e');
          return [];
        }
      } else {
        throw Exception(
          'Erreur lors de la récupération des paiements: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ PaymentService: Erreur getAllPayments: $e');
      rethrow;
    }
  }

  // Récupérer un paiement par ID
  Future<PaymentModel> getPaymentById(int paymentId) async {
    try {
      print('🌐 PaymentService: getPaymentById() appelé pour ID: $paymentId');

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
      print('❌ PaymentService: Erreur getPaymentById: $e');
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
      print('🌐 PaymentService: getComptablePayments() appelé');
      print(
        '📊 PaymentService: comptableId=$comptableId, status=$status, type=$type',
      );

      final token = storage.read('token');
      print('🔑 PaymentService: Token récupéré: ${token != null ? "✅" : "❌"}');

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

      print('🔗 PaymentService: URL complète appelée: $url');
      print('🌐 PaymentService: Base URL: $baseUrl');
      print('📡 PaymentService: Endpoint: payments');
      print(
        '🔑 PaymentService: Headers: Accept: application/json, Authorization: Bearer $token',
      );

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
        '📡 PaymentService: Réponse reçue - Status: ${response.statusCode}',
      );
      print('📄 PaymentService: Body length: ${response.body.length}');
      print(
        '📄 PaymentService: Body content (first 200 chars): ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}',
      );
      print('📄 PaymentService: Headers de réponse: ${response.headers}');

      if (response.statusCode == 200) {
        try {
          // Nettoyer la réponse JSON avant de la parser
          String cleanedBody = response.body.trim();

          // Vérifier si la réponse se termine correctement
          if (!cleanedBody.endsWith('}') && !cleanedBody.endsWith(']')) {
            print('⚠️ PaymentService: Réponse JSON potentiellement tronquée');
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
            print('🔧 PaymentService: Réponse JSON corrigée');
          }

          final responseData = jsonDecode(cleanedBody);
          print('📊 PaymentService: Response data keys: ${responseData.keys}');
          print('📄 PaymentService: Response data content: $responseData');

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

          print(
            '📦 PaymentService: ${data.length} paiements trouvés dans l\'API',
          );

          if (data.isEmpty) {
            print('⚠️ PaymentService: Aucun paiement trouvé dans l\'API');
            print(
              '📄 PaymentService: Structure de réponse: ${responseData.runtimeType}',
            );
            print('📄 PaymentService: Contenu complet: $responseData');

            // Retourner une liste vide au lieu de lever une exception
            return [];
          }

          try {
            return data.map((json) {
              print('🔍 PaymentService: Parsing payment JSON: $json');
              return PaymentModel.fromJson(json);
            }).toList();
          } catch (e) {
            print('❌ PaymentService: Erreur lors du parsing des paiements: $e');
            print('📄 PaymentService: Données problématiques: $data');
            rethrow;
          }
        } catch (e) {
          print('❌ PaymentService: Erreur de parsing JSON: $e');
          print('📄 PaymentService: Body content: ${response.body}');

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

            print(
              '🔧 PaymentService: Tentative de nettoyage des caractères invalides',
            );

            // Vérifier si le JSON nettoyé est valide
            if (cleanedBody.isEmpty) {
              print('❌ PaymentService: JSON vide après nettoyage');
              return [];
            }

            final responseData = jsonDecode(cleanedBody);
            print('✅ PaymentService: JSON nettoyé avec succès');

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
              print('⚠️ PaymentService: Aucune donnée trouvée après nettoyage');
              return [];
            }

            return data.map((json) => PaymentModel.fromJson(json)).toList();
          } catch (cleanError) {
            print('❌ PaymentService: Échec du nettoyage JSON: $cleanError');

            // Dernière tentative : essayer de parser seulement une partie de la réponse
            try {
              print('🔧 PaymentService: Tentative de parsing partiel...');

              // Essayer de trouver le début d'un JSON valide
              int startIndex = response.body.indexOf('{');
              int endIndex = response.body.lastIndexOf('}');

              if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
                String partialJson = response.body.substring(
                  startIndex,
                  endIndex + 1,
                );
                print(
                  '📄 PaymentService: JSON partiel extrait: ${partialJson.length} caractères',
                );

                final responseData = jsonDecode(partialJson);
                print('✅ PaymentService: JSON partiel parsé avec succès');

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

              print(
                '❌ PaymentService: Impossible de récupérer des données valides',
              );
              return [];
            } catch (partialError) {
              print(
                '❌ PaymentService: Échec du parsing partiel: $partialError',
              );
              throw Exception('Erreur de format des données: $e');
            }
          }
        }
      } else {
        print(
          '❌ PaymentService: Erreur API ${response.statusCode}: ${response.body}',
        );
        throw Exception(
          'Erreur lors de la récupération des paiements: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ PaymentService: Erreur lors du chargement: $e');
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
      print('🔄 PaymentService: approvePayment() appelé pour ID: $paymentId');

      final token = storage.read('token');
      final response = await http.patch(
        Uri.parse('$baseUrl/payments/$paymentId/approve'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: comments != null ? jsonEncode({'comments': comments}) : null,
      );

      if (response.statusCode == 200) {
        print('✅ PaymentService: Paiement approuvé avec succès');
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'approbation: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ PaymentService: Erreur approvePayment: $e');
      rethrow;
    }
  }

  // Rejeter un paiement
  Future<Map<String, dynamic>> rejectPayment(
    int paymentId, {
    String? reason,
  }) async {
    try {
      print('🔄 PaymentService: rejectPayment() appelé pour ID: $paymentId');

      final token = storage.read('token');
      final response = await http.patch(
        Uri.parse('$baseUrl/payments/$paymentId/reject'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: reason != null ? jsonEncode({'reason': reason}) : null,
      );

      if (response.statusCode == 200) {
        print('✅ PaymentService: Paiement rejeté avec succès');
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors du rejet: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ PaymentService: Erreur rejectPayment: $e');
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
      print('🔄 PaymentService: markAsPaid() appelé pour ID: $paymentId');

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
        print('✅ PaymentService: Paiement marqué comme payé avec succès');
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors du marquage: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ PaymentService: Erreur markAsPaid: $e');
      rethrow;
    }
  }

  // Réactiver un paiement rejeté
  Future<Map<String, dynamic>> reactivatePayment(int paymentId) async {
    try {
      print(
        '🔄 PaymentService: reactivatePayment() appelé pour ID: $paymentId',
      );

      final token = storage.read('token');
      final response = await http.patch(
        Uri.parse('$baseUrl/payments/$paymentId/reactivate'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print('✅ PaymentService: Paiement réactivé avec succès');
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la réactivation: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ PaymentService: Erreur reactivatePayment: $e');
      rethrow;
    }
  }

  // ===== MÉTHODES POUR LES PLANNINGS DE PAIEMENT =====

  // Récupérer les plannings de paiement
  Future<List<Map<String, dynamic>>> getPaymentSchedules() async {
    try {
      print('🌐 PaymentService: getPaymentSchedules() appelé');

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
      print('❌ PaymentService: Erreur getPaymentSchedules: $e');
      rethrow;
    }
  }

  // Mettre en pause un planning
  Future<Map<String, dynamic>> pauseSchedule(int scheduleId) async {
    try {
      print('🔄 PaymentService: pauseSchedule() appelé pour ID: $scheduleId');

      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/payment-schedules/$scheduleId/pause'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print('✅ PaymentService: Planning mis en pause avec succès');
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors de la pause: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ PaymentService: Erreur pauseSchedule: $e');
      rethrow;
    }
  }

  // Reprendre un planning
  Future<Map<String, dynamic>> resumeSchedule(int scheduleId) async {
    try {
      print('🔄 PaymentService: resumeSchedule() appelé pour ID: $scheduleId');

      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/payment-schedules/$scheduleId/resume'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print('✅ PaymentService: Planning repris avec succès');
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors de la reprise: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ PaymentService: Erreur resumeSchedule: $e');
      rethrow;
    }
  }

  // Annuler un planning
  Future<Map<String, dynamic>> cancelSchedule(int scheduleId) async {
    try {
      print('🔄 PaymentService: cancelSchedule() appelé pour ID: $scheduleId');

      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/payment-schedules/$scheduleId/cancel'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print('✅ PaymentService: Planning annulé avec succès');
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors de l\'annulation: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ PaymentService: Erreur cancelSchedule: $e');
      rethrow;
    }
  }

  // Marquer une échéance comme payée
  Future<Map<String, dynamic>> markInstallmentPaid(
    int scheduleId,
    int installmentId,
  ) async {
    try {
      print(
        '🔄 PaymentService: markInstallmentPaid() appelé pour schedule: $scheduleId, installment: $installmentId',
      );

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
        print('✅ PaymentService: Échéance marquée comme payée avec succès');
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors du marquage de l\'échéance: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ PaymentService: Erreur markInstallmentPaid: $e');
      rethrow;
    }
  }

  // ===== MÉTHODES POUR LES STATISTIQUES =====

  // Récupérer les statistiques des plannings
  Future<Map<String, dynamic>> getScheduleStats() async {
    try {
      print('🌐 PaymentService: getScheduleStats() appelé');

      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/payment-stats/schedules'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print(
          '✅ PaymentService: Statistiques des plannings récupérées avec succès',
        );
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la récupération des statistiques des plannings: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ PaymentService: Erreur getScheduleStats: $e');
      rethrow;
    }
  }

  // Récupérer les paiements à venir
  Future<List<Map<String, dynamic>>> getUpcomingPayments() async {
    try {
      print('🌐 PaymentService: getUpcomingPayments() appelé');

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
        print('✅ PaymentService: Paiements à venir récupérés avec succès');
        return List<Map<String, dynamic>>.from(data['payments'] ?? []);
      } else {
        throw Exception(
          'Erreur lors de la récupération des paiements à venir: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ PaymentService: Erreur getUpcomingPayments: $e');
      rethrow;
    }
  }

  // Récupérer les paiements en retard
  Future<List<Map<String, dynamic>>> getOverduePayments() async {
    try {
      print('🌐 PaymentService: getOverduePayments() appelé');

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
        print('✅ PaymentService: Paiements en retard récupérés avec succès');
        return List<Map<String, dynamic>>.from(data['payments'] ?? []);
      } else {
        throw Exception(
          'Erreur lors de la récupération des paiements en retard: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ PaymentService: Erreur getOverduePayments: $e');
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
      final response = await http.post(
        Uri.parse('$baseUrl/payments'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors de la création: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ PaymentService: Erreur createPayment: $e');
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
      print('❌ PaymentService: Erreur submitPaymentToPatron: $e');
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
      print('❌ PaymentService: Erreur deletePayment: $e');
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
      print('❌ PaymentService: Erreur togglePaymentSchedule: $e');
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
      print('❌ PaymentService: Erreur getPaymentStats: $e');
      rethrow;
    }
  }
}
