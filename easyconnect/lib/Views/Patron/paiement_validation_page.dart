import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/payment_controller.dart';
import 'package:easyconnect/Models/payment_model.dart';
import 'package:intl/intl.dart';

class PaiementValidationPage extends StatefulWidget {
  const PaiementValidationPage({super.key});

  @override
  State<PaiementValidationPage> createState() => _PaiementValidationPageState();
}

class _PaiementValidationPageState extends State<PaiementValidationPage>
    with SingleTickerProviderStateMixin {
  late final PaymentController controller;
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Vérifier et initialiser le contrôleur
    if (!Get.isRegistered<PaymentController>()) {
      Get.put(PaymentController(), permanent: true);
    }
    controller = Get.find<PaymentController>();

    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      _onTabChanged();
    });
    _loadPayments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadPayments();
    }
  }

  Future<void> _loadPayments() async {
    print(
      '🔵 [PAIEMENT_VALIDATION] _loadPayments() appelé - Onglet: ${_tabController.index}',
    );

    String? status;
    switch (_tabController.index) {
      case 0: // Tous
        status = null;
        print('🔵 [PAIEMENT_VALIDATION] Onglet "Tous" sélectionné');
        break;
      case 1: // En attente - inclure tous les statuts en attente
        // Ne pas filtrer par status ici, on chargera tout et filtrera côté client
        status = null;
        print(
          '🔵 [PAIEMENT_VALIDATION] Onglet "En attente" sélectionné - Chargement de tous les paiements',
        );
        break;
      case 2: // Validés
        status = 'approved';
        print(
          '🔵 [PAIEMENT_VALIDATION] Onglet "Validés" sélectionné - Filtre: $status',
        );
        break;
      case 3: // Rejetés
        status = 'rejected';
        print(
          '🔵 [PAIEMENT_VALIDATION] Onglet "Rejetés" sélectionné - Filtre: $status',
        );
        break;
    }

    if (status != null) {
      controller.selectedStatus.value = status;
    } else {
      controller.selectedStatus.value = 'all';
    }
    print(
      '🔵 [PAIEMENT_VALIDATION] selectedStatus défini à: ${controller.selectedStatus.value}',
    );
    await controller.loadPayments();
    print(
      '🔵 [PAIEMENT_VALIDATION] Après loadPayments - Nombre de paiements: ${controller.payments.length}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Paiements'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadPayments();
            },
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tous', icon: Icon(Icons.list)),
            Tab(text: 'En attente', icon: Icon(Icons.pending)),
            Tab(text: 'Validés', icon: Icon(Icons.check_circle)),
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
                hintText: 'Rechercher par référence, client...',
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
                      : _buildPaymentList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList() {
    // Utiliser Obx pour rendre réactif l'accès à controller.payments
    return Obx(() {
      print(
        '🟢 [PAIEMENT_VALIDATION] _buildPaymentList() - Onglet: ${_tabController.index}',
      );
      print(
        '🟢 [PAIEMENT_VALIDATION] Nombre total de paiements dans controller: ${controller.payments.length}',
      );
      print(
        '🟢 [PAIEMENT_VALIDATION] isLoading: ${controller.isLoading.value}',
      );

      // Afficher tous les statuts pour debug
      if (controller.payments.isNotEmpty) {
        final allStatuses = controller.payments.map((p) => p.status).toSet();
        print('🟢 [PAIEMENT_VALIDATION] Statuts trouvés: $allStatuses');

        // Afficher les détails de chaque paiement
        for (var payment in controller.payments) {
          print(
            '🟢 [PAIEMENT_VALIDATION] Paiement: ${payment.paymentNumber} - Status: ${payment.status} - isPending: ${payment.isPending} - isApproved: ${payment.isApproved} - isRejected: ${payment.isRejected}',
          );
        }
      } else {
        print(
          '🟢 [PAIEMENT_VALIDATION] ⚠️ Aucun paiement dans controller.payments',
        );
      }

      // Filtrer selon l'onglet actif et la recherche
      List<PaymentModel> filteredPayments = controller.payments;
      print(
        '🟢 [PAIEMENT_VALIDATION] Avant filtrage: ${filteredPayments.length} paiements',
      );

      // Filtrer par statut selon l'onglet actif
      if (_tabController.index == 1) {
        // Onglet "En attente" - inclure tous les statuts en attente (pending, submitted, draft)
        final beforeCount = filteredPayments.length;
        filteredPayments =
            filteredPayments.where((payment) {
              final isPending = payment.isPending;
              if (isPending) {
                print(
                  '🟢 [PAIEMENT_VALIDATION] ✅ Paiement en attente trouvé: ${payment.paymentNumber} - Status: ${payment.status}',
                );
              }
              return isPending;
            }).toList();
        print(
          '🟢 [PAIEMENT_VALIDATION] Après filtrage "En attente": ${filteredPayments.length} sur $beforeCount',
        );
      } else if (_tabController.index == 2) {
        // Onglet "Validés"
        final beforeCount = filteredPayments.length;
        filteredPayments =
            filteredPayments.where((payment) => payment.isApproved).toList();
        print(
          '🟢 [PAIEMENT_VALIDATION] Après filtrage "Validés": ${filteredPayments.length} sur $beforeCount',
        );
      } else if (_tabController.index == 3) {
        // Onglet "Rejetés"
        final beforeCount = filteredPayments.length;
        filteredPayments =
            filteredPayments.where((payment) => payment.isRejected).toList();
        print(
          '🟢 [PAIEMENT_VALIDATION] Après filtrage "Rejetés": ${filteredPayments.length} sur $beforeCount',
        );
      }
      // Onglet 0 (Tous) - pas de filtre supplémentaire

      // Appliquer la recherche
      if (_searchQuery.isNotEmpty) {
        final beforeCount = filteredPayments.length;
        filteredPayments =
            filteredPayments
                .where(
                  (paiement) =>
                      (paiement.reference ?? '').toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      paiement.clientName.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                )
                .toList();
        print(
          '🟢 [PAIEMENT_VALIDATION] Après filtrage recherche: ${filteredPayments.length} sur $beforeCount',
        );
      }

      print(
        '🟢 [PAIEMENT_VALIDATION] ✅ Paiements finaux à afficher: ${filteredPayments.length}',
      );

      if (filteredPayments.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payment, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty
                    ? 'Aucun paiement trouvé'
                    : 'Aucun paiement correspondant à "$_searchQuery"',
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
        itemCount: filteredPayments.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final payment = filteredPayments[index];
          return _buildPaymentCard(context, payment);
        },
      );
    });
  }

  Widget _buildPaymentCard(BuildContext context, PaymentModel payment) {
    final formatDate = DateFormat('dd/MM/yyyy');
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
    );
    final statusColor = _getStatusColor(payment.status);
    final statusIcon = _getStatusIcon(payment.status);
    final statusText = _getStatusText(payment.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          payment.paymentNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Client: ${payment.clientName}'),
            Text('Date: ${formatDate.format(payment.paymentDate)}'),
            Text('Montant: ${formatCurrency.format(payment.amount)}'),
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
                  'Informations générales',
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
                      Text('Numéro: ${payment.paymentNumber}'),
                      Text('Type: ${_getPaymentTypeText(payment.type)}'),
                      Text('Client: ${payment.clientName}'),
                      Text('Email: ${payment.clientEmail}'),
                      Text('Adresse: ${payment.clientAddress}'),
                      Text('Comptable: ${payment.comptableName}'),
                      Text(
                        'Date paiement: ${formatDate.format(payment.paymentDate)}',
                      ),
                      if (payment.dueDate != null)
                        Text(
                          'Date échéance: ${formatDate.format(payment.dueDate!)}',
                        ),
                      Text(
                        'Méthode: ${_getPaymentMethodText(payment.paymentMethod)}',
                      ),
                      if (payment.reference != null)
                        Text('Référence: ${payment.reference}'),
                      if (payment.description != null)
                        Text('Description: ${payment.description}'),
                      if (payment.notes != null)
                        Text('Notes: ${payment.notes}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Montant total:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        formatCurrency.format(payment.amount),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButtons(payment, statusColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(PaymentModel payment, Color statusColor) {
    // Vérifier si le paiement est en attente (pending, submitted, ou draft)
    if (payment.isPending) {
      // En attente - Afficher boutons Valider/Rejeter
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showApproveConfirmation(payment),
                icon: const Icon(Icons.check),
                label: const Text('Valider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showRejectDialog(payment),
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
    }

    // Si le paiement est approuvé
    if (payment.isApproved) {
      // Validé - Afficher seulement info
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
              'Paiement validé',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // Si le paiement est rejeté
    if (payment.isRejected) {
      // Rejeté - Afficher motif du rejet
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'Paiement rejeté',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

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
            'Statut: ${controller.getPaymentStatusName(payment.status)}',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'submitted':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'submitted':
        return 'En attente';
      case 'approved':
        return 'Validé';
      case 'rejected':
        return 'Rejeté';
      default:
        return status;
    }
  }

  String _getPaymentTypeText(String type) {
    switch (type) {
      case 'one_time':
        return 'Paiement unique';
      case 'monthly':
        return 'Paiement mensuel';
      default:
        return type;
    }
  }

  String _getPaymentMethodText(String method) {
    switch (method) {
      case 'bank_transfer':
        return 'Virement bancaire';
      case 'check':
        return 'Chèque';
      case 'cash':
        return 'Espèces';
      case 'card':
        return 'Carte';
      case 'direct_debit':
        return 'Prélèvement';
      default:
        return method;
    }
  }

  void _showApproveConfirmation(PaymentModel payment) {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Voulez-vous valider ce paiement ?',
      textConfirm: 'Valider',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.approvePayment(payment.id);
        _loadPayments();
      },
    );
  }

  void _showRejectDialog(PaymentModel payment) {
    final reasonController = TextEditingController();

    Get.defaultDialog(
      title: 'Rejeter le paiement',
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
        controller.rejectPayment(payment.id, reason: reasonController.text);
        _loadPayments();
      },
    );
  }
}
