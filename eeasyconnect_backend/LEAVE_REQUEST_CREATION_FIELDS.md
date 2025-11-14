# Champs Nécessaires pour la Création d'une Demande de Congé

## Vue d'ensemble

Ce document liste tous les champs que le frontend doit envoyer au backend pour créer une demande de congé via l'endpoint `POST /api/leave-requests`.

---

## Champs Obligatoires (Required)

| Champ | Type | Validation | Description | Exemple |
|-------|------|------------|-------------|---------|
| `employee_id` | `integer` | `required\|exists:employees,id` | ID de l'employé (doit exister dans la table `employees`) | `1` |
| `leave_type` | `string` | `required\|in:annual,sick,maternity,paternity,personal,emergency,unpaid` | Type de congé | `"annual"` |
| `start_date` | `date` | `required\|date\|after_or_equal:today` | Date de début (doit être aujourd'hui ou dans le futur) | `"2024-12-01T00:00:00Z"` |
| `end_date` | `date` | `required\|date\|after:start_date` | Date de fin (doit être après la date de début) | `"2024-12-15T23:59:59Z"` |
| `reason` | `string` | `required\|string\|min:10\|max:1000` | Raison détaillée de la demande de congé (min 10 caractères, max 1000) | `"Demande de congés annuels pour repos et détente"` |

---

## Champs Optionnels

| Champ | Type | Validation | Description | Exemple |
|-------|------|------------|-------------|---------|
| `comments` | `string` | `nullable\|string\|max:2000` | Commentaires supplémentaires (max 2000 caractères) | `"Je serai disponible par email en cas d'urgence"` |
| `attachment_paths` | `array` | `nullable\|array` | Liste des chemins des fichiers joints (justificatifs, certificats médicaux, etc.) | `["uploads/leaves/certificat_medical_123.pdf"]` |

---

## Valeurs Acceptées pour les Enums

### `leave_type`
- `"annual"` - Congés payés
- `"sick"` - Congé maladie
- `"maternity"` - Congé maternité
- `"paternity"` - Congé paternité
- `"personal"` - Congé personnel
- `"emergency"` - Congé d'urgence
- `"unpaid"` - Congé sans solde

---

## Exemple de Requête JSON Complète

### Exemple 1 : Congé annuel (annual)

```json
{
  "employee_id": 1,
  "leave_type": "annual",
  "start_date": "2024-12-01T00:00:00Z",
  "end_date": "2024-12-15T23:59:59Z",
  "reason": "Demande de congés annuels pour repos et détente. Je souhaite prendre mes congés avant la fin de l'année.",
  "comments": "Je serai disponible par email en cas d'urgence",
  "attachment_paths": []
}
```

### Exemple 2 : Congé maladie (sick)

```json
{
  "employee_id": 2,
  "leave_type": "sick",
  "start_date": "2024-12-10T00:00:00Z",
  "end_date": "2024-12-12T23:59:59Z",
  "reason": "Congé maladie pour grippe. Certificat médical joint.",
  "comments": "Certificat médical fourni",
  "attachment_paths": [
    "uploads/leaves/certificat_medical_123.pdf"
  ]
}
```

### Exemple 3 : Congé maternité (maternity)

```json
{
  "employee_id": 3,
  "leave_type": "maternity",
  "start_date": "2024-12-20T00:00:00Z",
  "end_date": "2025-03-27T23:59:59Z",
  "reason": "Congé de maternité prévu. Date d'accouchement prévue : 25 décembre 2024.",
  "comments": "Certificat médical et attestation de grossesse joints",
  "attachment_paths": [
    "uploads/leaves/certificat_medical_maternite.pdf",
    "uploads/leaves/attestation_grossesse.pdf"
  ]
}
```

### Exemple 4 : Congé d'urgence (emergency)

```json
{
  "employee_id": 4,
  "leave_type": "emergency",
  "start_date": "2024-12-05T00:00:00Z",
  "end_date": "2024-12-07T23:59:59Z",
  "reason": "Urgence familiale. Décès d'un membre de la famille proche.",
  "comments": null,
  "attachment_paths": []
}
```

### Exemple 5 : Congé personnel (personal)

```json
{
  "employee_id": 5,
  "leave_type": "personal",
  "start_date": "2024-12-18T00:00:00Z",
  "end_date": "2024-12-20T23:59:59Z",
  "reason": "Congé personnel pour affaires personnelles importantes nécessitant ma présence.",
  "comments": "Je reprendrai le travail le 21 décembre",
  "attachment_paths": []
}
```

### Exemple 6 : Congé sans solde (unpaid)

```json
{
  "employee_id": 6,
  "leave_type": "unpaid",
  "start_date": "2025-01-10T00:00:00Z",
  "end_date": "2025-01-31T23:59:59Z",
  "reason": "Demande de congé sans solde pour raisons personnelles. J'ai épuisé mes congés payés.",
  "comments": "Je comprends que cette période ne sera pas rémunérée",
  "attachment_paths": []
}
```

---

## Règles de Validation Importantes

### 1. Date de début (`start_date`)
- **Doit être aujourd'hui ou dans le futur**
- Ne peut pas être dans le passé
- Format ISO 8601 recommandé

### 2. Date de fin (`end_date`)
- **Doit être après** `start_date`
- Ne peut pas être égale ou antérieure à `start_date`
- Format ISO 8601 recommandé

### 3. Raison (`reason`)
- **Minimum 10 caractères** requis
- **Maximum 1000 caractères**
- Doit être une description détaillée de la raison du congé

### 4. Calcul automatique des jours
- Le nombre de jours (`total_days`) est **calculé automatiquement** par le backend
- Le calcul exclut les weekends (samedi et dimanche)
- Exemple : Du lundi 1er décembre au vendredi 15 décembre = 11 jours ouvrés

### 5. Vérification des conflits
- Le backend vérifie automatiquement s'il y a des **conflits de dates** avec d'autres congés approuvés
- Si un conflit est détecté, la demande sera rejetée avec un message d'erreur

### 6. Employé
- `employee_id` **doit exister** dans la table `employees`
- L'employé sera automatiquement chargé pour remplir `employee_name`

---

## Champs Générés Automatiquement

Ces champs sont gérés par le backend et **ne doivent PAS être envoyés** :

| Champ | Description |
|-------|-------------|
| `id` | Généré automatiquement |
| `total_days` | Calculé automatiquement à partir de `start_date` et `end_date` (jours ouvrés) |
| `status` | Automatiquement défini à `"pending"` (en attente) |
| `approved_at` | `null` (sera rempli lors de l'approbation) |
| `approved_by` | `null` (sera rempli avec l'ID de l'utilisateur qui approuve) |
| `approved_by_name` | `null` (sera rempli avec le nom de l'utilisateur qui approuve) |
| `rejection_reason` | `null` (sera rempli en cas de rejet) |
| `created_by` | Récupéré depuis l'utilisateur authentifié |
| `created_at` | Timestamp de création |
| `updated_at` | Timestamp de mise à jour |

---

## Format de Date Recommandé

Utiliser le format **ISO 8601** :

- **Format complet** : `"2024-12-01T00:00:00Z"` (datetime avec timezone)
- **Format date simple** : `"2024-12-01"` (accepté aussi)

### Exemples de dates valides

```json
"start_date": "2024-12-01T00:00:00Z"
"start_date": "2024-12-01T08:00:00Z"
"start_date": "2024-12-01"
"end_date": "2024-12-15T23:59:59Z"
"end_date": "2024-12-15T17:00:00Z"
"end_date": "2024-12-15"
```

---

## Endpoint

**POST** `/api/leave-requests`

### Headers Requis

```
Authorization: Bearer {token}
Content-Type: application/json
```

---

## Réponse de Succès (201 Created)

```json
{
  "success": true,
  "message": "Demande de congé créée avec succès",
  "data": {
    "id": 1,
    "employee_id": 1,
    "employee_name": "Jean Dupont",
    "leave_type": "annual",
    "start_date": "2024-12-01T00:00:00Z",
    "end_date": "2024-12-15T23:59:59Z",
    "total_days": 11,
    "reason": "Demande de congés annuels pour repos et détente. Je souhaite prendre mes congés avant la fin de l'année.",
    "status": "pending",
    "comments": "Je serai disponible par email en cas d'urgence",
    "rejection_reason": null,
    "approved_at": null,
    "approved_by": null,
    "approved_by_name": null,
    "created_at": "2024-11-15T10:00:00Z",
    "updated_at": "2024-11-15T10:00:00Z",
    "attachments": []
  }
}
```

---

## Erreurs de Validation Possibles (422)

### Erreur 422 - Validation Failed

```json
{
  "success": false,
  "message": "The given data was invalid.",
  "errors": {
    "employee_id": ["The employee id field is required."],
    "leave_type": ["The selected leave type is invalid."],
    "start_date": ["The start date must be a date after or equal to today."],
    "end_date": ["The end date must be a date after start date."],
    "reason": ["The reason must be at least 10 characters."]
  }
}
```

### Erreur 400 - Conflit de Dates

```json
{
  "success": false,
  "message": "Conflit de dates détecté",
  "data": {
    "has_conflicts": true,
    "conflicting_requests": [
      {
        "id": 5,
        "start_date": "2024-12-10T00:00:00Z",
        "end_date": "2024-12-20T23:59:59Z",
        "status": "approved"
      }
    ]
  }
}
```

### Erreurs Communes

1. **Champ manquant** : Tous les champs requis doivent être présents
2. **Type de congé invalide** : `leave_type` doit correspondre aux valeurs acceptées
3. **Date de début dans le passé** : `start_date` doit être aujourd'hui ou dans le futur
4. **Date de fin avant la date de début** : `end_date` doit être après `start_date`
5. **Raison trop courte** : Minimum 10 caractères
6. **Conflit de dates** : Vérifier qu'il n'y a pas de chevauchement avec d'autres congés approuvés

---

## Checklist de Validation Frontend

Avant d'envoyer la requête, vérifier :

- [ ] `employee_id` : Présent et existe dans la base de données
- [ ] `leave_type` : Une des valeurs acceptées (`annual`, `sick`, `maternity`, `paternity`, `personal`, `emergency`, `unpaid`)
- [ ] `start_date` : Date valide, aujourd'hui ou dans le futur (format ISO 8601)
- [ ] `end_date` : Date valide, après `start_date` (format ISO 8601)
- [ ] `reason` : Minimum 10 caractères, maximum 1000 caractères
- [ ] `comments` : Maximum 2000 caractères (optionnel)
- [ ] `attachment_paths` : Tableau de strings (optionnel)
- [ ] L'utilisateur est authentifié (token présent dans les headers)
- [ ] Content-Type : `application/json`
- [ ] Vérifier qu'il n'y a pas de conflit avec d'autres congés (optionnel, le backend le vérifie aussi)

---

## Calcul des Jours Ouvrés

Le backend calcule automatiquement le nombre de jours ouvrés en excluant les weekends :

- **Samedi** : Exclu
- **Dimanche** : Exclu
- **Jours fériés** : Actuellement non exclus (peut être ajouté plus tard)

### Exemple de Calcul

- **Période** : Du lundi 1er décembre au vendredi 15 décembre 2024
- **Jours calendaires** : 15 jours
- **Weekends** : 2 samedis + 2 dimanches = 4 jours
- **Jours ouvrés** : 15 - 4 = **11 jours**

---

## Vérification des Conflits

Le backend vérifie automatiquement s'il y a des conflits avec d'autres congés approuvés du même employé. Un conflit existe si :

- La période demandée chevauche une période de congé approuvée
- La période demandée est complètement incluse dans une période de congé approuvée
- La période demandée englobe complètement une période de congé approuvée

### Vérification Proactive (Optionnel)

Vous pouvez vérifier les conflits avant de créer la demande en utilisant :

**POST** `/api/leave-requests/check-conflicts`

```json
{
  "employee_id": 1,
  "start_date": "2024-12-01T00:00:00Z",
  "end_date": "2024-12-15T23:59:59Z",
  "exclude_request_id": null
}
```

**Réponse** :
```json
{
  "success": true,
  "data": {
    "has_conflicts": false,
    "conflicting_requests": []
  }
}
```

---

## Gestion des Pièces Jointes

### Note Actuelle

Le champ `attachment_paths` est accepté mais l'implémentation complète des pièces jointes est en cours. Pour l'instant, vous pouvez :

1. **Envoyer les chemins** : Si vous avez déjà uploadé les fichiers ailleurs
2. **Laisser vide** : Les pièces jointes peuvent être ajoutées plus tard via un autre endpoint

### Structure de `attachment_paths`

```json
"attachment_paths": [
  "uploads/leaves/certificat_medical_123.pdf",
  "uploads/leaves/justificatif_absence.pdf"
]
```

Chaque élément doit être une string représentant le chemin du fichier.

---

## Exemple de Code Flutter/Dart

```dart
Future<Map<String, dynamic>> createLeaveRequest({
  required int employeeId,
  required String leaveType,
  required DateTime startDate,
  required DateTime endDate,
  required String reason,
  String? comments,
  List<String>? attachmentPaths,
}) async {
  try {
    // Vérifier que start_date est aujourd'hui ou dans le futur
    if (startDate.isBefore(DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0))) {
      throw Exception('La date de début doit être aujourd\'hui ou dans le futur');
    }

    // Vérifier que end_date est après start_date
    if (endDate.isBefore(startDate) || endDate.isAtSameMomentAs(startDate)) {
      throw Exception('La date de fin doit être après la date de début');
    }

    // Vérifier que reason a au moins 10 caractères
    if (reason.length < 10) {
      throw Exception('La raison doit contenir au moins 10 caractères');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/leave-requests'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'employee_id': employeeId,
        'leave_type': leaveType,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'reason': reason,
        'comments': comments,
        'attachment_paths': attachmentPaths ?? [],
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data;
    } else if (response.statusCode == 422) {
      final errorData = jsonDecode(response.body);
      throw Exception('Erreur de validation: ${errorData['errors']}');
    } else if (response.statusCode == 400) {
      final errorData = jsonDecode(response.body);
      if (errorData['message'] == 'Conflit de dates détecté') {
        throw Exception('Conflit de dates: ${errorData['data']['conflicting_requests']}');
      }
      throw Exception('Erreur: ${errorData['message']}');
    } else {
      throw Exception('Erreur lors de la création: ${response.statusCode}');
    }
  } catch (e) {
    rethrow;
  }
}
```

### Exemple d'utilisation

```dart
try {
  final result = await createLeaveRequest(
    employeeId: 1,
    leaveType: 'annual',
    startDate: DateTime(2024, 12, 1),
    endDate: DateTime(2024, 12, 15),
    reason: 'Demande de congés annuels pour repos et détente. Je souhaite prendre mes congés avant la fin de l\'année.',
    comments: 'Je serai disponible par email en cas d\'urgence',
    attachmentPaths: [],
  );
  
  print('Demande créée avec succès: ${result['data']['id']}');
  print('Nombre de jours: ${result['data']['total_days']}');
} catch (e) {
  print('Erreur: $e');
}
```

---

## Types de Congés Disponibles

Pour récupérer la liste complète des types de congés avec leurs détails :

**GET** `/api/leave-types`

**Réponse** :
```json
{
  "success": true,
  "data": [
    {
      "value": "annual",
      "label": "Congés payés",
      "description": "Congés annuels payés",
      "requires_approval": true,
      "max_days": 30,
      "is_paid": true
    },
    {
      "value": "sick",
      "label": "Congé maladie",
      "description": "Congé pour maladie",
      "requires_approval": true,
      "max_days": 90,
      "is_paid": true
    },
    {
      "value": "maternity",
      "label": "Congé maternité",
      "description": "Congé de maternité",
      "requires_approval": true,
      "max_days": 98,
      "is_paid": true
    },
    {
      "value": "paternity",
      "label": "Congé paternité",
      "description": "Congé de paternité",
      "requires_approval": true,
      "max_days": 11,
      "is_paid": true
    },
    {
      "value": "personal",
      "label": "Congé personnel",
      "description": "Congé pour affaires personnelles",
      "requires_approval": true,
      "max_days": 5,
      "is_paid": false
    },
    {
      "value": "emergency",
      "label": "Congé d'urgence",
      "description": "Congé pour urgence familiale",
      "requires_approval": true,
      "max_days": 3,
      "is_paid": false
    },
    {
      "value": "unpaid",
      "label": "Congé sans solde",
      "description": "Congé non rémunéré",
      "requires_approval": true,
      "max_days": 30,
      "is_paid": false
    }
  ]
}
```

---

## Vérification du Solde de Congés

Avant de créer une demande, vous pouvez vérifier le solde disponible :

**GET** `/api/leave-balance/{employeeId}`

**Réponse** :
```json
{
  "success": true,
  "data": {
    "employee_id": 1,
    "employee_name": "Jean Dupont",
    "annual_leave_days": 25,
    "used_annual_leave": 5,
    "remaining_annual_leave": 20,
    "sick_leave_days": 10,
    "used_sick_leave": 2,
    "remaining_sick_leave": 8,
    "personal_leave_days": 5,
    "used_personal_leave": 0,
    "remaining_personal_leave": 5,
    "last_updated": "2024-11-15T10:00:00Z"
  }
}
```

---

## Workflow de la Demande de Congé

1. **Création** : La demande est créée avec le statut `"pending"` (en attente)
2. **Validation** : Un responsable (RH, Patron, Admin) approuve ou rejette la demande
3. **Approbation** : Si approuvée, le statut passe à `"approved"` et les jours sont déduits du solde
4. **Rejet** : Si rejetée, le statut passe à `"rejected"` avec une raison de rejet
5. **Annulation** : L'employé peut annuler sa demande si elle est encore en attente

### Statuts Possibles

- `"pending"` - En attente d'approbation
- `"approved"` - Approuvée (les jours sont déduits du solde)
- `"rejected"` - Rejetée
- `"cancelled"` - Annulée

---

## Notes Importantes

1. **Statut initial** : Toute nouvelle demande est créée avec le statut `"pending"` (en attente)
2. **Calcul automatique** : Le nombre de jours (`total_days`) est calculé automatiquement en excluant les weekends
3. **Vérification des conflits** : Le backend vérifie automatiquement les conflits avec d'autres congés approuvés
4. **Format de date** : Le format ISO 8601 avec timezone (`2024-12-01T00:00:00Z`) est recommandé
5. **Authentification** : Tous les endpoints nécessitent une authentification valide (middleware `auth:sanctum`)
6. **Date de début** : Ne peut pas être dans le passé (doit être aujourd'hui ou dans le futur)
7. **Raison** : Doit contenir au moins 10 caractères pour être valide
8. **Pièces jointes** : Actuellement en cours d'implémentation, peut être laissé vide pour l'instant

---

## Conclusion

Ce document fournit toutes les informations nécessaires pour implémenter la création de demandes de congé côté frontend. Assurez-vous de :

1. Valider tous les champs avant l'envoi
2. Gérer les erreurs de validation (422)
3. Gérer les conflits de dates (400)
4. Afficher les messages d'erreur appropriés
5. Vérifier le solde de congés disponible avant de créer la demande
6. Utiliser le format ISO 8601 pour les dates
7. Vérifier que la date de début n'est pas dans le passé

Pour toute question ou clarification, référez-vous aux exemples de requêtes et réponses fournis dans ce document.

