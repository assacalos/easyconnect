import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/contract_controller.dart';
import 'package:easyconnect/Models/contract_model.dart';
import 'package:intl/intl.dart';

class ContractValidationPage extends StatefulWidget {
  const ContractValidationPage({super.key});

  @override
  State<ContractValidationPage> createState() => _ContractValidationPageState();
}

class _ContractValidationPageState extends State<ContractValidationPage>
    with SingleTickerProviderStateMixin {
  final ContractController controller = Get.find<ContractController>();
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      _onTabChanged();
    });
    _loadContracts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadContracts();
    }
  }

  Future<void> _loadContracts() async {
    String? status;
    switch (_tabController.index) {
      case 0: // Tous
        status = null;
        break;
      case 1: // En attente
        status = 'pending';
        break;
      case 2: // Actifs
        status = 'active';
        break;
      case 3: // Rejetés
        status = 'cancelled';
        break;
    }

    controller.selectedStatus.value = status ?? 'all';
    await controller.loadContracts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Contrats'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadContracts();
            },
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tous', icon: Icon(Icons.list)),
            Tab(text: 'En attente', icon: Icon(Icons.pending)),
            Tab(text: 'Actifs', icon: Icon(Icons.check_circle)),
            Tab(text: 'Rejetés', icon: Icon(Icons.cancel)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par employé, département...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Contenu des onglets
          Expanded(
            child: Obx(
              () =>
                  controller.isLoading.value
                      ? const Center(child: CircularProgressIndicator())
                      : _buildContractList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractList() {
    // Filtrer les contrats selon la recherche et le statut
    List<Contract> filteredContracts = controller.contracts;

    // Filtrer par statut selon l'onglet
    switch (_tabController.index) {
      case 1: // En attente
        filteredContracts =
            filteredContracts
                .where((contract) => contract.status == 'pending')
                .toList();
        break;
      case 2: // Actifs
        filteredContracts =
            filteredContracts
                .where((contract) => contract.status == 'active')
                .toList();
        break;
      case 3: // Rejetés
        filteredContracts =
            filteredContracts
                .where((contract) => contract.status == 'cancelled')
                .toList();
        break;
    }

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      filteredContracts =
          filteredContracts
              .where(
                (contract) =>
                    contract.employeeName.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    contract.department.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    contract.jobTitle.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();
    }

    if (filteredContracts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Aucun contrat trouvé'
                  : 'Aucun contrat correspondant à "$_searchQuery"',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Effacer la recherche'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredContracts.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final contract = filteredContracts[index];
        return _buildContractCard(context, contract);
      },
    );
  }

  Widget _buildContractCard(BuildContext context, Contract contract) {
    final formatDate = DateFormat('dd/MM/yyyy');
    final statusColor = _getStatusColor(contract.status);
    final statusIcon = _getStatusIcon(contract.status);
    final statusText = _getStatusText(contract.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          contract.employeeName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Poste: ${contract.jobTitle}'),
            Text('Département: ${contract.department}'),
            Text(
              'Du ${formatDate.format(contract.startDate)}${contract.endDate != null ? ' au ${formatDate.format(contract.endDate!)}' : ''}',
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations générales
                const Text(
                  'Informations du contrat',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Numéro: ${contract.contractNumber}'),
                      Text('Employé: ${contract.employeeName}'),
                      Text('Email: ${contract.employeeEmail}'),
                      if (contract.employeePhone != null)
                        Text('Téléphone: ${contract.employeePhone}'),
                      Text('Type: ${contract.contractType}'),
                      Text('Poste: ${contract.jobTitle}'),
                      Text('Département: ${contract.department}'),
                      Text(
                        'Salaire brut: ${contract.grossSalary.toStringAsFixed(0)} ${contract.salaryCurrency}',
                      ),
                      Text(
                        'Salaire net: ${contract.netSalary.toStringAsFixed(0)} ${contract.salaryCurrency}',
                      ),
                      Text('Fréquence: ${contract.paymentFrequency}'),
                      Text('Horaire: ${contract.workSchedule}'),
                      Text('Heures/semaine: ${contract.weeklyHours}'),
                      Text(
                        'Date début: ${formatDate.format(contract.startDate)}',
                      ),
                      if (contract.endDate != null)
                        Text(
                          'Date fin: ${formatDate.format(contract.endDate!)}',
                        ),
                      if (contract.workLocation.isNotEmpty)
                        Text('Lieu: ${contract.workLocation}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButtons(contract, statusColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Contract contract, Color statusColor) {
    if (contract.status == 'pending') {
      // En attente - Afficher boutons Valider/Rejeter
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showApproveConfirmation(contract),
                icon: const Icon(Icons.check),
                label: const Text('Valider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showRejectDialog(contract),
                icon: const Icon(Icons.close),
                label: const Text('Rejeter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      );
    } else if (contract.status == 'active') {
      // Actif - Afficher seulement info
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              'Contrat validé',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (contract.status == 'cancelled') {
      // Rejeté - Afficher motif du rejet
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cancel, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Contrat rejeté',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (contract.rejectionReason != null &&
                contract.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Motif: ${contract.rejectionReason}',
                style: TextStyle(color: Colors.red[700], fontSize: 12),
              ),
            ],
          ],
        ),
      );
    } else {
      // Autres statuts
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'Statut: ${contract.status}',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.blue;
      case 'terminated':
        return Colors.red;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'active':
        return Icons.check_circle;
      case 'expired':
        return Icons.event_busy;
      case 'terminated':
        return Icons.block;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'active':
        return 'Actif';
      case 'expired':
        return 'Expiré';
      case 'terminated':
        return 'Résilié';
      case 'cancelled':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  void _showApproveConfirmation(Contract contract) {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Voulez-vous valider ce contrat ?',
      textConfirm: 'Valider',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.approveContract(contract);
        _loadContracts();
      },
    );
  }

  void _showRejectDialog(Contract contract) {
    final reasonController = TextEditingController();

    Get.defaultDialog(
      title: 'Rejeter le contrat',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Motif du rejet',
              hintText: 'Entrez le motif du rejet',
            ),
            maxLines: 3,
          ),
        ],
      ),
      textConfirm: 'Rejeter',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        if (reasonController.text.isEmpty) {
          Get.snackbar(
            'Erreur',
            'Veuillez entrer un motif de rejet',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        Get.back();
        controller.rejectContract(contract, reasonController.text.trim());
        _loadContracts();
      },
    );
  }
}
