import '../mock/mock_faculty_data.dart';
import '../models/faculty_models.dart';

abstract class FacultyRepository {
  Future<List<Complaint>> fetchComplaints();
  Future<List<AcademicProject>> fetchProjects();
  Future<List<InternshipOffer>> fetchInternshipOffers();
  Future<List<CourseGrade>> fetchGrades();
  Future<List<RiskStudent>> fetchRiskStudents();
}

class MockFacultyRepository implements FacultyRepository {
  @override
  Future<List<Complaint>> fetchComplaints() async => MockFacultyData.complaints;

  @override
  Future<List<CourseGrade>> fetchGrades() async => MockFacultyData.grades;

  @override
  Future<List<InternshipOffer>> fetchInternshipOffers() async =>
      MockFacultyData.internshipOffers;

  @override
  Future<List<AcademicProject>> fetchProjects() async =>
      MockFacultyData.projects;

  @override
  Future<List<RiskStudent>> fetchRiskStudents() async =>
      MockFacultyData.riskStudents;
}

class FacultyDataSource {
  static FacultyRepository repository = MockFacultyRepository();
}
