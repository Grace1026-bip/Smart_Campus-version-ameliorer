import 'package:flutter/material.dart';

import '../../donnees/modeles/modeles_faculte.dart';
import '../../donnees/services/service_session.dart';
import '../../fonctionnalites/administration/presentation/ecran_tableau_bord_administration.dart';
import '../../fonctionnalites/administration/presentation/ecran_gestion_administration.dart';
import '../../fonctionnalites/analyses/presentation/ecran_analyses.dart';
import '../../fonctionnalites/apparitorat/presentation/ecran_assistant_appariteur.dart';
import '../../fonctionnalites/apparitorat/presentation/ecran_supervision_appariteur.dart';
import '../../fonctionnalites/apparitorat/presentation/ecran_tableau_bord_apparitorat.dart';
import '../../fonctionnalites/authentification/presentation/ecran_mot_de_passe_oublie.dart';
import '../../fonctionnalites/authentification/presentation/ecran_connexion.dart';
import '../../fonctionnalites/authentification/presentation/ecran_demande_inscription.dart';
import '../../fonctionnalites/reclamations/presentation/ecran_detail_reclamation.dart';
import '../../fonctionnalites/reclamations/presentation/ecran_reclamations.dart';
import '../../fonctionnalites/doyen/presentation/ecran_tableau_bord_doyen.dart';
import '../../fonctionnalites/notes/presentation/ecran_notes.dart';
import '../../fonctionnalites/stages/presentation/ecran_stages.dart';
import '../../fonctionnalites/notifications/presentation/ecran_notifications.dart';
import '../../fonctionnalites/profil/presentation/ecran_profil.dart';
import '../../fonctionnalites/projets/presentation/ecran_projets.dart';
import '../../fonctionnalites/chef_promotion/presentation/ecran_tableau_bord_chef_promotion.dart';
import '../../fonctionnalites/etudiants_risque/presentation/ecran_etudiants_risque.dart';
import '../../fonctionnalites/etudiant/presentation/ecran_alertes_etudiant.dart';
import '../../fonctionnalites/etudiant/presentation/ecran_cours_etudiant.dart';
import '../../fonctionnalites/etudiant/presentation/ecran_tableau_bord_etudiant.dart';
import '../../fonctionnalites/etudiant/presentation/ecran_valve_etudiant.dart';
import '../../fonctionnalites/enseignant/presentation/ecran_cours_enseignant.dart';
import '../../fonctionnalites/enseignant/presentation/ecran_tableau_bord_enseignant.dart';

class AppRoutes {
  static const login = '/';
  static const forgotPassword = '/forgot-password';
  static const registrationRequest = '/signup';
  static const adminDashboard = '/admin';
  static const adminManagement = '/administration/management';
  static const apparitorDashboard = '/apparitor';
  static const apparitorAssistant = '/apparitorat/assistant';
  static const apparitorStudents = '/apparitorat/etudiants';
  static const apparitorTeachers = '/apparitorat/enseignants';
  static const apparitorPromotions = '/apparitorat/promotions';
  static const apparitorPromotionDetail = '/apparitorat/promotions/detail';
  static const apparitorCourses = '/apparitorat/cours';
  static const apparitorCourseDetail = '/apparitorat/cours/detail';
  static const apparitorComplaints = '/apparitorat/reclamations';
  static const apparitorRisks = '/apparitorat/risques';
  static const apparitorProjects = '/apparitorat/projets';
  static const apparitorInternships = '/apparitorat/stages';
  static const apparitorReports = '/apparitorat/rapports';
  static const studentDashboard = '/student';
  static const studentCourses = '/student/courses';
  static const studentCourseDetail = '/student/courses/detail';
  static const studentValve = '/student/valve';
  static const studentValveCourse = '/student/valve/cours';
  static const studentAlerts = '/student/alerts';
  static const teacherDashboard = '/teacher';
  static const teacherCourses = '/teacher/courses';
  static const teacherCourseDetail = '/teacher/courses/detail';
  static const promotionChiefDashboard = '/promotion-chief';
  static const deanDashboard = '/dean';
  static const complaints = '/complaints';
  static const complaintDetail = '/reclamations/detail';
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
      case UserRole.apparitor:
        return apparitorDashboard;
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

