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
    // Vérifier si une URL personnalisée est stockée
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

    // Par défaut, utiliser l'URL de production pour tous les builds
    // (debug, profile, release) sauf si on est en mode debug ET qu'on n'a pas forcé
    // Utiliser l'URL locale uniquement si explicitement demandé via variable d'environnement
    const bool useLocalUrl = bool.fromEnvironment(
      'USE_LOCAL_URL',
      defaultValue: false,
    );

    // Si on est en mode debug ET qu'on veut utiliser l'URL locale
    if (kDebugMode && useLocalUrl) {
      return _defaultBaseUrl;
    }

    // Par défaut, utiliser l'URL de production (pour debug, profile et release)
    return _productionBaseUrl;
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
}
