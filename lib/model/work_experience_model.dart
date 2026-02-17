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
    period: 'Oct 2024 - Present',
    points: [
      'Developing and maintaining the SIMRS (Sistem Informasi Manajemen Rumah Sakit) system.',
      'Building robust backend services using Laravel framework.',
      'Collaborating with the IT team to optimize hospital management workflows.',
    ],
    techStack: ['Laravel', 'PHP', 'MySQL', 'REST API'],
  ),
  WorkExperienceModel(
    title: 'Software Programmer (Intern)',
    company: 'PT. Kilang Pertamina Internasional RU VII',
    location: 'Kasim, Indonesia',
    period: 'Sept 2023 - Jan 2024',
    points: [
      'Engineered a mobile overtime tracking system using Kotlin and Laravel.',
      'Optimized database queries for reporting across 500+ employees.',
      'Improved HR operational efficiency by automating manual logging processes.',
    ],
    techStack: ['Kotlin', 'Android', 'Laravel', 'PostgreSQL'],
  ),
  WorkExperienceModel(
    title: 'Computer Literacy Instructor',
    company: 'SDN Sendangsari (KKN Program)',
    location: 'Yogyakarta, Indonesia',
    period: 'July 2023',
    points: [
      'Developed a custom IT curriculum for primary students.',
      'Led workshops on digital tools and internet safety.',
    ],
    techStack: ['Teaching', 'Curriculum Design', 'Public Speaking'],
  ),
];
