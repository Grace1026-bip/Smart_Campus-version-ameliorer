import 'package:flutter/material.dart';

import '../../data/models/faculty_models.dart';
import '../../data/services/session_service.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/admin_management_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/complaints/presentation/complaint_detail_screen.dart';
import '../../features/complaints/presentation/complaints_screen.dart';
import '../../features/dean/presentation/dean_dashboard_screen.dart';
import '../../features/grades/presentation/grades_screen.dart';
import '../../features/internships/presentation/internships_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/projects/presentation/projects_screen.dart';
import '../../features/promotion_chief/presentation/promotion_chief_dashboard_screen.dart';
import '../../features/risk_students/presentation/risk_students_screen.dart';
import '../../features/student/presentation/student_dashboard_screen.dart';
import '../../features/teacher/presentation/teacher_dashboard_screen.dart';

class AppRoutes {
  static const login = '/';
  static const forgotPassword = '/forgot-password';
  static const adminDashboard = '/admin';
  static const adminManagement = '/admin/management';
  static const studentDashboard = '/student';
  static const teacherDashboard = '/teacher';
  static const promotionChiefDashboard = '/promotion-chief';
  static const deanDashboard = '/dean';
  static const complaints = '/complaints';
  static const complaintDetail = '/complaints/detail';
  static const analytics = '/analytics';
  static const projects = '/projects';
  static const internships = '/internships';
  static const grades = '/grades';
  static const riskStudents = '/risk-students';
  static const notifications = '/notifications';
  static const profile = '/profile';

  static String dashboardForRole(UserRole role) {
    switch (role) {
      case UserRole.administrator:
        return adminDashboard;
      case UserRole.student:
        return studentDashboard;
      case UserRole.teacher:
        return teacherDashboard;
      case UserRole.promotionChief:
        return promotionChiefDashboard;
      case UserRole.dean:
        return deanDashboard;
    }
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final requestedRoute = settings.name ?? login;
    if (!_isPublicRoute(requestedRoute) &&
        !_isRouteAllowed(SessionService.currentRole, requestedRoute)) {
      final fallbackRoute = dashboardForRole(SessionService.currentRole);
      return _route(
        RouteSettings(name: fallbackRoute),
        _dashboardScreenForRole(SessionService.currentRole),
      );
    }

    switch (settings.name) {
      case login:
        return _route(settings, const LoginScreen());
      case forgotPassword:
        return _route(settings, const ForgotPasswordScreen());
      case adminDashboard:
        return _route(settings, const AdminDashboardScreen());
      case adminManagement:
        final args = settings.arguments;
        final category =
            args is AdminManagementArgs ? args.category : 'Etudiants';
        return _route(settings, AdminManagementScreen(category: category));
      case studentDashboard:
        return _route(settings, const StudentDashboardScreen());
      case teacherDashboard:
        return _route(settings, const TeacherDashboardScreen());
      case promotionChiefDashboard:
        return _route(settings, const PromotionChiefDashboardScreen());
      case deanDashboard:
        return _route(settings, const DeanDashboardScreen());
      case complaints:
        return _route(settings, const ComplaintsScreen());
      case complaintDetail:
        final args = settings.arguments;
        return _route(
          settings,
          ComplaintDetailScreen(complaint: args is Complaint ? args : null),
        );
      case analytics:
        return _route(settings, const AnalyticsScreen());
      case projects:
        return _route(settings, const ProjectsScreen());
      case internships:
        return _route(settings, const InternshipsScreen());
      case grades:
        return _route(settings, const GradesScreen());
      case riskStudents:
        return _route(settings, const RiskStudentsScreen());
      case notifications:
        return _route(settings, const NotificationsScreen());
      case profile:
        return _route(settings, const ProfileScreen());
      default:
        return _route(settings, const LoginScreen());
    }
  }

  static MaterialPageRoute<dynamic> _route(
    RouteSettings settings,
    Widget page,
  ) {
    return MaterialPageRoute<dynamic>(settings: settings, builder: (_) => page);
  }

  static bool _isPublicRoute(String route) {
    return route == login || route == forgotPassword;
  }

  static bool _isRouteAllowed(UserRole role, String route) {
    final normalizedRoute = route == complaintDetail ? complaints : route;

    if ({notifications, profile}.contains(normalizedRoute)) return true;

    switch (role) {
      case UserRole.administrator:
        return const {
          adminDashboard,
          adminManagement,
          complaints,
          analytics,
          projects,
          internships,
          grades,
          riskStudents,
        }.contains(normalizedRoute);
      case UserRole.student:
        return const {
          studentDashboard,
          complaints,
          analytics,
          projects,
          internships,
          grades,
        }.contains(normalizedRoute);
      case UserRole.teacher:
        return const {
          teacherDashboard,
          complaints,
          analytics,
          projects,
          internships,
          grades,
          riskStudents,
        }.contains(normalizedRoute);
      case UserRole.promotionChief:
        return const {
          promotionChiefDashboard,
          complaints,
          analytics,
          projects,
          internships,
          grades,
          riskStudents,
        }.contains(normalizedRoute);
      case UserRole.dean:
        return const {
          deanDashboard,
          analytics,
          complaints,
          projects,
          internships,
          grades,
          riskStudents,
        }.contains(normalizedRoute);
    }
  }

  static Widget _dashboardScreenForRole(UserRole role) {
    switch (role) {
      case UserRole.administrator:
        return const AdminDashboardScreen();
      case UserRole.student:
        return const StudentDashboardScreen();
      case UserRole.teacher:
        return const TeacherDashboardScreen();
      case UserRole.promotionChief:
        return const PromotionChiefDashboardScreen();
      case UserRole.dean:
        return const DeanDashboardScreen();
    }
  }
}
