import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/deep_links/app_deep_links.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/product_image.dart';
import '../cubit/product_details_cubit.dart';

class ProductDetailsPage extends StatelessWidget {
  const ProductDetailsPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider(
      create: (_) => sl<ProductDetailsCubit>()..load(id),
      child: BlocBuilder<ProductDetailsCubit, ProductDetailsState>(
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: Text(switch (state) {
              ProductDetailsLoaded(:final product) => product.name,
              _ => 'Product',
            }),
            actions: [
              if (state is ProductDetailsLoaded)
                IconButton(
                  tooltip: 'Share',
                  icon: const Icon(Icons.share),
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(
                      text: '${state.product.name}: ${productShareLink(id)}',
                    ),
                  ),
                ),
            ],
          ),
          body: switch (state) {
            ProductDetailsLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ProductDetailsError(:final message) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(message, style: theme.textTheme.titleMedium),
                ],
              ),
            ),
            ProductDetailsLoaded(:final product) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(child: ProductImage(id: product.id, size: 200)),
                const SizedBox(height: 24),
                Text(product.name, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(product.description, style: theme.textTheme.bodyLarge),
              ],
            ),
          },
        ),
      ),
    );
  }
}
