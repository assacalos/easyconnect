# Guide de Résolution du Problème d'Installation APK

## Problème Identifié
L'APK généré précédemment ne pouvait pas être installé à cause de :
1. **Signature avec clés de debug** : L'APK utilisait les clés de debug au lieu des clés de production
2. **Application ID générique** : `com.example.easyconnect` peut causer des conflits
3. **Configuration de signature manquante**

## Solutions Appliquées

### 1. Création d'une Clé de Signature de Production
- ✅ Clé générée : `android/app/keystore/easyconnect-key.jks`
- ✅ Mot de passe : `easyconnect123`
- ✅ Alias : `easyconnect`

### 2. Configuration de Signature
- ✅ Fichier `android/key.properties` créé
- ✅ Configuration de signature dans `build.gradle.kts`
- ✅ Application ID changé vers `com.easyconnect.app`

### 3. Scripts d'Automatisation
- ✅ `create_keystore.bat` : Création de la clé de signature
- ✅ `build_release_apk.bat` : Construction de l'APK de production
- ✅ `verify_apk.bat` : Vérification de la signature

## Instructions d'Utilisation

### Étape 1 : Construire l'APK de Production
```bash
.\build_release_apk.bat
```

### Étape 2 : Vérifier la Signature
```bash
.\verify_apk.bat
```

### Étape 3 : Installer l'APK
1. Copiez `build\app\outputs\flutter-apk\app-release.apk` sur votre appareil
2. Activez "Sources inconnues" dans les paramètres Android
3. Installez l'APK

## Fichiers Importants
- **APK de production** : `build\app\outputs\flutter-apk\app-release.apk`
- **Clé de signature** : `android\app\keystore\easyconnect-key.jks`
- **Configuration** : `android\key.properties`

## Notes de Sécurité
⚠️ **IMPORTANT** : Gardez votre fichier de clé `easyconnect-key.jks` en sécurité !
- Ne partagez jamais ce fichier
- Sauvegardez-le dans un endroit sûr
- Le mot de passe est : `easyconnect123`

## Résolution des Problèmes Courants

### Erreur "Impossible d'ouvrir le document"
- ✅ Résolu : APK maintenant signé avec des clés de production

### Erreur "Application non installée"
- Vérifiez que l'application ID est unique
- Désinstallez l'ancienne version si elle existe

### Erreur de signature
- Exécutez `verify_apk.bat` pour vérifier la signature
- Assurez-vous que le fichier `key.properties` existe

