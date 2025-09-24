import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print('=== DÉMARRAGE DU SPLASH SCREEN ===');

    // Attendre un délai minimum pour l'affichage du splash
    await Future.delayed(const Duration(seconds: 2));
    print('Délai d\'attente terminé');

    try {
      // Récupérer le contrôleur d'authentification
      final authController = Get.find<AuthController>();
      print('AuthController récupéré avec succès');

      // Attendre un peu pour s'assurer que l'initialisation est terminée
      await Future.delayed(const Duration(milliseconds: 500));

      // Vérifier si l'utilisateur est déjà connecté (persistance de session)
      final userRole = authController.userAuth.value?.role;
      print('Rôle utilisateur: $userRole');

      if (userRole != null) {
        // Utilisateur connecté, rediriger vers son dashboard
        final initialRoute = AppRoutes.getInitialRoute(userRole);
        print('Utilisateur déjà connecté, redirection vers: $initialRoute');
        Get.offAllNamed(initialRoute);
      } else {
        // Aucun utilisateur connecté, aller au login
        print('Aucun utilisateur connecté, redirection vers login');
        Get.offAllNamed('/login');
      }
    } catch (e) {
      // En cas d'erreur, rediriger vers la page de connexion
      print('Erreur lors de l\'initialisation: $e');
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Flutter ou de l'application
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.business,
                size: 60,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'EasyConnect',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Gestion d\'entreprise',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
