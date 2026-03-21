import 'dart:convert';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/Models/inventory_session_model.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';
import 'package:easyconnect/services/http_interceptor.dart';

class InventoryService {
  static final InventoryService _instance = InventoryService._();
  factory InventoryService() => _instance;
  InventoryService._();

  Future<Map<String, String>> _headers() async => ApiService.headersAsync();

  /// Liste des sessions d'inventaire (paginée)
  Future<InventorySessionListResponse> getSessions({
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    final url = Uri.parse('${AppConfig.baseUrl}/inventory-sessions').replace(
      queryParameters: {
        if (status != null && status != 'all') 'status': status,
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );
    AppLogger.httpRequest('GET', url.toString(), tag: 'INVENTORY_SERVICE');
    final headers = await _headers();
    final response = await RetryHelper.retryNetwork(
      operation: () => HttpInterceptor.get(url, headers: headers),
      maxRetries: AppConfig.defaultMaxRetries,
    );
    AppLogger.httpResponse(response.statusCode, url.toString(), tag: 'INVENTORY_SERVICE');
    await AuthErrorHandler.handleHttpResponse(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Erreur chargement sessions');
    }
    final list = (data['data'] as List?)?.map((e) => InventorySession.fromJson(Map<String, dynamic>.from(e))).toList() ?? [];
    final meta = data['meta'] as Map<String, dynamic>?;
    return InventorySessionListResponse(
      data: list,
      currentPage: meta != null ? (meta['current_page'] as int?) ?? 1 : 1,
      lastPage: meta != null ? (meta['last_page'] as int?) ?? 1 : 1,
      total: meta != null ? (meta['total'] as int?) ?? 0 : 0,
    );
  }

  /// Créer une session (date, dépôt optionnel) — le backend ajoute tous les articles du stock
  Future<InventorySession> createSession({
    required DateTime date,
    String? depot,
  }) async {
    final url = Uri.parse('${AppConfig.baseUrl}/inventory-sessions');
    final body = {
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      if (depot != null && depot.isNotEmpty) 'depot': depot,
    };
    AppLogger.httpRequest('POST', url.toString(), tag: 'INVENTORY_SERVICE');
    final headers = await _headers();
    final response = await RetryHelper.retryNetwork(
      operation: () => HttpInterceptor.post(url, headers: headers, body: jsonEncode(body)),
      maxRetries: AppConfig.defaultMaxRetries,
    );
    AppLogger.httpResponse(response.statusCode, url.toString(), tag: 'INVENTORY_SERVICE');
    await AuthErrorHandler.handleHttpResponse(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Erreur création session');
    }
    final sessionData = data['data'] as Map<String, dynamic>? ?? data;
    return InventorySession.fromJson(Map<String, dynamic>.from(sessionData));
  }

  /// Détail d'une session (avec items et stock)
  Future<InventorySession> getSession(int id) async {
    final url = Uri.parse('${AppConfig.baseUrl}/inventory-sessions/$id');
    AppLogger.httpRequest('GET', url.toString(), tag: 'INVENTORY_SERVICE');
    final headers = await _headers();
    final response = await RetryHelper.retryNetwork(
      operation: () => HttpInterceptor.get(url, headers: headers),
      maxRetries: AppConfig.defaultMaxRetries,
    );
    AppLogger.httpResponse(response.statusCode, url.toString(), tag: 'INVENTORY_SERVICE');
    await AuthErrorHandler.handleHttpResponse(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Session non trouvée');
    }
    final sessionData = data['data'] as Map<String, dynamic>? ?? data;
    return InventorySession.fromJson(Map<String, dynamic>.from(sessionData));
  }

  /// Mettre à jour la session (date, dépôt) et/ou les quantités comptées
  Future<InventorySession> updateSession(
    int id, {
    String? date,
    String? depot,
    List<Map<String, dynamic>>? items,
  }) async {
    final url = Uri.parse('${AppConfig.baseUrl}/inventory-sessions/$id');
    final body = <String, dynamic>{};
    if (date != null) body['date'] = date;
    if (depot != null) body['depot'] = depot;
    if (items != null) body['items'] = items;
    AppLogger.httpRequest('PUT', url.toString(), tag: 'INVENTORY_SERVICE');
    final headers = await _headers();
    final response = await RetryHelper.retryNetwork(
      operation: () => HttpInterceptor.put(url, headers: headers, body: jsonEncode(body)),
      maxRetries: AppConfig.defaultMaxRetries,
    );
    AppLogger.httpResponse(response.statusCode, url.toString(), tag: 'INVENTORY_SERVICE');
    await AuthErrorHandler.handleHttpResponse(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Erreur mise à jour');
    }
    final sessionData = data['data'] as Map<String, dynamic>? ?? data;
    return InventorySession.fromJson(Map<String, dynamic>.from(sessionData));
  }

  /// Enregistrer la quantité comptée d'une ligne
  Future<InventorySessionItem> updateItemCount(
    int sessionId,
    int itemId,
    double quantityCounted,
  ) async {
    final url = Uri.parse('${AppConfig.baseUrl}/inventory-sessions/$sessionId/items/$itemId');
    final body = {'quantity_counted': quantityCounted};
    AppLogger.httpRequest('PUT', url.toString(), tag: 'INVENTORY_SERVICE');
    final headers = await _headers();
    final response = await RetryHelper.retryNetwork(
      operation: () => HttpInterceptor.put(url, headers: headers, body: jsonEncode(body)),
      maxRetries: AppConfig.defaultMaxRetries,
    );
    AppLogger.httpResponse(response.statusCode, url.toString(), tag: 'INVENTORY_SERVICE');
    await AuthErrorHandler.handleHttpResponse(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Erreur mise à jour ligne');
    }
    final itemData = data['data'] as Map<String, dynamic>? ?? data;
    return InventorySessionItem.fromJson(Map<String, dynamic>.from(itemData));
  }

  /// Clôturer l'inventaire (applique les écarts aux stocks)
  Future<InventorySession> closeSession(int id) async {
    final url = Uri.parse('${AppConfig.baseUrl}/inventory-sessions/$id/close');
    AppLogger.httpRequest('POST', url.toString(), tag: 'INVENTORY_SERVICE');
    final headers = await _headers();
    final response = await RetryHelper.retryNetwork(
      operation: () => HttpInterceptor.post(url, headers: headers),
      maxRetries: AppConfig.defaultMaxRetries,
    );
    AppLogger.httpResponse(response.statusCode, url.toString(), tag: 'INVENTORY_SERVICE');
    await AuthErrorHandler.handleHttpResponse(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Erreur clôture');
    }
    final sessionData = data['data'] as Map<String, dynamic>? ?? data;
    return InventorySession.fromJson(Map<String, dynamic>.from(sessionData));
  }

  /// Supprimer une session (uniquement si en cours)
  Future<void> deleteSession(int id) async {
    final url = Uri.parse('${AppConfig.baseUrl}/inventory-sessions/$id');
    AppLogger.httpRequest('DELETE', url.toString(), tag: 'INVENTORY_SERVICE');
    final headers = await _headers();
    final response = await RetryHelper.retryNetwork(
      operation: () => HttpInterceptor.delete(url, headers: headers),
      maxRetries: AppConfig.defaultMaxRetries,
    );
    AppLogger.httpResponse(response.statusCode, url.toString(), tag: 'INVENTORY_SERVICE');
    await AuthErrorHandler.handleHttpResponse(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(data['message'] ?? 'Erreur suppression');
    }
  }
}

class InventorySessionListResponse {
  final List<InventorySession> data;
  final int currentPage;
  final int lastPage;
  final int total;

  InventorySessionListResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasNextPage => currentPage < lastPage;
}
