import 'package:easyconnect/Controllers/host_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BottomBarItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  BottomBarItem({required this.icon, required this.label, this.onTap});
}

class BottomBarWidget extends StatelessWidget {
  final List<BottomBarItem> items;
  final HostController hostController = Get.find();

  BottomBarWidget({required this.items, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => BottomNavigationBar(
        currentIndex: hostController.currentIndex.value,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueGrey.shade800,
        unselectedItemColor: Colors.grey,
        items:
            items
                .map(
                  (item) => BottomNavigationBarItem(
                    icon: Icon(item.icon),
                    label: item.label,
                  ),
                )
                .toList(),
        onTap: (index) {
          hostController.currentIndex.value = index;
          if (items[index].onTap != null) {
            items[index].onTap!();
          }
        },
      ),
    );
  }
}
