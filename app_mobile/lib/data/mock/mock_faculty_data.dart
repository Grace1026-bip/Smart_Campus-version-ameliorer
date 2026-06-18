import '../models/faculty_models.dart';

class MockFacultyData {
  static const users = <UserRole, FacultyUser>{
    UserRole.administrator: FacultyUser(
      name: 'Nadine Kabeya',
      email: 'admin@smartfaculty.cd',
      role: UserRole.administrator,
      department: 'Administration facultaire',
      avatarText: 'NK',
    ),
    UserRole.student: FacultyUser(
      name: 'Grâce Ilunga',
      email: 'student@smartfaculty.cd',
      role: UserRole.student,
      department: 'L3 Génie logiciel',
      avatarText: 'GI',
    ),
    UserRole.teacher: FacultyUser(
      name: 'Pr. David Mutombo',
      email: 'teacher@smartfaculty.cd',
      role: UserRole.teacher,
      department: 'Programmation avancée',
      avatarText: 'DM',
    ),
    UserRole.promotionChief: FacultyUser(
      name: 'Sarah Mbuyi',
      email: 'chief@smartfaculty.cd',
      role: UserRole.promotionChief,
      department: 'Chef L2 Informatique',
      avatarText: 'SM',
    ),
    UserRole.dean: FacultyUser(
      name: 'Doyen Alain Tshibangu',
      email: 'dean@smartfaculty.cd',
      role: UserRole.dean,
      department: 'Décanat',
      avatarText: 'AT',
    ),
  };

  static const adminKpis = [
    KpiMetric(
      title: 'Étudiants',
      value: '1 284',
      trend: '+8,4%',
      description: 'inscrits actifs',
    ),
    KpiMetric(
      title: 'Enseignants',
      value: '86',
      trend: '+4',
      description: 'profils académiques',
    ),
    KpiMetric(
      title: 'Réclamations',
      value: '142',
      trend: '31 en cours',
      description: 'demandes ce semestre',
    ),
    KpiMetric(
      title: 'Stages validés',
      value: '219',
      trend: '+15%',
      description: 'conventions suivies',
    ),
  ];

  static const decisionKpis = [
    KpiMetric(
      title: 'Taux de réussite',
      value: '78,6%',
      trend: '+5,1%',
      description: 'moyenne facultaire',
    ),
    KpiMetric(
      title: 'Taux d’échec',
      value: '12,8%',
      trend: '-2,3%',
      description: 'cours critiques',
    ),
    KpiMetric(
      title: 'Moyenne générale',
      value: '13,7',
      trend: '+0,8',
      description: 'sur 20',
    ),
    KpiMetric(
      title: 'Temps traitement',
      value: '2,4 j',
      trend: '-18%',
      description: 'réclamations',
    ),
  ];

  static final complaints = [
    Complaint(
      id: 'REC-2401',
      title: 'Note de base de données non reprise',
      type: ComplaintType.gradeError,
      status: ComplaintStatus.inProgress,
      author: 'Grâce Ilunga',
      createdAt: DateTime(2026, 5, 27),
      assignedTo: 'Secrétariat académique',
      description:
          'La note publiée dans le relevé ne correspond pas au score validé par l’enseignant.',
      history: const [
        'Soumise par l’étudiante',
        'Pièce justificative ajoutée',
        'Assignée au secrétariat académique',
      ],
    ),
    Complaint(
      id: 'REC-2402',
      title: 'Erreur sur le statut d’inscription',
      type: ComplaintType.registration,
      status: ComplaintStatus.pending,
      author: 'Noah Kanku',
      createdAt: DateTime(2026, 5, 29),
      assignedTo: 'Apparitorat',
      description:
          'Le dossier indique une inscription incomplète alors que les documents ont été déposés.',
      history: const ['Soumise par l’étudiant', 'En attente de vérification'],
    ),
    Complaint(
      id: 'REC-2403',
      title: 'Demande de duplicata de relevé',
      type: ComplaintType.academicDocument,
      status: ComplaintStatus.resolved,
      author: 'Mireille Nzuzi',
      createdAt: DateTime(2026, 5, 21),
      assignedTo: 'Secrétariat',
      description: 'Besoin d’un duplicata certifié pour un dossier de stage.',
      history: const [
        'Soumise par l’étudiante',
        'Validée par le secrétariat',
        'Document généré',
      ],
    ),
    Complaint(
      id: 'REC-2404',
      title: 'Conflit horaire avec laboratoire',
      type: ComplaintType.schedule,
      status: ComplaintStatus.rejected,
      author: 'Promotion L2',
      createdAt: DateTime(2026, 5, 16),
      assignedTo: 'Coordination pédagogique',
      description:
          'La séance de laboratoire chevauche un cours magistral obligatoire.',
      history: const [
        'Soumise par le chef de promotion',
        'Analysée par la coordination',
        'Rejetée: planning déjà corrigé',
      ],
    ),
  ];

