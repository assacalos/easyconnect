# Statuts des Paiements - Documentation

## Statuts standardisés

Le système de paiement utilise les statuts suivants, normalisés automatiquement depuis différentes variantes possibles du backend.

### 1. **draft** (Brouillon)
- **Variantes acceptées :** `draft`, `drafts`
- **Description :** Paiement créé mais pas encore soumis
- **Couleur :** Gris
- **Icône :** `pending`
- **Libellé affiché :** "Brouillon"
- **Peut être soumis :** Oui (par le comptable)

### 2. **pending** (En attente)
- **Variantes acceptées :** `pending`, `en_attente`
- **Description :** Paiement en attente de traitement
- **Couleur :** Orange
- **Icône :** `pending`
- **Libellé affiché :** "En attente"
- **Peut être approuvé :** Oui (par le patron)

### 3. **submitted** (Soumis)
- **Variantes acceptées :** `submitted`, `soumis`
- **Description :** Paiement soumis au patron pour validation
- **Couleur :** Orange
- **Icône :** `pending`
- **Libellé affiché :** "Soumis"
- **Peut être approuvé :** Oui (par le patron)

### 4. **approved** (Approuvé)
- **Variantes acceptées :** `approved`, `approuve`, `approuvé`, `valide`
- **Description :** Paiement approuvé par le patron
- **Couleur :** Bleu
- **Icône :** `check_circle`
- **Libellé affiché :** "Approuvé"
- **Peut être marqué comme payé :** Oui

### 5. **rejected** (Rejeté)
- **Variantes acceptées :** `rejected`, `rejete`, `rejeté`
- **Description :** Paiement rejeté par le patron
- **Couleur :** Rouge
- **Icône :** `cancel`
- **Libellé affiché :** "Rejeté"
- **Peut être réactivé :** Oui (par le patron)

### 6. **paid** (Payé)
- **Variantes acceptées :** `paid`, `paye`, `payé`
- **Description :** Paiement effectué
- **Couleur :** Vert
- **Icône :** `check_circle`
- **Libellé affiché :** "Payé"
- **Statut final :** Oui

### 7. **overdue** (En retard)
- **Variantes acceptées :** `overdue`, `en_retard`
- **Description :** Paiement en retard
- **Couleur :** Rouge
- **Icône :** `cancel`
- **Libellé affiché :** "En retard"
- **Action requise :** Relance ou mise à jour

## Normalisation automatique

Le système normalise automatiquement tous les statuts lors du parsing depuis le backend :

```dart
// Dans PaymentModel.fromJson()
status: _normalizeStatus(json['status']?.toString() ?? 'pending')
```

La méthode `_normalizeStatus()` convertit automatiquement :
- `drafts` → `draft`
- `soumis` → `submitted`
- `approuvé` → `approved`
- `valide` → `approved`
- `rejeté` → `rejected`
- `payé` → `paid`
- `en_attente` → `pending`
- etc.

## Méthodes utilitaires

### Dans PaymentModel

```dart
bool get isPending => status == 'pending' || status == 'submitted' || status == 'draft';
bool get isApproved => status == 'approved' || status == 'paid';
bool get isRejected => status == 'rejected';
```

### Dans PaymentController

```dart
Color getPaymentStatusColor(String status) // Retourne la couleur du statut
String getPaymentStatusName(String status) // Retourne le libellé en français
```

## Flux de statuts

```
draft → submitted → approved → paid
         ↓
      rejected (peut être réactivé)
```

## Problème résolu

**Problème initial :** Le backend envoyait parfois `"drafts"` (pluriel) au lieu de `"draft"` (singulier), ce qui causait l'affichage du statut brut "drafts" dans l'interface.

**Solution :** 
1. Normalisation automatique dans `PaymentModel.fromJson()` pour convertir `drafts` → `draft`
2. Gestion des variantes dans `getPaymentStatusName()` et `getPaymentStatusColor()`
3. Support de toutes les variantes possibles (français/anglais, singulier/pluriel)

## Recommandations backend

Pour éviter les incohérences, le backend devrait toujours utiliser les statuts standardisés suivants :

- `draft` (pas `drafts`)
- `pending` (pas `en_attente`)
- `submitted` (pas `soumis`)
- `approved` (pas `approuvé` ou `valide`)
- `rejected` (pas `rejeté`)
- `paid` (pas `payé`)
- `overdue` (pas `en_retard`)

Cependant, le code Flutter gère maintenant toutes ces variantes automatiquement.

