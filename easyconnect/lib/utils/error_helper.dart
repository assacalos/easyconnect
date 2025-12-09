import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/logger.dart';

/// Helper pour gérer l'affichage des erreurs aux utilisateurs
class ErrorHelper {
  /// Affiche un message d'erreur de manière sécurisée
  /// Ne montre pas les détails techniques aux utilisateurs finaux
  static void showError(
    dynamic error, {
    String? title,
    String? customMessage,
    bool showToUser = false, // Par défaut, ne pas afficher
    Duration? duration,
  }) {
    // Logger l'erreur pour le débogage
    AppLogger.error(
      'Error: $error',
      tag: 'ERROR_HELPER',
      error: error is Exception ? error : Exception(error.toString()),
    );

    // Ne pas afficher les erreurs techniques aux utilisateurs finaux
    if (!showToUser && !AppConfig.showErrorMessagesToUsers) {
      return; // Masquer l'erreur pour les utilisateurs finaux
    }

    // Déterminer le message à afficher
    final message =
        customMessage ??
        (AppConfig.showErrorMessagesToUsers
            ? error.toString()
            : AppConfig.getUserFriendlyErrorMessage(error));

    // Afficher le snackbar
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
  static void showErrorIfNotPostSuccess(
    dynamic error, {
    String? title,
    String? customMessage,
  }) {
    if (isPostSuccessError(error)) {
      // Ne pas afficher d'erreur pour les erreurs de parsing qui peuvent survenir après un succès
      return;
    }

    showError(
      error,
      title: title,
      customMessage: customMessage,
      showToUser: true,
    );
  }
}
