import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

/// Configuration centralisée de l'application
class AppConfig {
  static final _storage = GetStorage();

  // URLs
  static const String _defaultBaseUrl = 'http://10.0.2.2:8000/api';
  static const String _productionBaseUrl =
      'https://easykonect.smil-app.com/api';

  /// Récupère l'URL de base de l'API
  static String get baseUrl {
    // Vérifier si une URL personnalisée est stockée (priorité la plus haute)
    final customUrl = _storage.read<String>('api_base_url');
    if (customUrl != null && customUrl.isNotEmpty) {
      return customUrl;
    }

    // Vérifier si on force l'URL de production via variable d'environnement
    const bool forceProduction = bool.fromEnvironment(
      'FORCE_PRODUCTION_URL',
      defaultValue: false,
    );
    if (forceProduction) {
      return _productionBaseUrl;
    }

    // Vérifier si on veut utiliser l'URL locale via variable d'environnement
    const bool useLocalUrl = bool.fromEnvironment(
      'USE_LOCAL_URL',
      defaultValue: false,
    );

    // Si on est en mode debug ET qu'on veut utiliser l'URL locale
    if (kDebugMode && useLocalUrl) {
      return _defaultBaseUrl;
    }

    // Par défaut, utiliser l'URL de production (pour debug, profile et release)
    // ⚠️ IMPORTANT: Même en mode debug, l'URL de production est utilisée par défaut
    // Pour utiliser l'URL locale en debug, il faut compiler avec:
    // flutter build apk --debug --dart-define=USE_LOCAL_URL=true
    return _productionBaseUrl;
  }

  /// Retourne l'URL de production
  static String get productionUrl => _productionBaseUrl;

  /// Retourne l'URL locale (pour développement)
  static String get localUrl => _defaultBaseUrl;

  /// Vérifie quelle URL est actuellement utilisée
  static String getCurrentUrlInfo() {
    final currentUrl = baseUrl;
    if (currentUrl == _productionBaseUrl) {
      return 'Production: $_productionBaseUrl';
    } else if (currentUrl == _defaultBaseUrl) {
      return 'Locale: $_defaultBaseUrl';
    } else {
      return 'Personnalisée: $currentUrl';
    }
  }

  /// Définit l'URL de base de l'API
  static Future<void> setBaseUrl(String url) async {
    await _storage.write('api_base_url', url);
  }

  /// Réinitialise l'URL à la valeur par défaut
  static Future<void> resetBaseUrl() async {
    await _storage.remove('api_base_url');
  }

  // Timeouts
  static const Duration defaultTimeout = Duration(seconds: 15);
  static const Duration longTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 5);

  // Retry
  static const int defaultMaxRetries = 3;
  static const Duration retryInitialDelay = Duration(seconds: 1);
  static const Duration retryMaxDelay = Duration(seconds: 30);

  // Cache
  static const Duration defaultCacheDuration = Duration(minutes: 5);
  static const Duration longCacheDuration = Duration(hours: 1);

  // Pagination
  static const int defaultPageSize = 20;
  static const int largePageSize = 50;

  // Version
  static const String appVersion = '1.0.0';
  static const String appName = 'EasyConnect';

  // Affichage des erreurs
  /// Masquer les messages d'erreur techniques aux utilisateurs finaux
  /// En production, les erreurs techniques ne sont pas affichées
  static bool get showErrorMessagesToUsers {
    // En mode debug, on peut afficher les erreurs pour le développement
    // En production (release), on masque les erreurs techniques
    return kDebugMode;
  }

  /// Retourne un message utilisateur-friendly pour les erreurs
  static String getUserFriendlyErrorMessage(dynamic error) {
    // Ne jamais afficher les détails techniques aux utilisateurs
    if (!showErrorMessagesToUsers) {
      // Messages génériques pour les utilisateurs finaux
      final errorString = error.toString().toLowerCase();

      if (errorString.contains('timeout') ||
          errorString.contains('timed out')) {
        return 'Connexion lente. Veuillez réessayer.';
      }
      if (errorString.contains('network') ||
          errorString.contains('connection')) {
        return 'Problème de connexion. Vérifiez votre internet.';
      }
      if (errorString.contains('404') || errorString.contains('not found')) {
        return 'Ressource introuvable.';
      }
      if (errorString.contains('500') || errorString.contains('server')) {
        return 'Erreur serveur. Réessayez plus tard.';
      }
      if (errorString.contains('401') || errorString.contains('unauthorized')) {
        return 'Session expirée. Veuillez vous reconnecter.';
      }
      if (errorString.contains('403') || errorString.contains('forbidden')) {
        return 'Accès refusé.';
      }
      if (errorString.contains('422') || errorString.contains('validation')) {
        return 'Données invalides. Vérifiez vos saisies.';
      }

      // Message générique par défaut
      return 'Une erreur est survenue. Veuillez réessayer.';
    }

    // En mode debug, on peut afficher l'erreur complète
    return error.toString();
  }
}
