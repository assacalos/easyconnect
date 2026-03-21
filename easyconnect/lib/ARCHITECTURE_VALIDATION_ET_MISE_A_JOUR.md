# Architecture : flux de validation multi-rôles et mises à jour fluides

Ce document décrit comment un système de soumission/validation (soumetteur → patron → onglets par statut) doit être conçu pour une expérience utilisateur fluide, les erreurs courantes et les corrections apportées dans ce projet.

---

## 1. Comportement attendu

- **Soumetteur** (commercial, comptable, RH, etc.) soumet une entité → statut "En attente".
- **Patron** reçoit une notification et voit l’entité dans l’onglet "En attente".
- **Patron valide** → l’entité doit **immédiatement** disparaître de "En attente" et apparaître dans "Validés" (sans rechargement manuel).
- **Patron rejette** → idem : disparition de "En attente", apparition dans "Rejetés".
- **Chez le soumetteur** : la même entité doit refléter le nouveau statut (mise à jour après rafraîchissement ou en temps réel si WebSocket/polling).

Pour que cela soit fluide, il faut une **source de vérité unique** et des **mises à jour d’état cohérentes**.

---

## 2. Principes à respecter

### 2.1 Une seule liste par type d’entité, filtrée par statut

- Un **seul** `state.clients` / `state.devis` / etc. contient **toutes** les entités (tous statuts).
- Les **onglets** ne sont que des **vues filtrées** :  
  `state.clients.where((c) => c.status == 0)` pour "En attente",  
  `state.clients.where((c) => c.status == 1)` pour "Validés", etc.
- Ne pas maintenir des listes séparées par statut (risque de désynchronisation).

### 2.2 À la validation/rejet : mettre à jour le statut dans la liste, ne pas supprimer

- **Erreur fréquente** : sur validation depuis l’onglet "En attente", **supprimer** l’entité de la liste (`list.removeAt(index)`).
- **Conséquence** : l’entité disparaît de "En attente" mais **n’apparaît pas** dans "Validés" car elle n’est plus dans la liste.
- **Bon comportement** : **toujours** mettre à jour l’entité **en place** avec le nouveau `status` (1 = validé, 2 ou 3 = rejeté selon le modèle). Ainsi :
  - Le filtre "En attente" ne la montre plus.
  - Le filtre "Validés" (ou "Rejetés") la montre tout de suite.
- **Règle** : sur validate/reject, faire `list[index] = entity.copyWith(status: newStatus)` (ou équivalent), **jamais** `list.removeAt(index)` pour faire "bouger" l’entité d’un onglet à l’autre.

### 2.3 Mise à jour optimiste + confirmation API

- **Avant** l’appel API : mettre à jour l’état local (liste + statut) pour un feedback immédiat.
- **Après** succès API : garder l’état, éventuellement invalider le cache et déclencher un refresh des dashboards (compteurs).
- **Après** échec API : restaurer l’entité dans son état précédent (rollback) et afficher une erreur.

### 2.4 Rafraîchir les dashboards après une action

- Après validate/reject, appeler `DashboardRefreshHelper.refreshPatronCounter('...')` et éventuellement `refreshCommercialDashboard()` (ou équivalent) pour que les **compteurs** des dashboards soient à jour.
- Les **listes** des pages de validation sont déjà à jour grâce à la mise à jour d’état en place (point 2.2).

### 2.5 Notifications

- Après succès, envoyer une notification (ex. `NotificationHelper.notifyValidation` / `notifyRejection`) pour que le soumetteur soit informé. Côté soumetteur, un rafraîchissement (pull-to-refresh ou retour sur la liste) ou du temps réel (WebSocket/polling) mettra la liste à jour.

### 2.6 Mise à jour côté soumetteur

- **Option 1** : le soumetteur rafraîchit la liste (pull-to-refresh ou rechargement) pour voir le nouveau statut.
- **Option 2** : WebSocket ou polling qui pousse les changements de statut ; à réception, mettre à jour l’entité dans le state (même règle : update in place, ne pas supprimer pour "déplacer" entre onglets). **Implémenté :** Option 1 — pull-to-refresh sur toutes les listes (clients, devis, bordereaux, bons de commande, dépenses, stock, salaires, taxes, factures, paiements, fournisseurs, interventions). Option 2 — WebSocket et polling déjà en place.

