import '../donnees_fictives/donnees_faculte_fictives.dart';
import '../modeles/modeles_faculte.dart';

abstract class FacultyRepository {
  Future<List<Complaint>> fetchComplaints();
  Future<List<AcademicProject>> fetchProjects();
  Future<List<InternshipOffer>> fetchInternshipOffers();
  Future<List<InternshipApplication>> fetchInternshipApplications();
  Future<List<PartnerCompany>> fetchPartnerCompanies();
  Future<List<CourseGrade>> fetchGrades();
  Future<List<AcademicHistory>> fetchAcademicHistory();
  Future<List<RiskStudent>> fetchRiskStudents();
  Future<List<CourseAssignment>> fetchCourseAssignments();
  Future<List<PromotionStudent>> fetchPromotionStudents();
  Future<List<FacultyNotification>> fetchNotifications();
  Future<List<ActivityItem>> fetchRecentActivities();
  Future<List<ApparitorInsight>> fetchApparitorInsights();
}

class MockFacultyRepository implements FacultyRepository {
  const MockFacultyRepository();

  @override
  Future<List<Complaint>> fetchComplaints() async => MockFacultyData.complaints;

  @override
  Future<List<CourseGrade>> fetchGrades() async => MockFacultyData.grades;

  @override
  Future<List<AcademicHistory>> fetchAcademicHistory() async =>
      MockFacultyData.academicHistory;

  @override
  Future<List<InternshipOffer>> fetchInternshipOffers() async =>
      MockFacultyData.internshipOffers;

  @override
  Future<List<InternshipApplication>> fetchInternshipApplications() async =>
      MockFacultyData.internshipApplications;

  @override
  Future<List<PartnerCompany>> fetchPartnerCompanies() async =>
      MockFacultyData.partnerCompanies;

  @override
  Future<List<AcademicProject>> fetchProjects() async =>
      MockFacultyData.projects;

  @override
  Future<List<RiskStudent>> fetchRiskStudents() async =>
      MockFacultyData.riskStudents;

  @override
  Future<List<CourseAssignment>> fetchCourseAssignments() async =>
      MockFacultyData.courseAssignments;

  @override
  Future<List<PromotionStudent>> fetchPromotionStudents() async =>
      MockFacultyData.promotionStudents;

  @override
  Future<List<FacultyNotification>> fetchNotifications() async =>
      MockFacultyData.notifications;

  @override
  Future<List<ActivityItem>> fetchRecentActivities() async =>
      MockFacultyData.recentActivities;

  @override
  Future<List<ApparitorInsight>> fetchApparitorInsights() async =>
      MockFacultyData.apparitorInsights;
}

class ApiFacultyRepository implements FacultyRepository {
  ApiFacultyRepository({required this.baseUrl});

  final String baseUrl;

  Never _notConnectedYet() {
    throw UnimplementedError(
      'Brancher ici les endpoints REST FastAPI manquants.',
    );
  }

  @override
  Future<List<Complaint>> fetchComplaints() async => _notConnectedYet();

  @override
  Future<List<CourseGrade>> fetchGrades() async => _notConnectedYet();

  @override
  Future<List<AcademicHistory>> fetchAcademicHistory() async =>
      _notConnectedYet();

  @override
  Future<List<InternshipOffer>> fetchInternshipOffers() async =>
      _notConnectedYet();

  @override
  Future<List<InternshipApplication>> fetchInternshipApplications() async =>
      _notConnectedYet();

  @override
  Future<List<PartnerCompany>> fetchPartnerCompanies() async =>
      _notConnectedYet();

  @override
  Future<List<AcademicProject>> fetchProjects() async => _notConnectedYet();

  @override
  Future<List<RiskStudent>> fetchRiskStudents() async => _notConnectedYet();

  @override
  Future<List<CourseAssignment>> fetchCourseAssignments() async =>
      _notConnectedYet();

  @override
  Future<List<PromotionStudent>> fetchPromotionStudents() async =>
      _notConnectedYet();

  @override
  Future<List<FacultyNotification>> fetchNotifications() async =>
      _notConnectedYet();

  @override
  Future<List<ActivityItem>> fetchRecentActivities() async =>
      _notConnectedYet();

  @override
  Future<List<ApparitorInsight>> fetchApparitorInsights() async =>
      _notConnectedYet();
}

class FacultyDataSource {
  static FacultyRepository repository = const MockFacultyRepository();
}
