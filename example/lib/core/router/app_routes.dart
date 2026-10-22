/// Every page path in the app. Deep links open these paths.
abstract final class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const products = '/products';
  static const productDetails = '/products/:id';

  static String product(String id) => '/products/$id';
}
