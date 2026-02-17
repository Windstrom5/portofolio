enum ProjectStatus { production, development, legacy }

class ProjectModel {
  final String id;
  final String title;
  final String description;
  final String shortDescription;
  final String iconUrl;
  final String bannerUrl;
  final List<String> screenshots;
  final String version;
  final double rating;
  final String downloadSize;
  final List<String> techStack;
  final String? demoUrl;
  final String? repoUrl;
  final String completionDate;
  final bool isInstalled;
  final String primaryLanguage;
  final String platform;
  final ProjectStatus status;
  final String? estimatedCompletion;

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.shortDescription,
    required this.iconUrl,
    required this.bannerUrl,
    required this.screenshots,
    required this.version,
    required this.rating,
    required this.downloadSize,
    required this.techStack,
    required this.completionDate,
    required this.primaryLanguage,
    required this.platform,
    required this.status,
    this.estimatedCompletion,
    this.demoUrl,
    this.repoUrl,
    this.isInstalled = false,
  });
}

// Initial Data
final List<ProjectModel> allProjects = [
  ProjectModel(
    id: 'portofolio',
    title: 'Portofolio OS',
    shortDescription: 'Interactive portfolio simulating a hacker/retro OS.',
    description:
        'A unique, interactive portfolio website capable of running mini-games, simulating an OS, and showcasing projects with flair. Built with Flutter Web and Web Assembly. Features a built-in resume exporter to PDF using custom templates.',
    iconUrl: 'https://cdn-icons-png.flaticon.com/512/1005/1005141.png',
    bannerUrl:
        'https://images.weserv.nl/?url=https://opengraph.githubassets.com/1/Windstrom5/portofolio',
    screenshots: [],
    version: '3.5.0',
    rating: 5.0,
    downloadSize: '18 MB',
    techStack: ['Flutter Web', 'Animations', 'PDF Export'],
    completionDate: '2025',
    repoUrl: 'https://github.com/Windstrom5/portofolio',
    isInstalled: true,
    primaryLanguage: 'Dart',
    platform: 'Web',
    status: ProjectStatus.production,
  ),
  ProjectModel(
    id: 'Diet_Gamification',
    title: 'Diet Gamifikasi',
    shortDescription: 'Gamified fitness & diet tracker journey.',
    description:
        'Transform your healthy lifestyle into a fun RPG with streaks and challenges. Authentication and API built with Laravel for secure data flows, and specialized PostgreSQL schema for analytics-friendly queries.',
    iconUrl: 'https://cdn-icons-png.flaticon.com/512/2738/2738650.png',
    bannerUrl:
        'https://images.weserv.nl/?url=https://opengraph.githubassets.com/1/Windstrom5/Diet_Gamification',
    screenshots: [],
    version: '1.1.0',
    rating: 4.6,
    downloadSize: '20 MB',
    techStack: ['Kotlin', 'Laravel', 'PostgreSQL'],
    completionDate: '2025',
    repoUrl: 'https://github.com/Windstrom5/Diet_Gamification',
    primaryLanguage: 'Kotlin',
    platform: 'Android',
    status: ProjectStatus.production,
  ),
  ProjectModel(
    id: 'WorkHubs',
    title: 'Workhubs',
    shortDescription: 'Employee activity tracking and daily attendance via QR.',
    description:
        'Enterprise-level employee activity tracking and daily attendance system via QR. Includes overtime and official duty logging with approvals. REST backend built with Laravel and PostgreSQL.',
    iconUrl: 'https://cdn-icons-png.flaticon.com/512/3062/3062634.png',
    bannerUrl:
        'https://images.weserv.nl/?url=https://images.unsplash.com/photo-1497215728101-856f4ea42174?q=80&w=2070&auto=format&fit=crop',
    screenshots: [],
    version: '1.2.0',
    rating: 4.5,
    downloadSize: '12 MB',
    techStack: ['Android', 'QR Attendance', 'Kotlin', 'Laravel'],
    completionDate: '2024',
    repoUrl: 'https://github.com/Windstrom5/WorkHubs',
    primaryLanguage: 'Kotlin',
    platform: 'Android',
    status: ProjectStatus.production,
  ),
  ProjectModel(
    id: 'Go-Fit-android',
    title: 'Go-Fit Android',
    shortDescription: 'Gym operations suite for members and instructors.',
    description:
        'Comprehensive gym operations suite featuring schedule/class management with attendance tracking. Includes a Web admin built with Vue.js for multi-instructor setups.',
    iconUrl:
        'https://raw.githubusercontent.com/Windstrom5/Go-Fit-android/master/app/src/main/res/drawable/logo.png',
    bannerUrl:
        'https://images.weserv.nl/?url=https://opengraph.githubassets.com/1/Windstrom5/Go-Fit-android',
    screenshots: [],
    version: '2.1.0',
    rating: 4.8,
    downloadSize: '15 MB',
    techStack: ['Kotlin', 'Laravel', 'Vue.js'],
    completionDate: '2023 - 2024',
    repoUrl: 'https://github.com/Windstrom5/Go-Fit-android',
    primaryLanguage: 'Kotlin',
    platform: 'Android',
    status: ProjectStatus.production,
  ),
  ProjectModel(
    id: 'karaoke-app',
    title: 'Karaoke App',
    shortDescription:
        'AI-powered vocal separation and lyrics generation. (WIP)',
    description:
        'Work In Progress: Real-time vocal/instrument separation via Python backend (Demucs, MoviePy, Torch). Features AI-powered automatic lyrics generation with Whisper, transliteration, and translation tools.',
    iconUrl: 'https://cdn-icons-png.flaticon.com/512/3059/3059518.png',
    bannerUrl:
        'https://images.weserv.nl/?url=https://opengraph.githubassets.com/1/Windstrom5/portofolio',
    screenshots: [],
    version: '0.1.0-WIP',
    rating: 4.7,
    downloadSize: '50 MB',
    techStack: [
      'Ktor',
      'Compose Multiplatform',
      'AI',
      'Python',
      'Demucs',
      'Whisper'
    ],
    completionDate: 'WIP',
    repoUrl: null, // No public GitHub page yet
    primaryLanguage: 'Kotlin',
    platform: 'Multiplatform',
    status: ProjectStatus.development,
    estimatedCompletion: 'Q4 2025',
  ),
  ProjectModel(
    id: 'Fatebound-Quest',
    title: 'Fatebound Quest',
    shortDescription: 'UE5 Roguelike with RNG Training. (WIP)',
    description:
        'Work In Progress: Tile and dice-based gameplay inspired by D&D mechanics. Features RNG-driven training progression and built in Unreal Engine 5 with data-driven content.',
    iconUrl: 'https://cdn-icons-png.flaticon.com/512/188/188987.png',
    bannerUrl:
        'https://images.weserv.nl/?url=https://opengraph.githubassets.com/1/Windstrom5/DungeonQuest',
    screenshots: [],
    version: '0.5.0-WIP',
    rating: 5.0,
    downloadSize: '2.1 GB',
    techStack: ['UE5', 'Roguelike', 'RNG Training'],
    completionDate: 'WIP',
    repoUrl: 'https://github.com/Windstrom5/Unreal-Engine-Pokedex',
    primaryLanguage: 'C++',
    platform: 'PC',
    status: ProjectStatus.development,
    estimatedCompletion: '2026',
  ),
  ProjectModel(
    id: 'nihonGO',
    title: 'nihonGO',
    shortDescription: 'Information about Japanese tourism destinations.',
    description:
        'Android application providing comprehensive information about Japanese tourism destinations. Focused on content presentation and ease of navigation.',
    iconUrl: 'https://cdn-icons-png.flaticon.com/512/197/197604.png',
    bannerUrl:
        'https://images.weserv.nl/?url=https://opengraph.githubassets.com/1/Windstrom5/nihonGO',
    screenshots: [],
    version: '2.0.0',
    rating: 4.9,
    downloadSize: '30 MB',
    techStack: ['Android', 'Kotlin'],
    completionDate: '2023',
    repoUrl: 'https://github.com/Windstrom5/nihonGO',
    primaryLanguage: 'Kotlin',
    platform: 'Android',
    status: ProjectStatus.legacy,
  ),
  ProjectModel(
    id: 'steam-box',
    title: 'Steam Box',
    shortDescription: 'Dynamic Steam profile README metrics.',
    description:
        'Update your GitHub profile README or pinned gist with your real-time Steam playtime leaderboard metrics.',
    iconUrl: 'https://cdn-icons-png.flaticon.com/512/888/888868.png',
    bannerUrl:
        'https://images.weserv.nl/?url=https://opengraph.githubassets.com/1/Windstrom5/steam-box',
    screenshots: [],
    version: '1.0.0',
    rating: 4.8,
    downloadSize: 'N/A',
    techStack: ['GitHub Actions', 'Node.js'],
    completionDate: '2023',
    repoUrl: 'https://github.com/Windstrom5/steam-box',
    primaryLanguage: 'JavaScript',
    platform: 'GitHub Actions',
    status: ProjectStatus.production,
  ),
];
