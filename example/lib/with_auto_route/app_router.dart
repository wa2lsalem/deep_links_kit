import 'package:auto_route/auto_route.dart';

import 'app_router.gr.dart';

/// One router for the whole app, so deep links can navigate with it.
final router = AppRouter();

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, path: '/', initial: true),
    AutoRoute(page: HomeRoute.page, path: '/home'),
    AutoRoute(page: ProductRoute.page, path: '/products/:id'),
    AutoRoute(page: UserRoute.page, path: '/users/:id'),
  ];
}
