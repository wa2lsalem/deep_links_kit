import 'package:go_router/go_router.dart';

import '../shared/details_page.dart';
import '../shared/home_page.dart';
import 'app_deep_links.dart';
import 'splash_page.dart';

abstract final class AppRouter {
  static final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashPage()),
      GoRoute(
        path: '/home',
        builder: (_, _) => HomePage(deepLinks: AppDeepLinks.instance),
      ),
      GoRoute(
        path: '/products/:id',
        builder: (_, state) =>
            DetailsPage('Product ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/users/:id',
        builder: (_, state) =>
            DetailsPage('User ${state.pathParameters['id']}'),
      ),
    ],
  );
}
