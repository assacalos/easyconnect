import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/models/user_model.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:get/get.dart';

/// Service centralisé pour la gestion de la session utilisateur
/// Fournit une interface unique pour accéder au token et aux informations utilisateur
/// Version améliorée avec stockage sécurisé et rafraîchissement automatique
class SessionService {
  // Stockage sécurisé pour les données sensibles (tokens)
  static final _secureStorage = FlutterSecureStorage(
    aOptions: const AndroidOptions(encryptedSharedPreferences: true),
    iOptions: const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Stockage normal pour les données non sensibles
  static final _storage = GetStorage();
  static const String _tokenKey = 'token';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _userKey = 'user';
  static const String _userIdKey = 'userId';
  static const String _userRoleKey = 'userRole';
  static const String _tokenExpiryKey = 'tokenExpiry';
  static const String _loginInProgressKey = 'loginInProgress';
  static const String _lastActivityKey = 'lastActivity';

  // Flag pour éviter les conflits lors de la connexion
  static bool _isLoginInProgress = false;

  // Timers pour les vérifications périodiques
  static Timer? _validationTimer;
  static Timer? _activityTimer;
  static bool _isRefreshing = false;

  /// Initialise le service (appelé au démarrage de l'app)
  static Future<void> initialize() async {
    // Migrer les anciens tokens depuis GetStorage vers SecureStorage si nécessaire
    await _migrateTokensIfNeeded();

    // Initialiser l'état de l'application comme étant au premier plan
    _appLifecycleState = AppLifecycleState.resumed;

    // Démarrer les vérifications périodiques si l'utilisateur est connecté
    if (isAuthenticated()) {
      startPeriodicValidation();
      startActivityTracking();
      updateLastActivity();
    }
  }

  /// Migre les tokens depuis GetStorage vers SecureStorage (rétrocompatibilité)
  static Future<void> _migrateTokensIfNeeded() async {
    try {
      final oldToken = _storage.read<String?>(_tokenKey);
      final secureToken = await _secureStorage.read(key: _tokenKey);

      if (oldToken != null && oldToken.isNotEmpty && secureToken == null) {
        await _secureStorage.write(key: _tokenKey, value: oldToken);
        AppLogger.info(
          'Token migré vers le stockage sécurisé',
          tag: 'SESSION_SERVICE',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la migration du token: $e',
        tag: 'SESSION_SERVICE',
      );
    }
  }

  /// Marque qu'une connexion est en cours
  static void setLoginInProgress(bool value) {
    _isLoginInProgress = value;
    _storage.write(_loginInProgressKey, value);
  }

  /// Vérifie si une connexion est en cours
  static bool isLoginInProgress() {
    if (_isLoginInProgress) return true;
    return _storage.read<bool>(_loginInProgressKey) ?? false;
  }

  /// Récupère le token d'authentification (depuis le stockage sécurisé)
  static Future<String?> getToken() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token != null && token.isNotEmpty) {
        return token;
      }
      // Fallback vers GetStorage pour rétrocompatibilité
      final oldToken = _storage.read<String?>(_tokenKey);
      if (oldToken != null && oldToken.isNotEmpty) {
        await _secureStorage.write(key: _tokenKey, value: oldToken);
        return oldToken;
      }
      return null;
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la récupération du token: $e',
        tag: 'SESSION_SERVICE',
      );
      return _storage.read<String?>(_tokenKey);
    }
  }

  /// Version synchrone pour compatibilité avec le code existant
  /// ⚠️ Utiliser getToken() async de préférence pour la sécurité
  static String? getTokenSync() {
    return _storage.read<String?>(_tokenKey);
  }

  /// Vérifie si l'utilisateur est authentifié
  /// Les tokens n'expirent jamais côté frontend (seul le backend peut invalider un token)
  /// Ne tente pas de rafraîchir automatiquement ici pour éviter les boucles
  static bool isAuthenticated({bool ignoreLoginInProgress = false}) {
    // Si une connexion est en cours et qu'on ne doit pas l'ignorer, considérer comme authentifié
    if (!ignoreLoginInProgress && isLoginInProgress()) {
      return true;
    }

    final token = getTokenSync();
    final user = _storage.read(_userKey);

    if (token == null || token.isEmpty || user == null) {
      return false;
    }

    // ⚠️ EXPIRATION DÉSACTIVÉE : Les tokens n'expirent jamais côté frontend
    // Si le backend invalide un token, il retournera une erreur 401
    // qui sera gérée par AuthErrorHandler

    return true;
  }

  /// Récupère l'ID de l'utilisateur
  static int? getUserId() {
    return _storage.read<int?>(_userIdKey);
  }

  /// Récupère le rôle de l'utilisateur
  static int? getUserRole() {
    final role = _storage.read(_userRoleKey);
    if (role is int) return role;
    if (role is String) return int.tryParse(role);
    return null;
  }

  /// Récupère les informations utilisateur complètes
  static Map<String, dynamic>? getUser() {
    return _storage.read<Map<String, dynamic>>(_userKey);
  }

  /// Récupère l'AuthController si disponible
  static AuthController? getAuthController() {
    if (Get.isRegistered<AuthController>()) {
      try {
        return Get.find<AuthController>();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Vérifie si l'utilisateur a un rôle spécifique
  static bool hasRole(int role) {
    return getUserRole() == role;
  }

  /// Vérifie si l'utilisateur a l'un des rôles spécifiés
  static bool hasAnyRole(List<int> roles) {
    final userRole = getUserRole();
    return userRole != null && roles.contains(userRole);
  }

  /// Nettoie la session (utilisé lors de la déconnexion)
  static Future<void> clearSession() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _storage.remove(_userKey);
      await _storage.remove(_userIdKey);
      await _storage.remove(_userRoleKey);
      await _storage.remove(_tokenExpiryKey);
      await _storage.remove(_loginInProgressKey);
      await _storage.remove(_lastActivityKey);
      await _storage.remove(_tokenKey); // Ancien token dans GetStorage
      _isLoginInProgress = false;
      stopPeriodicValidation();
      stopActivityTracking();
    } catch (e) {
      AppLogger.error(
        'Erreur lors du nettoyage de la session: $e',
        tag: 'SESSION_SERVICE',
      );
    }
  }

  /// Sauvegarde le token (sans expiration - tokens permanents)
  /// [expiresIn] : Paramètre conservé pour compatibilité mais non utilisé
  /// [refreshToken] : Token de rafraîchissement optionnel
  static Future<void> saveToken(
    String token, {
    int expiresIn = 2592000, // Paramètre ignoré - tokens permanents
    String? refreshToken,
  }) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
      await _storage.write(_tokenKey, token); // Rétrocompatibilité
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      }
      // ⚠️ EXPIRATION DÉSACTIVÉE : Ne plus stocker de date d'expiration
      // Les tokens n'expirent jamais côté frontend
      // Supprimer l'ancienne expiration si elle existe
      await _storage.remove(_tokenExpiryKey);
      updateLastActivity();
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la sauvegarde du token: $e',
        tag: 'SESSION_SERVICE',
      );
      await _storage.write(_tokenKey, token);
      await _storage.remove(_tokenExpiryKey);
    }
  }

  /// Sauvegarde les informations utilisateur
  static Future<void> saveUser(Map<String, dynamic> user) async {
    await _storage.write(_userKey, user);
    if (user['id'] != null) {
      await _storage.write(_userIdKey, user['id']);
    }
    if (user['role'] != null) {
      await _storage.write(_userRoleKey, user['role']);
    }
  }

  /// Vérifie si le token est expiré
  static bool isTokenExpired() {
    final expiryTimestamp = _storage.read<int?>(_tokenExpiryKey);
    if (expiryTimestamp == null) {
      // Si pas d'expiration définie, considérer comme valide
      return false;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    return now >= expiryTimestamp;
  }

  /// Récupère le temps restant avant expiration du token (en secondes)
  /// Retourne null si pas d'expiration définie
  static int? getTokenTimeRemaining() {
    final expiryTimestamp = _storage.read<int?>(_tokenExpiryKey);
    if (expiryTimestamp == null) {
      return null;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final remaining = (expiryTimestamp - now) ~/ 1000;
    return remaining > 0 ? remaining : 0;
  }

  /// Vérifie si la session est valide (token présent et utilisateur présent)
  /// Utile pour le middleware pour éviter les redirections pendant la connexion
  /// Les tokens n'expirent jamais côté frontend
  static bool isValidSession({bool allowLoginInProgress = true}) {
    // Si une connexion est en cours et qu'on l'autorise, considérer comme valide
    if (allowLoginInProgress && isLoginInProgress()) {
      return true;
    }

    final token = getTokenSync();
    final user = _storage.read(_userKey);

    if (token == null || token.isEmpty || user == null) {
      return false;
    }

    // ⚠️ EXPIRATION DÉSACTIVÉE : Les tokens n'expirent jamais côté frontend
    // La validation est gérée par le backend (erreurs 401)

    return true;
  }

  /// Rafraîchit le token automatiquement
  /// Utilise l'endpoint POST /api/refresh avec authentification Sanctum
  static Future<bool> refreshToken() async {
    // Éviter les rafraîchissements multiples simultanés
    if (_isRefreshing) {
      AppLogger.debug('Rafraîchissement déjà en cours', tag: 'SESSION_SERVICE');
      return false;
    }

    _isRefreshing = true;

    try {
      // Récupérer le token actuel pour l'authentification
      final currentToken = await getToken();
      if (currentToken == null || currentToken.isEmpty) {
        AppLogger.warning(
          'Aucun token disponible pour le rafraîchissement',
          tag: 'SESSION_SERVICE',
        );
        _isRefreshing = false;
        return false;
      }

      final url = '${AppConfig.baseUrl}/refresh';
      AppLogger.info(
        'Tentative de rafraîchissement du token',
        tag: 'SESSION_SERVICE',
      );

      // L'endpoint requiert l'authentification Sanctum (token dans le header)
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $currentToken',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout lors du rafraîchissement du token');
            },
          );

      AppLogger.httpResponse(response.statusCode, url, tag: 'SESSION_SERVICE');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Gérer différents formats de réponse
        Map<String, dynamic>? responseData;
        if (data['success'] == true && data['data'] != null) {
          responseData = data['data'] as Map<String, dynamic>?;
        } else if (data['token'] != null) {
          // Format direct avec token et user
          responseData = data;
        }

        if (responseData != null) {
          final newToken = responseData['token'] as String?;
          final expiresIn = responseData['expires_in'] as int? ?? 86400;
          final newRefreshToken = responseData['refresh_token'] as String?;

          // Mettre à jour les données utilisateur si fournies
          if (responseData['user'] != null) {
            await saveUser(responseData['user'] as Map<String, dynamic>);
            // Mettre à jour aussi l'AuthController si disponible
            final authController = getAuthController();
            if (authController != null) {
              try {
                authController.userAuth.value = UserModel.fromJson(
                  responseData['user'] as Map<String, dynamic>,
                );
              } catch (e) {
                AppLogger.warning(
                  'Erreur lors de la mise à jour de l\'utilisateur: $e',
                  tag: 'SESSION_SERVICE',
                );
              }
            }
          }

          if (newToken != null && newToken.isNotEmpty) {
            await saveToken(
              newToken,
              expiresIn: expiresIn,
              refreshToken: newRefreshToken,
            );

            AppLogger.info(
              'Token rafraîchi avec succès',
              tag: 'SESSION_SERVICE',
            );
            _isRefreshing = false;
            return true;
          }
        }
      }

      // Gérer les erreurs d'authentification
      if (response.statusCode == 401) {
        AppLogger.warning(
          'Token invalide lors du rafraîchissement - Déconnexion requise',
          tag: 'SESSION_SERVICE',
        );
        _isRefreshing = false;
        return false;
      }

      // Si l'endpoint n'existe pas (404), c'est normal, on continue sans rafraîchissement
      if (response.statusCode == 404) {
        AppLogger.info(
          'Endpoint de rafraîchissement non disponible (404)',
          tag: 'SESSION_SERVICE',
        );
        _isRefreshing = false;
        return false;
      }

      AppLogger.warning(
        'Échec du rafraîchissement du token: ${response.statusCode} - ${response.body}',
        tag: 'SESSION_SERVICE',
      );
      _isRefreshing = false;
      return false;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors du rafraîchissement du token: $e',
        tag: 'SESSION_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      _isRefreshing = false;
      return false;
    }
  }

  /// S'assure que le token est valide
  /// Les tokens n'expirent jamais côté frontend - toujours valide
  static Future<bool> ensureValidToken() async {
    // ⚠️ EXPIRATION DÉSACTIVÉE : Les tokens n'expirent jamais
    // La validation est gérée par le backend (erreurs 401)
    return true;
  }

  /// Met à jour la dernière activité
  static void updateLastActivity() {
    _storage.write(_lastActivityKey, DateTime.now().millisecondsSinceEpoch);
  }

  // État de l'application (premier plan/arrière-plan)
  static AppLifecycleState? _appLifecycleState;

  /// Met à jour l'état du cycle de vie de l'application
  static void updateAppLifecycleState(AppLifecycleState? state) {
    _appLifecycleState = state;
    // Mettre à jour l'activité quand l'app revient au premier plan
    if (state == AppLifecycleState.resumed) {
      updateLastActivity();
    }
  }

  /// Vérifie si l'application est en arrière-plan
  static bool isAppInBackground() {
    return _appLifecycleState == AppLifecycleState.paused ||
        _appLifecycleState == AppLifecycleState.inactive ||
        _appLifecycleState == AppLifecycleState.detached;
  }

  /// Vérifie si l'utilisateur est inactif
  /// [timeoutMinutes] : Durée d'inactivité avant déconnexion (par défaut 2 heures)
  static bool isInactive({int timeoutMinutes = 120}) {
    final lastActivity = _storage.read<int?>(_lastActivityKey);
    if (lastActivity == null) {
      updateLastActivity();
      return false;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final inactiveSeconds = (now - lastActivity) ~/ 1000;
    return inactiveSeconds > (timeoutMinutes * 60);
  }

  /// Démarre le suivi de l'activité
  /// DÉSACTIVÉE : Pas de déconnexion automatique pour inactivité
  static void startActivityTracking() {
    stopActivityTracking();
    // TOKEN PERMANENT : Suivi d'activité désactivé
    // L'utilisateur reste connecté indéfiniment, même en arrière-plan
    AppLogger.info(
      'Suivi d\'activité désactivé (tokens permanents)',
      tag: 'SESSION_SERVICE',
    );
  }

  /// Arrête le suivi de l'activité
  static void stopActivityTracking() {
    _activityTimer?.cancel();
    _activityTimer = null;
  }

  /// Démarre la vérification périodique (DÉSACTIVÉE - tokens permanents)
  /// Cette fonction est conservée pour compatibilité mais ne fait plus rien
  static void startPeriodicValidation() {
    // ⚠️ VALIDATION PÉRIODIQUE DÉSACTIVÉE : Les tokens n'expirent jamais
    // Si le backend invalide un token, les erreurs 401 seront gérées par AuthErrorHandler
    stopPeriodicValidation();
    AppLogger.info(
      'Validation périodique désactivée - tokens permanents',
      tag: 'SESSION_SERVICE',
    );
  }

  /// Arrête la vérification périodique
  static void stopPeriodicValidation() {
    _validationTimer?.cancel();
    _validationTimer = null;
  }
}
