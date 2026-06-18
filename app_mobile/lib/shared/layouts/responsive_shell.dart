import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/faculty_models.dart';
import '../../data/services/session_service.dart';
import '../widgets/app_logo.dart';

class SmartNavItem {
  const SmartNavItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class SmartFacultyShell extends StatelessWidget {
  const SmartFacultyShell({
    super.key,
    required this.role,
    required this.selectedRoute,
    required this.title,
    required this.subtitle,
    required this.body,
    this.actions = const [],
  });

  final UserRole role;
  final String selectedRoute;
  final String title;
  final String subtitle;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final items = _itemsForRole(role);
    final useSidebar = !Responsive.isMobile(context);

    if (useSidebar) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(role: role, items: items, selectedRoute: selectedRoute),
            Expanded(
              child: _PageFrame(
                title: title,
                subtitle: subtitle,
                actions: actions,
                child: body,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const SizedBox.shrink(),
        leadingWidth: 0,
        titleSpacing: 16,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: actions,
      ),
      body: _MobilePageFrame(child: body),
      bottomNavigationBar: _BottomNav(
        items: items.take(5).toList(),
        selectedRoute: selectedRoute,
      ),
    );
  }

  static List<SmartNavItem> _itemsForRole(UserRole role) {
    switch (role) {
      case UserRole.administrator:
        return const [
          SmartNavItem(
            label: 'Dashboard',
            icon: Icons.dashboard_rounded,
            route: AppRoutes.adminDashboard,
          ),
          SmartNavItem(
            label: 'Réclamations',
            icon: Icons.mark_email_unread_rounded,
            route: AppRoutes.complaints,
          ),
          SmartNavItem(
            label: 'Projets',
            icon: Icons.workspaces_rounded,
            route: AppRoutes.projects,
          ),
          SmartNavItem(
            label: 'Stages',
            icon: Icons.business_center_rounded,
            route: AppRoutes.internships,
          ),
          SmartNavItem(
            label: 'Notes',
            icon: Icons.fact_check_rounded,
            route: AppRoutes.grades,
          ),
          SmartNavItem(
            label: 'Analytics',
            icon: Icons.insights_rounded,
            route: AppRoutes.analytics,
          ),
          SmartNavItem(
            label: 'Risque',
            icon: Icons.health_and_safety_rounded,
            route: AppRoutes.riskStudents,
          ),
        ];
      case UserRole.student:
        return const [
          SmartNavItem(
            label: 'Accueil',
            icon: Icons.home_rounded,
            route: AppRoutes.studentDashboard,
          ),
          SmartNavItem(
            label: 'Notes',
            icon: Icons.fact_check_rounded,
            route: AppRoutes.grades,
          ),
          SmartNavItem(
            label: 'Projets',
            icon: Icons.workspaces_rounded,
            route: AppRoutes.projects,
          ),
          SmartNavItem(
            label: 'Stages',
            icon: Icons.business_center_rounded,
            route: AppRoutes.internships,
          ),
          SmartNavItem(
            label: 'Réclamations',
            icon: Icons.mark_email_unread_rounded,
            route: AppRoutes.complaints,
          ),
        ];
      case UserRole.teacher:
        return const [
          SmartNavItem(
            label: 'Accueil',
            icon: Icons.home_rounded,
            route: AppRoutes.teacherDashboard,
          ),
          SmartNavItem(
            label: 'Notes',
            icon: Icons.fact_check_rounded,
            route: AppRoutes.grades,
          ),
          SmartNavItem(
            label: 'Projets',
            icon: Icons.workspaces_rounded,
            route: AppRoutes.projects,
          ),
          SmartNavItem(
            label: 'Réclamations',
            icon: Icons.mark_email_unread_rounded,
            route: AppRoutes.complaints,
          ),
          SmartNavItem(
            label: 'Analytics',
            icon: Icons.insights_rounded,
            route: AppRoutes.analytics,
          ),
        ];
      case UserRole.promotionChief:
        return const [
          SmartNavItem(
            label: 'Accueil',
            icon: Icons.home_rounded,
            route: AppRoutes.promotionChiefDashboard,
          ),
          SmartNavItem(
            label: 'Risque',
            icon: Icons.health_and_safety_rounded,
            route: AppRoutes.riskStudents,
          ),
          SmartNavItem(
            label: 'Réclamations',
            icon: Icons.mark_email_unread_rounded,
            route: AppRoutes.complaints,
          ),
          SmartNavItem(
            label: 'Notes',
            icon: Icons.fact_check_rounded,
            route: AppRoutes.grades,
          ),
          SmartNavItem(
            label: 'Analytics',
            icon: Icons.insights_rounded,
            route: AppRoutes.analytics,
          ),
        ];
      case UserRole.dean:
        return const [
          SmartNavItem(
            label: 'Décisionnel',
            icon: Icons.dashboard_rounded,
            route: AppRoutes.deanDashboard,
          ),
          SmartNavItem(
            label: 'Analytics',
            icon: Icons.insights_rounded,
            route: AppRoutes.analytics,
          ),
          SmartNavItem(
            label: 'Risque',
            icon: Icons.health_and_safety_rounded,
            route: AppRoutes.riskStudents,
          ),
          SmartNavItem(
            label: 'Réclamations',
            icon: Icons.mark_email_unread_rounded,
            route: AppRoutes.complaints,
          ),
          SmartNavItem(
            label: 'Notes',
            icon: Icons.fact_check_rounded,
            route: AppRoutes.grades,
          ),
        ];
    }
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.role,
    required this.items,
    required this.selectedRoute,
  });

  final UserRole role;
  final List<SmartNavItem> items;
  final String selectedRoute;

  @override
  Widget build(BuildContext context) {
    final user = SessionService.currentUser;

    return Container(
      width: 284,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppLogo(),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        user.avatarText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            role.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final selected = _matchesRoute(item.route, selectedRoute);
                    return _NavButton(
                      item: item,
                      selected: selected,
                      onTap: () => _goTo(context, item.route),
                    );
                  },
                ),
              ),
              const Divider(),
              _NavButton(
                item: const SmartNavItem(
                  label: 'Déconnexion',
                  icon: Icons.logout_rounded,
                  route: AppRoutes.login,
                ),
                selected: false,
                onTap: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final SmartNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                size: 21,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.child,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 18),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Wrap(spacing: 8, children: actions),
                ],
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobilePageFrame extends StatelessWidget {
  const _MobilePageFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.items, required this.selectedRoute});

  final List<SmartNavItem> items;
  final String selectedRoute;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(items, selectedRoute);

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => _goTo(context, items[index].route),
      destinations: [
        for (final item in items)
          NavigationDestination(
            icon: Icon(item.icon),
            label: _mobileLabel(item.label),
          ),
      ],
    );
  }
}

int _selectedIndex(List<SmartNavItem> items, String selectedRoute) {
  final index = items.indexWhere(
    (item) => _matchesRoute(item.route, selectedRoute),
  );
  return index < 0 ? 0 : index;
}

bool _matchesRoute(String itemRoute, String selectedRoute) {
  if (itemRoute == selectedRoute) return true;
  if (selectedRoute == AppRoutes.complaintDetail &&
      itemRoute == AppRoutes.complaints) {
    return true;
  }
  return false;
}

void _goTo(BuildContext context, String route) {
  final current = ModalRoute.of(context)?.settings.name;
  if (current == route) return;
  Navigator.of(context).pushReplacementNamed(route);
}

String _mobileLabel(String label) {
  switch (label) {
    case 'Réclamations':
      return 'Réclam.';
    case 'Décisionnel':
      return 'Doyen';
    case 'Dashboard':
      return 'Accueil';
    default:
      return label;
  }
}
