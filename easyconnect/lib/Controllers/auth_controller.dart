import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/roles.dart';

class AuthController extends GetxController {
  /// --- Observables
  var isLoading = false.obs;
  var userAuth = Rxn<UserModel>();
  var showPassword = false.obs;

  /// --- Stockage local
  final storage = GetStorage();

  /// --- Champs du formulaire
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  /// --- Connexion
  Future<void> login() async {
    print("Starting login process...");
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar("Erreur", "Veuillez remplir tous les champs");
      return;
    }

    try {
      print("Setting loading state...");
      isLoading.value = true;

      print("Calling API service...");
      final response = await ApiService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      isLoading.value = false;

      print("Processing response: $response");
      if (response['success'] == true) {
        final data = response['data'];
        print("Processing user data: $data");

        /// Création du modèle utilisateur
        userAuth.value = UserModel.fromJson(data['user']);

        /// Sauvegarde en local
        storage.write("token", data['token']);
        storage.write("userId", userAuth.value?.id);
        storage.write("userRole", userAuth.value?.role);
        storage.write("user", data['user']); // garde les infos utilisateur

        print(
          "Stored user data - ID: ${userAuth.value?.id}, Role: ${userAuth.value?.role}",
        );

        /// Redirection selon le rôle
        switch (userAuth.value?.role) {
          case Roles.COMMERCIAL:
            Get.offAllNamed('/commercial');
            break;
          case Roles.COMPTABLE:
            Get.offAllNamed('/comptable');
            break;
          case Roles.PATRON:
            Get.offAllNamed('/patron');
            break;
          case Roles.RH:
            Get.offAllNamed('/rh');
            break;
          case Roles.TECHNICIEN:
            Get.offAllNamed('/technicien');
            break;
          default:
            Get.offAllNamed('/login');
        }

        Get.snackbar("Succès", "Bienvenue ${userAuth.value?.nom ?? ''} !");
      } else {
        Get.snackbar(
          "Erreur",
          response['message'] ?? "Email ou mot de passe incorrect",
        );
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Erreur", "Une erreur est survenue: $e");
    }
  }

  /// --- Déconnexion
  void logout() {
    storage.erase();
    userAuth.value = null;
    Get.offAllNamed("/login");
  }

  /// --- Charger utilisateur depuis le stockage local (auto-login)
  void loadUserFromStorage() {
    try {
      final savedUser = storage.read("user");
      final savedToken = storage.read("token");

      if (savedUser != null && savedToken != null) {
        userAuth.value = UserModel.fromJson(
          Map<String, dynamic>.from(savedUser),
        );

        // Vérifier et stocker l'ID et le rôle
        storage.write("userId", userAuth.value?.id);
        storage.write("userRole", userAuth.value?.role);

        print(
          "Session restaurée - ID: ${userAuth.value?.id}, Role: ${userAuth.value?.role}",
        );
      } else {
        print("Aucune session sauvegardée trouvée");
        userAuth.value = null;
      }
    } catch (e) {
      print("Erreur lors du chargement de la session: $e");
      userAuth.value = null;
    }
  }

  /// --- Vérifier la validité du token (optionnel)
  Future<bool> validateToken() async {
    try {
      final token = storage.read("token");
      if (token == null) return false;

      // Ici vous pouvez ajouter une vérification côté serveur
      // Pour l'instant, on considère que le token est valide s'il existe
      return true;
    } catch (e) {
      print("Erreur validation token: $e");
      return false;
    }
  }

  void togglePasswordVisibility() {
    showPassword.value = !showPassword.value;
  }

  @override
  void onInit() {
    super.onInit();
    loadUserFromStorage();
  }
}
