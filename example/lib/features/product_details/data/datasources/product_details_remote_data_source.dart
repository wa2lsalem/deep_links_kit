import '../../../../core/error/exceptions.dart';
import '../../../../core/fake_api/fake_api.dart';
import '../models/product_details_model.dart';

abstract interface class ProductDetailsRemoteDataSource {
  /// Throws a `NotFoundException` when there is no such product, and a
  /// `ServerException` when the request fails.
  Future<ProductDetailsModel> getProduct(String id);
}

class ProductDetailsRemoteDataSourceImpl
    implements ProductDetailsRemoteDataSource {
  const ProductDetailsRemoteDataSourceImpl(this._api);

  final FakeApi _api;

  @override
  Future<ProductDetailsModel> getProduct(String id) async {
    final json = await _api.getProduct(id);
    if (json == null) throw const NotFoundException();
    return ProductDetailsModel.fromJson(json);
  }
}
