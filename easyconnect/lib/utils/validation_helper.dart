import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/utils/app_config.dart';

/// Helper class pour standardiser les pages de validation
class ValidationHelper {
  /// Logs de débogage standardisés pour le chargement des données
  static void logDataLoading(
    String pageName,
    String methodName,
    String status,
    int itemCount,
    List<dynamic> items,
  ) {
    print('🔍 $pageName.$methodName - Début');
    print('📊 Paramètres: status=$status');
    print('📊 $pageName.$methodName - $itemCount éléments chargés');

    for (int i = 0; i < items.length && i < 5; i++) {
      // Limiter à 5 éléments pour éviter les logs trop longs
      final item = items[i];
      print('📋 ${item.runtimeType}: ${item.toString()}');
    }

    if (items.length > 5) {
      print('📋 ... et ${items.length - 5} autres éléments');
    }
  }

  /// Logs d'erreur standardisés
  static void logError(String pageName, String methodName, dynamic error) {
    print('❌ $pageName.$methodName - Erreur: $error');
  }

  /// Logs de succès standardisés
  static void logSuccess(String pageName, String methodName, String action) {
    print('✅ $pageName.$methodName - $action réussi');
  }

  /// Gestion d'erreur standardisée avec snackbar
  static void handleError(
    String pageName,
    String methodName,
    dynamic error, {
    String? customMessage,
    bool showToUser = false, // Par défaut, ne pas afficher aux utilisateurs
  }) {
    logError(pageName, methodName, error);

    // Ne pas afficher les erreurs techniques aux utilisateurs finaux
    if (!showToUser && !AppConfig.showErrorMessagesToUsers) {
      return; // Masquer l'erreur pour les utilisateurs finaux
    }

    // Afficher un message utilisateur-friendly
    final userMessage =
        customMessage ??
        (AppConfig.showErrorMessagesToUsers
            ? 'Erreur lors du chargement: $error'
            : AppConfig.getUserFriendlyErrorMessage(error));

    Get.snackbar(
      'Erreur',
      userMessage,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  /// Gestion de succès standardisée avec snackbar
  static void handleSuccess(String action, {String? customMessage}) {
    logSuccess('Validation', action, action);
    Get.snackbar(
      'Succès',
      customMessage ?? '$action avec succès',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  /// Widget d'état vide standardisé
  static Widget buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Widget de chargement standardisé
  static Widget buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  /// Méthode pour recharger les données avec logs
  static Future<void> reloadData<T>(
    String pageName,
    String methodName,
    String status,
    Future<List<T>> Function(String status) loadFunction,
    Function(List<T>) onSuccess,
    Function(dynamic) onError,
  ) async {
    try {
      print('🔄 $pageName.$methodName - Rechargement des données');
      final items = await loadFunction(status);
      logDataLoading(pageName, methodName, status, items.length, items);
      onSuccess(items);
    } catch (e) {
      logError(pageName, methodName, e);
      onError(e);
    }
  }
}
