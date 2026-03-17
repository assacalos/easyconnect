import 'package:get_storage/get_storage.dart';

/// Auth binding GetX remplacé par Riverpod (authProvider).
/// Session chargée via SplashScreen / AuthNotifier.
class AuthBinding {
  void dependencies() {
    GetStorage.init();
  }
}
