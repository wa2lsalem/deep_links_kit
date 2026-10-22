import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/product_image.dart';
import '../cubit/product_list_cubit.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final priceStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Theme.of(context).colorScheme.primary,
    );
    return BlocProvider(
      create: (_) => sl<ProductListCubit>()..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Products')),
        body: BlocBuilder<ProductListCubit, ProductListState>(
          builder: (context, state) => switch (state) {
            ProductListLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ProductListError(:final message) => Center(child: Text(message)),
            ProductListLoaded(:final products) => ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: products.length,
              separatorBuilder: (_, _) => const Divider(indent: 88),
              itemBuilder: (context, i) {
                final product = products[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: ProductImage(id: product.id),
                  title: Text(product.name),
                  trailing: Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: priceStyle,
                  ),
                  onTap: () => context.push(AppRoutes.product(product.id)),
                );
              },
            ),
          },
        ),
      ),
    );
  }
}
