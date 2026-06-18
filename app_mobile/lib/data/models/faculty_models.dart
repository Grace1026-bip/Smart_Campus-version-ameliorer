enum UserRole { administrator, student, teacher, promotionChief, dean }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.administrator:
        return 'Administrateur';
      case UserRole.student:
        return 'Étudiant';
      case UserRole.teacher:
        return 'Enseignant';
      case UserRole.promotionChief:
        return 'Chef de promotion';
      case UserRole.dean:
        return 'Doyen';
    }
  }
}

enum ComplaintStatus { pending, inProgress, resolved, rejected }

extension ComplaintStatusLabel on ComplaintStatus {
  String get label {
    switch (this) {
      case ComplaintStatus.pending:
        return 'En attente';
      case ComplaintStatus.inProgress:
        return 'En cours';
      case ComplaintStatus.resolved:
        return 'Résolue';
      case ComplaintStatus.rejected:
        return 'Rejetée';
    }
  }
}

enum ComplaintType {
  gradeError,
  registration,
  administration,
  payment,
  schedule,
  academicDocument,
}

extension ComplaintTypeLabel on ComplaintType {
  String get label {
    switch (this) {
      case ComplaintType.gradeError:
        return 'Erreur de note';
      case ComplaintType.registration:
        return 'Problème d’inscription';
      case ComplaintType.administration:
        return 'Problème administratif';
      case ComplaintType.payment:
        return 'Paiement';
      case ComplaintType.schedule:
        return 'Horaire';
      case ComplaintType.academicDocument:
        return 'Document académique';
    }
  }
}

enum RiskLevel { low, medium, high }

extension RiskLevelLabel on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.low:
        return 'Faible';
      case RiskLevel.medium:
        return 'Moyen';
      case RiskLevel.high:
        return 'Élevé';
    }
  }
}

class KpiMetric {
  const KpiMetric({
    required this.title,
    required this.value,
    required this.trend,
    required this.description,
  });

  final String title;
  final String value;
  final String trend;
  final String description;
}

class ChartPoint {
  const ChartPoint(this.label, this.value);

  final String label;
  final double value;
}

class FacultyUser {
  const FacultyUser({
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.avatarText,
  });

  final String name;
  final String email;
  final UserRole role;
  final String department;
  final String avatarText;
}

class Complaint {
  const Complaint({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.author,
    required this.createdAt,
    required this.assignedTo,
    required this.description,
    required this.history,
  });

  final String id;
  final String title;
  final ComplaintType type;
  final ComplaintStatus status;
  final String author;
  final DateTime createdAt;
  final String assignedTo;
  final String description;
  final List<String> history;
}

class AcademicProject {
  const AcademicProject({
    required this.id,
    required this.title,
    required this.supervisor,
    required this.members,
    required this.progress,
    required this.status,
    required this.nextDeliverable,
    required this.deliverables,
  });

  final String id;
  final String title;
  final String supervisor;
  final List<String> members;
  final double progress;
  final String status;
  final String nextDeliverable;
  final List<String> deliverables;
}

class InternshipOffer {
  const InternshipOffer({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.duration,
    required this.status,
    required this.applicants,
    required this.description,
  });

  final String id;
  final String title;
  final String company;
  final String location;
  final String duration;
  final String status;
  final int applicants;
  final String description;
}

class CourseGrade {
  const CourseGrade({
    required this.course,
    required this.teacher,
    required this.credits,
    required this.grade,
    required this.result,
  });

  final String course;
  final String teacher;
  final int credits;
  final double grade;
  final String result;
}

class AcademicHistory {
  const AcademicHistory({
    required this.period,
    required this.average,
    required this.credits,
    required this.result,
  });

  final String period;
  final double average;
  final int credits;
  final String result;
}

class RiskStudent {
  const RiskStudent({
    required this.name,
    required this.promotion,
    required this.average,
    required this.failures,
    required this.level,
  });

  final String name;
  final String promotion;
  final double average;
  final int failures;
  final RiskLevel level;
}

class CourseAssignment {
  const CourseAssignment({
    required this.course,
    required this.promotion,
    required this.students,
    required this.publishedGrades,
  });

  final String course;
  final String promotion;
  final int students;
  final int publishedGrades;
}
