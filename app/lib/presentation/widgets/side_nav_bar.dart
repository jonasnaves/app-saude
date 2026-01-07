import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';

class SideNavBar extends StatelessWidget {
  final String currentRoute;

  const SideNavBar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Logo ou ícone principal
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.medical_services,
                color: AppColors.textPrimary,
                size: 24,
              ),
            ),
            const SizedBox(height: 32),
            // Menu items
            Expanded(
              child: Column(
                children: [
                  _SideNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    route: '/dashboard',
                    isActive: currentRoute == '/dashboard',
                    tooltip: 'Início',
                  ),
                  const SizedBox(height: 16),
                  _SideNavItem(
                    icon: Icons.people_outlined,
                    activeIcon: Icons.people,
                    route: '/patients',
                    isActive: currentRoute.startsWith('/patients'),
                    tooltip: 'Pacientes',
                  ),
                  const SizedBox(height: 16),
                  _SideNavItem(
                    icon: Icons.medical_services_outlined,
                    activeIcon: Icons.medical_services,
                    route: '/clinical',
                    isActive: currentRoute.startsWith('/clinical'),
                    tooltip: 'Clínico',
                  ),
                  const SizedBox(height: 16),
                  _SideNavItem(
                    icon: Icons.support_agent_outlined,
                    activeIcon: Icons.support_agent,
                    route: '/support',
                    isActive: currentRoute.startsWith('/support'),
                    tooltip: "IA's",
                  ),
                  const SizedBox(height: 16),
                  _SideNavItem(
                    icon: Icons.business_outlined,
                    activeIcon: Icons.business,
                    route: '/business',
                    isActive: currentRoute.startsWith('/business'),
                    tooltip: 'Business',
                  ),
                ],
              ),
            ),
            // Botão de gravação centralizado
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: _RecordingButton(
                isActive: currentRoute.startsWith('/clinical'),
                onTap: () => context.go('/clinical/recording'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final bool isActive;
  final String tooltip;

  const _SideNavItem({
    required this.icon,
    required this.activeIcon,
    required this.route,
    required this.isActive,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => context.go(route),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isActive ? activeIcon : icon,
            color: isActive ? AppColors.primary : AppColors.textSecondary,
            size: 24,
          ),
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
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.mic,
          color: Colors.white,
          size: 28,
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(
      duration: 1000.ms,
      begin: const Offset(1.0, 1.0),
      end: const Offset(1.05, 1.05),
    );
  }
}
