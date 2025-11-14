# Modifications Backend Requises pour les Pièces Jointes des Contrats

## Résumé

Pour permettre l'upload de fichiers (pièces jointes) dans le formulaire de contrat, le backend doit **modifier l'endpoint d'ajout de pièces jointes** pour accepter les fichiers directement via `multipart/form-data` au lieu de recevoir uniquement un chemin de fichier.

---

## Problème Actuel

L'endpoint actuel `POST /api/contracts/{id}/attachments` attend un JSON avec un `file_path` :

```json
{
  "file_name": "contrat_signe.pdf",
  "file_path": "/storage/contracts/1/contrat_signe.pdf",
  "file_type": "application/pdf",
  "file_size": 245678,
  "attachment_type": "contract",
  "description": "Contrat signé par les deux parties"
}
```

**Problème** : Le frontend ne peut pas envoyer un `file_path` car le fichier est sur l'appareil mobile. Il faut uploader le fichier directement.

---

## Solution : Modifier l'Endpoint pour Accepter les Fichiers

### Endpoint à Modifier

**POST** `/api/contracts/{id}/attachments`

### Nouveau Format de Requête

L'endpoint doit accepter une requête `multipart/form-data` avec :

1. **Le fichier** : champ nommé `file` (ou `attachment`)
2. **Les métadonnées** : champs texte pour les informations du fichier

### Champs Requis

| Champ | Type | Description | Requis |
|-------|------|-------------|--------|
| `file` | File | Le fichier à uploader (PDF, images, documents) | ✅ Oui |
| `attachment_type` | String | Type de pièce jointe (`contract`, `addendum`, `amendment`, `termination`, `other`) | ✅ Oui |
| `description` | String | Description optionnelle de la pièce jointe | ❌ Non |

### Types de Fichiers Acceptés

- **PDF** : `.pdf`
- **Images** : `.jpg`, `.jpeg`, `.png`, `.gif`, `.webp`
- **Documents** : `.doc`, `.docx`, `.txt`
- **Taille maximale** : 10 MB par fichier

---

## Exemple d'Implémentation Laravel

### 1. Route (déjà existante, pas de modification nécessaire)

```php
Route::post('/contracts/{id}/attachments', [ContractController::class, 'addAttachment']);
```

### 2. Méthode du Controller

```php
public function addAttachment(Request $request, $id)
{
    // Valider que le contrat existe
    $contract = Contract::findOrFail($id);
    
    // Validation
    $validated = $request->validate([
        'file' => 'required|file|max:10240|mimes:pdf,jpg,jpeg,png,gif,webp,doc,docx,txt',
        'attachment_type' => 'required|in:contract,addendum,amendment,termination,other',
        'description' => 'nullable|string|max:500',
    ]);
    
    // Upload du fichier
    $file = $request->file('file');
    $fileName = time() . '_' . $file->getClientOriginalName();
    $filePath = $file->storeAs('contracts/' . $id, $fileName, 'public');
    
    // Créer l'enregistrement de la pièce jointe
    $attachment = ContractAttachment::create([
        'contract_id' => $contract->id,
        'file_name' => $file->getClientOriginalName(),
        'file_path' => '/storage/' . $filePath,
        'file_type' => $file->getMimeType(),
        'file_size' => $file->getSize(),
        'attachment_type' => $validated['attachment_type'],
        'description' => $validated['description'] ?? null,
        'uploaded_by' => auth()->id(),
        'uploaded_at' => now(),
    ]);
    
    return response()->json([
        'success' => true,
        'message' => 'Pièce jointe ajoutée avec succès',
        'data' => [
            'id' => $attachment->id,
            'contract_id' => $attachment->contract_id,
            'file_name' => $attachment->file_name,
            'file_path' => $attachment->file_path,
            'file_type' => $attachment->file_type,
            'file_size' => $attachment->file_size,
            'attachment_type' => $attachment->attachment_type,
            'description' => $attachment->description,
            'uploaded_at' => $attachment->uploaded_at->toIso8601String(),
            'uploaded_by' => $attachment->uploaded_by,
            'uploaded_by_name' => $attachment->uploader->name ?? null,
        ],
    ], 201);
}
```

### 3. Migration (si la table n'existe pas encore)

```php
Schema::create('contract_attachments', function (Blueprint $table) {
    $table->id();
    $table->foreignId('contract_id')->constrained()->onDelete('cascade');
    $table->string('file_name');
    $table->string('file_path');
    $table->string('file_type');
    $table->integer('file_size');
    $table->enum('attachment_type', ['contract', 'addendum', 'amendment', 'termination', 'other']);
    $table->text('description')->nullable();
    $table->timestamp('uploaded_at');
    $table->foreignId('uploaded_by')->constrained('users');
    $table->timestamps();
});
```

---

## Exemple de Requête Flutter/Dart

```dart
Future<void> uploadContractAttachment({
  required int contractId,
  required File file,
  required String attachmentType,
  String? description,
}) async {
  try {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/contracts/$contractId/attachments'),
    );

    // Headers (retirer Content-Type pour MultipartRequest)
    final headers = ApiService.headers();
    headers.remove('Content-Type');
    request.headers.addAll(headers);

    // Ajouter le fichier
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: file.path.split('/').last,
      ),
    );

    // Ajouter les champs texte
    request.fields['attachment_type'] = attachmentType;
    if (description != null && description.isNotEmpty) {
      request.fields['description'] = description;
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Erreur lors de l\'upload: ${response.statusCode}');
    }
  } catch (e) {
    rethrow;
  }
}
```

