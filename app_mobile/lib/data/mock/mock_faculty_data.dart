import '../models/faculty_models.dart';

class MockFacultyData {
  static const users = <UserRole, FacultyUser>{
    UserRole.administrator: FacultyUser(
      name: 'Nadine Kabeya',
      email: 'admin@smartfaculty.cd',
      role: UserRole.administrator,
      department: 'Secretariat general academique',
      avatarText: 'NK',
      matricule: 'ADM-001',
      phone: '+243 810 000 104',
      location: 'Campus FASI, bloc administratif',
    ),
    UserRole.student: FacultyUser(
      name: 'Grace Ilunga',
      email: 'student@smartfaculty.cd',
      role: UserRole.student,
      department: 'L3 Genie logiciel',
      avatarText: 'GI',
      matricule: 'FASI-L3-GL-014',
      phone: '+243 820 314 522',
      location: 'Kinshasa',
    ),
    UserRole.teacher: FacultyUser(
      name: 'Pr. David Mutombo',
      email: 'teacher@smartfaculty.cd',
      role: UserRole.teacher,
      department: 'Programmation avancee',
      avatarText: 'DM',
      matricule: 'ENS-038',
      phone: '+243 899 420 122',
      location: 'Departement informatique',
    ),
    UserRole.promotionChief: FacultyUser(
      name: 'Sarah Mbuyi',
      email: 'chief@smartfaculty.cd',
      role: UserRole.promotionChief,
      department: 'Chef L2 Informatique',
      avatarText: 'SM',
      matricule: 'FASI-L2-INF-009',
      phone: '+243 812 771 006',
      location: 'Promotion L2 Informatique',
    ),
    UserRole.dean: FacultyUser(
      name: 'Doyen Alain Tshibangu',
      email: 'dean@smartfaculty.cd',
      role: UserRole.dean,
      department: 'Decanat FASI',
      avatarText: 'AT',
      matricule: 'DEC-001',
      phone: '+243 815 000 200',
      location: 'Bureau du doyen',
    ),
  };

  static const adminKpis = [
    KpiMetric(
      title: 'Etudiants',
      value: '1 284',
      trend: '+8,4%',
      description: 'inscrits actifs',
    ),
    KpiMetric(
      title: 'Enseignants',
      value: '86',
      trend: '+4',
      description: 'profils academiques',
    ),
    KpiMetric(
      title: 'Cours',
      value: '62',
      trend: '14 promotions',
      description: 'unites configurees',
    ),
    KpiMetric(
      title: 'Reclamations',
      value: '142',
      trend: '31 en cours',
      description: 'demandes ce semestre',
    ),
  ];

  static const studentKpis = [
    KpiMetric(
      title: 'Moyenne generale',
      value: '13,7',
      trend: '+0,8',
      description: 'semestre actuel',
    ),
    KpiMetric(
      title: 'Credits valides',
      value: '26/30',
      trend: '87%',
      description: 'progression academique',
    ),
    KpiMetric(
      title: 'Cours du semestre',
      value: '8',
      trend: '7 valides',
      description: 'dont 1 a reprendre',
    ),
    KpiMetric(
      title: 'Reclamations',
      value: '2',
      trend: '1 en cours',
      description: 'demandes personnelles',
    ),
  ];

  static const teacherKpis = [
    KpiMetric(
      title: 'Cours attribues',
      value: '3',
      trend: '2 promotions',
      description: 'semestre actuel',
    ),
    KpiMetric(
      title: 'Etudiants suivis',
      value: '219',
      trend: '76%',
      description: 'notes publiees',
    ),
    KpiMetric(
      title: 'Projets encadres',
      value: '8',
      trend: '3 critiques',
      description: 'groupes actifs',
    ),
    KpiMetric(
      title: 'Reclamations',
      value: '14',
      trend: '+6',
      description: 'liees aux cours',
    ),
  ];

  static const promotionKpis = [
    KpiMetric(
      title: 'Promotion',
      value: '276',
      trend: 'L2 info',
      description: 'etudiants actifs',
    ),
    KpiMetric(
      title: 'Moyenne',
      value: '12,9',
      trend: '+0,3',
      description: 'promotion',
    ),
    KpiMetric(
      title: 'A risque',
      value: '2',
      trend: '1 eleve',
      description: 'alertes pedagogiques',
    ),
    KpiMetric(
      title: 'Reclamations',
      value: '24',
      trend: '7 ouvertes',
      description: 'promotion',
    ),
  ];

