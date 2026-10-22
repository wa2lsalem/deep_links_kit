import 'package:go_router/go_router.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/product_details/presentation/pages/product_details_page.dart';
import '../../features/product_list/presentation/pages/product_list_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import 'app_routes.dart';

final router = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
    GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage()),
    GoRoute(
      path: AppRoutes.products,
      builder: (_, _) => const ProductListPage(),
    ),
    GoRoute(
      path: AppRoutes.productDetails,
      builder: (_, state) =>
          ProductDetailsPage(id: state.pathParameters['id']!),
    ),
  ],
);
