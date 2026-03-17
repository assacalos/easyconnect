import 'package:easyconnect/models/user_model.dart';
import 'package:easyconnect/providers/auth_notifier.dart';

/// Stub sans Get : délègue à currentAuthState (Riverpod) pour compatibilité avec les controllers qui font AuthController.to.userAuth.
class AuthController {
  static final AuthController _instance = AuthController._();
  static AuthController get to => _instance;
  factory AuthController() => _instance;
  AuthController._();

  UserModel? get userAuth => currentAuthState?.user;
  bool get isLoading => currentAuthState?.isLoading ?? false;
  bool get showPassword => currentAuthState?.showPassword ?? false;

  void togglePasswordVisibility() {
    // Utiliser authProvider.notifier depuis l'UI
  }

  Future<void> login() async {
    // Login géré par authProvider (LoginPage utilise ref.read(authProvider.notifier).login)
  }

  Future<void> logout({bool silent = false, String? redirectTo}) async {
    // Déconnexion gérée par AuthErrorHandler.logoutCallback (Riverpod)
  }

  void loadUserFromStorage() {}

  Future<bool> validateToken() async => false;

  Future<void> refreshUserData() async {}
}
