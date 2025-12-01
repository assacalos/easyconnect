import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/utils/app_config.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  bool _notificationsEnabled = true;
  bool _autoBackup = false;
  String _selectedLanguage = 'fr';
  String _selectedTheme = 'system';
  final TextEditingController _apiUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiUrlController.text = AppConfig.baseUrl;
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres de l\'application'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section Configuration API
          _buildSectionHeader('Configuration API'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('URL de l\'API'),
                  subtitle: Text(
                    AppConfig.getCurrentUrlInfo(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  leading: const Icon(Icons.api),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showApiUrlDialog();
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Réinitialiser l\'URL'),
                  subtitle: const Text('Restaurer l\'URL par défaut'),
                  leading: const Icon(Icons.refresh),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showResetApiUrlDialog();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section Général
          _buildSectionHeader('Général'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Notifications'),
                  subtitle: const Text('Recevoir des notifications push'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Langue'),
                  subtitle: const Text('Français'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showLanguageDialog();
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Thème'),
                  subtitle: Text(_getThemeName(_selectedTheme)),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showThemeDialog();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section Sécurité
          _buildSectionHeader('Sécurité'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Changer le mot de passe'),
                  subtitle: const Text('Modifier votre mot de passe'),
                  leading: const Icon(Icons.lock),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Get.toNamed('/admin/change-password');
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Sessions actives'),
                  subtitle: const Text('Gérer les sessions ouvertes'),
                  leading: const Icon(Icons.devices),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Get.toNamed('/admin/sessions');
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Authentification à deux facteurs'),
                  subtitle: const Text('Sécuriser votre compte'),
                  leading: const Icon(Icons.security),
                  trailing: Switch(
                    value: false,
                    onChanged: (value) {
                      // TODO: Implémenter 2FA
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section Sauvegarde
          _buildSectionHeader('Sauvegarde et données'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Sauvegarde automatique'),
                  subtitle: const Text(
                    'Sauvegarder automatiquement les données',
                  ),
                  value: _autoBackup,
                  onChanged: (value) {
                    setState(() {
                      _autoBackup = value;
                    });
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Sauvegarder maintenant'),
                  subtitle: const Text('Créer une sauvegarde manuelle'),
                  leading: const Icon(Icons.backup),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showBackupDialog();
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Restaurer depuis sauvegarde'),
                  subtitle: const Text('Restaurer les données'),
                  leading: const Icon(Icons.restore),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Get.toNamed('/admin/restore');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section Maintenance
          _buildSectionHeader('Maintenance'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Nettoyer le cache'),
                  subtitle: const Text('Libérer l\'espace de stockage'),
                  leading: const Icon(Icons.cleaning_services),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showCacheDialog();
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Logs système'),
                  subtitle: const Text('Consulter les logs d\'erreur'),
                  leading: const Icon(Icons.article),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Get.toNamed('/admin/logs');
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Informations système'),
                  subtitle: const Text('Version et détails techniques'),
                  leading: const Icon(Icons.info),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showSystemInfo();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Bouton de sauvegarde
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _saveSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Sauvegarder les paramètres',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  String _getThemeName(String theme) {
    switch (theme) {
      case 'light':
        return 'Clair';
      case 'dark':
        return 'Sombre';
      case 'system':
        return 'Système';
      default:
        return 'Système';
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sélectionner la langue'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('Français'),
                  value: 'fr',
                  groupValue: _selectedLanguage,
                  onChanged: (value) {
                    setState(() {
                      _selectedLanguage = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('English'),
                  value: 'en',
                  groupValue: _selectedLanguage,
                  onChanged: (value) {
                    setState(() {
                      _selectedLanguage = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sélectionner le thème'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('Clair'),
                  value: 'light',
                  groupValue: _selectedTheme,
                  onChanged: (value) {
                    setState(() {
                      _selectedTheme = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Sombre'),
                  value: 'dark',
                  groupValue: _selectedTheme,
                  onChanged: (value) {
                    setState(() {
                      _selectedTheme = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Système'),
                  value: 'system',
                  groupValue: _selectedTheme,
                  onChanged: (value) {
                    setState(() {
                      _selectedTheme = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sauvegarder'),
            content: const Text(
              'Voulez-vous créer une sauvegarde maintenant ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Get.snackbar(
                    'Succès',
                    'Sauvegarde créée avec succès',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                },
                child: const Text('Sauvegarder'),
              ),
            ],
          ),
    );
  }

  void _showCacheDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Nettoyer le cache'),
            content: const Text(
              'Cette action va supprimer tous les fichiers temporaires. Continuer ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Get.snackbar(
                    'Succès',
                    'Cache nettoyé avec succès',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                },
                child: const Text('Nettoyer'),
              ),
            ],
          ),
    );
  }

  void _showSystemInfo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Informations système'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Version: 1.0.0'),
                Text('Build: 2024.01.15'),
                Text('Flutter: 3.16.0'),
                Text('Dart: 3.2.0'),
                Text('Plateforme: Android/iOS'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
    );
  }

  void _showApiUrlDialog() {
    _apiUrlController.text = AppConfig.baseUrl;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Configuration de l\'URL de l\'API'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _apiUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL de l\'API',
                    hintText: 'https://example.com/api',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'URL actuelle: ${AppConfig.baseUrl}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newUrl = _apiUrlController.text.trim();
                  if (newUrl.isNotEmpty) {
                    await AppConfig.setBaseUrl(newUrl);
                    Navigator.pop(context);
                    setState(() {});
                    Get.snackbar(
                      'Succès',
                      'URL de l\'API mise à jour avec succès',
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  } else {
                    Get.snackbar(
                      'Erreur',
                      'L\'URL ne peut pas être vide',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
    );
  }

  void _showResetApiUrlDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Réinitialiser l\'URL de l\'API'),
            content: const Text(
              'Voulez-vous réinitialiser l\'URL de l\'API à sa valeur par défaut ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await AppConfig.resetBaseUrl();
                  Navigator.pop(context);
                  setState(() {});
                  Get.snackbar(
                    'Succès',
                    'URL de l\'API réinitialisée avec succès',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                },
                child: const Text('Réinitialiser'),
              ),
            ],
          ),
    );
  }

  void _saveSettings() {
    Get.snackbar(
      'Succès',
      'Paramètres sauvegardés avec succès',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }
}
