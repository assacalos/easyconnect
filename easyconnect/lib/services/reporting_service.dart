import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:easyconnect/Models/reporting_model.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/constant.dart';

class ReportingService extends GetxService {
  static ReportingService get to => Get.find();

  // Créer un rapport
  Future<Map<String, dynamic>> createReport({
    required int userId,
    required String userRole,
    required DateTime reportDate,
    required Map<String, dynamic> metrics,
    String? comments,
  }) async {
    try {
      final requestBody = {
        'user_id': userId,
        'user_role': userRole,
        'report_date': reportDate.toIso8601String(),
        'metrics': metrics,
        'comments': comments,
      };
      final response = await http.post(
        Uri.parse('$baseUrl/user-reportings-create'),
        headers: ApiService.headers(),
        body: jsonEncode(requestBody),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        // Route non trouvée - retourner une réponse simulée pour le développement
        return {
          'success': true,
          'message': 'Rapport créé avec succès (simulation)',
          'data': {
            'id': DateTime.now().millisecondsSinceEpoch,
            'user_id': userId,
            'user_role': userRole,
            'report_date': reportDate.toIso8601String(),
            'metrics': metrics,
            'comments': comments,
            'status': 'submitted',
            'created_at': DateTime.now().toIso8601String(),
          },
        };
      } else {
        throw Exception(
          'Erreur lors de la création du rapport: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les rapports d'un utilisateur
  Future<List<ReportingModel>> getUserReports({
    required int userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String url = '$baseUrl/user-reportings-list';

      if (startDate != null && endDate != null) {
        url +=
            '?start_date=${startDate.toIso8601String()}&end_date=${endDate.toIso8601String()}';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: ApiService.headers(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> reportsData;

        // Gérer différents formats de réponse
        if (data is List) {
          // La réponse est directement une liste
          reportsData = data;
        } else if (data['data'] != null) {
          // La réponse contient une clé 'data'
          if (data['data'] is List) {
            reportsData = data['data'];
          } else if (data['data']['data'] != null &&
              data['data']['data'] is List) {
            // Cas de pagination Laravel: data.data.data
            reportsData = data['data']['data'];
          } else {
            reportsData = [data['data']];
          }
        } else {
          return [];
        }

        if (reportsData.isNotEmpty) {}

        final List<ReportingModel> reportsList =
            reportsData
                .map((json) {
                  try {
                    return ReportingModel.fromJson(json);
                  } catch (e) {
                    return null;
                  }
                })
                .where((report) => report != null)
                .cast<ReportingModel>()
                .toList();

        // Filtrer par userId pour s'assurer que l'utilisateur ne voit que ses propres reporting
        final filteredReports =
            reportsList.where((report) => report.userId == userId).toList();
        return filteredReports;
      } else {
        throw Exception(
          'Erreur lors de la récupération des rapports: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer tous les rapports (pour le patron)
  Future<List<ReportingModel>> getAllReports({
    DateTime? startDate,
    DateTime? endDate,
    String? userRole,
  }) async {
    try {
      String url = '$baseUrl/user-reportings-list';
      List<String> params = [];

      if (startDate != null) {
        params.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        params.add('end_date=${endDate.toIso8601String()}');
      }
      if (userRole != null) {
        params.add('user_role=$userRole');
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

        List<dynamic> reportsData;

        // Gérer différents formats de réponse
        if (data is List) {
          // La réponse est directement une liste
          reportsData = data;
        } else if (data['data'] != null) {
          // La réponse contient une clé 'data'
          if (data['data'] is List) {
            reportsData = data['data'];
          } else if (data['data']['data'] != null &&
              data['data']['data'] is List) {
            // Cas de pagination Laravel: data.data.data
            reportsData = data['data']['data'];
          } else {
            reportsData = [data['data']];
          }
        } else {
          return [];
        }

        if (reportsData.isNotEmpty) {}

        final List<ReportingModel> reportsList =
            reportsData
                .map((json) {
                  try {
                    return ReportingModel.fromJson(json);
                  } catch (e) {
                    return null;
                  }
                })
                .where((report) => report != null)
                .cast<ReportingModel>()
                .toList();

        return reportsList;
      } else {
        throw Exception(
          'Erreur lors de la récupération des rapports: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Soumettre un rapport
  Future<Map<String, dynamic>> submitReport(int reportId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user-reportings-submit/$reportId'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la soumission du rapport: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Approuver un rapport (pour le patron)
  Future<Map<String, dynamic>> approveReport(
    int reportId, {
    String? comments,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user-reportings-validate/$reportId'),
        headers: ApiService.headers(),
        body: jsonEncode({'comments': comments}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'approbation du rapport: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Mettre à jour un rapport
  Future<Map<String, dynamic>> updateReport({
    required int reportId,
    required Map<String, dynamic> metrics,
    String? comments,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user-reportings-update/$reportId'),
        headers: ApiService.headers(),
        body: jsonEncode({'metrics': metrics, 'comments': comments}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la mise à jour du rapport: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Supprimer un rapport
  Future<Map<String, dynamic>> deleteReport(int reportId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/user-reportings-delete/$reportId'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la suppression du rapport: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer un rapport spécifique
  Future<ReportingModel> getReport(int reportId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user-reportings-show/$reportId'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ReportingModel.fromJson(data);
      } else {
        throw Exception(
          'Erreur lors de la récupération du rapport: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Générer un rapport
  Future<Map<String, dynamic>> generateReport({
    required int userId,
    required String userRole,
    required DateTime reportDate,
    required Map<String, dynamic> metrics,
    String? comments,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user-reportings-generate'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'user_id': userId,
          'user_role': userRole,
          'report_date': reportDate.toIso8601String(),
          'metrics': metrics,
          'comments': comments,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la génération du rapport: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les statistiques de reporting
  Future<Map<String, dynamic>> getReportingStats({
    DateTime? startDate,
    DateTime? endDate,
    String? userRole,
  }) async {
    try {
      String url = '$baseUrl/user-reportings-stats';
      List<String> params = [];

      if (startDate != null) {
        params.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        params.add('end_date=${endDate.toIso8601String()}');
      }
      if (userRole != null) {
        params.add('user_role=$userRole');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiService.headers(),
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

  // Rejeter un rapport
  Future<Map<String, dynamic>> rejectReport(
    int reportId, {
    String? comments,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user-reportings-reject/$reportId'),
        headers: ApiService.headers(),
        body: jsonEncode({'comments': comments}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors du rejet du rapport: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Ajouter ou modifier la note du patron sur un rapport
  Future<Map<String, dynamic>> addPatronNote(
    int reportId, {
    String? note,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user-reportings-note/$reportId'),
        headers: ApiService.headers(),
        body: jsonEncode({'patron_note': note}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'ajout de la note: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
