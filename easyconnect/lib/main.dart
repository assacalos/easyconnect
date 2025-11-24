import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/routes/app_routes.dart';
import 'package:easyconnect/bindings/auth_binding.dart';
import 'package:easyconnect/Views/Components/app_lifecycle_wrapper.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('=== DÉMARRAGE DE L\'APPLICATION ===');
  // Assurer l'initialisation du stockage avant de lancer l'app
  await GetStorage.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'EasyConnect',
      debugShowCheckedModeBanner: false,
      // Optimisations de performance
      builder: (context, child) {
        return AppLifecycleWrapper(
          child: MediaQuery(
            // Désactiver l'accessibilité pour améliorer les performances
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.0)),
            child: child!,
          ),
        );
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      getPages: AppRoutes.routes,
      initialBinding:
          AuthBinding(), // Utilisation du binding d'authentification
      defaultTransition: Transition.fadeIn,
    );
  }
}
