import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/global_search_controller.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

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
        // Obx ciblé uniquement sur isSearching et searchQuery
        final isSearching = controller.isSearching.value;
        final searchQuery = controller.searchQuery.value;

        if (isSearching) {
          return const SkeletonSearchResults(itemCount: 6);
        }

        if (searchQuery.isEmpty) {
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

        final hasNoResults = controller.hasNoResults.value;
        if (hasNoResults) {
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

        // Extraire les valeurs une seule fois pour éviter les accès multiples
        final clientsResults = controller.clientsResults;
        final invoicesResults = controller.invoicesResults;
        final paymentsResults = controller.paymentsResults;
        final employeesResults = controller.employeesResults;
        final suppliersResults = controller.suppliersResults;
        final stocksResults = controller.stocksResults;

        return CustomScrollView(
          slivers: [
            // Clients - Obx ciblé uniquement sur cette liste
            _ReactiveSearchSection(
              list: clientsResults,
              title: 'Clients',
              buildHeader: _buildSectionHeader,
              buildCard: _buildClientCard,
            ),

            // Factures - Obx ciblé uniquement sur cette liste
            _ReactiveSearchSection(
              list: invoicesResults,
              title: 'Factures',
              buildHeader: _buildSectionHeader,
              buildCard: _buildInvoiceCard,
            ),

            // Paiements - Obx ciblé uniquement sur cette liste
            _ReactiveSearchSection(
              list: paymentsResults,
              title: 'Paiements',
              buildHeader: _buildSectionHeader,
              buildCard: _buildPaymentCard,
            ),

            // Employés - Obx ciblé uniquement sur cette liste
            _ReactiveSearchSection(
              list: employeesResults,
              title: 'Employés',
              buildHeader: _buildSectionHeader,
              buildCard: _buildEmployeeCard,
            ),

            // Fournisseurs - Obx ciblé uniquement sur cette liste
            _ReactiveSearchSection(
              list: suppliersResults,
              title: 'Fournisseurs',
              buildHeader: _buildSectionHeader,
              buildCard: _buildSupplierCard,
            ),

            // Stocks - Obx ciblé uniquement sur cette liste
            _ReactiveSearchSection(
              list: stocksResults,
              title: 'Stocks',
              buildHeader: _buildSectionHeader,
              buildCard: _buildStockCard,
            ),

            // Padding final
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
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

/// Widget réactif pour une section de recherche - ne reconstruit que si sa liste change
class _ReactiveSearchSection extends StatelessWidget {
  final RxList list;
  final String title;
  final Widget Function(String, int) buildHeader;
  final Widget Function(dynamic) buildCard;

  const _ReactiveSearchSection({
    required this.list,
    required this.title,
    required this.buildHeader,
    required this.buildCard,
  });

  @override
  Widget build(BuildContext context) {
    // Obx ciblé uniquement sur cette liste spécifique
    return Obx(() {
      if (list.isEmpty) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }

      return SliverMainAxisGroup(
        slivers: [
          // En-tête de section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: buildHeader(title, list.length),
            ),
          ),
          // Liste des résultats
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = list[index];
                return buildCard(item);
              }, childCount: list.length),
            ),
          ),
          // Espacement après la section
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      );
    });
  }
}
