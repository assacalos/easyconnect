# Guide de résolution : "System UI isn't responding" sur l'émulateur

## Solutions rapides

### 1. Désactiver les animations système (RECOMMANDÉ)

**Sur Windows :**
```bash
disable_animations.bat
```

**Sur Mac/Linux :**
```bash
chmod +x disable_animations.sh
./disable_animations.sh
```

Ou manuellement via ADB :
```bash
adb shell settings put global window_animation_scale 0
adb shell settings put global transition_animation_scale 0
adb shell settings put global animator_duration_scale 0
```

### 2. Augmenter les ressources de l'émulateur

1. Ouvrir **Android Studio** > **AVD Manager**
2. Cliquer sur l'icône **✏️ (Edit)** de votre émulateur
3. Cliquer sur **Show Advanced Settings**
4. Augmenter :
   - **RAM** : 2048 MB minimum (4096 MB recommandé)
   - **VM heap** : 512 MB minimum (1024 MB recommandé)
   - **Graphics** : **Hardware - GLES 2.0** (ou **Automatic**)

### 3. Utiliser un émulateur plus performant

- Choisir un appareil avec **API 30+** (Android 11+)
- Utiliser une image système **x86_64** (plus rapide que ARM)
- Activer **Hardware acceleration** dans les paramètres de l'émulateur

### 4. Redémarrer l'émulateur

Parfois, un simple redémarrage résout le problème :
```bash
adb reboot
```

### 5. Nettoyer et reconstruire le projet

```bash
flutter clean
flutter pub get
flutter run
```

### 6. Vérifier les ressources système

- Fermer les applications inutiles
- Vérifier que vous avez au moins **8 GB de RAM** disponible
- Désactiver les antivirus temporairement pendant le développement

### 7. Utiliser un appareil physique (Alternative)

Si le problème persiste, tester sur un appareil physique :
```bash
flutter run
# Puis sélectionner votre appareil physique
```

## Vérification

Après avoir appliqué les solutions, vérifier que les animations sont bien désactivées :
```bash
adb shell settings get global window_animation_scale
# Doit retourner : 0.0
```

## Si le problème persiste

1. Créer un nouvel émulateur avec des ressources plus importantes
2. Utiliser **Android Studio Emulator** au lieu de l'émulateur par défaut
3. Vérifier les logs : `flutter logs` pour identifier les erreurs
4. Tester sur un appareil physique pour confirmer que c'est un problème d'émulateur



