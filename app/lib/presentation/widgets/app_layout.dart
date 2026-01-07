import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import 'bottom_nav_bar.dart';
import 'side_nav_bar.dart';

class AppLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const AppLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    if (isDesktop) {
      // Layout para desktop: menu lateral
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            SideNavBar(currentRoute: currentRoute),
            Expanded(
              child: child,
            ),
          ],
        ),
      );
    } else {
      // Layout para mobile/tablet: menu inferior
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Expanded(
              child: child,
            ),
            BottomNavBar(currentRoute: currentRoute),
          ],
        ),
      );
    }
  }
}


