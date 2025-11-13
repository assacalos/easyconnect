# Guide de Compatibilité APK - EasyConnect

## 🔧 Problèmes de Compatibilité Résolus

### 1. **Architectures CPU Supportées**

L'APK a été configuré pour supporter toutes les architectures CPU courantes :
- **armeabi-v7a** : Appareils ARM 32-bit (la plupart des smartphones Android)
- **arm64-v8a** : Appareils ARM 64-bit (appareils modernes)
- **x86** : Émulateurs et quelques tablettes Intel
- **x86_64** : Émulateurs et tablettes Intel 64-bit

### 2. **Version Android Minimale**

- **minSdk = 21** (Android 5.0 Lollipop)
- Supporte environ **95%+ des appareils Android** actifs
- Si vous avez besoin de supporter des appareils plus anciens, vous pouvez réduire à 19 (Android 4.4), mais cela peut limiter certaines fonctionnalités

### 3. **Permissions et Compatibilité**

Les permissions ont été configurées pour :
- Android 13+ (API 33+) : Permissions granulaires pour les médias
- Appareils sans caméra/GPS : Les fonctionnalités sont marquées comme optionnelles
- Support des permissions runtime

## 📱 Comment Construire un APK Universel

### Option 1 : Script Automatique (Recommandé)
```bash
build_release_apk.bat
```

### Option 2 : Commande Flutter
```bash
flutter build apk --release --target-platform android-arm,android-arm64,android-x64
```

### Option 3 : APK Universel (Fat APK)
```bash
flutter build apk --release
```

## ⚠️ Problèmes Courants et Solutions

### Problème : "L'application ne s'installe pas"
**Solutions :**
1. Vérifier que l'appareil a Android 5.0 (API 21) ou supérieur
2. Activer "Sources inconnues" dans les paramètres de sécurité
3. Vérifier l'espace de stockage disponible

### Problème : "L'application se ferme au démarrage"
**Causes possibles :**
1. Architecture CPU non supportée (normalement résolu maintenant)
2. Permissions manquantes
3. Problème de mémoire (appareil avec peu de RAM)

### Problème : "APK trop volumineux"
**Solutions :**
1. Utiliser des APK séparés par architecture (voir build.gradle.kts)
2. Activer la minification et le shrinkResources
3. Utiliser App Bundle (.aab) au lieu d'APK

## 🔍 Vérification de la Compatibilité

Pour vérifier quelles architectures sont incluses dans votre APK :

```bash
# Sur Windows (avec Android SDK)
aapt dump badging app-release.apk | findstr native-code

# Sur Linux/Mac
aapt dump badging app-release.apk | grep native-code
```

Vous devriez voir :
```
native-code: 'armeabi-v7a' 'arm64-v8a' 'x86' 'x86_64'
```

## 📊 Statistiques de Compatibilité

Avec minSdk = 21 :
- **~95% des appareils Android** sont supportés
- Compatible avec Android 5.0+ (Lollipop, Marshmallow, Nougat, Oreo, Pie, 10, 11, 12, 13, 14)

## 🛠️ Configuration Avancée

### Créer des APK Séparés par Architecture

Si vous voulez réduire la taille de chaque APK, modifiez `android/app/build.gradle.kts` :

```kotlin
splits {
    abi {
        isEnable = true
        reset()
        include("armeabi-v7a", "arm64-v8a", "x86", "x86_64")
        isUniversalApk = false  // Pas d'APK universel
    }
}
```

Puis construisez avec :
```bash
flutter build apk --release --split-per-abi
```

### Réduire la Taille de l'APK

Activez la minification et le shrinkResources dans `build.gradle.kts` :

```kotlin
buildTypes {
    release {
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

## 📝 Notes Importantes

1. **Testez sur plusieurs appareils** : Différentes marques (Samsung, Xiaomi, Huawei, etc.) peuvent avoir des comportements différents
2. **Testez sur différentes versions Android** : Au minimum Android 5.0, 7.0, 10, et 13+
3. **Vérifiez les permissions** : Certains appareils nécessitent des permissions supplémentaires
4. **APK de test vs Production** : Les APK de test peuvent avoir des limitations que les APK signés n'ont pas

## 🚀 Prochaines Étapes

1. Reconstruire l'APK avec les nouvelles configurations
2. Tester sur plusieurs appareils physiques
3. Si des problèmes persistent, vérifier les logs avec `adb logcat`


