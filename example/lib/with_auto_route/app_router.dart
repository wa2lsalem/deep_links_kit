import 'package:auto_route/auto_route.dart';

import 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  /// One router for the whole app, so deep links can navigate with it.
  static final instance = AppRouter();

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, path: '/', initial: true),
    AutoRoute(page: HomeRoute.page, path: '/home'),
    AutoRoute(page: ProductRoute.page, path: '/products/:id'),
    AutoRoute(page: UserRoute.page, path: '/users/:id'),
  ];
}
