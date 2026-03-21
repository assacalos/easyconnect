import 'package:http/http.dart' as http;
import 'package:easyconnect/services/session_service.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';

/// Point d’entrée unique pour les requêtes API authentifiées (GET/POST/PUT/PATCH/DELETE).
///
/// Enchaînement : `ensureValidToken` → requête → si **401**, `refreshToken` puis **une**
/// nouvelle tentative. Si le refresh échoue, délégation à
/// `AuthErrorHandler.handleHttpResponse` avec `skipRefresh: true` (pas de double
/// refresh côté handler). Les services appellent ensuite à nouveau
/// `AuthErrorHandler.handleHttpResponse` (défaut `skipRefresh: true`) pour un
/// traitement 401 cohérent sans boucle de refresh.
class HttpInterceptor {
  /// Intercepte une requête HTTP et gère automatiquement le rafraîchissement du token
  /// en cas d'erreur 401
  static Future<http.Response> interceptRequest(
    Future<http.Response> Function() request, {
    int maxRetries = 1,
  }) async {
    // S'assurer que le token est valide avant la requête
    await SessionService.ensureValidToken();

    // Effectuer la requête
    var response = await request();

    // Si 401, essayer de rafraîchir et réessayer une fois
    if (response.statusCode == 401 && maxRetries > 0) {
      AppLogger.info(
        'Erreur 401 détectée - Tentative de rafraîchissement du token',
        tag: 'HTTP_INTERCEPTOR',
      );

      final refreshed = await SessionService.refreshToken();
      if (refreshed) {
        // Réessayer la requête avec le nouveau token
        AppLogger.info(
          'Token rafraîchi - Nouvelle tentative de la requête',
          tag: 'HTTP_INTERCEPTOR',
        );
        response = await request();
      } else {
        // Si le rafraîchissement échoue, gérer la déconnexion
        AppLogger.warning(
          'Échec du rafraîchissement - Déconnexion requise',
          tag: 'HTTP_INTERCEPTOR',
        );
        await AuthErrorHandler.handleHttpResponse(
          response,
          skipRefresh: true,
        );
      }
    }

    return response;
  }

  /// Wrapper pour les requêtes GET (en-têtes via [ApiService.headersAsync] si non fournis)
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    int maxRetries = 1,
  }) async {
    return await interceptRequest(
      () async {
        final h = headers ?? await ApiService.headersAsync();
        return http.get(url, headers: h);
      },
      maxRetries: maxRetries,
    );
  }

  /// Wrapper pour les requêtes POST
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    int maxRetries = 1,
  }) async {
    return await interceptRequest(
      () async {
        final h = headers ?? await ApiService.headersAsync();
        return http.post(url, headers: h, body: body);
      },
      maxRetries: maxRetries,
    );
  }

  /// Wrapper pour les requêtes PUT
  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    int maxRetries = 1,
  }) async {
    return await interceptRequest(
      () async {
        final h = headers ?? await ApiService.headersAsync();
        return http.put(url, headers: h, body: body);
      },
      maxRetries: maxRetries,
    );
  }

  /// Wrapper pour les requêtes DELETE
  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    int maxRetries = 1,
  }) async {
    return await interceptRequest(
      () async {
        final h = headers ?? await ApiService.headersAsync();
        return http.delete(url, headers: h, body: body);
      },
      maxRetries: maxRetries,
    );
  }

  /// Wrapper pour les requêtes PATCH
  static Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    int maxRetries = 1,
  }) async {
    return await interceptRequest(
      () async {
        final h = headers ?? await ApiService.headersAsync();
        return http.patch(url, headers: h, body: body);
      },
      maxRetries: maxRetries,
    );
  }
}
