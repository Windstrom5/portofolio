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
  final String? attachmentPath;

  AchievementModel({
    required this.certificateName,
    required this.organizationName,
    required this.date,
    required this.description,
    required this.skills,
    this.attachmentPath,
  });
}

final List<EducationModel> allEducation = [
  EducationModel(
    schoolName: "Universitas Atma Jaya Yogyakarta",
    location: "Yogyakarta, Indonesia",
    years: "2020 - 2025",
    degreeType: "S1 - TEKNIK INFORMATIKA (GPA: 3.54)",
    description:
        "Bachelor's degree in Informatics Engineering from Fakultas Teknik Industri. Focused on software development, database systems, and practical application building.",
    learnings:
        "- Software Engineering & Development.\n- Web & Mobile Application Development.\n- Database Management (SQL).\n- Object-Oriented Programming.\n- Software Project Management.",
    skills: [
      "Software Engineering",
      "Web Development",
      "Mobile Development",
      "Database",
      "OOP",
      "Project Management"
    ],
  ),
  EducationModel(
    schoolName: "SMA Negeri 8 Samarinda",
    location: "Samarinda, Indonesia",
    years: "2017 - 2020",
    degreeType: "HIGH SCHOOL GRADUATE (IPA)",
    description:
        "High school education focusing on comprehensive academic development and preparing students for higher education in technology and sciences.",
    learnings:
        "- Advanced Mathematics & Physics.\n- Social & Organizational leadership.\n- Scientific Research Foundations.",
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
        "- Basic Sciences & Mathematics.\n- Foundational Computer Literacy.\n- Extracurricular leadership as class representative.",
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
    attachmentPath: "assets/Coursera_Researcher_Management.jpg",
  ),
  AchievementModel(
    certificateName: "English Score Certificate",
    organizationName: "British Council",
    date: "May 2024",
    description:
        "Internationally recognized English test from the British Council, assessing reading, writing, listening, and speaking skills.",
    skills: ["English Proficiency", "Communication"],
    attachmentPath: "assets/EnglishScore.jpg",
  ),
  AchievementModel(
    certificateName: "Coding Camp Certificate of Attendance",
    organizationName: "RevoU",
    date: "Jun 2026",
    description:
        "Completed a 1-week Coding Camp by RevoU covering the fundamentals of HTML, CSS, and JavaScript. Gained hands-on experience in building basic web pages, applying responsive styling, and implementing simple interactive web features.",
    skills: [
      "HTML",
      "CSS",
      "JavaScript",
      "Web Development",
      "Responsive Design"
    ],
    attachmentPath: "assets/revou_Certificate.jpg",
  ),
  AchievementModel(
    certificateName: "TOEFL ITP Certificate",
    organizationName: "IIEF",
    date: "Apr 2026",
    description:
        "Achieved a total score of 517 (Listening: 58, Structure: 44, Reading: 53), validating professional proficiency in English listening, structure, and reading comprehension.",
    skills: ["English Proficiency", "Listening", "Grammar", "Reading"],
    attachmentPath: "assets/TOEFL_Angga.pdf",
  ),
  AchievementModel(
    certificateName: "Internship Completion Certificate",
    organizationName: "MagangHub",
    date: "Apr 2026",
    description:
        "Official internship completion certificate issued through MagangHub for the Backend Programmer internship at RSU Mitra Paramedika Yogyakarta, validating hands-on experience in hospital information system development.",
    skills: ["Backend Development", "Laravel", "SIMRS", "Internship"],
    attachmentPath: "assets/sertifikat_3262617f-fef8-41f0-b8b9-9341452acf8d.pdf",
  ),
];
