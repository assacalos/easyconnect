import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaginatedDataView extends StatelessWidget {
  final List<Widget> children;
  final int itemsPerPage;
  final bool isLoading;
  final ScrollController scrollController;
  final Function() onLoadMore;
  final bool hasMoreData;

  const PaginatedDataView({
    super.key,
    required this.children,
    this.itemsPerPage = 10,
    this.isLoading = false,
    required this.scrollController,
    required this.onLoadMore,
    required this.hasMoreData,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!isLoading &&
            hasMoreData &&
            scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          onLoadMore();
        }
        return true;
      },
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < children.length) {
                  return children[index];
                }
                if (isLoading && hasMoreData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return null;
              },
              childCount: children.length + (isLoading && hasMoreData ? 1 : 0),
            ),
          ),
        ],
      ),
    );
  }
}

class PaginationController extends GetxController {
  final int itemsPerPage;
  final RxInt currentPage = 1.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasMoreData = true.obs;
  final ScrollController scrollController = ScrollController();

  PaginationController({this.itemsPerPage = 10});

  void resetPagination() {
    currentPage.value = 1;
    hasMoreData.value = true;
  }

  Future<void> loadNextPage() async {
    if (isLoading.value || !hasMoreData.value) return;

    isLoading.value = true;
    await loadData();
    isLoading.value = false;
  }

  Future<void> loadData() async {
    // À implémenter dans les classes dérivées
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
