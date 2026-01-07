import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import 'modern/glass_container.dart';

class BottomNavBar extends StatelessWidget {
  final String currentRoute;

  const BottomNavBar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(32),
      blur: 15,
      opacity: 0.8,
      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Início',
                  route: '/dashboard',
                  isActive: currentRoute == '/dashboard',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NavItem(
                  icon: Icons.people_outlined,
                  activeIcon: Icons.people,
                  label: 'Pacientes',
                  route: '/patients',
                  isActive: currentRoute.startsWith('/patients'),
                ),
              ),
              // Botão central destacado (círculo verde) - na mesma linha
              _RecordingButton(
                isActive: currentRoute.startsWith('/clinical'),
                onTap: () => context.go('/clinical/recording'),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.support_agent_outlined,
                  activeIcon: Icons.support_agent,
                  label: "IA's",
                  route: '/support',
                  isActive: currentRoute.startsWith('/support'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NavItem(
                  icon: Icons.business_outlined,
                  activeIcon: Icons.business,
                  label: 'Business',
                  route: '/business',
                  isActive: currentRoute.startsWith('/business'),
                ),
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
  final IconData activeIcon;
  final String label;
  final String route;
  final bool isActive;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(route),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ).animate(target: isActive ? 1 : 0).scale(
        duration: 200.ms,
        begin: const Offset(0.9, 0.9),
      ),
    );
  }
}

class _RecordingButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _RecordingButton({
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.mic,
          color: Colors.white,
          size: 24,
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(
      duration: 1500.ms,
      begin: const Offset(1.0, 1.0),
      end: const Offset(1.05, 1.05),
    );
  }
}
