import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simulasi offline yang deterministik untuk demo dan testing,
/// sehingga tidak bergantung pada kondisi Wi-Fi kelas.
final forceOfflineProvider =
    NotifierProvider<ForceOfflineNotifier, bool>(ForceOfflineNotifier.new);

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}
