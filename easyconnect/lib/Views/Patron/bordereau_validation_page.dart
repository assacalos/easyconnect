import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/bordereau_controller.dart';
import 'package:easyconnect/Models/bordereau_model.dart';
import 'package:intl/intl.dart';

class BordereauValidationPage extends StatefulWidget {
  const BordereauValidationPage({super.key});

  @override
  State<BordereauValidationPage> createState() =>
      _BordereauValidationPageState();
}

class _BordereauValidationPageState extends State<BordereauValidationPage>
    with SingleTickerProviderStateMixin {
  final BordereauxController controller = Get.find<BordereauxController>();
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
    _loadBordereaux();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadBordereaux();
    }
  }

  Future<void> _loadBordereaux() async {
    print('🔍 BordereauValidationPage._loadBordereaux - Début');
    print('📊 Onglet sélectionné: ${_tabController.index}');

    int? status;
    switch (_tabController.index) {
      case 0: // Tous
        status = null;
        break;
      case 1: // En attente
        status = 1;
        break;
      case 2: // Validés
        status = 2;
        break;
      case 3: // Rejetés
        status = 3;
        break;
    }

    print('📊 Status à charger: $status');
    await controller.loadBordereaux(status: status);
    print(
      '📊 BordereauValidationPage._loadBordereaux - ${controller.bordereaux.length} bordereaux chargés',
    );
    for (final bordereau in controller.bordereaux) {
      print('📋 Bordereau: ${bordereau.id} - Status: ${bordereau.status}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des bordereaux'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadBordereaux();
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
                hintText: 'Rechercher par référence...',
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
                      : _buildBordereauList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBordereauList() {
    // Filtrer les bordereaux selon la recherche
    final filteredBordereaux =
        _searchQuery.isEmpty
            ? controller.bordereaux
            : controller.bordereaux
                .where(
                  (bordereau) => bordereau.reference.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
                )
                .toList();

    if (filteredBordereaux.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Aucun bordereau trouvé'
                  : 'Aucun bordereau correspondant à "$_searchQuery"',
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
      itemCount: filteredBordereaux.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final bordereau = filteredBordereaux[index];
        return _buildBordereauCard(bordereau);
      },
    );
  }

  Widget _buildBordereauCard(Bordereau bordereau) {
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'fcfa',
    );
    final formatDate = DateFormat('dd/MM/yyyy');

    // Déterminer la couleur et l'icône selon le statut
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (bordereau.status) {
      case 0:
        statusColor = Colors.grey;
        statusIcon = Icons.edit;
        statusText = 'Brouillon';
        break;
      case 1:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'En attente';
        break;
      case 2:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Validé';
        break;
      case 3:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejeté';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Inconnu';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          bordereau.reference,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Date: ${formatDate.format(bordereau.dateCreation)}'),
            Text('Montant: ${formatCurrency.format(bordereau.montantTTC)}'),
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
                // Informations client (ID seulement pour l'instant)
                const Text(
                  'Informations client',
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
                      Text(
                        'Client ID: ${bordereau.clientId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (bordereau.devisId != null)
                        Text('Devis ID: ${bordereau.devisId}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Détails des articles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...bordereau.items.map((item) => _buildItemDetails(item)),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total HT:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(formatCurrency.format(bordereau.montantHT)),
                  ],
                ),
                if (bordereau.remiseGlobale != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Remise (${bordereau.remiseGlobale}%):',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '- ${formatCurrency.format(bordereau.montantHT * (bordereau.remiseGlobale! / 100))}',
                      ),
                    ],
                  ),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TVA (${bordereau.tva}%):',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(formatCurrency.format(bordereau.montantTVA)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total TTC:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      formatCurrency.format(bordereau.montantTTC),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActionButtons(bordereau, statusColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetails(BordereauItem item) {
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'fcfa',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.designation,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (item.description != null)
                  Text(
                    item.description!,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
              ],
            ),
          ),
          Expanded(child: Text('${item.quantite} ${item.unite}')),
          Expanded(child: Text(formatCurrency.format(item.prixUnitaire))),
          Expanded(
            child: Text(
              formatCurrency.format(item.montantTotal),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Bordereau bordereau, Color statusColor) {
    // Afficher les boutons selon le statut
    switch (bordereau.status) {
      case 1: // En attente - Afficher boutons Valider/Rejeter
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () => _showApproveConfirmation(bordereau),
              icon: const Icon(Icons.check),
              label: const Text('Valider'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showRejectDialog(bordereau),
              icon: const Icon(Icons.close),
              label: const Text('Rejeter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      case 2: // Validé - Afficher seulement info
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
                'Bordereau validé',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case 3: // Rejeté - Afficher motif du rejet
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
                    'Bordereau rejeté',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (bordereau.commentaireRejet != null &&
                  bordereau.commentaireRejet!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Motif: ${bordereau.commentaireRejet}',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      default: // Autres statuts
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
                'Statut: ${bordereau.status}',
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

  void _showApproveConfirmation(Bordereau bordereau) {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Voulez-vous valider ce bordereau ?',
      textConfirm: 'Valider',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.approveBordereau(bordereau.id!);
      },
    );
  }

  void _showRejectDialog(Bordereau bordereau) {
    final commentController = TextEditingController();

    Get.defaultDialog(
      title: 'Rejeter le bordereau',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: commentController,
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
        if (commentController.text.isEmpty) {
          Get.snackbar(
            'Erreur',
            'Veuillez entrer un motif de rejet',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        Get.back();
        controller.rejectBordereau(bordereau.id!, commentController.text);
      },
    );
  }
}
