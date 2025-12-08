# Guide d'utilisation des photos et documents - Flutter EasyConnect

Ce guide explique comment utiliser les photos et documents dans l'application Flutter EasyConnect.

## 📸 Photos d'attendance (Pointages)

### Affichage des photos

Les photos de pointage sont automatiquement construites avec l'URL complète via la propriété `photoUrl` du modèle `AttendancePunchModel`.

```dart
// Dans une vue Flutter
Image.network(
  attendance.photoUrl,
  fit: BoxFit.cover,
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return Center(
      child: CircularProgressIndicator(
        value: loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes!
            : null,
      ),
    );
  },
  errorBuilder: (context, error, stackTrace) {
    return const Center(
      child: Icon(Icons.broken_image, size: 64),
    );
  },
)
```

### Exemple complet dans une carte

```dart
Container(
  height: 200,
  width: double.infinity,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey[300]!),
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.network(
      pointage.photoUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(Icons.broken_image, size: 64),
        );
      },
    ),
  ),
)
```

## 🧾 Reçus de dépenses

### Affichage des reçus

Les reçus de dépenses utilisent la propriété `receiptUrl` du modèle `Expense` pour construire l'URL complète.

#### Pour les images (JPG, PNG, etc.)

```dart
// Afficher l'image du reçu
if (expense.receiptPath != null && expense.receiptUrl.isNotEmpty) {
  Container(
    height: 200,
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        expense.receiptUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, size: 64),
          );
        },
      ),
    ),
  )
}
```

#### Pour les autres types de fichiers (PDF, etc.)

```dart
// Afficher une icône de fichier
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.grey[100],
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey[300]!),
  ),
  child: Row(
    children: [
      const Icon(Icons.insert_drive_file, size: 48),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fichier joint',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              expense.receiptPath?.split('/').last ?? 'Justificatif',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
)
```

### Téléchargement des reçus

Pour télécharger un reçu, utilisez la propriété `receiptDownloadUrl` :

```dart
// Bouton de téléchargement
IconButton(
  icon: const Icon(Icons.download),
  tooltip: 'Télécharger',
  onPressed: () {
    if (expense.receiptDownloadUrl.isNotEmpty) {
      // Ouvrir l'URL de téléchargement
      // Utiliser url_launcher ou un package de téléchargement
      launchUrl(Uri.parse(expense.receiptDownloadUrl));
    }
  },
)
```

## 🔧 Construction des URLs

### Comment ça fonctionne

Les modèles `AttendancePunchModel` et `Expense` construisent automatiquement les URLs complètes :

1. **Si le chemin est déjà une URL complète** (commence par `http://` ou `https://`), elle est retournée telle quelle.

2. **Sinon**, l'URL est construite en combinant :
   - La base URL de l'API (sans `/api` à la fin)
   - Le préfixe `/storage/` si nécessaire
   - Le chemin du fichier

### Exemple de construction

```dart
// Dans AttendancePunchModel
String get photoUrl {
  if (photoPath != null && photoPath!.isNotEmpty) {
    if (photoPath!.startsWith('http://') || photoPath!.startsWith('https://')) {
      return photoPath!;
    }
    
    String baseUrlWithoutApi = AppConfig.baseUrl;
    if (baseUrlWithoutApi.endsWith('/api')) {
      baseUrlWithoutApi = baseUrlWithoutApi.substring(0, baseUrlWithoutApi.length - 4);
    }
    
    String cleanPath = photoPath!;
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }
    
    if (cleanPath.contains('storage/')) {
      return '$baseUrlWithoutApi/$cleanPath';
    }
    
    return '$baseUrlWithoutApi/storage/$cleanPath';
  }
  return '';
}
```

## 📝 Bonnes pratiques

### 1. Toujours vérifier que l'URL n'est pas vide

```dart
if (attendance.photoUrl.isNotEmpty) {
  Image.network(attendance.photoUrl, ...)
}
```

### 2. Gérer le chargement et les erreurs

```dart
Image.network(
  url,
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return CircularProgressIndicator(...);
  },
  errorBuilder: (context, error, stackTrace) {
    return Icon(Icons.broken_image);
  },
)
```

### 3. Utiliser `fit: BoxFit.cover` pour les images en carte

```dart
Image.network(
  url,
  fit: BoxFit.cover, // Pour remplir le conteneur
)
```

### 4. Détecter le type de fichier

```dart
final isImage = receiptPath != null &&
    ['jpg', 'jpeg', 'png', 'gif', 'webp'].any(
      (ext) => receiptPath!.toLowerCase().endsWith('.$ext'),
    );
```

## 🔗 Packages recommandés

Pour le téléchargement de fichiers, vous pouvez utiliser :

- `url_launcher` : Pour ouvrir les URLs dans le navigateur
- `dio` : Pour télécharger les fichiers directement
- `path_provider` : Pour obtenir les chemins de stockage local

## 📍 Exemples dans le code

### Photos d'attendance
- `lib/Views/Rh/pointage_detail.dart` (ligne 93)
- `lib/Views/Patron/pointage_validation_page.dart` (ligne 311)
- `lib/Views/Components/attendance_validation_page.dart` (ligne 297)

### Reçus de dépenses
- `lib/Views/Comptable/expense_detail.dart` (méthode `_buildReceiptCard()`)

## ⚠️ Notes importantes

1. **Les URLs sont construites automatiquement** : Pas besoin de construire manuellement les URLs complètes.

2. **Gestion des erreurs** : Toujours prévoir un `errorBuilder` pour gérer les cas où l'image ne peut pas être chargée.

3. **Performance** : Les images sont chargées à la demande. Pour améliorer les performances, considérez l'utilisation d'un cache d'images.

4. **Sécurité** : Les URLs sont construites à partir des chemins stockés en base de données. Assurez-vous que le backend Laravel valide les accès aux fichiers.

