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
      'Developed the inpatient (rawat inap) module of the SIMRS using Laravel.',
      'Built backend features for patient records and hospitalization workflows.',
      'Collaborated with the team to integrate the module with the overall hospital system.',
    ],
    techStack: ['Laravel', 'PHP', 'MySQL', 'REST API'],
  ),
  WorkExperienceModel(
    title: 'Software Programmer (Intern)',
    company: 'PT. Kilang Pertamina Internasional RU VII',
    location: 'Kasim, Indonesia',
    period: 'Sept 2023 - Jan 2024',
    points: [
      'Developed an Android-based attendance system using QR code for employee check-in.',
      'Built features for overtime, business trip, and leave management.',
      'Integrated the mobile app with backend services using Kotlin and Laravel.',
    ],
    techStack: ['Kotlin', 'Android', 'Laravel', 'PostgreSQL'],
  ),
  WorkExperienceModel(
    title: 'Computer Literacy Instructor',
    company: 'SDN Sendangsari (KKN Program)',
    location: 'Yogyakarta, Indonesia',
    period: 'July 2023',
    points: [
      'Taught basic Microsoft Word and Excel to elementary school students.',
      'Guided students in basic computer usage and digital literacy fundamentals.',
    ],
    techStack: ['Microsoft Office', 'Public Speaking', 'Digital Literacy'],
  ),
];
