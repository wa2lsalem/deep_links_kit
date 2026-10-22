import '../../../../core/fake_api/fake_api.dart';
import '../models/featured_product_model.dart';

abstract interface class HomeRemoteDataSource {
  /// Throws a `ServerException` when the request fails.
  Future<List<FeaturedProductModel>> getFeaturedProducts();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  const HomeRemoteDataSourceImpl(this._api);

  final FakeApi _api;

  @override
  Future<List<FeaturedProductModel>> getFeaturedProducts() async {
    final json = await _api.getFeaturedProducts();
    return json.map(FeaturedProductModel.fromJson).toList();
  }
}
