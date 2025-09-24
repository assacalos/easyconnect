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
      final response = await http.post(
        Uri.parse('$baseUrl/reports'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'user_id': userId,
          'user_role': userRole,
          'report_date': reportDate.toIso8601String(),
          'metrics': metrics,
          'comments': comments,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la création du rapport: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur ReportingService.createReport: $e');
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
      String url = '$baseUrl/reports/user/$userId';

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
        return (data['data'] as List)
            .map((json) => ReportingModel.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des rapports: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur ReportingService.getUserReports: $e');
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
      String url = '$baseUrl/reports';
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
        return (data['data'] as List)
            .map((json) => ReportingModel.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des rapports: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur ReportingService.getAllReports: $e');
      rethrow;
    }
  }

  // Soumettre un rapport
  Future<Map<String, dynamic>> submitReport(int reportId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/reports/$reportId/submit'),
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
      print('Erreur ReportingService.submitReport: $e');
      rethrow;
    }
  }

  // Approuver un rapport (pour le patron)
  Future<Map<String, dynamic>> approveReport(
    int reportId, {
    String? comments,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/reports/$reportId/approve'),
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
      print('Erreur ReportingService.approveReport: $e');
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
        Uri.parse('$baseUrl/reports/$reportId'),
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
      print('Erreur ReportingService.updateReport: $e');
      rethrow;
    }
  }

  // Supprimer un rapport
  Future<Map<String, dynamic>> deleteReport(int reportId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/reports/$reportId'),
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
      print('Erreur ReportingService.deleteReport: $e');
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
      String url = '$baseUrl/reports/stats';
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
      print('Erreur ReportingService.getReportingStats: $e');
      rethrow;
    }
  }
}
