class WorkExperienceModel {
  final String title;
  final String company;
  final String location;
  final String period;
  final List<String> points;
  final List<String> techStack;
  final String? logoPath;

  WorkExperienceModel({
    required this.title,
    required this.company,
    required this.location,
    required this.period,
    required this.points,
    required this.techStack,
    this.logoPath,
  });
}

final List<WorkExperienceModel> allWorkExperiences = [
  WorkExperienceModel(
    title: 'Backend Programmer (Intern)',
    company: 'RSU Mitra Paramedika Yogyakarta',
    location: 'Yogyakarta, Indonesia',
    period: 'Oct 2025 - Apr 2026',
    points: [
      'Architecting and maintaining the SIMRS (Sistem Informasi Manajemen Rumah Sakit) enterprise system.',
      'Developed high-performance backend services using Laravel, focusing on scalability and data integrity.',
      'Collaborated with cross-functional teams to streamline hospital management workflows and improve operational efficiency.',
    ],
    techStack: ['Laravel', 'PHP', 'MySQL', 'REST API', 'Clean Architecture'],
  ),
  WorkExperienceModel(
    title: 'Software Programmer (Intern)',
    company: 'PT. Kilang Pertamina Internasional RU VII',
    location: 'Kasim, Indonesia',
    period: 'Sept 2023 - Jan 2024',
    points: [
      'Engineered a robust mobile overtime tracking system using Kotlin and Laravel, improving HR data accuracy.',
      'Optimized complex database queries for real-time reporting across a workforce of 500+ employees.',
      'Automated legacy manual logging processes, reducing administrative overhead by 40%.',
    ],
    techStack: ['Kotlin', 'Android', 'Laravel', 'PostgreSQL', 'Query Optimization'],
  ),
  WorkExperienceModel(
    title: 'Computer Literacy Instructor',
    company: 'SDN Sendangsari (KKN Program)',
    location: 'Yogyakarta, Indonesia',
    period: 'July 2023',
    points: [
      'Designed and implemented a comprehensive IT curriculum for primary education levels.',
      'Facilitated workshops on digital literacy, internet safety, and essential software tools for 100+ students.',
    ],
    techStack: ['Curriculum Design', 'Public Speaking', 'Instructional Leadership'],
  ),
];