  static const decisionKpis = [
    KpiMetric(
      title: 'Taux de reussite',
      value: '78,6%',
      trend: '+5,1%',
      description: 'moyenne facultaire',
    ),
    KpiMetric(
      title: 'Taux d echec',
      value: '12,8%',
      trend: '-2,3%',
      description: 'cours critiques',
    ),
    KpiMetric(
      title: 'Moyenne generale',
      value: '13,7',
      trend: '+0,8',
      description: 'sur 20',
    ),
    KpiMetric(
      title: 'Etudiants a risque',
      value: '47',
      trend: '11 eleves',
      description: 'suivi prioritaire',
    ),
  ];

  static final complaints = [
    Complaint(
      id: 'REC-2401',
      title: 'Note de bases de donnees non reprise',
      type: ComplaintType.gradeError,
      status: ComplaintStatus.inProgress,
      author: 'Grace Ilunga',
      createdAt: DateTime(2026, 5, 27),
      assignedTo: 'Secretariat academique',
      priority: 'Haute',
      description:
          'La note publiee dans le releve ne correspond pas au score valide par l enseignant apres consultation.',
      history: [
        ComplaintHistory(
          date: DateTime(2026, 5, 27),
          actor: 'Grace Ilunga',
          message: 'Reclamation soumise avec capture du bulletin provisoire.',
        ),
        ComplaintHistory(
          date: DateTime(2026, 5, 28),
          actor: 'Secretariat academique',
          message: 'Dossier assigne pour verification du PV de cours.',
        ),
        ComplaintHistory(
          date: DateTime(2026, 5, 30),
          actor: 'Pr. David Mutombo',
          message: 'Verification academique en cours.',
        ),
      ],
    ),
    Complaint(
      id: 'REC-2402',
      title: 'Erreur sur le statut d inscription',
      type: ComplaintType.registration,
      status: ComplaintStatus.pending,
      author: 'Noah Kanku',
      createdAt: DateTime(2026, 5, 29),
      assignedTo: 'Apparitorat',
      priority: 'Moyenne',
      description:
          'Le dossier indique une inscription incomplete alors que les documents ont ete deposes au service.',
      history: [
        ComplaintHistory(
          date: DateTime(2026, 5, 29),
          actor: 'Noah Kanku',
          message: 'Demande soumise depuis le portail etudiant.',
        ),
        ComplaintHistory(
          date: DateTime(2026, 5, 29),
          actor: 'Systeme',
          message: 'Dossier en attente de prise en charge.',
        ),
      ],
    ),
    Complaint(
      id: 'REC-2403',
      title: 'Demande de duplicata de releve',
      type: ComplaintType.academicDocument,
      status: ComplaintStatus.resolved,
      author: 'Mireille Nzuzi',
      createdAt: DateTime(2026, 5, 21),
      assignedTo: 'Secretariat',
      priority: 'Basse',
      description:
          'Besoin d un duplicata certifie pour completer un dossier de stage.',
      history: [
        ComplaintHistory(
          date: DateTime(2026, 5, 21),
          actor: 'Mireille Nzuzi',
          message: 'Demande creee avec reference de paiement.',
        ),
        ComplaintHistory(
          date: DateTime(2026, 5, 22),
          actor: 'Secretariat',
          message: 'Document verifie et genere.',
        ),
        ComplaintHistory(
          date: DateTime(2026, 5, 23),
          actor: 'Secretariat',
          message: 'Dossier cloture apres retrait.',
        ),
      ],
    ),
    Complaint(
      id: 'REC-2404',
      title: 'Conflit horaire avec laboratoire',
      type: ComplaintType.schedule,
      status: ComplaintStatus.rejected,
      author: 'Promotion L2 Informatique',
      createdAt: DateTime(2026, 5, 16),
      assignedTo: 'Coordination pedagogique',
      priority: 'Moyenne',
      description:
          'La seance de laboratoire chevauche un cours magistral obligatoire dans le planning initial.',
      history: [
        ComplaintHistory(
          date: DateTime(2026, 5, 16),
          actor: 'Sarah Mbuyi',
          message: 'Reclamation collective soumise.',
        ),
        ComplaintHistory(
          date: DateTime(2026, 5, 17),
          actor: 'Coordination pedagogique',
          message: 'Planning analyse avec les titulaires.',
        ),
        ComplaintHistory(
          date: DateTime(2026, 5, 18),
          actor: 'Coordination pedagogique',
          message: 'Rejetee car le planning avait deja ete corrige.',
        ),
      ],
    ),
    Complaint(
      id: 'REC-2405',
      title: 'Paiement non synchronise',
      type: ComplaintType.payment,
      status: ComplaintStatus.inProgress,
      author: 'Aline Mbala',
      createdAt: DateTime(2026, 6, 2),
      assignedTo: 'Service finances',
      priority: 'Haute',
      description:
          'Le paiement effectue apparait comme non recu dans le statut administratif.',
      history: [
        ComplaintHistory(
          date: DateTime(2026, 6, 2),
          actor: 'Aline Mbala',
          message: 'Preuve de paiement ajoutee au dossier.',
        ),
        ComplaintHistory(
          date: DateTime(2026, 6, 3),
          actor: 'Service finances',
          message: 'Verification bancaire en cours.',
        ),
      ],
    ),
  ];

