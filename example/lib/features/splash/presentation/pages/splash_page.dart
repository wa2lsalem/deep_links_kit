import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/deep_links/app_deep_links.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_routes.dart';
import '../cubit/splash_cubit.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SplashCubit>()..start(),
      child: BlocListener<SplashCubit, SplashState>(
        listener: (context, state) {
          if (state is SplashDone) {
            context.go(AppRoutes.home);
            deepLinks.ready(); // links that arrived meanwhile open now
          }
        },
        child: const _SplashView(),
      ),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront, size: 80, color: colors.onPrimary),
            const SizedBox(height: 16),
            Text(
              'Shop',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: colors.onPrimary),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(color: colors.onPrimary),
          ],
        ),
      ),
    );
  }
}
