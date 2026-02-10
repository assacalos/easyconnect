import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/logger.dart';

/// Helper pour gérer l'affichage des erreurs aux utilisateurs
class ErrorHelper {
  /// Affiche un message d'erreur de manière sécurisée
  /// Ne montre pas les détails techniques aux utilisateurs finaux
  /// En production, les erreurs ne sont pas affichées sauf si showToUser est true
  static void showError(
    dynamic error, {
    String? title,
    String? customMessage,
    bool showToUser = false, // Par défaut, ne pas afficher
    Duration? duration,
    bool ignorePostSuccess = false, // Si true, ignore les erreurs post-succès
  }) {
    // Logger l'erreur pour le débogage (toujours logger)
    AppLogger.error(
      'Error: $error',
      tag: 'ERROR_HELPER',
      error: error is Exception ? error : Exception(error.toString()),
    );

    // Ne pas afficher les erreurs post-succès (parsing, JSON, etc.)
    if (!ignorePostSuccess && isPostSuccessError(error)) {
      AppLogger.debug(
        'Erreur post-succès ignorée: $error',
        tag: 'ERROR_HELPER',
      );
      return;
    }

    // En production, ne pas afficher les erreurs techniques sauf si explicitement demandé
    if (!showToUser && !AppConfig.showErrorMessagesToUsers) {
      return; // Masquer l'erreur pour les utilisateurs finaux en production
    }

    // Déterminer le message à afficher
    final message =
        customMessage ??
        (AppConfig.showErrorMessagesToUsers
            ? error.toString()
            : AppConfig.getUserFriendlyErrorMessage(error));

    // Afficher le snackbar seulement en debug ou si showToUser est true
    if (kDebugMode || showToUser) {
      Get.snackbar(
        title ?? 'Erreur',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: duration ?? const Duration(seconds: 3),
        isDismissible: true,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    }
  }

  /// Affiche un message d'erreur de validation (toujours affiché car utilisateur-friendly)
  static void showValidationError(String message) {
    Get.snackbar(
      'Erreur de validation',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      isDismissible: true,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  /// Affiche un message de succès
  static void showSuccess(String message, {String? title}) {
    Get.snackbar(
      title ?? 'Succès',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      isDismissible: true,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  /// Affiche un message d'information
  static void showInfo(String message, {String? title}) {
    Get.snackbar(
      title ?? 'Information',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      isDismissible: true,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  /// Vérifie si une erreur est probablement survenue après un succès
  /// (erreurs de parsing, JSON, type, etc. qui peuvent survenir lors du traitement de la réponse)
  static bool isPostSuccessError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('parsing') ||
        errorStr.contains('json') ||
        errorStr.contains('type') ||
        errorStr.contains('cast') ||
        errorStr.contains('null') ||
        errorStr.contains('no such method') ||
        errorStr.contains('method not found');
  }

  /// Affiche une erreur seulement si ce n'est pas une erreur post-succès
  /// Utilise cette méthode pour les erreurs qui doivent être affichées à l'utilisateur
  static void showErrorIfNotPostSuccess(
    dynamic error, {
    String? title,
    String? customMessage,
    bool forceShow = false, // Force l'affichage même en production
  }) {
    if (isPostSuccessError(error)) {
      // Ne pas afficher d'erreur pour les erreurs de parsing qui peuvent survenir après un succès
      AppLogger.debug(
        'Erreur post-succès ignorée: $error',
        tag: 'ERROR_HELPER',
      );
      return;
    }

    showError(
      error,
      title: title,
      customMessage: customMessage,
      showToUser: forceShow || kDebugMode,
      ignorePostSuccess: true, // Déjà vérifié
    );
  }

  /// Affiche une erreur seulement en mode debug
  /// En production, l'erreur est seulement loggée
  static void showErrorDebugOnly(
    dynamic error, {
    String? title,
    String? customMessage,
  }) {
    // Toujours logger l'erreur
    AppLogger.error(
      'Error (debug only): $error',
      tag: 'ERROR_HELPER',
      error: error is Exception ? error : Exception(error.toString()),
    );

    // Afficher seulement en mode debug
    if (kDebugMode) {
      final message = customMessage ?? error.toString();
      Get.snackbar(
        title ?? 'Erreur (Debug)',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        isDismissible: true,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    }
  }
}