  static final projects = [
    AcademicProject(
      id: 'PRJ-01',
      title: 'Plateforme de suivi des stages',
      summary:
          'Application de suivi des offres, candidatures et validations de stage pour la FASI.',
      supervisor: 'Pr. David Mutombo',
      members: ['Grace Ilunga', 'Joel Banza', 'Aline Mbala'],
      progress: 0.72,
      status: 'Prototype valide',
      nextDeliverable: 'Rapport intermediaire',
      defenseWindow: 'Juillet 2026',
      deliverables: [
        ProjectDeliverable(
          name: 'Cahier des charges',
          status: 'Valide',
          dueDate: DateTime(2026, 3, 12),
        ),
        ProjectDeliverable(
          name: 'Maquettes UX',
          status: 'Valide',
          dueDate: DateTime(2026, 4, 4),
        ),
        ProjectDeliverable(
          name: 'Prototype Flutter',
          status: 'En revision',
          dueDate: DateTime(2026, 6, 28),
        ),
      ],
    ),
    AcademicProject(
      id: 'PRJ-02',
      title: 'Detection des etudiants a risque',
      summary:
          'Modele analytique pour identifier les alertes academiques par promotion et par cours.',
      supervisor: 'Dr. Esther Kalonji',
      members: ['Sarah Mbuyi', 'Kevin Luba'],
      progress: 0.48,
      status: 'Collecte des donnees',
      nextDeliverable: 'Modele analytique',
      defenseWindow: 'Aout 2026',
      deliverables: [
        ProjectDeliverable(
          name: 'Sujet valide',
          status: 'Valide',
          dueDate: DateTime(2026, 2, 8),
        ),
        ProjectDeliverable(
          name: 'Plan de recherche',
          status: 'Valide',
          dueDate: DateTime(2026, 3, 18),
        ),
        ProjectDeliverable(
          name: 'Jeu de donnees nettoye',
          status: 'En cours',
          dueDate: DateTime(2026, 6, 30),
        ),
      ],
    ),
    AcademicProject(
      id: 'PRJ-03',
      title: 'Portail documentaire academique',
      summary:
          'Depot numerique pour notes de cours, releves et documents facultaires.',
      supervisor: 'Pr. Alain Tshibangu',
      members: ['Mireille Nzuzi', 'Noah Kanku'],
      progress: 0.86,
      status: 'Pre-soutenance',
      nextDeliverable: 'Version finale',
      defenseWindow: 'Juin 2026',
      deliverables: [
        ProjectDeliverable(
          name: 'Analyse fonctionnelle',
          status: 'Valide',
          dueDate: DateTime(2026, 2, 24),
        ),
        ProjectDeliverable(
          name: 'Backend simule',
          status: 'Valide',
          dueDate: DateTime(2026, 4, 19),
        ),
        ProjectDeliverable(
          name: 'Tests utilisateurs',
          status: 'A finaliser',
          dueDate: DateTime(2026, 6, 21),
        ),
      ],
    ),
  ];

