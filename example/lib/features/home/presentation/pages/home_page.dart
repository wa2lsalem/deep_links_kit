import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/product_image.dart';
import '../cubit/home_cubit.dart';
import '../widgets/deep_link_samples.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return BlocProvider(
      create: (_) => sl<HomeCubit>()..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Shop')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Featured', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) => switch (state) {
                  HomeLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  HomeError(:final message) => Center(child: Text(message)),
                  HomeLoaded(:final featured) => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: featured.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, i) => _FeaturedCard(
                      id: featured[i].id,
                      name: featured[i].name,
                    ),
                  ),
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => context.push(AppRoutes.products),
              icon: const Icon(Icons.grid_view),
              label: const Text('See all products'),
            ),
            const SizedBox(height: 24),
            Text('Try a deep link', style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Each one opens as if you tapped it in another app.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            const Card(child: DeepLinkSamples()),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.id, required this.name});

  final String id;
  final String name;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(AppRoutes.product(id)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductImage(id: id, size: 64),
                const Spacer(),
                Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
