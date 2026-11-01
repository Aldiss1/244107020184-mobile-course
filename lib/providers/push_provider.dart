import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../messaging/push_service.dart';

/// Status boot Firebase, di-override dari `main()` setelah `initializeApp()`.
class FirebaseBoot {
  const FirebaseBoot({required this.ready, this.error});

  final bool ready;
  final String? error;
}

/// Default: belum siap. `main()` meng-override dengan hasil sebenarnya.
final firebaseBootProvider = Provider<FirebaseBoot>(
  (ref) => const FirebaseBoot(ready: false),
);

final pushServiceProvider = Provider<PushService>((ref) {
  final service = PushService();
  ref.onDispose(service.dispose);
  return service;
});
