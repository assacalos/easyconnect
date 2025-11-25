import 'package:get/get.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:http/http.dart' as http;
import 'package:easyconnect/utils/logger.dart';

/// Helper centralisé pour gérer les erreurs d'authentification
class AuthErrorHandler {
  static bool _isHandlingLogout = false;

  /// Vérifie si une réponse HTTP contient une erreur d'authentification
  /// et déconnecte automatiquement l'utilisateur si nécessaire
  static Future<void> handleHttpResponse(http.Response response) async {
    if (response.statusCode == 401) {
      await _handleUnauthorized();
    }
  }

  /// Vérifie si une exception contient une erreur d'authentification
  static Future<void> handleException(dynamic error) async {
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('401') ||
        errorString.contains('unauthorized') ||
        errorString.contains('non autorisé')) {
      await _handleUnauthorized();
    }
  }

  /// Gère la déconnexion automatique en cas d'erreur 401
  static Future<void> _handleUnauthorized() async {
    // Éviter les déconnexions multiples simultanées
    if (_isHandlingLogout) {
      return;
    }

    _isHandlingLogout = true;

    try {
      // Attendre un peu pour éviter les conflits
      await Future.delayed(const Duration(milliseconds: 100));

      // Récupérer le contrôleur d'authentification
      if (Get.isRegistered<AuthController>()) {
        final authController = Get.find<AuthController>();

        // Logger l'événement sans afficher de message à l'utilisateur
        AppLogger.warning(
          'Session expirée - Déconnexion automatique',
          tag: 'AUTH_ERROR_HANDLER',
        );

        // Déconnecter l'utilisateur silencieusement
        authController.logout();
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la gestion de la déconnexion: $e',
        tag: 'AUTH_ERROR_HANDLER',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      // Réinitialiser le flag après un délai
      Future.delayed(const Duration(seconds: 2), () {
        _isHandlingLogout = false;
      });
    }
  }

  /// Vérifie si une erreur doit être ignorée (pour éviter les messages multiples)
  static bool shouldIgnoreError(dynamic error) {
    if (_isHandlingLogout) {
      return true;
    }
    return false;
  }

  /// Wrapper pour gérer automatiquement les erreurs d'authentification dans les réponses HTTP
  /// Retourne true si la réponse est valide (200-299), false sinon
  /// Gère automatiquement les erreurs 401
  static Future<bool> checkResponse(http.Response response) async {
    await handleHttpResponse(response);
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  /// Wrapper pour gérer les exceptions avec gestion automatique des erreurs 401
  /// Retourne true si l'erreur est une erreur d'authentification (déjà gérée)
  static Future<bool> handleError(dynamic error) async {
    await handleException(error);
    return shouldIgnoreError(error);
  }
}