    if (!_isPublicRoute(requestedRoute) && !SessionService.isAuthenticated) {
      return _route(const RouteSettings(name: login), const LoginScreen());
    }

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
      case registrationRequest:
        return _route(settings, const RegistrationRequestScreen());
      case adminDashboard:
        return _route(settings, const AdminDashboardScreen());
      case adminManagement:
        final args = settings.arguments;
        final category =
            args is AdminManagementArgs ? args.category : 'Etudiants';
        return _route(settings, AdminManagementScreen(category: category));
      case apparitorDashboard:
        return _route(settings, const ApparitorDashboardScreen());
      case apparitorAssistant:
        return _route(settings, const ApparitorAssistantScreen());
      case apparitorStudents:
        return _route(settings, const ApparitorStudentsScreen());
      case apparitorTeachers:
        return _route(settings, const ApparitorTeachersScreen());
      case apparitorPromotions:
        return _route(settings, const ApparitorPromotionsScreen());
      case apparitorPromotionDetail:
        final args = settings.arguments;
        final promotionId = args is int
            ? args
            : args is Map<String, dynamic>
                ? (args['id'] as num?)?.toInt() ?? 0
                : 0;
        return _route(
          settings,
          ApparitorPromotionDetailScreen(promotionId: promotionId),
        );
      case apparitorCourses:
        return _route(settings, const ApparitorCoursesScreen());
      case apparitorCourseDetail:
        final args = settings.arguments;
        final courseId = args is int
            ? args
            : args is Map<String, dynamic>
                ? (args['id'] as num?)?.toInt() ?? 0
                : 0;
        return _route(
          settings,
          ApparitorCourseDetailScreen(courseId: courseId),
        );
      case apparitorComplaints:
        return _route(settings, const ApparitorComplaintsScreen());
      case apparitorRisks:
        return _route(settings, const ApparitorRisksScreen());
      case apparitorProjects:
        return _route(settings, const ApparitorProjectsScreen());
      case apparitorInternships:
        return _route(settings, const ApparitorInternshipsScreen());
      case apparitorReports:
        return _route(settings, const ApparitorReportsScreen());
      case studentDashboard:
        return _route(settings, const StudentDashboardScreen());
      case studentCourses:
        return _route(settings, const StudentCoursesScreen());
      case studentCourseDetail:
        final args = settings.arguments;
        final courseId = args is int
            ? args
            : args is Map<String, dynamic>
                ? (args['id'] as num?)?.toInt() ?? 0
                : 0;
        return _route(settings, StudentCourseDetailScreen(courseId: courseId));
      case studentValve:
        return _route(settings, const StudentValveScreen());
      case studentValveCourse:
        final args = settings.arguments;
        final courseId = args is int
            ? args
            : args is Map<String, dynamic>
                ? (args['id'] as num?)?.toInt() ?? 0
                : 0;
        return _route(settings, StudentCourseValveScreen(courseId: courseId));
      case studentAlerts:
        return _route(settings, const StudentAlertsScreen());
      case teacherDashboard:
        return _route(settings, const TeacherDashboardScreen());
      case teacherCourses:
        return _route(settings, const TeacherCoursesScreen());
      case teacherCourseDetail:
        final args = settings.arguments;
        final courseId = args is int
            ? args
            : args is Map<String, dynamic>
                ? (args['id'] as num?)?.toInt() ?? 0
                : 0;
        return _route(settings, TeacherCourseDetailScreen(courseId: courseId));
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
        final args = settings.arguments;
        final courseId = args is int
            ? args
            : args is Map<String, dynamic>
                ? (args['cours_id'] as num?)?.toInt() ??
                    (args['course_id'] as num?)?.toInt()
                : null;
        return _route(settings, GradesScreen(initialCourseId: courseId));
      case riskStudents:
        return _route(settings, const RiskStudentsScreen());
      case notifications:
        final args = settings.arguments;
        final courseId = args is int
            ? args
            : args is Map<String, dynamic>
                ? (args['cours_id'] as num?)?.toInt() ??
                    (args['course_id'] as num?)?.toInt()
                : null;
        final type = args is Map<String, dynamic>
            ? (args['type_publication'] ?? args['type'])?.toString()
            : null;
        return _route(
          settings,
          NotificationsScreen(initialCourseId: courseId, initialType: type),
        );
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
    return route == login ||
        route == forgotPassword ||
        route == registrationRequest;
  }

  static bool _isRouteAllowed(UserRole role, String route) {
    final normalizedRoute = route == complaintDetail
        ? complaints
        : route == apparitorPromotionDetail
            ? apparitorPromotions
            : route == apparitorCourseDetail
                ? apparitorCourses
                : route == studentCourseDetail
                    ? studentCourses
                    : route == studentValveCourse
                        ? studentValve
                        : route;

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
      case UserRole.apparitor:
        return const {
          apparitorDashboard,
          apparitorAssistant,
          apparitorStudents,
          apparitorTeachers,
          apparitorPromotions,
          apparitorCourses,
          apparitorComplaints,
          apparitorRisks,
          apparitorProjects,
          apparitorInternships,
          apparitorReports,
        }.contains(normalizedRoute);
      case UserRole.student:
        return const {
          studentDashboard,
          studentCourses,
          studentValve,
          studentAlerts,
          complaints,
          grades,
        }.contains(normalizedRoute);
      case UserRole.teacher:
        return const {
          teacherDashboard,
          teacherCourses,
          teacherCourseDetail,
          complaints,
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
      case UserRole.apparitor:
        return const ApparitorDashboardScreen();
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