  static const internshipOffers = [
    InternshipOffer(
      id: 'STG-101',
      title: 'Developpeur Flutter Junior',
      company: 'Kin Digital Lab',
      location: 'Kinshasa',
      duration: '3 mois',
      status: 'Ouverte',
      applicants: 18,
      description:
          'Contribution a une application mobile de services institutionnels.',
      requirements: ['Flutter', 'Git', 'API REST'],
    ),
    InternshipOffer(
      id: 'STG-102',
      title: 'Assistant Data Analyst',
      company: 'Campus Analytics',
      location: 'Hybride',
      duration: '4 mois',
      status: 'Selection',
      applicants: 11,
      description:
          'Nettoyage de donnees academiques et creation de tableaux de bord.',
      requirements: ['Excel', 'SQL', 'Visualisation'],
    ),
    InternshipOffer(
      id: 'STG-103',
      title: 'Support systemes academiques',
      company: 'Universite Partenaire',
      location: 'Gombe',
      duration: '2 mois',
      status: 'Validee',
      applicants: 7,
      description:
          'Assistance aux utilisateurs et documentation des processus.',
      requirements: ['Support', 'Documentation', 'Communication'],
    ),
  ];

  static final internshipApplications = [
    InternshipApplication(
      student: 'Grace Ilunga',
      company: 'Kin Digital Lab',
      position: 'Flutter Junior',
      status: 'Envoyee',
      updatedAt: DateTime(2026, 6, 3),
    ),
    InternshipApplication(
      student: 'Joel Banza',
      company: 'Campus Analytics',
      position: 'Data Analyst',
      status: 'Entretien',
      updatedAt: DateTime(2026, 6, 5),
    ),
    InternshipApplication(
      student: 'Mireille Nzuzi',
      company: 'Universite Partenaire',
      position: 'Support systemes',
      status: 'Validee',
      updatedAt: DateTime(2026, 6, 8),
    ),
  ];

  static const partnerCompanies = [
    PartnerCompany(
      name: 'Kin Digital Lab',
      sector: 'Developpement logiciel',
      activeInterns: 8,
      agreementStatus: 'Convention active',
    ),
    PartnerCompany(
      name: 'Campus Analytics',
      sector: 'Data & reporting',
      activeInterns: 5,
      agreementStatus: 'Renouvellement',
    ),
    PartnerCompany(
      name: 'Universite Partenaire',
      sector: 'Systemes academiques',
      activeInterns: 12,
      agreementStatus: 'Convention active',
    ),
  ];

  static final grades = [
    CourseGrade(
      course: 'Bases de donnees avancees',
      teacher: 'Pr. David Mutombo',
      credits: 5,
      grade: 15.5,
      result: 'Valide',
      publishedAt: DateTime(2026, 5, 20),
    ),
    CourseGrade(
      course: 'Architecture logicielle',
      teacher: 'Dr. Esther Kalonji',
      credits: 4,
      grade: 13.0,
      result: 'Valide',
      publishedAt: DateTime(2026, 5, 22),
    ),
    CourseGrade(
      course: 'Reseaux informatiques',
      teacher: 'Ir. Michel Lukusa',
      credits: 4,
      grade: 9.5,
      result: 'A reprendre',
      publishedAt: DateTime(2026, 5, 24),
    ),
    CourseGrade(
      course: 'Methodes de recherche',
      teacher: 'Pr. Alain Tshibangu',
      credits: 3,
      grade: 16.0,
      result: 'Valide',
      publishedAt: DateTime(2026, 5, 25),
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
      reason: 'Absences repetees et deux cours critiques.',
    ),
    RiskStudent(
      name: 'Mireille Nzuzi',
      promotion: 'L1 Informatique',
      average: 10.2,
      failures: 3,
      level: RiskLevel.medium,
      reason: 'Progression instable depuis deux evaluations.',
    ),
    RiskStudent(
      name: 'Joel Banza',
      promotion: 'L3 Genie logiciel',
      average: 11.4,
      failures: 2,
      level: RiskLevel.medium,
      reason: 'Projet en retard et moyenne sous seuil.',
    ),
    RiskStudent(
      name: 'Aline Mbala',
      promotion: 'L2 Informatique',
      average: 12.1,
      failures: 1,
      level: RiskLevel.low,
      reason: 'Surveillance preventive apres une note faible.',
    ),
  ];

