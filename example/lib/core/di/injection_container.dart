import 'package:get_it/get_it.dart';

import '../../features/home/data/datasources/home_remote_data_source.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_featured_products.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/product_details/data/datasources/product_details_remote_data_source.dart';
import '../../features/product_details/data/repositories/product_details_repository_impl.dart';
import '../../features/product_details/domain/repositories/product_details_repository.dart';
import '../../features/product_details/domain/usecases/get_product_details.dart';
import '../../features/product_details/presentation/cubit/product_details_cubit.dart';
import '../../features/product_list/data/datasources/product_list_remote_data_source.dart';
import '../../features/product_list/data/repositories/product_list_repository_impl.dart';
import '../../features/product_list/domain/repositories/product_list_repository.dart';
import '../../features/product_list/domain/usecases/get_products.dart';
import '../../features/product_list/presentation/cubit/product_list_cubit.dart';
import '../../features/splash/data/datasources/session_local_data_source.dart';
import '../../features/splash/data/repositories/session_repository_impl.dart';
import '../../features/splash/domain/repositories/session_repository.dart';
import '../../features/splash/domain/usecases/load_session.dart';
import '../../features/splash/presentation/cubit/splash_cubit.dart';
import '../fake_api/fake_api.dart';

final sl = GetIt.instance;

void initDependencies() {
  // Core
  sl.registerLazySingleton(FakeApi.new);

  // Splash
  sl
    ..registerFactory(() => SplashCubit(sl()))
    ..registerLazySingleton(() => LoadSession(sl()))
    ..registerLazySingleton<SessionRepository>(
      () => SessionRepositoryImpl(sl()),
    )
    ..registerLazySingleton<SessionLocalDataSource>(
      SessionLocalDataSourceImpl.new,
    );

  // Home
  sl
    ..registerFactory(() => HomeCubit(sl()))
    ..registerLazySingleton(() => GetFeaturedProducts(sl()))
    ..registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl(sl()))
    ..registerLazySingleton<HomeRemoteDataSource>(
      () => HomeRemoteDataSourceImpl(sl()),
    );

  // Product list
  sl
    ..registerFactory(() => ProductListCubit(sl()))
    ..registerLazySingleton(() => GetProducts(sl()))
    ..registerLazySingleton<ProductListRepository>(
      () => ProductListRepositoryImpl(sl()),
    )
    ..registerLazySingleton<ProductListRemoteDataSource>(
      () => ProductListRemoteDataSourceImpl(sl()),
    );

  // Product details
  sl
    ..registerFactory(() => ProductDetailsCubit(sl()))
    ..registerLazySingleton(() => GetProductDetails(sl()))
    ..registerLazySingleton<ProductDetailsRepository>(
      () => ProductDetailsRepositoryImpl(sl()),
    )
    ..registerLazySingleton<ProductDetailsRemoteDataSource>(
      () => ProductDetailsRemoteDataSourceImpl(sl()),
    );
}
