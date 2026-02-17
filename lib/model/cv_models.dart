class EducationModel {
  final String schoolName;
  final String location;
  final String years;
  final String degreeType;
  final String description;
  final String learnings;
  final List<String> skills;

  EducationModel({
    required this.schoolName,
    required this.location,
    required this.years,
    required this.degreeType,
    required this.description,
    required this.learnings,
    required this.skills,
  });
}

class AchievementModel {
  final String certificateName;
  final String organizationName;
  final String date;
  final String description;
  final List<String> skills;

  AchievementModel({
    required this.certificateName,
    required this.organizationName,
    required this.date,
    required this.description,
    required this.skills,
  });
}

final List<EducationModel> allEducation = [
  EducationModel(
    schoolName: "Universitas Atma Jaya",
    location: "Yogyakarta, Indonesia",
    years: "2020 - 2025",
    degreeType: "BACHELOR OF INFORMATION SYSTEMS",
    description:
        "A premier private university in Yogyakarta known for its rigorous curriculum in technology and business. The Information Systems program bridges the gap between technical software engineering and strategic business management.",
    learnings:
        "• Advanced Software Engineering.\n• Enterprise Systems Analysis & Design.\n• Business Intelligence & Data Mining.\n• Database Management (SQL/NoSQL).\n• IT Project Management & Agile Methodologies.",
    skills: [
      "Software Engineering",
      "System Analysis",
      "Web/Android/Desktop",
      "Data Mining",
      "Project Management",
      "UI/UX Design"
    ],
  ),
  EducationModel(
    schoolName: "SMA Negeri 8 Samarinda",
    location: "Samarinda, Indonesia",
    years: "2017 - 2020",
    degreeType: "HIGH SCHOOL GRADUATE",
    description:
        "High school education focusing on comprehensive academic development and preparing students for higher education in technology and sciences.",
    learnings:
        "• Advanced Mathematics & Physics.\n• Social & Organizational leadership.\n• Scientific Research Foundations.",
    skills: ["Mathematics", "Physics", "Logic", "Leadership"],
  ),
  EducationModel(
    schoolName: "SMP Negeri 16 Samarinda",
    location: "Samarinda, Indonesia",
    years: "2014 - 2017",
    degreeType: "JUNIOR HIGH SCHOOL GRADUATE",
    description:
        "Secondary education focusing on foundational academic skills and developing early interests in science and technology.",
    learnings:
        "• Basic Sciences & Mathematics.\n• Foundational Computer Literacy.\n• Extracurricular leadership as class representative.",
    skills: ["General Science", "Basic Math", "Quick Learning", "Teamwork"],
  ),
];

final List<AchievementModel> allAchievements = [
  AchievementModel(
    certificateName: "Researcher Management",
    organizationName: "University of Colorado",
    date: "Nov 2024",
    description:
        "Specialized training in managing research lifecycles, ensuring data integrity, and leading collaborative research teams.",
    skills: ["Research Ops", "Team Leadership", "Data Integrity"],
  ),
  AchievementModel(
    certificateName: "English Score Certificate",
    organizationName: "British Council",
    date: "May 2024",
    description:
        "Internationally recognized certification validating professional proficiency in English reading, writing, listening, and speaking.",
    skills: ["C1 Advanced", "Business English", "Communication"],
  ),
];
