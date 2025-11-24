import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/global_search_controller.dart';

class GlobalSearchPage extends StatelessWidget {
  const GlobalSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalSearchController controller =
        Get.find<GlobalSearchController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche globale'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: controller.searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Rechercher dans toute l\'application...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(() {
                  if (controller.searchQuery.value.isNotEmpty) {
                    return IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.searchController.clear();
                        controller.searchQuery.value = '';
                        controller.clearResults();
                      },
                    );
                  }
                  return const SizedBox.shrink();
                }),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                controller.searchQuery.value = value;
                if (value.isNotEmpty) {
                  controller.performSearch(value);
                } else {
                  controller.clearResults();
                }
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  controller.performSearch(value);
                }
              },
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isSearching.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.searchQuery.value.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Recherchez dans toute l\'application',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tapez votre recherche ci-dessus',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        if (controller.hasNoResults.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucun résultat trouvé',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Essayez avec d\'autres mots-clés',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clients
              if (controller.clientsResults.isNotEmpty) ...[
                _buildSectionHeader(
                  'Clients',
                  controller.clientsResults.length,
                ),
                const SizedBox(height: 8),
                ...controller.clientsResults.map(
                  (client) => _buildClientCard(client),
                ),
                const SizedBox(height: 16),
              ],

              // Factures
              if (controller.invoicesResults.isNotEmpty) ...[
                _buildSectionHeader(
                  'Factures',
                  controller.invoicesResults.length,
                ),
                const SizedBox(height: 8),
                ...controller.invoicesResults.map(
                  (invoice) => _buildInvoiceCard(invoice),
                ),
                const SizedBox(height: 16),
              ],

              // Paiements
              if (controller.paymentsResults.isNotEmpty) ...[
                _buildSectionHeader(
                  'Paiements',
                  controller.paymentsResults.length,
                ),
                const SizedBox(height: 8),
                ...controller.paymentsResults.map(
                  (payment) => _buildPaymentCard(payment),
                ),
                const SizedBox(height: 16),
              ],

              // Employés
              if (controller.employeesResults.isNotEmpty) ...[
                _buildSectionHeader(
                  'Employés',
                  controller.employeesResults.length,
                ),
                const SizedBox(height: 8),
                ...controller.employeesResults.map(
                  (employee) => _buildEmployeeCard(employee),
                ),
                const SizedBox(height: 16),
              ],

              // Fournisseurs
              if (controller.suppliersResults.isNotEmpty) ...[
                _buildSectionHeader(
                  'Fournisseurs',
                  controller.suppliersResults.length,
                ),
                const SizedBox(height: 8),
                ...controller.suppliersResults.map(
                  (supplier) => _buildSupplierCard(supplier),
                ),
                const SizedBox(height: 16),
              ],

              // Stocks
              if (controller.stocksResults.isNotEmpty) ...[
                _buildSectionHeader('Stocks', controller.stocksResults.length),
                const SizedBox(height: 8),
                ...controller.stocksResults.map(
                  (stock) => _buildStockCard(stock),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClientCard(dynamic client) {
    // Prioriser nom entreprise
    final clientName =
        client.nomEntreprise?.isNotEmpty == true
            ? client.nomEntreprise!
            : '${client.nom ?? ''} ${client.prenom ?? ''}'.trim().isNotEmpty
            ? '${client.nom ?? ''} ${client.prenom ?? ''}'.trim()
            : 'Client #${client.id}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: const Icon(Icons.person, color: Colors.blue),
        ),
        title: Text(clientName),
        subtitle: Text(client.email ?? client.contact ?? ''),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigation vers les détails du client
          Get.toNamed('/clients/${client.id}');
        },
      ),
    );
  }

  Widget _buildInvoiceCard(dynamic invoice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.1),
          child: const Icon(Icons.receipt, color: Colors.green),
        ),
        title: Text('Facture ${invoice.invoiceNumber}'),
        subtitle: Text('Client: ${invoice.clientName}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Get.toNamed('/factures/${invoice.id}');
        },
      ),
    );
  }

  Widget _buildPaymentCard(dynamic payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.1),
          child: const Icon(Icons.payment, color: Colors.orange),
        ),
        title: Text('Paiement ${payment.reference ?? payment.id}'),
        subtitle: Text('Montant: ${payment.amount ?? 0} FCFA'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Get.toNamed('/paiements/${payment.id}');
        },
      ),
    );
  }

  Widget _buildEmployeeCard(dynamic employee) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.withOpacity(0.1),
          child: const Icon(Icons.person_outline, color: Colors.purple),
        ),
        title: Text('${employee.firstName ?? ''} ${employee.lastName ?? ''}'),
        subtitle: Text(employee.email ?? ''),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Get.toNamed('/employees/${employee.id}');
        },
      ),
    );
  }

  Widget _buildSupplierCard(dynamic supplier) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.withOpacity(0.1),
          child: const Icon(Icons.business, color: Colors.teal),
        ),
        title: Text(supplier.nom),
        subtitle: Text('${supplier.email} | ${supplier.telephone}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Get.toNamed('/suppliers/${supplier.id}');
        },
      ),
    );
  }

  Widget _buildStockCard(dynamic stock) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.withOpacity(0.1),
          child: const Icon(Icons.inventory, color: Colors.indigo),
        ),
        title: Text(stock.name),
        subtitle: Text('SKU: ${stock.sku} | Catégorie: ${stock.category}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Get.toNamed('/stocks/${stock.id}');
        },
      ),
    );
  }
}
