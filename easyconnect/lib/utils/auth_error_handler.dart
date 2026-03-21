import 'package:flutter/foundation.dart';
import 'package:easyconnect/services/session_service.dart';
import 'package:http/http.dart' show Response;
import 'package:easyconnect/utils/logger.dart';

/// Gestion centralisée des **401** et déconnexion.
///
/// **Chemin nominal (API métier)** : `HttpInterceptor` appelle déjà
/// `SessionService.ensureValidToken`, puis en cas de 401 tente `refreshToken` et
/// **réessaie une fois** la requête. Les services appellent ensuite
/// [handleHttpResponse] : par défaut [skipRefresh] est `true` pour ne pas
/// dupliquer un second cycle de refresh (comportement cohérent, un seul message
/// « session expirée »). Pour une réponse 401 **sans** passer par
/// `HttpInterceptor`, utiliser `skipRefresh: false`.
///
/// **Cas conservés** : période de grâce après login, debounce du snackbar,
/// pas de déconnexion sur les écrans auth, [logoutCallback] depuis `main.dart`.
class AuthErrorHandler {
  static bool _isHandlingLogout = false;
  static int? _lastSessionExpiredShownAt;
  static const int _sessionExpiredDebounceMs = 60000; // 1 min entre deux messages "session expirée"

  /// Callback pour effectuer la déconnexion (à définir par l'app, ex: ref.read(authProvider.notifier).logout).
  static Future<void> Function({bool silent, String? redirectTo})? logoutCallback;

  /// Callback pour récupérer la route actuelle (ex: go_router).
  static String Function()? currentRouteCallback;

  /// Callback pour afficher un snackbar (ex: ScaffoldMessenger).
  static void Function(String title, String message, {Duration? duration})? showSnackbarCallback;

  /// Réagit à une [Response] HTTP, surtout **401 Unauthorized**.
  ///
  /// [skipRefresh] : `true` par défaut — après une requête passée par
  /// `HttpInterceptor` (refresh + retry déjà effectués). `false` si la requête
  /// n’a pas utilisé l’intercepteur et qu’un refresh Sanctum peut encore aider.
  static Future<void> handleHttpResponse(
    Response response, {
    bool skipRefresh = true,
  }) async {
    if (response.statusCode == 401) {
      if (_isHandlingLogout) {
        AppLogger.debug(
          '401 ignoré (déconnexion déjà en cours)',
          tag: 'AUTH_ERROR_HANDLER',
        );
        return;
      }
      if (SessionService.isWithinGracePeriodAfterLogin()) {
        AppLogger.info(
          '401 ignoré (période de grâce après connexion)',
          tag: 'AUTH_ERROR_HANDLER',
        );
        return;
      }
      if (!skipRefresh) {
        try {
          bool refreshed = await SessionService.refreshToken();
          if (refreshed) {
            AppLogger.info(
              'Token rafraîchi avec succès après erreur 401',
              tag: 'AUTH_ERROR_HANDLER',
            );
            return;
          }
          // Un autre appel peut être en train de rafraîchir : attendre un peu puis réessayer une fois
          await Future.delayed(const Duration(milliseconds: 800));
          refreshed = await SessionService.refreshToken();
          if (refreshed) {
            AppLogger.info(
              'Token rafraîchi après second essai (401)',
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
      await _handleUnauthorized();
    }
  }

  static Future<void> handleException(dynamic error) async {
    if (_isHandlingLogout) {
      return;
    }
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('401') ||
        errorString.contains('unauthorized') ||
        errorString.contains('non autorisé')) {
      if (SessionService.isWithinGracePeriodAfterLogin()) {
        AppLogger.info(
          'Erreur auth ignorée (période de grâce après connexion)',
          tag: 'AUTH_ERROR_HANDLER',
        );
        return;
      }
      await _handleUnauthorized();
    }
  }

  static Future<void> _handleUnauthorized({bool? showMessage}) async {
    if (_isHandlingLogout) return;
    _isHandlingLogout = true;

    try {
      await Future.delayed(const Duration(milliseconds: 50));

      final route = currentRouteCallback?.call() ?? '';
      final isOnAuthPage = route == '/welcome' ||
          route == '/login' ||
          route == '/register' ||
          route.contains('welcome') ||
          route.contains('login') ||
          route.contains('register');
      final isOnSplash = route == '/splash' || route.contains('splash');
      final now = DateTime.now().millisecondsSinceEpoch;
      final canShowMessage = _lastSessionExpiredShownAt == null ||
          (now - _lastSessionExpiredShownAt!) > _sessionExpiredDebounceMs;
      final shouldShowMessage = !isOnAuthPage &&
          (showMessage ?? kDebugMode) &&
          canShowMessage &&
          showSnackbarCallback != null;

      if (shouldShowMessage) {
        _lastSessionExpiredShownAt = now;
        showSnackbarCallback!(
          'Session expirée',
          'Votre session a expiré. Veuillez vous reconnecter.',
          duration: const Duration(seconds: 3),
        );
        await Future.delayed(const Duration(milliseconds: 400));
      }

      final String? redirectTo = isOnAuthPage
          ? null
          : (isOnSplash ? '/welcome' : '/login');

      if (logoutCallback != null) {
        AppLogger.warning(
          'Session expirée - Déconnexion automatique (redirectTo=$redirectTo, route=$route)',
          tag: 'AUTH_ERROR_HANDLER',
        );
        await logoutCallback!(silent: !shouldShowMessage, redirectTo: redirectTo);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la gestion de la déconnexion: $e',
        tag: 'AUTH_ERROR_HANDLER',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        _isHandlingLogout = false;
      });
    }
  }

  /// À appeler après un login réussi pour permettre à nouveau l'affichage du message "session expirée" si besoin.
  static void resetSessionExpiredDebounce() {
    _lastSessionExpiredShownAt = null;
  }

  static bool shouldIgnoreError(dynamic error) =>
      _isHandlingLogout;

  static Future<bool> checkResponse(Response response) async {
    await handleHttpResponse(response);
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  static Future<bool> handleError(dynamic error) async {
    await handleException(error);
    return shouldIgnoreError(error);
  }
}
