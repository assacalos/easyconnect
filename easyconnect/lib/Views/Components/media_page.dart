import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/media_controller.dart';
import 'package:easyconnect/Models/media_model.dart';
import 'package:easyconnect/Views/Components/dashboard_wrapper.dart';
import 'package:intl/intl.dart';

/// Page pour afficher tous les médias (images et fichiers) par catégorie
class MediaPage extends StatelessWidget {
  const MediaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MediaController());

    return DashboardWrapper(
      currentIndex: 4, // Index du bouton "Médias" dans la bottom navigation
      appBar: AppBar(
        title: const Text('Médias'),
        actions: [
          // Bouton de scan
          IconButton(
            icon: const Icon(Icons.scanner),
            tooltip: 'Scanner un document',
            onPressed: () => controller.scanDocument(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => controller.scanDocument(),
        icon: const Icon(Icons.scanner),
        label: const Text('Scanner'),
      ),
      child: Column(
        children: [
          // Filtres par catégorie
          _buildCategoryFilters(controller),

          // Liste des médias
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredMedia = controller.getFilteredMedia();

              if (filteredMedia.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun média trouvé',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.8,
                ),
                itemCount: filteredMedia.length,
                itemBuilder: (context, index) {
                  return _buildMediaItem(filteredMedia[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Construire les filtres de catégorie
  Widget _buildCategoryFilters(MediaController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            _buildCategoryChip(
              controller,
              'all',
              'Tous',
              Icons.photo_library,
              controller.allMedia.length,
            ),
            _buildCategoryChip(
              controller,
              'attendance',
              'Pointages',
              Icons.access_time,
              controller.getMediaCount('attendance'),
            ),
            _buildCategoryChip(
              controller,
              'bon_commande',
              'Bons de commande',
              Icons.shopping_cart,
              controller.getMediaCount('bon_commande'),
            ),
            _buildCategoryChip(
              controller,
              'expense',
              'Dépenses',
              Icons.receipt,
              controller.getMediaCount('expense'),
            ),
            _buildCategoryChip(
              controller,
              'salary',
              'Salaires',
              Icons.account_balance_wallet,
              controller.getMediaCount('salary'),
            ),
            _buildCategoryChip(
              controller,
              'other',
              'Autres',
              Icons.folder,
              controller.getMediaCount('other'),
            ),
          ],
        ),
      ),
    );
  }

  /// Construire un chip de catégorie
  Widget _buildCategoryChip(
    MediaController controller,
    String category,
    String label,
    IconData icon,
    int count,
  ) {
    final isSelected = controller.selectedCategory.value == category;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.blue : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
        onSelected: (selected) {
          controller.filterByCategory(category);
        },
      ),
    );
  }

  /// Construire un élément de média
  Widget _buildMediaItem(MediaItem media) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showMediaDetail(media),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image ou icône
            Expanded(
              child:
                  media.isImage
                      ? Image.network(
                        media.url,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, size: 48),
                          );
                        },
                      )
                      : Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            media.isPdf
                                ? Icons.picture_as_pdf
                                : Icons.insert_drive_file,
                            size: 48,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
            ),
            // Informations
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media.fileName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(media.category),
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _getCategoryLabel(media.category),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd/MM/yyyy').format(media.createdAt),
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Obtenir l'icône de catégorie
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'attendance':
        return Icons.access_time;
      case 'bon_commande':
        return Icons.shopping_cart;
      case 'expense':
        return Icons.receipt;
      case 'salary':
        return Icons.account_balance_wallet;
      default:
        return Icons.folder;
    }
  }

  /// Obtenir le label de catégorie
  String _getCategoryLabel(String category) {
    switch (category) {
      case 'attendance':
        return 'Pointage';
      case 'bon_commande':
        return 'Bon de commande';
      case 'expense':
        return 'Dépense';
      case 'salary':
        return 'Salaire';
      default:
        return 'Autre';
    }
  }

  /// Afficher les détails d'un média
  void _showMediaDetail(MediaItem media) {
    Get.dialog(
      Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(media.fileName),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            Expanded(
              child:
                  media.isImage
                      ? Image.network(
                        media.url,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, size: 64),
                          );
                        },
                      )
                      : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              media.isPdf
                                  ? Icons.picture_as_pdf
                                  : Icons.insert_drive_file,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              media.fileName,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.download),
                              label: const Text('Télécharger'),
                              onPressed: () {
                                // TODO: Implémenter le téléchargement
                                Get.snackbar(
                                  'Information',
                                  'Téléchargement à implémenter',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
            ),
            // Informations
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Catégorie', _getCategoryLabel(media.category)),
                  _buildInfoRow(
                    'Date',
                    DateFormat('dd/MM/yyyy à HH:mm').format(media.createdAt),
                  ),
                  if (media.fileSize != null)
                    _buildInfoRow('Taille', _formatFileSize(media.fileSize!)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