---

## 3. Erreurs fréquentes (et comment les éviter)

| Erreur | Conséquence | Correction |
|--------|-------------|------------|
| Supprimer l’entité de la liste au lieu de changer son statut | Elle disparaît de "En attente" mais n’apparaît pas dans "Validés" / "Rejetés" | Toujours mettre à jour `status` en place dans la même liste |
| Avoir plusieurs listes par statut | Désynchronisation, doublons, entités "perdues" | Une seule liste, filtrage par `status` dans l’UI |
| Ne rafraîchir que les dashboards sans mettre à jour la liste | Compteurs à jour mais listes de validation incorrectes | Mise à jour immédiate de la liste (point 2.2) + refresh des compteurs |
| Oublier d’invalider le cache (ex. CacheHelper, Hive) après validate/reject | Ancien état réaffiché au prochain chargement | `CacheHelper.clearByPrefix('...')` et/ou invalidation cible après succès API |
| Mise à jour conditionnelle selon l’onglet courant (ex. "si onglet En attente alors remove, sinon update") | Comportement différent selon l’onglet, bugs subtils | Une seule logique : toujours update le statut en place |

---

## 4. Corrections appliquées dans ce projet

- **client_notifier** : `approveClient` / `rejectClient` — auparavant on supprimait l’entité quand `currentStatus == 0`. Désormais on met toujours à jour le `Client` en place avec `status: 1` (validé) ou `status: 2` (rejeté).
- **devis_notifier** : `rejectDevis` — mise à jour du `Devis` en place avec `status: 3` (rejeté).
- **bordereau_notifier** : `approveBordereau` et `rejectBordereau` — mise à jour du `Bordereau` en place avec `status: 2` ou `3`.
- **bon_de_commande_fournisseur_notifier** : `approveBonDeCommande` / `rejectBonDeCommande` — mise à jour en place avec `statut: 'valide'` ou `'rejete'`.
- **stock_notifier** : `approveStock` / `rejectStock` — mise à jour en place avec `status: 'valide'` ou `'rejete'`.
- **expense_notifier** : `approveExpense` / `rejectExpense` — mise à jour en place dans `expenses` et `pendingExpenses` avec `status: 'approved'` ou `'rejected'`.
- **salary_notifier** : `approveSalary` / `rejectSalary` — mise à jour en place dans `salaries` et `pendingSalaries` avec `status: 'approved'` ou `'rejected'`.
- **tax_notifier** : `validateTax` / `rejectTax` — mise à jour de `allTaxes` en place avec `status: 'valide'` ou `'rejete'`.
- **payment_notifier** : `approvePayment` / `rejectPayment` — mise à jour de `payments` en place avec `status: 'approved'` ou `'rejected'`.
- **invoice_notifier** : `approveInvoice` / `rejectInvoice` — mise à jour en place dans `invoices` ; si la facture n'était que dans `pendingInvoices`, elle est ajoutée à `invoices` avec le nouveau statut.
- **intervention_notifier** : `approveIntervention` / `rejectIntervention` — mise à jour de `interventions` en place avec `status: 'approved'` ou `'rejected'`.

Pour les autres entités (bon de commande, facture, paiement, etc.), appliquer la même règle : **un seul state de liste, mise à jour du statut en place à la validation/rejet, pas de suppression pour faire "changer d’onglet"**.

---

## 5. Checklist pour une nouvelle entité à validation

1. **State** : une seule liste (ex. `state.items`) pour tous les statuts.
2. **UI** : onglets = `state.items.where((e) => e.status == x)`.
3. **Approve** : trouver l’index, faire `list[index] = item.copyWith(status: validatedStatus)` (ou équivalent), puis `state = state.copyWith(items: list)` ; appeler l’API ; sur succès, invalider le cache et rafraîchir les dashboards.
4. **Reject** : même chose avec `status: rejectedStatus`.
5. **Jamais** : `list.removeAt(index)` pour faire passer l’entité d’un onglet à l’autre.
6. **Notifications** : après succès API, notifier (validation/rejet) pour informer le soumetteur.

En suivant cette architecture, les mises à jour et l’affichage par onglets restent cohérents et fluides pour tous les rôles.
