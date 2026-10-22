import '../../../../core/fake_api/fake_api.dart';
import '../models/product_model.dart';

abstract interface class ProductListRemoteDataSource {
  /// Throws a `ServerException` when the request fails.
  Future<List<ProductModel>> getProducts();
}

class ProductListRemoteDataSourceImpl implements ProductListRemoteDataSource {
  const ProductListRemoteDataSourceImpl(this._api);

  final FakeApi _api;

  @override
  Future<List<ProductModel>> getProducts() async {
    final json = await _api.getProducts();
    return json.map(ProductModel.fromJson).toList();
  }
}
