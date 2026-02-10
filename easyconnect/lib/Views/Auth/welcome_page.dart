import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/services/session_service.dart';

/// Page d'accueil avec image de bienvenue, boutons S'INSCRIRE et SE CONNECTER.
/// Placer l'image de fond dans assets/images/welcome_bg.png
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (SessionService.isAuthenticated()) {
        Get.offNamed('/splash');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Image de fond en plein écran
          Image.asset(
            'assets/images/welcome_bg.png',
            fit: BoxFit.cover,
            errorBuilder:
                (_, __, ___) => Container(
                  color: const Color(0xFF0A1628),
                  child: Center(
                    child: Text(
                      'Bienvenue sur EasyKonect CRM',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
          ),
          // Overlay léger pour améliorer la lisibilité du texte
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
          // Boutons en haut à droite
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _WelcomeButton(
                      label: "S'INSCRIRE",
                      onTap: () => Get.offNamed('/register'),
                    ),
                    const SizedBox(width: 12),
                    _WelcomeButton(
                      label: 'SE CONNECTER',
                      onTap: () => Get.offNamed('/login'),
                      isPrimary: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _WelcomeButton({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? Colors.white : Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border:
                isPrimary
                    ? null
                    : Border.all(color: Colors.white54, width: 1.5),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isPrimary ? const Color(0xFF0A1628) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}
