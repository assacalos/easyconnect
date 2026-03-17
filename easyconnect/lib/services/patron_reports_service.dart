import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';

/// Réponse de l'API GET /patron-reports (trésorerie + âge des créances).
class PatronReportsApiResponse {
  final double encaissements;
  final double decaissements;
  final double soldeTresorerie;
  final double receivables0_30;
  final double receivables31_60;
  final double receivables61_90;
  final double receivablesOver90;

  PatronReportsApiResponse({
    required this.encaissements,
    required this.decaissements,
    required this.soldeTresorerie,
    required this.receivables0_30,
    required this.receivables31_60,
    required this.receivables61_90,
    required this.receivablesOver90,
  });

  factory PatronReportsApiResponse.fromJson(Map<String, dynamic> json) {
    final tresorerie = json['tresorerie'] as Map<String, dynamic>? ?? {};
    final aging = json['receivables_aging'] as Map<String, dynamic>? ?? {};
    return PatronReportsApiResponse(
      encaissements: _toDouble(tresorerie['encaissements']),
      decaissements: _toDouble(tresorerie['decaissements']),
      soldeTresorerie: _toDouble(tresorerie['solde_tresorerie']),
      receivables0_30: _toDouble(aging['receivables_0_30']),
      receivables31_60: _toDouble(aging['receivables_31_60']),
      receivables61_90: _toDouble(aging['receivables_61_90']),
      receivablesOver90: _toDouble(aging['receivables_over_90']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}

class PatronReportsService {
  static final PatronReportsService _instance = PatronReportsService._();
  static PatronReportsService get to => _instance;
  factory PatronReportsService() => _instance;
  PatronReportsService._();

  final _storage = GetStorage();
  String get _baseUrl => AppConfig.baseUrl;

  /// GET /patron-reports?start_date=...&end_date=...
  /// Retourne trésorerie (encaissements, décaissements, solde) et âge des créances par tranche.
  Future<PatronReportsApiResponse?> getPatronReports({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final token = _storage.read('token');
      final queryParams = <String, String>{
        'start_date': startDate.toIso8601String().split('T').first,
        'end_date': endDate.toIso8601String().split('T').first,
      };
      final uri = Uri.parse('$_baseUrl/patron-reports').replace(
        queryParameters: queryParams,
      );
      AppLogger.httpRequest('GET', uri.toString(), tag: 'PATRON_REPORTS_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation: () => http.get(
          uri,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, uri.toString(), tag: 'PATRON_REPORTS_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] != true) return null;
        final dataPayload = data['data'] as Map<String, dynamic>?;
        if (dataPayload == null) return null;
        final tresorerie = dataPayload['tresorerie'] as Map<String, dynamic>? ?? {};
        final aging = dataPayload['receivables_aging'] as Map<String, dynamic>? ?? {};
        return PatronReportsApiResponse(
          encaissements: PatronReportsApiResponse._toDouble(tresorerie['encaissements']),
          decaissements: PatronReportsApiResponse._toDouble(tresorerie['decaissements']),
          soldeTresorerie: PatronReportsApiResponse._toDouble(tresorerie['solde_tresorerie']),
          receivables0_30: PatronReportsApiResponse._toDouble(aging['receivables_0_30']),
          receivables31_60: PatronReportsApiResponse._toDouble(aging['receivables_31_60']),
          receivables61_90: PatronReportsApiResponse._toDouble(aging['receivables_61_90']),
          receivablesOver90: PatronReportsApiResponse._toDouble(aging['receivables_over_90']),
        );
      }
      return null;
    } catch (e) {
      AppLogger.error('Erreur getPatronReports: $e', tag: 'PATRON_REPORTS_SERVICE');
      return null;
    }
  }
}
