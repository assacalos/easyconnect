import 'package:get_storage/get_storage.dart';

class HostController {
  static final HostController _instance = HostController._();
  static HostController get to => _instance;
  factory HostController() => _instance;
  HostController._();

  int currentIndex = 0;
}
