enum UserRole {
  administrator,
  apparitor,
  student,
  teacher,
  promotionChief,
  dean,
  viceDean,
}

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.administrator:
        return 'Administrateur';
      case UserRole.apparitor:
        return 'Appariteur';
      case UserRole.student:
        return 'Etudiant';
      case UserRole.teacher:
        return 'Enseignant';
      case UserRole.promotionChief:
        return 'Chef de promotion';
      case UserRole.dean:
        return 'Doyen';
      case UserRole.viceDean:
        return 'Vice-doyen';
    }
  }

  String get workspaceLabel {
    switch (this) {
      case UserRole.administrator:
        return 'Administration facultaire';
      case UserRole.apparitor:
        return 'Apparitorat academique';
      case UserRole.student:
        return 'Espace etudiant';
      case UserRole.teacher:
        return 'Espace enseignant';
      case UserRole.promotionChief:
        return 'Espace promotion';
      case UserRole.dean:
        return 'Pilotage decisionnel';
      case UserRole.viceDean:
        return 'Pilotage decisionnel';
    }
  }

  String get apiValue {
    switch (this) {
      case UserRole.administrator:
        return 'administrateur';
      case UserRole.apparitor:
        return 'appariteur';
      case UserRole.student:
        return 'etudiant';
      case UserRole.teacher:
        return 'enseignant';
      case UserRole.promotionChief:
        return 'chef_promotion';
      case UserRole.dean:
        return 'doyen';
      case UserRole.viceDean:
        return 'vice_doyen';
    }
  }
}

UserRole? userRoleFromApi(String value) {
  for (final role in UserRole.values) {
    if (role.apiValue == value.trim().toLowerCase()) return role;
  }
  return null;
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
        return 'Resolue';
      case ComplaintStatus.rejected:
        return 'Rejetee';
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
        return 'Probleme inscription';
      case ComplaintType.administration:
        return 'Probleme administratif';
      case ComplaintType.payment:
        return 'Paiement';
      case ComplaintType.schedule:
        return 'Horaire';
      case ComplaintType.academicDocument:
        return 'Document academique';
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
        return 'Eleve';
    }
  }
}

enum NotificationTone { info, success, warning, danger }

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
    required this.matricule,
    required this.promotion,
    required this.phone,
    required this.location,
  });

  final String name;
  final String email;
  final UserRole role;
  final String department;
  final String avatarText;
  final String matricule;
  final String promotion;
  final String phone;
  final String location;
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
    required this.priority,
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
  final String priority;
  final List<ComplaintHistory> history;
}

class ComplaintHistory {
  const ComplaintHistory({
    required this.date,
    required this.actor,
    required this.message,
  });

  final DateTime date;
  final String actor;
  final String message;
}

class AcademicProject {
  const AcademicProject({
    required this.id,
    required this.title,
    required this.summary,
    required this.supervisor,
    required this.members,
    required this.promotion,
    required this.progress,
    required this.status,
    required this.nextDeliverable,
    required this.defenseWindow,
    required this.deliverables,
  });

  final String id;
  final String title;
  final String summary;
  final String supervisor;
  final List<String> members;
  final String promotion;
  final double progress;
  final String status;
  final String nextDeliverable;
  final String defenseWindow;
  final List<ProjectDeliverable> deliverables;
}

class ProjectDeliverable {
  const ProjectDeliverable({
    required this.name,
    required this.status,
    required this.dueDate,
  });

  final String name;
  final String status;
  final DateTime dueDate;
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
    required this.requirements,
  });

  final String id;
  final String title;
  final String company;
  final String location;
  final String duration;
  final String status;
  final int applicants;
  final String description;
  final List<String> requirements;
}

class InternshipApplication {
  const InternshipApplication({
    required this.student,
    required this.company,
    required this.position,
    required this.status,
    required this.updatedAt,
  });

  final String student;
  final String company;
  final String position;
  final String status;
  final DateTime updatedAt;
}

class PartnerCompany {
  const PartnerCompany({
    required this.name,
    required this.sector,
    required this.activeInterns,
    required this.agreementStatus,
  });

  final String name;
  final String sector;
  final int activeInterns;
  final String agreementStatus;
}

class CourseGrade {
  const CourseGrade({
    required this.course,
    required this.student,
    required this.matricule,
    required this.promotion,
    required this.teacher,
    required this.credits,
    required this.grade,
    required this.courseAverage,
    required this.result,
    required this.published,
    required this.locked,
    required this.publishedAt,
  });

  final String course;
  final String student;
  final String matricule;
  final String promotion;
  final String teacher;
  final int credits;
  final double grade;
  final double courseAverage;
  final String result;
  final bool published;
  final bool locked;
  final DateTime publishedAt;
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
    required this.course,
    required this.teacher,
    required this.average,
    required this.failures,
    required this.level,
    required this.reason,
  });

  final String name;
  final String promotion;
  final String course;
  final String teacher;
  final double average;
  final int failures;
  final RiskLevel level;
  final String reason;
}

class CourseAssignment {
  const CourseAssignment({
    required this.course,
    required this.promotion,
    required this.teacher,
    required this.students,
    required this.publishedGrades,
    required this.average,
    required this.locked,
  });

  final String course;
  final String promotion;
  final String teacher;
  final int students;
  final int publishedGrades;
  final double average;
  final bool locked;
}

class PromotionStudent {
  const PromotionStudent({
    required this.name,
    required this.matricule,
    required this.average,
    required this.status,
  });

  final String name;
  final String matricule;
  final double average;
  final String status;
}

class FacultyNotification {
  const FacultyNotification({
    required this.title,
    required this.message,
    required this.timeLabel,
    required this.tone,
    required this.audience,
  });

  final String title;
  final String message;
  final String timeLabel;
  final NotificationTone tone;
  final String audience;
}

class ActivityItem {
  const ActivityItem({
    required this.title,
    required this.detail,
    required this.timeLabel,
  });

  final String title;
  final String detail;
  final String timeLabel;
}

class ApparitorInsight {
  const ApparitorInsight({
    required this.title,
    required this.detail,
    required this.metric,
    required this.tone,
  });

  final String title;
  final String detail;
  final String metric;
  final NotificationTone tone;
}
