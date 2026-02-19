import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import '../constants/app_breakpoints.dart';

class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.showTitle = false,
  });

  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool showTitle;

  Widget _buildTopBar(BuildContext context) {
    if (!showTitle) return const SizedBox.shrink();

    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            bottom: BorderSide(color: AppColors.border.withValues(alpha:0.5), width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Everest',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= AppBreakpoints.tablet;
        if (isTablet) {
          return Row(
            children: [
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: NavigationRail(
                  selectedIndex: currentIndex,
                  onDestinationSelected: onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: Text('الرئيسية'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.menu_book_outlined),
                    selectedIcon: Icon(Icons.menu_book),
                    label: Text('الدورات'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.auto_graph_outlined),
                    selectedIcon: Icon(Icons.auto_graph),
                    label: Text('التقدم'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.work_outline),
                    selectedIcon: Icon(Icons.work),
                    label: Text('الوظائف'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: Text('الملف'),
                  ),
                ],
                ),
              ),
              const VerticalDivider(width: 1, color: AppColors.border),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopBar(context),
                    Expanded(child: body),
                  ],
                ),
              ),
            ],
          );
        }
        return Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(context),
              Expanded(child: body),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'الرئيسية'),
              NavigationDestination(
                icon: Icon(Icons.menu_book),
                label: 'الدورات',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_graph),
                label: 'التقدم',
              ),
              NavigationDestination(
                icon: Icon(Icons.work_outline),
                label: 'الوظائف',
              ),
              NavigationDestination(icon: Icon(Icons.person), label: 'الملف'),
            ],
            ),
          ),
        );
      },
    );
  }
}

