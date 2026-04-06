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
    shortDescription: 'Immersive terminal-based portfolio simulating a high-tech OS environment.',
    description:
        'A sophisticated, interactive portfolio system featuring a custom terminal emulator, window management, and real-time system monitoring. Built with Flutter Web and WebAssembly, it includes an integrated PDF engine for dynamic resume generation with customizable themes.',
    iconUrl: 'https://cdn-icons-png.flaticon.com/512/1005/1005141.png',
    bannerUrl:
        'https://images.weserv.nl/?url=https://opengraph.githubassets.com/1/Windstrom5/portofolio',
    screenshots: [],
    version: '3.5.0',
    rating: 5.0,
    downloadSize: '18 MB',
    techStack: ['Flutter Web', 'WebAssembly', 'PDF Engine', 'Custom Animations'],
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
    shortDescription: 'Gamified digital health & nutrition tracking ecosystem.',
    description:
        'Revolutionizing health tracking by integrating RPG-style progression and behavioral gamification. Features a high-integrity backend powered by Laravel and a specialized PostgreSQL schema optimized for health analytics and trend reporting.',
    iconUrl: 'https://cdn-icons-png.flaticon.com/512/2738/2738650.png',
    bannerUrl:
        'https://images.weserv.nl/?url=https://opengraph.githubassets.com/1/Windstrom5/Diet_Gamification',
    screenshots: [],
    version: '1.1.0',
    rating: 4.6,
    downloadSize: '20 MB',
    techStack: ['Kotlin', 'Laravel', 'PostgreSQL', 'Data Analytics'],
    completionDate: '2025',
    repoUrl: 'https://github.com/Windstrom5/Diet_Gamification',
    primaryLanguage: 'Kotlin',
    platform: 'Android',
    status: ProjectStatus.production,
  ),
  ProjectModel(
    id: 'WorkHubs',
    title: 'WorkHubs',
    shortDescription: 'Enterprise-grade employee productivity and attendance management.',
    description:
        'A comprehensive workforce management suite featuring secure QR-based attendance, overtime orchestration, and official duty tracking. Engineered with a focus on administrative transparency and operational efficiency.',
    iconUrl: 'https://cdn-icons-png.flaticon.com/512/3062/3062634.png',
    bannerUrl:
        'https://images.weserv.nl/?url=https://images.unsplash.com/photo-1497215728101-856f4ea42174?q=80&w=2070&auto=format&fit=crop',
    screenshots: [],
    version: '1.2.0',
    rating: 4.5,
    downloadSize: '12 MB',
    techStack: ['Kotlin', 'Laravel', 'PostgreSQL', 'QR Security'],
    completionDate: '2024',
    repoUrl: 'https://github.com/Windstrom5/WorkHubs',
    primaryLanguage: 'Kotlin',
    platform: 'Android',
    status: ProjectStatus.production,
  ),
  ProjectModel(
    id: 'Go-Fit-android',
    title: 'Go-Fit',
    shortDescription: 'Full-spectrum gym management and member engagement platform.',
    description:
        'An all-in-one operations suite for fitness centers, facilitating class scheduling, instructor management, and member progress tracking. Includes a high-performance Web Admin built with Vue.js for enterprise-level oversight.',
    iconUrl:
        'https://raw.githubusercontent.com/Windstrom5/Go-Fit-android/master/app/src/main/res/drawable/logo.png',
    bannerUrl:
        'https://images.weserv.nl/?url=https://opengraph.githubassets.com/1/Windstrom5/Go-Fit-android',
    screenshots: [],
    version: '2.1.0',
    rating: 4.8,
    downloadSize: '15 MB',
    techStack: ['Kotlin', 'Laravel', 'Vue.js', 'Enterprise Architecture'],
    completionDate: '2023 - 2024',
    repoUrl: 'https://github.com/Windstrom5/Go-Fit-android',
    primaryLanguage: 'Kotlin',
    platform: 'Android',
    status: ProjectStatus.production,
  ),
  ProjectModel(
    id: 'karaoke-app',
    title: 'Karaoke AI',
    shortDescription: 'Neural-assisted vocal separation and real-time lyric synthesis.',
    description:
        'Cutting-edge research into AI-powered audio processing. Implements high-fidelity vocal/instrument separation via Python-based ML models (Demucs/Torch) and automated Whisper-driven lyric generation and translation.',
    iconUrl: 'https://cdn-icons-png.flaticon.com/512/3059/3059518.png',
    bannerUrl:
        'https://images.weserv.nl/?url=https://opengraph.githubassets.com/1/Windstrom5/portofolio',
    screenshots: [],
    version: '0.1.0-WIP',
    rating: 4.7,
    downloadSize: '50 MB',
    techStack: [
      'Compose Multiplatform',
      'Python AI',
      'Machine Learning',
      'Audio Processing'
    ],
    completionDate: 'In Development',
    repoUrl: null,
    primaryLanguage: 'Kotlin',
    platform: 'Multiplatform',
    status: ProjectStatus.development,
    estimatedCompletion: 'Q4 2025',
  ),
  ProjectModel(
    id: 'Fatebound-Quest',
    title: 'Fatebound Quest',
    shortDescription: 'Advanced UE5 Roguelike featuring data-driven RPG mechanics.',
    description:
        'A next-generation Roguelike experience developed in Unreal Engine 5. Focuses on procedural content generation, complex tile-based systems, and a high-fidelity dice-rolling engine inspired by classic tabletop mechanics.',
    iconUrl: 'https://cdn-icons-png.flaticon.com/512/188/188987.png',
    bannerUrl:
        'https://images.weserv.nl/?url=https://opengraph.githubassets.com/1/Windstrom5/DungeonQuest',
    screenshots: [],
    version: '0.5.0-WIP',
    rating: 5.0,
    downloadSize: '2.1 GB',
    techStack: ['Unreal Engine 5', 'C++', 'Procedural Generation', 'Blueprints'],
    completionDate: 'In Development',
    repoUrl: 'https://github.com/Windstrom5/Unreal-Engine-Pokedex',
    primaryLanguage: 'C++',
    platform: 'PC',
    status: ProjectStatus.development,
    estimatedCompletion: '2026',
  ),
  ProjectModel(
    id: 'nihonGO',
    title: 'nihonGO',
    shortDescription: 'Premium Japanese tourism and destination intelligence platform.',
    description:
        'A modern Android application providing meticulously curated information on Japanese tourism. Prioritizes UX-focused navigation and rich content presentation for seamless travel discovery.',
    iconUrl: 'https://cdn-icons-png.flaticon.com/512/197/197604.png',
    bannerUrl:
        'https://images.weserv.nl/?url=https://opengraph.githubassets.com/1/Windstrom5/nihonGO',
    screenshots: [],
    version: '2.0.0',
    rating: 4.9,
    downloadSize: '30 MB',
    techStack: ['Android', 'Kotlin', 'UX/UI Design'],
    completionDate: '2023',
    repoUrl: 'https://github.com/Windstrom5/nihonGO',
    primaryLanguage: 'Kotlin',
    platform: 'Android',
    status: ProjectStatus.legacy,
  ),
  ProjectModel(
    id: 'steam-box',
    title: 'Steam Box',
    shortDescription: 'Automated dynamic metric orchestration for GitHub ecosystems.',
    description:
        'A serverless automation tool that synchronizes real-time Steam gaming metrics with GitHub profile metadata, utilizing high-availability Node.js environments and GitHub Actions.',
    iconUrl: 'https://cdn-icons-png.flaticon.com/512/888/888868.png',
    bannerUrl:
        'https://images.weserv.nl/?url=https://opengraph.githubassets.com/1/Windstrom5/steam-box',
    screenshots: [],
    version: '1.0.0',
    rating: 4.8,
    downloadSize: 'N/A',
    techStack: ['GitHub Actions', 'Node.js', 'API Integration'],
    completionDate: '2023',
    repoUrl: 'https://github.com/Windstrom5/steam-box',
    primaryLanguage: 'JavaScript',
    platform: 'GitHub Actions',
    status: ProjectStatus.production,
  ),
];
