import 'package:flutter/material.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/logger.dart';

/// Callback pour afficher un snackbar (défini dans [main.dart] sur le `ScaffoldMessenger` racine).
void Function(
  String title,
  String message, {
  Color? backgroundColor,
  Color? colorText,
  Duration? duration,
})? validationHelperShowSnackbar;

/// Helper unifié : états de page (listes), erreurs chargement, et **validateurs de formulaire**.
class ValidationHelper {
  // --- Logs (listes / pages validation) ---

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
      final item = items[i];
      print('📋 ${item.runtimeType}: ${item.toString()}');
    }

    if (items.length > 5) {
      print('📋 ... et ${items.length - 5} autres éléments');
    }
  }

  static void logError(String pageName, String methodName, dynamic error) {
    print('❌ $pageName.$methodName - Erreur: $error');
  }

  static void logSuccess(String pageName, String methodName, String action) {
    print('✅ $pageName.$methodName - $action réussi');
  }

  /// Erreur technique / chargement (snackbar rouge par défaut).
  static void handleError(
    String pageName,
    String methodName,
    dynamic error, {
    String? customMessage,
    bool showToUser = false,
  }) {
    logError(pageName, methodName, error);

    if (!showToUser && !AppConfig.showErrorMessagesToUsers) {
      return;
    }

    final userMessage =
        customMessage ??
        (AppConfig.showErrorMessagesToUsers
            ? 'Erreur lors du chargement: $error'
            : AppConfig.getUserFriendlyErrorMessage(error));

    validationHelperShowSnackbar?.call(
      'Erreur',
      userMessage,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  static void handleSuccess(String action, {String? customMessage}) {
    logSuccess('Validation', action, action);
    validationHelperShowSnackbar?.call(
      'Succès',
      customMessage ?? '$action avec succès',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  /// Message de succès court (formulaires).
  static void showSuccessMessage(String message) {
    AppLogger.info('Success: $message');
    validationHelperShowSnackbar?.call(
      'Succès',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// Erreur de validation formulaire (snackbar orange).
  static void showValidationError(String message, {bool showToUser = true}) {
    AppLogger.warning('Validation error: $message');

    if (!showToUser && !AppConfig.showErrorMessagesToUsers) {
      return;
    }

    validationHelperShowSnackbar?.call(
      'Erreur de validation',
      message,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  // --- Widgets d'état ---

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

  static Widget buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

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

  // --- Validateurs formulaire (ex-ValidationHelperEnhanced) ---

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format d\'email invalide';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de téléphone est requis';
    }
    final phoneRegex = RegExp(r'^[0-9+\-\s()]+$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Format de téléphone invalide';
    }
    return null;
  }

  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Ce champ'} est requis';
    }
    return null;
  }

  static String? validateNumber(
    String? value, {
    double? min,
    double? max,
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Ce champ'} est requis';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return '${fieldName ?? 'Ce champ'} doit être un nombre';
    }
    if (min != null && number < min) {
      return '${fieldName ?? 'Ce champ'} doit être supérieur ou égal à $min';
    }
    if (max != null && number > max) {
      return '${fieldName ?? 'Ce champ'} doit être inférieur ou égal à $max';
    }
    return null;
  }

  static String? validateDate(DateTime? value, {String? fieldName}) {
    if (value == null) {
      return '${fieldName ?? 'La date'} est requise';
    }
    return null;
  }

  static String? validateFutureDate(DateTime? value, {String? fieldName}) {
    final baseError = validateDate(value, fieldName: fieldName);
    if (baseError != null) return baseError;
    if (value!.isBefore(DateTime.now())) {
      return '${fieldName ?? 'La date'} doit être dans le futur';
    }
    return null;
  }

  static String? validateLength(
    String? value, {
    int? min,
    int? max,
    String? fieldName,
  }) {
    if (value == null) {
      return '${fieldName ?? 'Ce champ'} est requis';
    }
    if (min != null && value.length < min) {
      return '${fieldName ?? 'Ce champ'} doit contenir au moins $min caractères';
    }
    if (max != null && value.length > max) {
      return '${fieldName ?? 'Ce champ'} doit contenir au plus $max caractères';
    }
    return null;
  }
}