  static const projects = [
    AcademicProject(
      id: 'PRJ-01',
      title: 'Plateforme de suivi des stages',
      supervisor: 'Pr. David Mutombo',
      members: ['Grâce Ilunga', 'Joël Banza', 'Aline Mbala'],
      progress: 0.72,
      status: 'Prototype validé',
      nextDeliverable: 'Rapport intermédiaire',
      deliverables: ['Cahier des charges', 'Maquettes UI', 'Prototype Flutter'],
    ),
    AcademicProject(
      id: 'PRJ-02',
      title: 'Détection des étudiants à risque',
      supervisor: 'Dr. Esther Kalonji',
      members: ['Sarah Mbuyi', 'Kevin Luba'],
      progress: 0.48,
      status: 'Collecte des données',
      nextDeliverable: 'Modèle analytique',
      deliverables: ['Sujet validé', 'Plan de recherche'],
    ),
    AcademicProject(
      id: 'PRJ-03',
      title: 'Portail documentaire académique',
      supervisor: 'Pr. Alain Tshibangu',
      members: ['Mireille Nzuzi', 'Noah Kanku'],
      progress: 0.86,
      status: 'Pré-soutenance',
      nextDeliverable: 'Version finale',
      deliverables: ['Analyse', 'Backend simulé', 'Tests utilisateurs'],
    ),
  ];

  static const internshipOffers = [
    InternshipOffer(
      id: 'STG-101',
      title: 'Développeur Flutter Junior',
      company: 'Kin Digital Lab',
      location: 'Kinshasa',
      duration: '3 mois',
      status: 'Ouverte',
      applicants: 18,
      description:
          'Contribution à une application mobile de services institutionnels.',
    ),
    InternshipOffer(
      id: 'STG-102',
      title: 'Assistant Data Analyst',
      company: 'Campus Analytics',
      location: 'Hybride',
      duration: '4 mois',
      status: 'Sélection',
      applicants: 11,
      description:
          'Nettoyage de données académiques et création de tableaux de bord.',
    ),
    InternshipOffer(
      id: 'STG-103',
      title: 'Support systèmes académiques',
      company: 'Université Partenaire',
      location: 'Gombe',
      duration: '2 mois',
      status: 'Validée',
      applicants: 7,
      description:
          'Assistance aux utilisateurs et documentation des processus.',
    ),
  ];

  static const grades = [
    CourseGrade(
      course: 'Bases de données avancées',
      teacher: 'Pr. David Mutombo',
      credits: 5,
      grade: 15.5,
      result: 'Validé',
    ),
    CourseGrade(
      course: 'Architecture logicielle',
      teacher: 'Dr. Esther Kalonji',
      credits: 4,
      grade: 13.0,
      result: 'Validé',
    ),
    CourseGrade(
      course: 'Réseaux informatiques',
      teacher: 'Ir. Michel Lukusa',
      credits: 4,
      grade: 9.5,
      result: 'À reprendre',
    ),
    CourseGrade(
      course: 'Méthodes de recherche',
      teacher: 'Pr. Alain Tshibangu',
      credits: 3,
      grade: 16.0,
      result: 'Validé',
    ),
  ];

  static const academicHistory = [
    AcademicHistory(
      period: 'L1 Informatique',
      average: 12.8,
      credits: 54,
      result: 'Admis',
    ),
    AcademicHistory(
      period: 'L2 Informatique',
      average: 13.4,
      credits: 58,
      result: 'Admis',
    ),
    AcademicHistory(
      period: 'L3 Semestre actuel',
      average: 13.7,
      credits: 26,
      result: 'En cours',
    ),
  ];

  static const riskStudents = [
    RiskStudent(
      name: 'Noah Kanku',
      promotion: 'L2 Informatique',
      average: 8.7,
      failures: 4,
      level: RiskLevel.high,
    ),
    RiskStudent(
      name: 'Mireille Nzuzi',
      promotion: 'L1 Informatique',
      average: 10.2,
      failures: 3,
      level: RiskLevel.medium,
    ),
    RiskStudent(
      name: 'Joël Banza',
      promotion: 'L3 Génie logiciel',
      average: 11.4,
      failures: 2,
      level: RiskLevel.medium,
    ),
    RiskStudent(
      name: 'Aline Mbala',
      promotion: 'L2 Informatique',
      average: 12.1,
      failures: 1,
      level: RiskLevel.low,
    ),
  ];

  static const courseAssignments = [
    CourseAssignment(
      course: 'Bases de données avancées',
      promotion: 'L3 Génie logiciel',
      students: 64,
      publishedGrades: 52,
    ),
    CourseAssignment(
      course: 'Algorithmique II',
      promotion: 'L2 Informatique',
      students: 91,
      publishedGrades: 91,
    ),
    CourseAssignment(
      course: 'Architecture logicielle',
      promotion: 'L3 Génie logiciel',
      students: 64,
      publishedGrades: 38,
    ),
  ];

  static const complaintsByCategory = [
    ChartPoint('Notes', 42),
    ChartPoint('Inscription', 26),
    ChartPoint('Admin', 18),
    ChartPoint('Paiement', 15),
    ChartPoint('Horaire', 23),
  ];

  static const complaintsByStatus = [
    ChartPoint('Attente', 36),
    ChartPoint('En cours', 31),
    ChartPoint('Résolues', 64),
    ChartPoint('Rejetées', 11),
  ];

  static const performanceByPromotion = [
    ChartPoint('L1', 67),
    ChartPoint('L2', 74),
    ChartPoint('L3', 81),
    ChartPoint('M1', 78),
    ChartPoint('M2', 84),
  ];

  static const performanceByCourse = [
    ChartPoint('BD', 76),
    ChartPoint('Algo', 69),
    ChartPoint('Réseaux', 58),
    ChartPoint('Mobile', 82),
    ChartPoint('IA', 73),
  ];
}
