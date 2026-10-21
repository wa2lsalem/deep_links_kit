import 'package:go_router/go_router.dart';

import 'pages/details_page.dart';
import 'pages/home_page.dart';
import 'pages/splash_page.dart';

abstract final class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
      GoRoute(path: '/', builder: (_, _) => const HomePage()),
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