---

## Réponse Attendue (201 Created)

```json
{
  "success": true,
  "message": "Pièce jointe ajoutée avec succès",
  "data": {
    "id": 1,
    "contract_id": 1,
    "file_name": "contrat_signe.pdf",
    "file_path": "/storage/contracts/1/1695123456_contrat_signe.pdf",
    "file_type": "application/pdf",
    "file_size": 245678,
    "attachment_type": "contract",
    "description": "Contrat signé par les deux parties",
    "uploaded_at": "2024-01-15T15:00:00Z",
    "uploaded_by": 1,
    "uploaded_by_name": "Admin User"
  }
}
```

---

## Gestion des Erreurs

### Erreur 422 (Validation Failed)

```json
{
  "success": false,
  "message": "The given data was invalid.",
  "errors": {
    "file": ["The file field is required."],
    "attachment_type": ["The selected attachment type is invalid."],
    "file": ["The file must not be greater than 10240 kilobytes."],
    "file": ["The file must be a file of type: pdf, jpg, jpeg, png, gif, webp, doc, docx, txt."]
  }
}
```

### Erreur 404 (Contrat non trouvé)

```json
{
  "success": false,
  "message": "Contrat non trouvé"
}
```

### Erreur 413 (Fichier trop volumineux)

```json
{
  "success": false,
  "message": "Le fichier est trop volumineux (max 10 MB)"
}
```

---

## Stockage des Fichiers

### Structure de Dossiers Recommandée

```
storage/
  app/
    public/
      contracts/
        1/
          fichier1.pdf
          fichier2.jpg
        2/
          fichier1.pdf
```

### Configuration Laravel

Assurez-vous que le lien symbolique est créé :

```bash
php artisan storage:link
```

Cela permet d'accéder aux fichiers via `/storage/contracts/{id}/filename.ext`

---

## Sécurité

### Validations à Implémenter

1. **Vérifier que l'utilisateur a le droit d'ajouter des pièces jointes** au contrat
2. **Vérifier que le contrat existe** et appartient à l'utilisateur (ou que l'utilisateur a les permissions)
3. **Valider le type de fichier** (whitelist des extensions)
4. **Valider la taille du fichier** (max 10 MB)
5. **Scanner les fichiers** pour les virus (optionnel mais recommandé)
6. **Sanitizer les noms de fichiers** pour éviter les injections

### Exemple de Validation de Permissions

```php
// Dans le controller
$contract = Contract::findOrFail($id);

// Vérifier les permissions
if (!auth()->user()->can('manage_contracts') && 
    $contract->employee_id !== auth()->id()) {
    return response()->json([
        'success' => false,
        'message' => 'Vous n\'avez pas la permission d\'ajouter des pièces jointes à ce contrat'
    ], 403);
}
```

---

## Endpoint de Téléchargement (Optionnel mais Recommandé)

Pour permettre le téléchargement des pièces jointes :

**GET** `/api/contracts/{id}/attachments/{attachmentId}/download`

```php
public function downloadAttachment($contractId, $attachmentId)
{
    $contract = Contract::findOrFail($contractId);
    $attachment = ContractAttachment::where('contract_id', $contractId)
        ->findOrFail($attachmentId);
    
    $filePath = storage_path('app/public/' . str_replace('/storage/', '', $attachment->file_path));
    
    if (!file_exists($filePath)) {
        return response()->json([
            'success' => false,
            'message' => 'Fichier non trouvé'
        ], 404);
    }
    
    return response()->download($filePath, $attachment->file_name);
}
```

---

## Checklist de Mise en Place

- [ ] Modifier l'endpoint `POST /api/contracts/{id}/attachments` pour accepter `multipart/form-data`
- [ ] Ajouter la validation des fichiers (type, taille)
- [ ] Implémenter l'upload des fichiers dans le storage Laravel
- [ ] Créer la table `contract_attachments` si elle n'existe pas
- [ ] Ajouter les permissions pour l'upload de pièces jointes
- [ ] Tester l'upload avec différents types de fichiers
- [ ] Tester la validation des erreurs (fichier trop volumineux, type invalide)
- [ ] Créer le lien symbolique `storage:link`
- [ ] (Optionnel) Implémenter l'endpoint de téléchargement
- [ ] (Optionnel) Ajouter la suppression de pièces jointes

---

## Notes Importantes

1. **Rétrocompatibilité** : Si d'autres parties de l'application utilisent encore l'ancien format JSON, vous pouvez :
   - Garder les deux formats (détecter automatiquement)
   - Ou créer un nouvel endpoint dédié pour l'upload de fichiers

2. **Performance** : Pour les gros fichiers, envisagez :
   - L'upload asynchrone
   - La compression des images
   - L'utilisation d'un service de stockage cloud (S3, etc.)

3. **Sécurité** : Ne stockez jamais les fichiers dans le dossier `public` sans validation. Utilisez toujours le système de storage Laravel.

---

## Conclusion

Cette modification permettra au frontend d'uploader directement les fichiers depuis l'appareil mobile vers le backend, sans avoir besoin d'un chemin de fichier préexistant. L'implémentation suit le même pattern que l'upload de photos pour les pointages (`attendance_punch_service.dart`).

