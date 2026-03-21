# Vérification backend – Dashboards (compteurs)

Ce document résume la vérification côté API Laravel pour que les compteurs des dashboards Flutter ne restent pas à 0.

---

## 1. Format des réponses attendu par l’app

L’app Flutter (PaginationHelper) accepte notamment :
- `{ "success": true, "data": [ ... ], "pagination": { "current_page", "last_page", "per_page", "total", ... } }`
- ou `{ "success": true, "data": [ ... ], "meta": { ... } }`

Les contrôleurs doivent renvoyer **success**, **data** (tableau), et **pagination** (ou **meta**) pour les listes paginées.

---

## 2. Contrôleurs vérifiés

| Endpoint (app) | Route API | Contrôleur | Format retour |
|----------------|-----------|------------|----------------|
| clients-list | GET /clients-list | ClientController::index | ✅ success, data, pagination |
| devis | GET /devis | DevisController::index | ✅ success, data, pagination |
| bordereaux-list / bordereaux | GET /bordereaux-list, /bordereaux | BordereauController::index | ✅ success, data, pagination |
| commandes-entreprise-list | GET /commandes-entreprise-list | CommandeEntrepriseController::index | ✅ (même pattern) |
| factures-list | GET /factures-list | FactureController::index | ✅ success, data, pagination |
| payments | GET /payments | PaiementController::index | ✅ success, data, pagination |
| expenses-list | GET /expenses-list | ExpenseController::index | ✅ success, data, pagination |
| salaries-list / salaires-list | GET /salaries-list, /salaires-list | SalaryController::index | ✅ success, data, pagination |
| user-reportings | GET /user-reportings | UserReportingController::index | ✅ (à confirmer format) |
| attendances | GET /attendances | AttendanceController::index | À vérifier (route dans groupe role) |
| interventions-list | GET /interventions-list | InterventionController::index | ✅ success, data, pagination |
| **interventions** | **GET /interventions** | **InterventionController::index** | **✅ Route ajoutée (voir §4)** |
| taxes-list | GET /taxes-list | TaxController::index | À vérifier format |
| recruitment-requests | GET /recruitment-requests | RecruitmentController::index | À vérifier format |
| contracts | GET /contracts | ContractController::index | À vérifier format |
| leave-requests | GET /leave-requests | LeaveRequestController::index | À vérifier format |
| fournisseurs-list | GET /fournisseurs-list | FournisseurController::index | À vérifier format |
| stocks | GET /stocks | StockController::index | À vérifier format |
| tasks-list | GET /tasks-list | TaskController::index | À vérifier format |

---

## 3. Comportement métier vérifié

### ClientController::index
- Si `status` est envoyé (ex. `0` = en attente, `1` = validé), le filtre est appliqué.
- Si `include_pending=1` est envoyé (sans `status`), tous les clients sont retournés (pas de filtre `status = 1`).
- Compatible avec le dashboard commercial (tous) et patron (status=0 pour les en attente).

### FactureController::index
- Retourne `status` au format chaîne (ex. `en_attente`, `valide`, `rejete`) via FactureResource.
- L’app considère « en attente » pour : `draft`, `en_attente`, `pending`.

### PaiementController, ExpenseController, SalaryController
- Réponse : `success`, `data` (Resource::collection du paginator), `pagination`.
- Compatible avec le parsing Flutter (success + data + pagination).

---

## 4. Correction appliquée

**Route manquante :** l’app Flutter utilise `GET /interventions` dans `getInterventionsPaginated` (intervention_service.dart), alors que l’API n’exposait que `GET /interventions-list`.

**Modification dans `routes/api.php` :**
- Ajout de : `Route::get('/interventions', [InterventionController::class, 'index']);`
- Placée à côté de la route existante `GET /interventions-list`.

Ainsi, les appels vers `/api/interventions` (avec ou sans query) fonctionnent comme la liste des interventions (même comportement que `/api/interventions-list`).

---

## 5. Recommandations

1. **Statuts factures**  
   S’assurer que la colonne `status` des factures contient bien des chaînes attendues par l’app (`en_attente`, `valide`, `draft`, `sent`, `paid`, etc.) selon le modèle Facture et FactureResource.

2. **Erreurs 401/403**  
   Les routes de listes utilisées par les dashboards sont dans `auth:sanctum`. En cas de token invalide ou expiré, l’API renvoie 401 et l’app peut recevoir une liste vide ou une erreur. Vérifier que le token est bien envoyé et valide (côté app déjà rendu résilient).

3. **Pagination**  
   Les dashboards demandent souvent `per_page=500` pour récupérer beaucoup d’entrées. Les contrôleurs limitent déjà à 100 max (`min((int) $request->get('per_page', 20), 100)`). Si besoin de plus pour les stats, envisager soit d’augmenter cette limite pour ces endpoints, soit d’exposer des endpoints « stats » ou « count » dédiés (certains existent déjà : factures/count, devis/count, etc.).

4. **Doublon dans InterventionController**  
   Dans la réponse JSON de `InterventionController::index`, la clé `'message'` est présente deux fois. Supprimer le doublon pour garder une réponse propre.

---

## 6. Résumé

- **Format des réponses** : Les contrôleurs principaux (clients, devis, bordereaux, factures, paiements, dépenses, salaires, interventions) renvoient bien `success`, `data`, `pagination`.
- **Correction** : Route `GET /interventions` ajoutée pour alignement avec l’app.
- **Suite** : En cas de compteurs encore à 0, vérifier les logs côté app (étiquettes du type `PATRON_DASHBOARD_RIVERPOD`) pour voir quel appel échoue, et côté backend les logs Laravel (erreurs 500, validation, etc.).
