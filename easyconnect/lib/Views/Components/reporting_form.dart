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
        child: Form(
          key: reportingController.formKey,
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
                                  text: reportingController.selectedDate.value
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
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Nature du reporting
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nature du Reporting',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Obx(
                        () => DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Nature',
                            border: OutlineInputBorder(),
                          ),
                          value: reportingController.nature.value.isEmpty
                              ? null
                              : reportingController.nature.value,
                          items: _getNatureOptions(userRole)
                              .map((option) => DropdownMenuItem(
                                    value: option['value']!,
                                    child: Text(option['label']!),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            reportingController.nature.value = value ?? '';
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez sélectionner une nature';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Informations société
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informations Société',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: reportingController.nomSocieteController,
                        decoration: const InputDecoration(
                          labelText: 'Nom de la société',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez saisir le nom de la société';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: reportingController.contactSocieteController,
                        decoration: const InputDecoration(
                          labelText: 'Contact société',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Informations personne
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informations Personne',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: reportingController.nomPersonneController,
                        decoration: const InputDecoration(
                          labelText: 'Nom de la personne de l\'échange',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez saisir le nom de la personne';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller:
                            reportingController.contactPersonneController,
                        decoration: const InputDecoration(
                          labelText: 'Contact de la personne',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Moyen de contact
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Moyen de Contact',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Obx(
                        () => DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Moyen utilisé',
                            border: OutlineInputBorder(),
                          ),
                          value: reportingController.moyenContact.value.isEmpty
                              ? null
                              : reportingController.moyenContact.value,
                          items: const [
                            DropdownMenuItem(
                              value: 'mail',
                              child: Text('Mail'),
                            ),
                            DropdownMenuItem(
                              value: 'whatsapp',
                              child: Text('WhatsApp'),
                            ),
                            DropdownMenuItem(
                              value: 'linkedin',
                              child: Text('LinkedIn'),
                            ),
                          ],
                          onChanged: (value) {
                            reportingController.moyenContact.value =
                                value ?? '';
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez sélectionner un moyen de contact';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Produit démarche et commentaire
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Détails',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller:
                            reportingController.produitDemarcheController,
                        decoration: const InputDecoration(
                          labelText: 'Produit démarche',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: reportingController.commentaireController,
                        decoration: const InputDecoration(
                          labelText: 'Commentaire',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Relance (pour commercial : téléphonique, mail, RDV ; pour technicien : RDV uniquement, rappel)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userRole == Roles.TECHNICIEN
                            ? 'Relance RDV (rappel)'
                            : 'Relance',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Obx(
                        () => DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: userRole == Roles.TECHNICIEN
                                ? 'Relance par RDV (rappel)'
                                : 'Type de relance',
                            border: const OutlineInputBorder(),
                          ),
                          value: reportingController.typeRelance.value.isEmpty
                              ? null
                              : reportingController.typeRelance.value,
                          items: _getRelanceOptions(userRole)
                              .map((opt) => DropdownMenuItem<String>(
                                    value: opt['value']!,
                                    child: Text(opt['label']!),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            reportingController.typeRelance.value =
                                value ?? '';
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Obx(
                        () {
                          final type = reportingController.typeRelance.value;
                          if (type.isEmpty) return const SizedBox.shrink();
                          final label = type == 'relance_rdv'
                              ? 'Date et heure du RDV (rappel)'
                              : type == 'relance_telephonique'
                                  ? 'Date et heure de rappel (relance téléphonique)'
                                  : 'Date et heure de rappel (relance mail)';
                          return Column(
                            children: [
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: label,
                                  border: const OutlineInputBorder(),
                                ),
                                readOnly: true,
                                controller: TextEditingController(
                                  text: reportingController
                                              .relanceDateHeure.value !=
                                          null
                                      ? '${reportingController.relanceDateHeure.value!.toString().split(' ')[0]} ${reportingController.relanceDateHeure.value!.hour.toString().padLeft(2, '0')}:${reportingController.relanceDateHeure.value!.minute.toString().padLeft(2, '0')}'
                                      : '',
                                ),
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 365)),
                                  );
                                  if (date != null) {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
                                    );
                                    if (time != null) {
                                      reportingController
                                          .relanceDateHeure.value =
                                          DateTime(
                                        date.year,
                                        date.month,
                                        date.day,
                                        time.hour,
                                        time.minute,
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

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
                        onPressed: reportingController.isLoading.value
                            ? null
                            : () => reportingController.createReport(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        child: reportingController.isLoading.value
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
      ),
    );
  }

  List<Map<String, String>> _getNatureOptions(int? userRole) {
    if (userRole == Roles.COMMERCIAL) {
      return [
        {'value': 'echange_telephonique', 'label': 'Échange téléphonique'},
        {'value': 'visite', 'label': 'Visite'},
      ];
    } else if (userRole == Roles.TECHNICIEN) {
      return [
        {'value': 'depannage_visite', 'label': 'Dépannage visite'},
        {'value': 'depannage_bureau', 'label': 'Dépannage bureau'},
        {'value': 'depannage_telephonique', 'label': 'Dépannage téléphonique'},
        {'value': 'programmation', 'label': 'Programmation'},
      ];
    }
    return [];
  }

  /// Options de relance : technicien = uniquement RDV (rappel), autres rôles = téléphonique, mail, RDV
  List<Map<String, String>> _getRelanceOptions(int? userRole) {
    if (userRole == Roles.TECHNICIEN) {
      return [
        {'value': 'relance_rdv', 'label': 'Relance par RDV (rappel)'},
      ];
    }
    return [
      {'value': 'relance_telephonique', 'label': 'Relance téléphonique'},
      {'value': 'relance_mail', 'label': 'Relance par mail'},
      {'value': 'relance_rdv', 'label': 'Relance par RDV'},
    ];
  }
}
