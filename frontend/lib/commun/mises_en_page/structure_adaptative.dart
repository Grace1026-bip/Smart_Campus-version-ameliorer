import 'package:flutter/material.dart';

import '../../coeur/routes/routes_application.dart';
import '../../coeur/theme/couleurs_application.dart';
import '../../coeur/utilitaires/adaptatif.dart';
import '../../donnees/modeles/modeles_faculte.dart';
import '../../donnees/services/service_session.dart';
import '../composants/logo_application.dart';

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
                role: role,
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
        titleSpacing: 16,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: _topActions(context, actions, role),
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
            label: 'Reclamations',
            icon: Icons.mark_email_unread_rounded,
            route: AppRoutes.complaints,
          ),
          SmartNavItem(
            label: 'Notes',
            icon: Icons.fact_check_rounded,
            route: AppRoutes.grades,
          ),
          SmartNavItem(
            label: 'Notifications',
            icon: Icons.notifications_rounded,
            route: AppRoutes.notifications,
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
            label: 'Profil',
            icon: Icons.person_rounded,
            route: AppRoutes.profile,
          ),
        ];
      case UserRole.apparitor:
        return const [
          SmartNavItem(
            label: 'Accueil',
            icon: Icons.dashboard_rounded,
            route: AppRoutes.apparitorDashboard,
          ),
          SmartNavItem(
            label: 'Etudiants',
            icon: Icons.groups_rounded,
            route: AppRoutes.apparitorStudents,
          ),
          SmartNavItem(
            label: 'Enseignants',
            icon: Icons.school_rounded,
            route: AppRoutes.apparitorTeachers,
          ),
          SmartNavItem(
            label: 'Promotions',
            icon: Icons.account_tree_rounded,
            route: AppRoutes.apparitorPromotions,
          ),
          SmartNavItem(
            label: 'Cours',
            icon: Icons.menu_book_rounded,
            route: AppRoutes.apparitorCourses,
          ),
          SmartNavItem(
            label: 'Reclamations',
            icon: Icons.mark_email_unread_rounded,
            route: AppRoutes.apparitorComplaints,
          ),
          SmartNavItem(
            label: 'A risque',
            icon: Icons.health_and_safety_rounded,
            route: AppRoutes.apparitorRisks,
          ),
          SmartNavItem(
            label: 'Projets',
            icon: Icons.workspaces_rounded,
            route: AppRoutes.apparitorProjects,
          ),
          SmartNavItem(
            label: 'Stages',
            icon: Icons.business_center_rounded,
            route: AppRoutes.apparitorInternships,
          ),
          SmartNavItem(
            label: 'Assistant',
            icon: Icons.auto_awesome_rounded,
            route: AppRoutes.apparitorAssistant,
          ),
          SmartNavItem(
            label: 'Rapports',
            icon: Icons.insights_rounded,
            route: AppRoutes.apparitorReports,
          ),
          SmartNavItem(
            label: 'Profil',
            icon: Icons.person_rounded,
            route: AppRoutes.profile,
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
            label: 'Mes cours',
            icon: Icons.menu_book_rounded,
            route: AppRoutes.studentCourses,
          ),
          SmartNavItem(
            label: 'Valve',
            icon: Icons.campaign_rounded,
            route: AppRoutes.studentValve,
          ),
          SmartNavItem(
            label: 'Notes',
            icon: Icons.fact_check_rounded,
            route: AppRoutes.grades,
          ),
          SmartNavItem(
            label: 'Alertes',
            icon: Icons.warning_amber_rounded,
            route: AppRoutes.studentAlerts,
          ),
          SmartNavItem(
            label: 'Reclamations',
            icon: Icons.mark_email_unread_rounded,
            route: AppRoutes.complaints,
          ),
          SmartNavItem(
            label: 'Profil',
            icon: Icons.person_rounded,
            route: AppRoutes.profile,
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
            label: 'Mes cours',
            icon: Icons.menu_book_rounded,
            route: AppRoutes.teacherCourses,
          ),
          SmartNavItem(
            label: 'Valve',
            icon: Icons.campaign_rounded,
            route: AppRoutes.notifications,
          ),
          SmartNavItem(
            label: 'Notes',
            icon: Icons.fact_check_rounded,
            route: AppRoutes.grades,
          ),
          SmartNavItem(
            label: 'Reclamations',
            icon: Icons.mark_email_unread_rounded,
            route: AppRoutes.complaints,
          ),
          SmartNavItem(
            label: 'A risque',
            icon: Icons.health_and_safety_rounded,
            route: AppRoutes.riskStudents,
          ),
          SmartNavItem(
            label: 'Profil',
            icon: Icons.person_rounded,
            route: AppRoutes.profile,
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
            label: 'Reclamations',
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
            label: 'Profil',
            icon: Icons.person_rounded,
            route: AppRoutes.profile,
          ),
        ];
      case UserRole.dean:
        return const [
          SmartNavItem(
            label: 'Decisionnel',
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
            label: 'Reclamations',
            icon: Icons.mark_email_unread_rounded,
            route: AppRoutes.complaints,
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
            label: 'Profil',
            icon: Icons.person_rounded,
            route: AppRoutes.profile,
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
      width: 292,
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppLogo(onDark: true),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        user.avatarText,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
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
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            role.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.sidebarMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  _sidebarNote(role),
                  style: const TextStyle(
                    color: AppColors.sidebarMuted,
                    height: 1.35,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _NavButton(
                item: const SmartNavItem(
                  label: 'Deconnexion',
                  icon: Icons.logout_rounded,
                  route: AppRoutes.login,
                ),
                selected: false,
                onTap: () async {
                  await SessionService.clear();
                  if (!context.mounted) return;
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
                },
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
      color: selected ? Colors.white : Colors.transparent,
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
                color: selected ? AppColors.primaryDark : AppColors.sidebarText,
                size: 21,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? AppColors.primaryDark
                        : AppColors.sidebarText,
                    fontWeight: FontWeight.w900,
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
    required this.role,
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.child,
  });

  final UserRole role;
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
              color: AppColors.background,
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
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: _topActions(context, actions, role),
                ),
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

List<Widget> _topActions(
  BuildContext context,
  List<Widget> actions,
  UserRole role,
) {
  final teacher = role == UserRole.teacher;
  final student = role == UserRole.student;
  final apparitor = role == UserRole.apparitor;

  return [
    ...actions,
    IconButton(
      tooltip: teacher
          ? 'Valve'
          : apparitor
              ? 'Assistant'
              : 'Notifications',
      onPressed: () => _goTo(
        context,
        student
            ? AppRoutes.notifications
            : apparitor
                ? AppRoutes.apparitorAssistant
                : AppRoutes.notifications,
      ),
      icon: Icon(
        teacher
            ? Icons.campaign_rounded
            : apparitor
                ? Icons.auto_awesome_rounded
                : Icons.notifications_rounded,
      ),
    ),
    IconButton(
      tooltip: 'Profil',
      onPressed: () => _goTo(context, AppRoutes.profile),
      icon: const Icon(Icons.account_circle_rounded),
    ),
  ];
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
  if (selectedRoute == AppRoutes.studentCourseDetail &&
      itemRoute == AppRoutes.studentCourses) {
    return true;
  }
  if (selectedRoute == AppRoutes.studentValveCourse &&
      itemRoute == AppRoutes.studentValve) {
    return true;
  }
  if (selectedRoute == AppRoutes.apparitorPromotionDetail &&
      itemRoute == AppRoutes.apparitorPromotions) {
    return true;
  }
  if (selectedRoute == AppRoutes.apparitorCourseDetail &&
      itemRoute == AppRoutes.apparitorCourses) {
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
    case 'Reclamations':
      return 'Reclam.';
    case 'Mes cours':
      return 'Cours';
    case 'Decisionnel':
      return 'Doyen';
    case 'Dashboard':
      return 'Accueil';
    case 'Promotions':
      return 'Promo.';
    case 'Enseignants':
      return 'Ens.';
    default:
      return label;
  }
}

String _sidebarNote(UserRole role) {
  if (role == UserRole.teacher) {
    return 'Espace enseignant centre sur vos cours, la valve, les notes et les reclamations.';
  }

  if (role == UserRole.student) {
    return 'Vos donnees academiques proviennent des publications et notes officielles.';
  }

  if (role == UserRole.apparitor) {
    return 'Supervision academique : etudiants, enseignants, promotions, cours, reclamations et risques.';
  }

  return 'Espace academique connecte a l API REST FastAPI et aux donnees MySQL.';
}
