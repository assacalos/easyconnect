import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/contract_controller.dart';
import 'package:easyconnect/Models/contract_model.dart';
import 'package:easyconnect/Views/Rh/contract_form.dart';
import 'package:intl/intl.dart';

class ContractDetail extends StatelessWidget {
  final Contract contract;

  const ContractDetail({super.key, required this.contract});

  @override
  Widget build(BuildContext context) {
    final ContractController controller = Get.put(ContractController());

    return Scaffold(
      appBar: AppBar(
        title: Text('Contrat ${contract.contractNumber}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (contract.isDraft && controller.canManageContracts.value)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Get.to(() => ContractForm(contract: contract)),
            ),
          if (contract.isPending && controller.canApproveContracts.value) ...[
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => _showApproveDialog(contract, controller),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _showRejectDialog(contract, controller),
            ),
          ],
          if (contract.isActive && controller.canManageContracts.value)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _showTerminateDialog(contract, controller),
            ),
          if (contract.canCancel)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () => _showCancelDialog(contract, controller),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            _buildHeaderCard(contract),

            const SizedBox(height: 16),

            // Informations générales
            _buildGeneralInfoCard(contract),

            const SizedBox(height: 16),

            // Informations employé
            _buildEmployeeInfoCard(contract),

            const SizedBox(height: 16),

            // Détails du contrat
            _buildContractDetailsCard(contract),

            const SizedBox(height: 16),

            // Conditions de travail
            _buildWorkConditionsCard(contract),

            const SizedBox(height: 16),

            // Avantages et bénéfices
            _buildBenefitsCard(contract),

            const SizedBox(height: 16),

            // Documents et notes
            _buildDocumentsCard(contract),

            const SizedBox(height: 16),

            // Historique
            _buildHistoryCard(contract),

            const SizedBox(height: 16),

            // Actions
            _buildActionsCard(contract, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Contract contract) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contract.contractNumber,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${contract.employeeName} - ${contract.jobTitle}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(contract),
              ],
            ),
            if (contract.isExpiringSoon) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ce contrat expire bientôt',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralInfoCard(Contract contract) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations Générales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Type de contrat', contract.contractTypeText),
            _buildInfoRow('Département', contract.department),
            _buildInfoRow('Poste', contract.jobTitle),
            _buildInfoRow(
              'Date de début',
              DateFormat('dd/MM/yyyy').format(contract.startDate),
            ),
            if (contract.endDate != null)
              _buildInfoRow(
                'Date de fin',
                DateFormat('dd/MM/yyyy').format(contract.endDate!),
              ),
            _buildInfoRow('Statut', contract.statusText),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeInfoCard(Contract contract) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations Employé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Nom complet', contract.employeeName),
            _buildInfoRow('Email', contract.employeeEmail),
            _buildInfoRow('Téléphone', contract.employeePhone ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildContractDetailsCard(Contract contract) {
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'fcfa',
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Détails du Contrat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Salaire brut',
              formatCurrency.format(contract.grossSalary),
            ),
            _buildInfoRow(
              'Fréquence de paiement',
              contract.paymentFrequencyText,
            ),
            _buildInfoRow('Heures par semaine', '${contract.weeklyHours}h'),
            _buildInfoRow('Période d\'essai', contract.probationPeriodText),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkConditionsCard(Contract contract) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Conditions de Travail',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Lieu de travail', contract.workLocation),
            if (contract.workSchedule.isNotEmpty)
              _buildInfoRow('Horaires de travail', contract.workSchedule),
            if (contract.reportingManager?.isNotEmpty == true)
              _buildInfoRow('Superviseur direct', contract.reportingManager!),
            if (contract.jobDescription.isNotEmpty)
              _buildInfoRow('Description du poste', contract.jobDescription),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsCard(Contract contract) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Avantages et Bénéfices',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            if (contract.healthInsurance?.isNotEmpty == true)
              _buildInfoRow('Assurance maladie', contract.healthInsurance!),
            if (contract.retirementPlan?.isNotEmpty == true)
              _buildInfoRow('Plan de retraite', contract.retirementPlan!),
            if (contract.vacationDays != null)
              _buildInfoRow(
                'Jours de congé par an',
                '${contract.vacationDays}',
              ),
            if (contract.otherBenefits?.isNotEmpty == true)
              _buildInfoRow('Autres avantages', contract.otherBenefits!),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsCard(Contract contract) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Documents et Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            if (contract.notes?.isNotEmpty == true)
              _buildInfoRow('Notes', contract.notes!),
            if (contract.attachments.isNotEmpty)
              _buildInfoRow(
                'Pièces jointes',
                contract.attachments.map((a) => a.fileName).join(', '),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Contract contract) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historique',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            if (contract.history?.isNotEmpty == true) ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: contract.history!.length,
                itemBuilder: (context, index) {
                  return _buildHistoryEntry(contract.history![index]);
                },
              ),
            ] else ...[
              Text(
                'Aucun historique disponible',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryEntry(dynamic entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            _getHistoryIcon(entry.action),
            size: 16,
            color: _getHistoryColor(entry.action),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.actionText ?? 'Action',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (entry.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.notes,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${entry.userName ?? 'Utilisateur'} - ${DateFormat('dd/MM/yyyy à HH:mm').format(entry.createdAt ?? DateTime.now())}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(Contract contract, ContractController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            if (contract.isDraft && controller.canManageContracts.value) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Soumettre pour approbation'),
                onPressed: () => _showSubmitDialog(contract, controller),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (contract.isPending && controller.canApproveContracts.value) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Approuver'),
                onPressed: () => _showApproveDialog(contract, controller),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text('Rejeter'),
                onPressed: () => _showRejectDialog(contract, controller),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (contract.isActive && controller.canManageContracts.value) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text('Résilier'),
                onPressed: () => _showTerminateDialog(contract, controller),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (contract.canCancel) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.cancel),
                label: const Text('Annuler'),
                onPressed: () => _showCancelDialog(contract, controller),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        contract.statusText,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getHistoryIcon(String action) {
    switch (action) {
      case 'created':
        return Icons.add;
      case 'submitted':
        return Icons.send;
      case 'approved':
        return Icons.check;
      case 'rejected':
        return Icons.close;
      case 'terminated':
        return Icons.cancel;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info;
    }
  }

  Color _getHistoryColor(String action) {
    switch (action) {
      case 'created':
        return Colors.blue;
      case 'submitted':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'terminated':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
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
                      ? DateFormat('dd/MM/yyyy').format(selectedDate)
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
