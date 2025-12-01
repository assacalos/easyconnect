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

    // Charger les contrats au chargement de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // S'assurer de charger tous les contrats (sans filtre de statut)
      controller.selectedStatus.value = 'all';
      controller.loadContracts();
    });

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Contrats'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                controller.selectedStatus.value = 'all';
                controller.loadContracts();
              },
              tooltip: 'Actualiser',
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'En attente'),
              Tab(text: 'Actifs'),
              Tab(text: 'Expirés'),
              Tab(text: 'Résiliés'),
              Tab(text: 'Annulés'),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _buildContractList('pending', controller), // En attente
                _buildContractList('active', controller), // Actifs
                _buildContractList('expired', controller), // Expirés
                _buildContractList('terminated', controller), // Résiliés
                _buildContractList('cancelled', controller), // Annulés
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
      ),
    );
  }

  Widget _buildContractList(String status, ContractController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // Filtrer selon le statut
      List<Contract> contractList;
      contractList =
          controller.contracts.where((c) => c.status == status).toList();

      if (contractList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                status == 'pending'
                    ? Icons.pending
                    : status == 'active'
                    ? Icons.check_circle
                    : status == 'expired'
                    ? Icons.event_busy
                    : status == 'terminated'
                    ? Icons.block
                    : Icons.cancel,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                status == 'pending'
                    ? 'Aucun contrat en attente'
                    : status == 'active'
                    ? 'Aucun contrat actif'
                    : status == 'expired'
                    ? 'Aucun contrat expiré'
                    : status == 'terminated'
                    ? 'Aucun contrat résilié'
                    : 'Aucun contrat annulé',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: contractList.length,
        itemBuilder: (context, index) {
          final contract = contractList[index];
          return _buildContractCard(contract, controller);
        },
      );
    });
  }

  Widget _buildContractCard(Contract contract, ContractController controller) {
    final formatDate = DateFormat('dd/MM/yyyy');

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (contract.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'En attente';
        break;
      case 'active':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Actif';
        break;
      case 'expired':
        statusColor = Colors.blue;
        statusIcon = Icons.event_busy;
        statusText = 'Expiré';
        break;
      case 'terminated':
        statusColor = Colors.red;
        statusIcon = Icons.block;
        statusText = 'Résilié';
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
        statusText = 'Annulé';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Inconnu';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => Get.to(() => ContractDetail(contract: contract)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec numéro de contrat et statut
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contract.contractNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contract.employeeName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Informations du contrat
              Row(
                children: [
                  const Icon(Icons.work, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      contract.jobTitle,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(contract.department),
                ],
              ),
              const SizedBox(height: 4),

              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${contract.grossSalary.toStringAsFixed(0)} ${contract.salaryCurrency}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Du ${formatDate.format(contract.startDate)}${contract.endDate != null ? ' au ${formatDate.format(contract.endDate!)}' : ''}',
                  ),
                ],
              ),

              // Actions selon le statut
              if (contract.status == 'active') ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (controller.canManageContracts.value)
                      TextButton.icon(
                        onPressed:
                            () => _showTerminateDialog(contract, controller),
                        icon: const Icon(Icons.block, size: 18),
                        label: const Text('Résilier'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showTerminateDialog(Contract contract, ContractController controller) {
    DateTime? selectedDate;
    final reasonController = TextEditingController();

    Get.dialog(
      StatefulBuilder(
        builder:
            (context, setState) => AlertDialog(
              title: const Text('Résilier le contrat'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Veuillez indiquer la date et la raison de résiliation :',
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: contract.startDate,
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          setState(() {
                            selectedDate = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date de résiliation',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          selectedDate != null
                              ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                              : 'Sélectionner une date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Raison de résiliation',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedDate == null) {
                      Get.snackbar(
                        'Erreur',
                        'Veuillez sélectionner une date',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return;
                    }
                    if (reasonController.text.trim().isEmpty) {
                      Get.snackbar(
                        'Erreur',
                        'Veuillez indiquer la raison',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return;
                    }
                    controller.terminateContract(
                      contract,
                      reasonController.text.trim(),
                      selectedDate!,
                    );
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Résilier'),
                ),
              ],
            ),
      ),
    );
  }
}
