import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/contract_controller.dart';
import 'package:easyconnect/Models/contract_model.dart';
import 'package:easyconnect/Views/Rh/contract_form.dart';
import 'package:easyconnect/Views/Rh/contract_detail.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:intl/intl.dart';

class ContractList extends StatelessWidget {
  const ContractList({super.key});

  @override
  Widget build(BuildContext context) {
    final ContractController controller = Get.put(ContractController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Contrats'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadContracts(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Barre de recherche et filtres
              _buildSearchAndFilters(controller),

              // Statistiques rapides
              _buildQuickStats(controller),

              // Liste des contrats
              Expanded(child: _buildContractList(controller)),
            ],
          ),
          // Bouton d'ajout uniforme en bas à droite
          if (controller.canManageContracts.value)
            UniformAddButton(
              onPressed: () => Get.to(() => const ContractForm()),
              label: 'Nouveau Contrat',
              icon: Icons.description,
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(ContractController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: controller.searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un contrat...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => controller.searchContracts(value),
          ),

          const SizedBox(height: 12),

          // Filtres
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.selectedStatus.value,
                    decoration: const InputDecoration(
                      labelText: 'Statut',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items:
                        controller.statusOptions.map<DropdownMenuItem<String>>((
                          status,
                        ) {
                          return DropdownMenuItem<String>(
                            value: status['value']!,
                            child: Text(status['label']!),
                          );
                        }).toList(),
                    onChanged: (value) => controller.filterByStatus(value!),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.selectedContractType.value,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items:
                        controller.contractTypeOptions
                            .map<DropdownMenuItem<String>>((type) {
                              return DropdownMenuItem<String>(
                                value: type['value']!,
                                child: Text(type['label']!),
                              );
                            })
                            .toList(),
                    onChanged:
                        (value) => controller.filterByContractType(value!),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Bouton pour réinitialiser les filtres
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Réinitialiser'),
                onPressed: () => controller.clearFilters(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ContractController controller) {
    return Obx(() {
      if (controller.contractStats.value == null) {
        return const SizedBox.shrink();
      }

      final stats = controller.contractStats.value!;
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                '${stats.totalContracts}',
                Icons.description,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Actifs',
                '${stats.activeContracts}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'En attente',
                '${stats.pendingContracts}',
                Icons.schedule,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Expirant',
                '${stats.contractsExpiringSoon}',
                Icons.warning,
                Colors.red,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContractList(ContractController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final filteredContracts = controller.filteredContracts;

      if (filteredContracts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun contrat trouvé',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Commencez par créer un contrat',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredContracts.length,
        itemBuilder: (context, index) {
          final contract = filteredContracts[index];
          return _buildContractCard(contract, controller);
        },
      );
    });
  }

  Widget _buildContractCard(Contract contract, ContractController controller) {
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'fcfa',
    );
    final formatDate = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Get.to(() => ContractDetail(contract: contract)),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec numéro et statut
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contract.contractNumber,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${contract.employeeName} - ${contract.jobTitle}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(contract),
                ],
              ),

              const SizedBox(height: 12),

              // Informations clés
              Row(
                children: [
                  Icon(Icons.business, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    contract.department,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.work, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    contract.contractTypeText,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Salaire et horaires
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${formatCurrency.format(contract.grossSalary)}/${contract.paymentFrequencyText}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${contract.weeklyHours}h/sem',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Dates
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Début: ${formatDate.format(contract.startDate)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  if (contract.endDate != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.event, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Fin: ${formatDate.format(contract.endDate!)}',
                      style: TextStyle(
                        color:
                            contract.hasExpired ? Colors.red : Colors.grey[600],
                        fontSize: 14,
                        fontWeight:
                            contract.hasExpired
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),

              if (contract.isExpiringSoon) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Expire bientôt',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (contract.isDraft &&
                      controller.canManageContracts.value) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text('Soumettre'),
                      onPressed: () => _showSubmitDialog(contract, controller),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                      onPressed:
                          () => Get.to(() => ContractForm(contract: contract)),
                    ),
                  ],
                  if (contract.isPending &&
                      controller.canApproveContracts.value) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approuver'),
                      onPressed: () => _showApproveDialog(contract, controller),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Rejeter'),
                      onPressed: () => _showRejectDialog(contract, controller),
                    ),
                  ],
                  if (contract.isActive &&
                      controller.canManageContracts.value) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Résilier'),
                      onPressed:
                          () => _showTerminateDialog(contract, controller),
                    ),
                  ],
                  if (contract.canCancel) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Annuler'),
                      onPressed: () => _showCancelDialog(contract, controller),
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

  Widget _buildStatusChip(Contract contract) {
    Color color;
    switch (contract.statusColor) {
      case 'grey':
        color = Colors.grey;
        break;
      case 'orange':
        color = Colors.orange;
        break;
      case 'green':
        color = Colors.green;
        break;
      case 'red':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        contract.statusText,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showSubmitDialog(Contract contract, ContractController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Soumettre le contrat'),
        content: const Text(
          'Êtes-vous sûr de vouloir soumettre ce contrat pour approbation ?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              controller.submitContract(contract);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Soumettre'),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(Contract contract, ContractController controller) {
    final notesController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Approuver le contrat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Êtes-vous sûr de vouloir approuver ce contrat ?'),
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
              controller.approveContract(
                contract,
                notes:
                    notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
              );
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approuver'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Contract contract, ContractController controller) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter le contrat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Êtes-vous sûr de vouloir rejeter ce contrat ?'),
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
                controller.rejectContract(
                  contract,
                  reasonController.text.trim(),
                );
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  void _showTerminateDialog(Contract contract, ContractController controller) {
    final reasonController = TextEditingController();
    DateTime? selectedDate;

    Get.dialog(
      AlertDialog(
        title: const Text('Résilier le contrat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Êtes-vous sûr de vouloir résilier ce contrat ?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison de la résiliation *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: Get.context!,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  selectedDate = date;
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date de résiliation *',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  selectedDate != null
                      ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                      : 'Sélectionner une date',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty &&
                  selectedDate != null) {
                controller.terminateContract(
                  contract,
                  reasonController.text.trim(),
                  selectedDate!,
                );
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Résilier'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(Contract contract, ContractController controller) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Annuler le contrat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Êtes-vous sûr de vouloir annuler ce contrat ?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison de l\'annulation (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Non')),
          ElevatedButton(
            onPressed: () {
              controller.cancelContract(
                contract,
                reason:
                    reasonController.text.trim().isEmpty
                        ? null
                        : reasonController.text.trim(),
              );
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }
}
