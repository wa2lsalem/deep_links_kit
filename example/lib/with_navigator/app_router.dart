import 'package:flutter/material.dart';

import '../shared/details_page.dart';
import '../shared/home_page.dart';
import 'app_deep_links.dart';
import 'splash_page.dart';

abstract final class AppRouter {
  /// Given to MaterialApp, so deep links can navigate without a context.
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// Turns a name like `/products/42` into a page.
  static Route<void> onGenerateRoute(RouteSettings settings) {
    final segments = Uri.parse(settings.name ?? '/').pathSegments;
    final page = switch (segments) {
      [] => const SplashPage(),
      ['products', final id] => DetailsPage('Product $id'),
      ['users', final id] => DetailsPage('User $id'),
      _ => HomePage(deepLinks: AppDeepLinks.instance),
    };
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
