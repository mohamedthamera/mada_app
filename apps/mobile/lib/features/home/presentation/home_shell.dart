import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/adaptive_scaffold.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  static const _routes = ['/home', '/courses', '/progress', '/jobs', '/profile'];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _routes.indexWhere((r) => location.startsWith(r));
    final currentIndex = index == -1 ? 0 : index;

    return AdaptiveScaffold(
      body: child,
      currentIndex: currentIndex,
      showTitle: currentIndex == 0,
      onDestinationSelected: (index) {
        context.go(_routes[index]);
      },
    );
  }
}

