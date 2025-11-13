# Guide d'Optimisation de l'Émulateur Android

## Problème de Performance

Si l'application Flutter est lente dans l'émulateur Android, cela peut être dû aux paramètres de l'émulateur, notamment l'accélération graphique.

## Solution : Modifier les Paramètres de l'Émulateur

### 1. Ouvrir les Paramètres de l'Émulateur

1. Dans Android Studio, ouvrez l'**Android Virtual Device (AVD) Manager**
2. Cliquez sur l'icône **✏️ (Edit)** à côté de votre émulateur
3. Cliquez sur **Show Advanced Settings** en bas de la fenêtre

### 2. Modifier l'Accélération Graphique

**Problème actuel :** L'accélération graphique est probablement réglée sur **"Software"**, ce qui est très lent.

**Solution :**

1. Dans la section **"Emulated Performance"**, trouvez **"Graphics"**
2. Changez la valeur de **"Software"** à l'une des options suivantes :
   - **"Automatic"** (recommandé) - Laisse Android Studio choisir la meilleure option
   - **"Hardware - GLES 2.0"** - Utilise l'accélération matérielle de votre GPU
   - **"Hardware - GLES 3.0"** - Version plus récente (si supportée)

### 3. Autres Paramètres Recommandés

#### CPU Cores
- **Recommandé :** 4 cores (vous avez déjà cela)
- Si votre machine est puissante, vous pouvez augmenter à 6-8 cores

#### RAM
- **Recommandé :** 4 GB (vous avez déjà cela)
- Ne dépassez pas 8 GB pour éviter de ralentir votre machine hôte

#### VM Heap Size
- **Recommandé :** 512 MB à 1 GB (vous avez 1 GB, c'est bien)
- Augmenter au-delà peut causer des problèmes

### 4. Redémarrer l'Émulateur

Après avoir modifié les paramètres :
1. Cliquez sur **"Finish"** pour sauvegarder
2. **Fermez complètement** l'émulateur actuel
3. **Redémarrez** l'émulateur avec les nouveaux paramètres

### 5. Vérifier les Performances

Après le redémarrage, l'application devrait être beaucoup plus rapide, surtout pour :
- L'affichage des interfaces
- Les animations
- Le chargement des données

## Optimisations du Code Effectuées

J'ai également optimisé le code de l'application en :
- Réduisant les `print()` statements excessifs (de 55+ à seulement les erreurs critiques)
- Optimisant le parsing JSON dans `bordereau_model.dart`
- Simplifiant les logs dans les contrôleurs

Ces optimisations devraient également améliorer les performances.

## Si le Problème Persiste

Si l'application est toujours lente après ces modifications :

1. **Vérifiez les performances de votre machine :**
   - CPU : Au moins 4 cores recommandés
   - RAM : Au moins 8 GB disponibles
   - GPU : Support de l'accélération matérielle

2. **Réduisez la résolution de l'émulateur :**
   - Utilisez une résolution plus faible (ex: 720x1280 au lieu de 1080x1920)

3. **Fermez les applications inutiles** sur votre machine hôte

4. **Testez sur un appareil physique** pour comparer les performances

