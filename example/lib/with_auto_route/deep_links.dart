import 'package:deep_links_kit/deep_links_kit.dart';

import 'app_router.dart';

final deepLinks = DeepLinksKit(
  navigator: DeepLinkNavigator.custom(
    push: router.pushPath,
    replace: router.navigatePath,
  ),

  routes: [
    // myapp://products/42 opens /products/42
    DeepLinkRoute('/products/:id', to: (m) => '/products/${m['id']}'),

    // https://app.example.com/u/7 opens /users/7
    DeepLinkRoute('/u/:id', to: (m) => '/users/${m['id']}'),
  ],
  fallback: (_) => '/home', // optional: any other link opens /home
);
