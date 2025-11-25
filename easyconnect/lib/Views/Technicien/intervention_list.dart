import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/intervention_controller.dart';
import 'package:easyconnect/Controllers/technicien_dashboard_controller.dart';
import 'package:easyconnect/Models/intervention_model.dart';
import 'package:easyconnect/Views/Technicien/intervention_form.dart';
import 'package:easyconnect/Views/Technicien/intervention_detail.dart';
import 'package:easyconnect/Views/Components/role_based_widget.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:intl/intl.dart';

class InterventionList extends StatelessWidget {
  final int? clientId;

  const InterventionList({super.key, this.clientId});

  @override
  Widget build(BuildContext context) {
    final InterventionController controller = Get.put(InterventionController());

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestion des Interventions'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.loadInterventions(),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.schedule), text: 'En attente'),
              Tab(icon: Icon(Icons.check_circle), text: 'Validé'),
              Tab(icon: Icon(Icons.cancel), text: 'Rejeté'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInterventionTab(controller, 'pending'),
            _buildInterventionTab(controller, 'approved'),
            _buildInterventionTab(controller, 'rejected'),
          ],
        ),
        floatingActionButton: RoleBasedWidget(
          allowedRoles: [Roles.ADMIN, Roles.TECHNICIEN, Roles.PATRON],
          child: FloatingActionButton.extended(
            onPressed: () async {
              await Get.to(() => const InterventionForm());
              // Recharger les données après retour du formulaire
              controller.loadInterventions();
              // Notifier le dashboard technicien pour qu'il se mette à jour
              if (Get.isRegistered<TechnicienDashboardController>()) {
                try {
                  final dashboardController =
                      Get.find<TechnicienDashboardController>();
                  dashboardController.refreshPendingEntities();
                } catch (e) {
                  print('⚠️ DashboardController non disponible: $e');
                }
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle Intervention'),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            elevation: 8,
            tooltip: 'Créer une nouvelle intervention',
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildInterventionTab(
    InterventionController controller,
    String status,
  ) {
    // Récupérer clientId depuis les arguments
    final args = Get.arguments as Map<String, dynamic>?;
    final filterClientId = clientId ?? args?['clientId'] as int?;

    return Obx(() {
      // Filtrer les interventions par statut
      var interventions =
          controller.interventions.where((intervention) {
            switch (status) {
              case 'pending':
                return intervention.status == 'pending';
              case 'approved':
                return intervention.status == 'approved' ||
                    intervention.status == 'in_progress' ||
                    intervention.status == 'completed';
              case 'rejected':
                return intervention.status == 'rejected';
              default:
                return true;
            }
          }).toList();

      // Filtrer par clientId si fourni
      if (filterClientId != null) {
        interventions =
            interventions
                .where(
                  (intervention) => intervention.clientId == filterClientId,
                )
                .toList();
      }

      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (interventions.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getEmptyIcon(status), size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _getEmptyMessage(status),
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                _getEmptySubMessage(status),
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: interventions.length,
        itemBuilder: (context, index) {
          final intervention = interventions[index];
          return _buildInterventionCard(intervention, controller);
        },
      );
    });
  }

  IconData _getEmptyIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'approved':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.build_outlined;
    }
  }

  String _getEmptyMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Aucune intervention en attente';
      case 'approved':
        return 'Aucune intervention validée';
      case 'rejected':
        return 'Aucune intervention rejetée';
      default:
        return 'Aucune intervention trouvée';
    }
  }

