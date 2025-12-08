import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:get/get.dart';

/// Service centralisé pour la gestion de la session utilisateur
/// Fournit une interface unique pour accéder au token et aux informations utilisateur
class SessionService {
  static final _storage = GetStorage();
  static const String _tokenKey = 'token';
  static const String _userKey = 'user';
  static const String _userIdKey = 'userId';
  static const String _userRoleKey = 'userRole';
  static const String _tokenExpiryKey = 'tokenExpiry';
  static const String _loginInProgressKey = 'loginInProgress';

  // Flag pour éviter les conflits lors de la connexion
  static bool _isLoginInProgress = false;

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

  /// Récupère le token d'authentification
  static String? getToken() {
    return _storage.read<String?>(_tokenKey);
  }

  /// Vérifie si l'utilisateur est authentifié
  /// Prend en compte l'expiration du token et les connexions en cours
  static bool isAuthenticated({bool ignoreLoginInProgress = false}) {
    // Si une connexion est en cours et qu'on ne doit pas l'ignorer, considérer comme authentifié
    if (!ignoreLoginInProgress && isLoginInProgress()) {
      return true;
    }

    final token = getToken();
    final user = _storage.read(_userKey);

    if (token == null || token.isEmpty || user == null) {
      return false;
    }

    // Vérifier l'expiration du token si disponible
    final expiryTimestamp = _storage.read<int?>(_tokenExpiryKey);
    if (expiryTimestamp != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now >= expiryTimestamp) {
        // Token expiré, nettoyer la session
        clearSession();
        return false;
      }
    }

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
    await _storage.remove(_tokenKey);
    await _storage.remove(_userKey);
    await _storage.remove(_userIdKey);
    await _storage.remove(_userRoleKey);
    await _storage.remove(_tokenExpiryKey);
    await _storage.remove(_loginInProgressKey);
    _isLoginInProgress = false;
  }

  /// Sauvegarde le token avec gestion de l'expiration
  /// [expiresIn] : Durée de validité en secondes (par défaut 24h)
  static Future<void> saveToken(String token, {int expiresIn = 86400}) async {
    await _storage.write(_tokenKey, token);

    // Calculer l'expiration (timestamp en millisecondes)
    final expiryTimestamp =
        DateTime.now().add(Duration(seconds: expiresIn)).millisecondsSinceEpoch;
    await _storage.write(_tokenExpiryKey, expiryTimestamp);
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

  /// Vérifie si la session est valide (token présent, non expiré, et utilisateur présent)
  /// Utile pour le middleware pour éviter les redirections pendant la connexion
  static bool isValidSession({bool allowLoginInProgress = true}) {
    // Si une connexion est en cours et qu'on l'autorise, considérer comme valide
    if (allowLoginInProgress && isLoginInProgress()) {
      return true;
    }

    final token = getToken();
    final user = _storage.read(_userKey);

    if (token == null || token.isEmpty || user == null) {
      return false;
    }

    // Vérifier l'expiration
    if (isTokenExpired()) {
      return false;
    }

    return true;
  }
}
