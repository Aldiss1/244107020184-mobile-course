import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../pages/announcement_page.dart';
import '../pages/debug_page.dart';
import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../pages/notifications_page.dart';
import '../pages/splash_page.dart';
import '../routes.dart';
import 'auth_provider.dart';

/// Menjembatani perubahan status auth ke GoRouter tanpa membangun ulang router.
class _AuthRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh();
  ref.onDispose(refresh.dispose);

  ref.listen<AsyncValue<bool>>(authStateProvider, (_, _) => refresh.notify());

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final location = state.matchedLocation;

      // Token masih dibaca dari secure storage: tahan di splash supaya
      // pengguna yang sudah login tidak sempat melihat halaman login.
      if (auth.isLoading && !auth.hasValue) {
        return location == Routes.splash ? null : Routes.splash;
      }

      final loggedIn = auth.value ?? false;
      final atSplash = location == Routes.splash;
      final atLogin = location == Routes.login;

      if (atSplash) return loggedIn ? Routes.home : Routes.login;
      if (!loggedIn && !atLogin) return Routes.login;
      if (loggedIn && atLogin) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: Routes.debug,
        builder: (context, state) => const DebugPage(),
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: Routes.announcementPattern,
        name: Routes.announcementName,
        builder: (context, state) =>
            AnnouncementPage(id: state.pathParameters['id'] ?? ''),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
