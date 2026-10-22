// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:auto_route/auto_route.dart' as _i2;
import 'package:deep_links_kit_example/with_auto_route/screens.dart' as _i1;
import 'package:flutter/material.dart' as _i3;

/// generated route for
/// [_i1.HomeScreen]
class HomeRoute extends _i2.PageRouteInfo<void> {
  const HomeRoute({List<_i2.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i2.PageInfo page = _i2.PageInfo(
    name,
    builder: (data) {
      return const _i1.HomeScreen();
    },
  );
}

/// generated route for
/// [_i1.ProductScreen]
class ProductRoute extends _i2.PageRouteInfo<ProductRouteArgs> {
  ProductRoute({
    _i3.Key? key,
    required String id,
    List<_i2.PageRouteInfo>? children,
  }) : super(
         ProductRoute.name,
         args: ProductRouteArgs(key: key, id: id),
         rawPathParams: {'id': id},
         initialChildren: children,
       );

  static const String name = 'ProductRoute';

  static _i2.PageInfo page = _i2.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<ProductRouteArgs>(
        orElse: () => ProductRouteArgs(id: pathParams.getString('id')),
      );
      return _i1.ProductScreen(key: args.key, id: args.id);
    },
  );
}

class ProductRouteArgs {
  const ProductRouteArgs({this.key, required this.id});

  final _i3.Key? key;

  final String id;

  @override
  String toString() {
    return 'ProductRouteArgs{key: $key, id: $id}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ProductRouteArgs) return false;
    return key == other.key && id == other.id;
  }

  @override
  int get hashCode => key.hashCode ^ id.hashCode;
}

/// generated route for
/// [_i1.SplashScreen]
class SplashRoute extends _i2.PageRouteInfo<void> {
  const SplashRoute({List<_i2.PageRouteInfo>? children})
    : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static _i2.PageInfo page = _i2.PageInfo(
    name,
    builder: (data) {
      return const _i1.SplashScreen();
    },
  );
}

/// generated route for
/// [_i1.UserScreen]
class UserRoute extends _i2.PageRouteInfo<UserRouteArgs> {
  UserRoute({
    _i3.Key? key,
    required String id,
    List<_i2.PageRouteInfo>? children,
  }) : super(
         UserRoute.name,
         args: UserRouteArgs(key: key, id: id),
         rawPathParams: {'id': id},
         initialChildren: children,
       );

  static const String name = 'UserRoute';

  static _i2.PageInfo page = _i2.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<UserRouteArgs>(
        orElse: () => UserRouteArgs(id: pathParams.getString('id')),
      );
      return _i1.UserScreen(key: args.key, id: args.id);
    },
  );
}

class UserRouteArgs {
  const UserRouteArgs({this.key, required this.id});

  final _i3.Key? key;

  final String id;

  @override
  String toString() {
    return 'UserRouteArgs{key: $key, id: $id}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UserRouteArgs) return false;
    return key == other.key && id == other.id;
  }

  @override
  int get hashCode => key.hashCode ^ id.hashCode;
}
