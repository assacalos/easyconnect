import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/reporting_controller.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/roles.dart';

class ReportingForm extends StatelessWidget {
  const ReportingForm({super.key});

  @override
  Widget build(BuildContext context) {
    final reportingController = Get.find<ReportingController>();
    final authController = Get.find<AuthController>();
    final userRole = authController.userAuth.value?.role;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Rapport'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations générales
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations Générales',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Obx(
                            () => TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Date du rapport',
                                border: OutlineInputBorder(),
                              ),
                              readOnly: true,
                              controller: TextEditingController(
                                text:
                                    reportingController.selectedDate.value
                                        .toString()
                                        .split(' ')[0],
                              ),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      reportingController.selectedDate.value,
                                  firstDate: DateTime.now().subtract(
                                    const Duration(days: 365),
                                  ),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  reportingController.selectedDate.value = date;
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: reportingController.commentsController,
                            decoration: const InputDecoration(
                              labelText: 'Commentaires',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Métriques selon le rôle
            if (userRole == Roles.COMMERCIAL) ...[
              _buildCommercialMetrics(context, reportingController),
            ] else if (userRole == Roles.COMPTABLE) ...[
              _buildComptableMetrics(context, reportingController),
            ] else if (userRole == Roles.TECHNICIEN) ...[
              _buildTechnicienMetrics(context, reportingController),
            ] else if (userRole == Roles.RH) ...[
              _buildRhMetrics(context, reportingController),
            ],

            const SizedBox(height: 24),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Obx(
                    () => ElevatedButton(
                      onPressed:
                          reportingController.isLoading.value
                              ? null
                              : () => reportingController.createReport(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child:
                          reportingController.isLoading.value
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text('Créer le Rapport'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommercialMetrics(
    BuildContext context,
    ReportingController controller,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Métriques Commerciales',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Métriques de base
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Clients prospectés',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          controller.updateCommercialMetrics(
                            clientsProspectes: int.tryParse(value) ?? 0,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Note clients prospectés',
                          border: OutlineInputBorder(),
                          hintText: 'Détails sur les prospects...',
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          controller.updateCommercialMetrics(
                            noteClientsProspectes: value,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Devis créés',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          controller.updateCommercialMetrics(
                            devisCrees: int.tryParse(value) ?? 0,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Note devis créés',
                          border: OutlineInputBorder(),
                          hintText: 'Détails sur les devis...',
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          controller.updateCommercialMetrics(
                            noteDevisCrees: value,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Devis acceptés',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          controller.updateCommercialMetrics(
                            devisAcceptes: int.tryParse(value) ?? 0,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Note devis acceptés',
                          border: OutlineInputBorder(),
                          hintText: 'Détails sur les acceptations...',
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          controller.updateCommercialMetrics(
                            noteDevisAcceptes: value,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Nouveaux clients',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          controller.updateCommercialMetrics(
                            nouveauxClients: int.tryParse(value) ?? 0,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Note nouveaux clients',
                          border: OutlineInputBorder(),
                          hintText: 'Détails sur les nouveaux clients...',
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          controller.updateCommercialMetrics(
                            noteNouveauxClients: value,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Appels effectués',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          controller.updateCommercialMetrics(
                            appelsEffectues: int.tryParse(value) ?? 0,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Note appels effectués',
                          border: OutlineInputBorder(),
                          hintText: 'Détails sur les appels...',
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          controller.updateCommercialMetrics(
                            noteAppelsEffectues: value,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Emails envoyés',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          controller.updateCommercialMetrics(
                            emailsEnvoyes: int.tryParse(value) ?? 0,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Note emails envoyés',
                          border: OutlineInputBorder(),
                          hintText: 'Détails sur les emails...',
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          controller.updateCommercialMetrics(
                            noteEmailsEnvoyes: value,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Visites réalisées',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          controller.updateCommercialMetrics(
                            visitesRealisees: int.tryParse(value) ?? 0,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Note visites réalisées',
                          border: OutlineInputBorder(),
                          hintText: 'Détails sur les visites...',
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          controller.updateCommercialMetrics(
                            noteVisitesRealisees: value,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section RDV
            Text('Rendez-vous', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: controller.rdvClientController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du client',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: controller.rdvDateController,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        controller.rdvDateController.text =
                            date.toString().split(' ')[0];
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: controller.rdvHeureController,
                    decoration: const InputDecoration(
                      labelText: 'Heure',
                      border: OutlineInputBorder(),
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        controller.rdvHeureController.text =
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.rdvTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Type (présentiel, téléphone, vidéo)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: controller.rdvNotesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => controller.addRdv(),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter RDV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComptableMetrics(
    BuildContext context,
    ReportingController controller,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Métriques Comptables',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Factures émises',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          controller.updateComptableMetrics(
                            facturesEmises: int.tryParse(value) ?? 0,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Note factures émises',
                          border: OutlineInputBorder(),
                          hintText: 'Détails sur les factures émises...',
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          controller.updateComptableMetrics(
                            noteFacturesEmises: value,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Factures payées',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          controller.updateComptableMetrics(
                            facturesPayees: int.tryParse(value) ?? 0,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Note factures payées',
                          border: OutlineInputBorder(),
                          hintText: 'Détails sur les factures payées...',
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          controller.updateComptableMetrics(
                            noteFacturesPayees: value,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Montant facturé (fcfa)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      controller.updateComptableMetrics(
                        montantFacture: double.tryParse(value) ?? 0,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Montant encaissé (fcfa)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      controller.updateComptableMetrics(
                        montantEncaissement: double.tryParse(value) ?? 0,
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Bordereaux traités',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      controller.updateComptableMetrics(
                        bordereauxTraites: int.tryParse(value) ?? 0,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Bons de commande traités',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      controller.updateComptableMetrics(
                        bonsCommandeTraites: int.tryParse(value) ?? 0,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicienMetrics(
    BuildContext context,
    ReportingController controller,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Métriques Techniques',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Interventions planifiées',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      controller.updateTechnicienMetrics(
                        interventionsPlanifiees: int.tryParse(value) ?? 0,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Interventions réalisées',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      controller.updateTechnicienMetrics(
                        interventionsRealisees: int.tryParse(value) ?? 0,
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Clients visités',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      controller.updateTechnicienMetrics(
                        clientsVisites: int.tryParse(value) ?? 0,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Problèmes résolus',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      controller.updateTechnicienMetrics(
                        problemesResolus: int.tryParse(value) ?? 0,
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Temps de travail (heures)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      controller.updateTechnicienMetrics(
                        tempsTravail: double.tryParse(value) ?? 0,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Déplacements',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      controller.updateTechnicienMetrics(
                        deplacements: int.tryParse(value) ?? 0,
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Notes techniques',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                controller.updateTechnicienMetrics(notesTechniques: value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRhMetrics(BuildContext context, ReportingController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Métriques RH', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Employés recrutés',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          controller.updateRhMetrics(
                            employesRecrutes: int.tryParse(value) ?? 0,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Note employés recrutés',
                          border: OutlineInputBorder(),
                          hintText: 'Détails sur les recrutements...',
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          controller.updateRhMetrics(
                            noteEmployesRecrutes: value,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Demandes congé traitées',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          controller.updateRhMetrics(
                            demandesCongeTraitees: int.tryParse(value) ?? 0,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Note demandes congé traitées',
                          border: OutlineInputBorder(),
                          hintText: 'Détails sur les demandes...',
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          controller.updateRhMetrics(
                            noteDemandesCongeTraitees: value,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Demandes congé approuvées',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      controller.updateRhMetrics(
                        demandesCongeApprouvees: int.tryParse(value) ?? 0,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Demandes congé rejetées',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      controller.updateRhMetrics(
                        demandesCongeRejetees: int.tryParse(value) ?? 0,
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Contrats créés',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          controller.updateRhMetrics(
                            contratsCrees: int.tryParse(value) ?? 0,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Note contrats créés',
                          border: OutlineInputBorder(),
                          hintText: 'Détails sur les contrats...',
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          controller.updateRhMetrics(noteContratsCrees: value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Contrats renouvelés',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      controller.updateRhMetrics(
                        contratsRenouveles: int.tryParse(value) ?? 0,
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Pointages validés',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          controller.updateRhMetrics(
                            pointagesValides: int.tryParse(value) ?? 0,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Note pointages validés',
                          border: OutlineInputBorder(),
                          hintText: 'Détails sur les pointages...',
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          controller.updateRhMetrics(
                            notePointagesValides: value,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Entretiens réalisés',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      controller.updateRhMetrics(
                        entretiensRealises: int.tryParse(value) ?? 0,
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Formations organisées',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          controller.updateRhMetrics(
                            formationsOrganisees: int.tryParse(value) ?? 0,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Note formations organisées',
                          border: OutlineInputBorder(),
                          hintText: 'Détails sur les formations...',
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          controller.updateRhMetrics(
                            noteFormationsOrganisees: value,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Évaluations effectuées',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          controller.updateRhMetrics(
                            evaluationsEffectuees: int.tryParse(value) ?? 0,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Note évaluations effectuées',
                          border: OutlineInputBorder(),
                          hintText: 'Détails sur les évaluations...',
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          controller.updateRhMetrics(
                            noteEvaluationsEffectuees: value,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
