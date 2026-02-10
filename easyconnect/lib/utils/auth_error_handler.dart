import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/services/session_service.dart';
import 'package:http/http.dart' as http;
import 'package:easyconnect/utils/logger.dart';

/// Helper centralisé pour gérer les erreurs d'authentification
class AuthErrorHandler {
  static bool _isHandlingLogout = false;

  /// Vérifie si une réponse HTTP contient une erreur d'authentification
  /// et déconnecte automatiquement l'utilisateur si nécessaire
  /// [skipRefresh] : Si true, ne tente pas de rafraîchir le token avant de déconnecter
  static Future<void> handleHttpResponse(
    http.Response response, {
    bool skipRefresh = false,
  }) async {
    if (response.statusCode == 401) {
      // Si on ne doit pas sauter le rafraîchissement, essayer de rafraîchir d'abord
      if (!skipRefresh) {
        try {
          final refreshed = await SessionService.refreshToken();
          if (refreshed) {
            // Si le rafraîchissement réussit, ne pas déconnecter
            AppLogger.info(
              'Token rafraîchi avec succès après erreur 401',
              tag: 'AUTH_ERROR_HANDLER',
            );
            return;
          }
        } catch (e) {
          AppLogger.warning(
            'Erreur lors du rafraîchissement: $e',
            tag: 'AUTH_ERROR_HANDLER',
          );
        }
      }

      // Si le rafraîchissement échoue ou est ignoré, déconnecter
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
  /// [showMessage] : Si false, ne pas afficher de message (par défaut: seulement en debug)
  static Future<void> _handleUnauthorized({bool? showMessage}) async {
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

        // Logger l'événement
        AppLogger.warning(
          'Session expirée - Déconnexion automatique',
          tag: 'AUTH_ERROR_HANDLER',
        );

        // Afficher un message seulement si demandé explicitement ou en mode debug
        // En production, ne pas afficher de message pour éviter les interruptions
        final shouldShowMessage = showMessage ?? kDebugMode;

        if (shouldShowMessage) {
          Get.snackbar(
            'Session expirée',
            'Votre session a expiré. Veuillez vous reconnecter.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            icon: const Icon(Icons.warning, color: Colors.white),
          );

          // Attendre un peu pour que l'utilisateur voie le message
          await Future.delayed(const Duration(milliseconds: 500));
        }

        // Déconnecter l'utilisateur silencieusement
        await authController.logout(silent: !shouldShowMessage);
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
