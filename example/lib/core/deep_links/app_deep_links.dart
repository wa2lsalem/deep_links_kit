import 'package:deep_links_kit/deep_links_kit.dart';

import '../router/app_router.dart';
import '../router/app_routes.dart';

/// The website domain, the same as `hosts` in `pubspec.yaml`. Shared links
/// use it, so tapping one in WhatsApp opens the app.
const appLinksHost = 'app.example.com';

/// The link to share for a product, e.g. https://app.example.com/products/42.
Uri productShareLink(String id) =>
    Uri.https(appLinksHost, AppRoutes.product(id));

/// All the deep link code of the app.
final deepLinks = DeepLinksKit(
  navigator: DeepLinkNavigator.custom(push: router.push, replace: router.go),
  routes: [
    // myapp://products opens the product list
    DeepLinkRoute('/products', to: (_) => AppRoutes.products),

    // myapp://products/42 opens product 42
    DeepLinkRoute('/products/:id', to: (m) => AppRoutes.product(m['id']!)),

    // https://app.example.com/p/42, a short link, also opens product 42
    DeepLinkRoute('/p/:id', to: (m) => AppRoutes.product(m['id']!)),
  ],
  fallback: (_) => AppRoutes.home, // optional: any other link opens home
);
