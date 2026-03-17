import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';

/// Service pour le portail client (rôle 7) : annonces, catalogue, offres, contact, demandes d'intervention.
class ClientPortalService {
  static String get _baseUrl => '${AppConfig.baseUrl}/client-portal';

  /// Annonces publiées (type optionnel: announcement | promotion)
  static Future<Map<String, dynamic>> getAnnouncements({String? type}) async {
    final uri = type != null
        ? Uri.parse('$_baseUrl/announcements?type=$type')
        : Uri.parse('$_baseUrl/announcements');
    final res = await http.get(uri, headers: ApiService.headers());
    await AuthErrorHandler.handleHttpResponse(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Catalogue des articles (catégorie optionnelle)
  static Future<Map<String, dynamic>> getCatalog({String? category}) async {
    final uri = category != null
        ? Uri.parse('$_baseUrl/catalog?category=$category')
        : Uri.parse('$_baseUrl/catalog');
    final res = await http.get(uri, headers: ApiService.headers());
    await AuthErrorHandler.handleHttpResponse(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Offres (articles marqués comme offres)
  static Future<Map<String, dynamic>> getOffers() async {
    final res = await http.get(Uri.parse('$_baseUrl/offers'), headers: ApiService.headers());
    await AuthErrorHandler.handleHttpResponse(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Coordonnées de contact
  static Future<Map<String, dynamic>> getContact() async {
    final res = await http.get(Uri.parse('$_baseUrl/contact'), headers: ApiService.headers());
    await AuthErrorHandler.handleHttpResponse(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Créer une demande d'intervention (ticket)
  static Future<Map<String, dynamic>> createInterventionRequest({
    required String title,
    required String description,
    required String type,
    required String priority,
    required String scheduledDate,
    String? location,
    String? equipment,
    String? problemDescription,
  }) async {
    final body = {
      'title': title,
      'description': description,
      'type': type,
      'priority': priority,
      'scheduled_date': scheduledDate,
      if (location != null && location.isNotEmpty) 'location': location,
      if (equipment != null && equipment.isNotEmpty) 'equipment': equipment,
      if (problemDescription != null && problemDescription.isNotEmpty) 'problem_description': problemDescription,
    };
    final res = await http.post(
      Uri.parse('$_baseUrl/intervention-requests'),
      headers: ApiService.headers(),
      body: jsonEncode(body),
    );
    await AuthErrorHandler.handleHttpResponse(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Mes demandes d'intervention (suivi)
  static Future<Map<String, dynamic>> getMyInterventions() async {
    final res = await http.get(Uri.parse('$_baseUrl/my-interventions'), headers: ApiService.headers());
    await AuthErrorHandler.handleHttpResponse(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
