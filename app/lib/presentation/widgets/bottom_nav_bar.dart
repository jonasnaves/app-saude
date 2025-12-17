import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';

class BottomNavBar extends StatelessWidget {
  final String currentRoute;

  const BottomNavBar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.deepNavy.withOpacity(0.8),
        border: const Border(
          top: BorderSide(color: AppColors.slate700, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home,
                label: 'Início',
                route: '/dashboard',
                isActive: currentRoute == '/dashboard',
              ),
              _NavItem(
                icon: Icons.medical_services,
                label: 'Clínico',
                route: '/clinical',
                isActive: currentRoute.startsWith('/clinical'),
              ),
              const SizedBox(width: 64), // Space for FAB
              _NavItem(
                icon: Icons.support_agent,
                label: 'Suporte',
                route: '/support',
                isActive: currentRoute.startsWith('/support'),
              ),
              _NavItem(
                icon: Icons.business,
                label: 'Business',
                route: '/business',
                isActive: currentRoute.startsWith('/business'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isActive;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.electricBlue : AppColors.slateLight,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive ? AppColors.electricBlue : AppColors.slateLight,
            ),
          ),
        ],
      ),
    );
  }
}

