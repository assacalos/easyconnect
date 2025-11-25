import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/devis_controller.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:easyconnect/Views/Components/responsive_widgets.dart';
import 'package:easyconnect/utils/responsive_helper.dart';
import 'package:intl/intl.dart';

class DevisListPage extends StatelessWidget {
  final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: 'fcfa');
  final DevisController controller = Get.find<DevisController>();
  final formatDate = DateFormat('dd/MM/yyyy');
  final int? clientId;

  DevisListPage({super.key, this.clientId});

  @override
  Widget build(BuildContext context) {
    // Recharger les devis au démarrage de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadDevis();
    });

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Devis'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'En attente'),
              Tab(text: 'Validés'),
              Tab(text: 'Rejetés'),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _buildDevisList(context, 1), // En attente
                _buildDevisList(context, 2), // Validés
                _buildDevisList(context, 3), // Rejetés
              ],
            ),
            // Bouton d'ajout uniforme en bas à droite
            UniformAddButton(
              onPressed: () => Get.toNamed('/devis/new'),
              label: 'Nouveau Devis',
              icon: Icons.description,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevisList(BuildContext context, int status) {
    final DevisController controller = Get.find<DevisController>();
    // Récupérer clientId depuis les arguments si non fourni
    final args = Get.arguments as Map<String, dynamic>?;
    final filterClientId = clientId ?? args?['clientId'] as int?;

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      var devisList =
          controller.devis.where((d) => d.status == status).toList();

      // Filtrer par clientId si fourni
      if (filterClientId != null) {
        devisList =
            devisList.where((d) => d.clientId == filterClientId).toList();
      }

      if (devisList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                status == 1
                    ? Icons.access_time
                    : status == 2
                    ? Icons.check_circle
                    : Icons.cancel,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                status == 1
                    ? 'Aucun devis en attente'
                    : status == 2
                    ? 'Aucun devis validé'
                    : 'Aucun devis rejeté',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ResponsiveScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getHorizontalPadding(context),
          vertical: ResponsiveHelper.getVerticalPadding(context),
        ),
        child: Column(
          children:
              devisList.map((devis) {
                return ResponsiveCard(
                  padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context)),
                  elevation: 2.0,
                  child: _buildDevisCard(context, devis, status),
                );
              }).toList(),
        ),
      );
    });
  }

  Widget _buildDevisCard(BuildContext context, devis, int status) {
    return InkWell(
      onTap: () => Get.toNamed('/devis/${devis.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            isThreeLine:
                status == 3 &&
                (devis.rejectionComment != null &&
                    devis.rejectionComment!.isNotEmpty),
            title: Row(
              children: [
                Expanded(
                  child: ResponsiveText(
                    devis.reference,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ResponsiveSpacing(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getSpacing(
                      context,
                      mobile: 6.0,
                      tablet: 8.0,
                      desktop: 10.0,
                    ),
                    vertical: ResponsiveHelper.getSpacing(
                      context,
                      mobile: 3.0,
                      tablet: 4.0,
                      desktop: 5.0,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: devis.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: devis.statusColor.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        devis.statusIcon,
                        size: ResponsiveHelper.getIconSize(
                          context,
                          mobile: 14.0,
                          tablet: 16.0,
                          desktop: 18.0,
                        ),
                        color: devis.statusColor,
                      ),
                      ResponsiveSpacing(width: 4),
                      Flexible(
                        child: ResponsiveText(
                          devis.statusText,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getFontSize(
                              context,
                              mobile: 11.0,
                              tablet: 12.0,
                              desktop: 13.0,
                            ),
                            color: devis.statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveSpacing(height: 8),
                Wrap(
                  spacing: ResponsiveHelper.getSpacing(context),
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: ResponsiveHelper.getIconSize(
                            context,
                            mobile: 12.0,
                            tablet: 14.0,
                            desktop: 16.0,
                          ),
                          color: Colors.grey.shade600,
                        ),
                        ResponsiveSpacing(width: 4),
                        ResponsiveText(
                          'Créé le ${formatDate.format(devis.dateCreation)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: ResponsiveHelper.getFontSize(
                              context,
                              mobile: 11.0,
                              tablet: 12.0,
                              desktop: 13.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (devis.dateValidite != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event,
                            size: ResponsiveHelper.getIconSize(
                              context,
                              mobile: 12.0,
                              tablet: 14.0,
                              desktop: 16.0,
                            ),
                            color: Colors.grey.shade600,
                          ),
                          ResponsiveSpacing(width: 4),
                          Flexible(
                            child: ResponsiveText(
                              'Valide jusqu\'au ${formatDate.format(devis.dateValidite!)}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: ResponsiveHelper.getFontSize(
                                  context,
                                  mobile: 11.0,
                                  tablet: 12.0,
                                  desktop: 13.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (status == 3 &&
                    (devis.rejectionComment != null &&
                        devis.rejectionComment!.isNotEmpty)) ...[
                  ResponsiveSpacing(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.report,
                        size: ResponsiveHelper.getIconSize(
                          context,
                          mobile: 12.0,
                          tablet: 14.0,
                          desktop: 16.0,
                        ),
                        color: Colors.red,
                      ),
                      ResponsiveSpacing(width: 4),
                      Expanded(
                        child: ResponsiveText(
                          'Raison du rejet: ${devis.rejectionComment}',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: ResponsiveHelper.getFontSize(
                              context,
                              mobile: 12.0,
                              tablet: 13.0,
                              desktop: 14.0,
                            ),
                          ),
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: Flexible(
              child: ResponsiveText(
                formatCurrency.format(devis.totalTTC),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveHelper.getFontSize(
                    context,
                    mobile: 14.0,
                    tablet: 16.0,
                    desktop: 18.0,
                  ),
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ),
          const Divider(height: 1),
          ButtonBar(
            alignment: MainAxisAlignment.end,
            children: [
              // Bouton Modifier pour les devis validés ou rejetés
              if (status == 2 || status == 3) ...[
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    size: ResponsiveHelper.getIconSize(context),
                  ),
                  onPressed: () => Get.toNamed('/devis/${devis.id}/edit'),
                  tooltip: 'Modifier',
                ),
              ],
              // Bouton PDF seulement pour les devis validés
              if (status == 2) ...[
                IconButton(
                  icon: Icon(
                    Icons.picture_as_pdf,
                    size: ResponsiveHelper.getIconSize(context),
                  ),
                  onPressed: () => controller.generatePDF(devis.id!),
                  tooltip: 'Générer PDF',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
