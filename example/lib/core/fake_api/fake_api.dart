/// Stands in for your backend, so the example runs without a server.
class FakeApi {
  static const _latency = Duration(milliseconds: 300);

  static const _products = <Map<String, dynamic>>[
    {
      'id': '1',
      'name': 'Coffee mug',
      'price': 12.5,
      'description': 'A 350 ml ceramic mug.',
    },
    {
      'id': '2',
      'name': 'Notebook',
      'price': 4.0,
      'description': 'A5, dotted pages.',
    },
    {
      'id': '3',
      'name': 'Backpack',
      'price': 49.9,
      'description': 'Fits a 15 inch laptop.',
    },
    {
      'id': '42',
      'name': 'Headphones',
      'price': 89.0,
      'description': 'Wireless, with noise cancelling.',
    },
  ];

  Future<List<Map<String, dynamic>>> getProducts() async {
    await Future<void>.delayed(_latency);
    return _products;
  }

  Future<List<Map<String, dynamic>>> getFeaturedProducts() async {
    await Future<void>.delayed(_latency);
    return _products.take(2).toList();
  }

  /// Returns `null` when there is no product with this [id], like a 404.
  Future<Map<String, dynamic>?> getProduct(String id) async {
    await Future<void>.delayed(_latency);
    for (final product in _products) {
      if (product['id'] == id) return product;
    }
    return null;
  }
}