  String _getEmptySubMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Les nouvelles interventions apparaîtront ici';
      case 'approved':
        return 'Les interventions approuvées apparaîtront ici';
      case 'rejected':
        return 'Les interventions rejetées apparaîtront ici';
      default:
        return 'Commencez par ajouter une intervention';
    }
  }

  Widget _buildInterventionCard(
    Intervention intervention,
    InterventionController controller,
  ) {
    final formatDate = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          await Get.to(() => InterventionDetail(intervention: intervention));
          // Recharger les données après retour de la page de détails
          controller.loadInterventions();
          // Notifier le dashboard technicien pour qu'il se mette à jour
          if (Get.isRegistered<TechnicienDashboardController>()) {
            try {
              final dashboardController =
                  Get.find<TechnicienDashboardController>();
              dashboardController.refreshPendingEntities();
            } catch (e) {
              print('⚠️ DashboardController non disponible: $e');
            }
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec titre et statut
              Row(
                children: [
                  Expanded(
                    child: Text(
                      intervention.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(intervention),
                ],
              ),

              const SizedBox(height: 8),

              // Type et priorité
              Row(
                children: [
                  Icon(
                    intervention.typeIcon,
                    size: 16,
                    color: intervention.typeColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    intervention.typeText,
                    style: TextStyle(
                      color: intervention.typeColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    intervention.priorityIcon,
                    size: 16,
                    color: intervention.priorityColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    intervention.priorityText,
                    style: TextStyle(
                      color: intervention.priorityColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                intervention.description,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Raison du rejet
              if (intervention.status == 'rejected' &&
                  (intervention.rejectionReason != null &&
                      intervention.rejectionReason!.isNotEmpty)) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.report, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Raison du rejet: ${intervention.rejectionReason}',
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Informations de planification
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Programmée: ${formatDate.format(intervention.scheduledDate)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  if (intervention.startDate != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.play_arrow, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Début: ${formatDate.format(intervention.startDate!)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ],
              ),

              if (intervention.location != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      intervention.location!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ],

              if (intervention.clientName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      intervention.clientName!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (intervention.status == 'pending' &&
                      controller.canManageInterventions) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                      onPressed:
                          () => Get.to(
                            () => InterventionForm(intervention: intervention),
                          ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (intervention.status == 'approved' &&
                      controller.canManageInterventions) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Démarrer'),
                      onPressed:
                          () => _showStartDialog(intervention, controller),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (intervention.status == 'in_progress' &&
                      controller.canManageInterventions) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.stop, size: 16),
                      label: const Text('Terminer'),
                      onPressed:
                          () => _showCompleteDialog(intervention, controller),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (intervention.status == 'pending' &&
                      controller.canApproveInterventions) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approuver'),
                      onPressed:
                          () => _showApproveDialog(intervention, controller),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Rejeter'),
                      onPressed:
                          () => _showRejectDialog(intervention, controller),
                    ),
                  ],
                  // Bouton PDF pour les interventions validées (approved, completed)
                  if (intervention.status == 'approved' ||
                      intervention.status == 'completed') ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text('PDF'),
                      onPressed: () {
                        // Note: Pas de méthode generatePDF pour les interventions
                        Get.snackbar(
                          'Information',
                          'Génération PDF non disponible pour les interventions',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(Intervention intervention) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: intervention.statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: intervention.statusColor.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        intervention.statusText,
        style: TextStyle(
          color: intervention.statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showStartDialog(
    Intervention intervention,
    InterventionController controller,
  ) {
    final notesController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Démarrer l\'intervention'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Êtes-vous sûr de vouloir démarrer cette intervention ?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              controller.notesController.text = notesController.text;
              controller.startIntervention(intervention);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Démarrer'),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(
    Intervention intervention,
    InterventionController controller,
  ) {
    final solutionController = TextEditingController();
    final completionNotesController = TextEditingController();
    final actualDurationController = TextEditingController();
    final costController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Terminer l\'intervention'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: solutionController,
                decoration: const InputDecoration(
                  labelText: 'Solution appliquée *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: completionNotesController,
                decoration: const InputDecoration(
                  labelText: 'Notes de fin (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: actualDurationController,
                decoration: const InputDecoration(
                  labelText: 'Durée réelle (heures)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: costController,
                decoration: const InputDecoration(
                  labelText: 'Coût (€)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              controller.solutionController.text = solutionController.text;
              controller.completionNotesController.text =
                  completionNotesController.text;
              controller.actualDurationController.text =
                  actualDurationController.text;
              controller.costController.text = costController.text;
              controller.completeIntervention(intervention);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(
    Intervention intervention,
    InterventionController controller,
  ) {
    final notesController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Approuver l\'intervention'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Êtes-vous sûr de vouloir approuver cette intervention ?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              controller.notesController.text = notesController.text;
              controller.approveIntervention(intervention);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approuver'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
    Intervention intervention,
    InterventionController controller,
  ) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter l\'intervention'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez indiquer la raison du rejet :'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison du rejet *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                controller.rejectIntervention(
                  intervention,
                  reasonController.text.trim(),
                );
                Get.back();
              } else {
                Get.snackbar('Erreur', 'Veuillez indiquer la raison du rejet');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }
}