  static const courseAssignments = [
    CourseAssignment(
      course: 'Bases de donnees avancees',
      promotion: 'L3 Genie logiciel',
      students: 64,
      publishedGrades: 52,
      average: 14.2,
    ),
    CourseAssignment(
      course: 'Algorithmique II',
      promotion: 'L2 Informatique',
      students: 91,
      publishedGrades: 91,
      average: 12.6,
    ),
    CourseAssignment(
      course: 'Architecture logicielle',
      promotion: 'L3 Genie logiciel',
      students: 64,
      publishedGrades: 38,
      average: 13.1,
    ),
  ];

  static const promotionStudents = [
    PromotionStudent(
      name: 'Sarah Mbuyi',
      matricule: 'FASI-L2-INF-009',
      average: 14.1,
      status: 'Regulier',
    ),
    PromotionStudent(
      name: 'Noah Kanku',
      matricule: 'FASI-L2-INF-044',
      average: 8.7,
      status: 'A risque',
    ),
    PromotionStudent(
      name: 'Aline Mbala',
      matricule: 'FASI-L2-INF-061',
      average: 12.1,
      status: 'Suivi leger',
    ),
    PromotionStudent(
      name: 'Kevin Luba',
      matricule: 'FASI-L2-INF-077',
      average: 13.3,
      status: 'Regulier',
    ),
  ];

  static const notifications = [
    FacultyNotification(
      title: 'Publication des notes',
      message: 'Les notes de bases de donnees avancees sont disponibles.',
      timeLabel: 'Il y a 2 h',
      tone: NotificationTone.info,
      audience: 'Etudiants L3',
    ),
    FacultyNotification(
      title: 'Soutenance blanche',
      message: 'La soutenance blanche est planifiee vendredi a 10h00.',
      timeLabel: 'Aujourd hui',
      tone: NotificationTone.warning,
      audience: 'Projets L3',
    ),
    FacultyNotification(
      title: 'Stage valide',
      message: 'Une convention de stage a ete approuvee par le secretariat.',
      timeLabel: 'Hier',
      tone: NotificationTone.success,
      audience: 'Administration',
    ),
    FacultyNotification(
      title: 'Risque academique',
      message: 'Un nouveau profil requiert un suivi prioritaire en L2.',
      timeLabel: 'Hier',
      tone: NotificationTone.danger,
      audience: 'Decanat',
    ),
  ];

  static const recentActivities = [
    ActivityItem(
      title: 'Reclamation REC-2401 assignee',
      detail: 'Verification academique transmise a Pr. David Mutombo.',
      timeLabel: '09:20',
    ),
    ActivityItem(
      title: 'Nouvelle offre de stage',
      detail: 'Kin Digital Lab a ouvert une offre Flutter Junior.',
      timeLabel: '10:45',
    ),
    ActivityItem(
      title: 'Notes consolidees',
      detail: 'Architecture logicielle publiee pour L3 Genie logiciel.',
      timeLabel: '12:05',
    ),
    ActivityItem(
      title: 'Alerte promotion',
      detail: 'Deux etudiants L2 sont passes en suivi renforce.',
      timeLabel: '14:10',
    ),
  ];

  static const complaintsByCategory = [
    ChartPoint('Notes', 42),
    ChartPoint('Inscription', 26),
    ChartPoint('Admin', 18),
    ChartPoint('Paiement', 15),
    ChartPoint('Horaire', 23),
    ChartPoint('Document', 18),
  ];

  static const complaintsByStatus = [
    ChartPoint('Attente', 36),
    ChartPoint('En cours', 31),
    ChartPoint('Resolues', 64),
    ChartPoint('Rejetees', 11),
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
    ChartPoint('Reseaux', 58),
    ChartPoint('Mobile', 82),
    ChartPoint('IA', 73),
  ];

  static const l2ProgressTrend = [
    ChartPoint('Oct', 58),
    ChartPoint('Nov', 63),
    ChartPoint('Dec', 67),
    ChartPoint('Jan', 70),
    ChartPoint('Fev', 74),
  ];

  static const l2CoursePerformance = [
    ChartPoint('Algo', 71),
    ChartPoint('BD', 76),
    ChartPoint('Reseaux', 58),
    ChartPoint('Anglais', 84),
    ChartPoint('Projet', 79),
  ];
}
