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
    shortDescription: 'Interactive terminal-based portfolio styled as a Linux desktop.',
    description:
        'A personal portfolio website built with Flutter Web, designed to look and feel like a Linux desktop environment. Features a working terminal emulator, draggable windows, mini-games, and a built-in PDF resume generator with multiple themes.',
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
    shortDescription: 'Health & nutrition tracking app with gamification elements.',
    description:
        'A diet and health tracking Android app that adds RPG-style progression to encourage healthy habits. Built with Kotlin for the frontend and Laravel + PostgreSQL for the backend API.',
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
    shortDescription: 'Employee attendance and work management app.',
    description:
        'An Android app for managing employee attendance via QR code scanning, with features for overtime tracking, business trip logging, and leave requests. Built with Kotlin and connected to a Laravel backend.',
    iconUrl: 'https://cdn-icons-png.flaticon.com/512/3062/3062634.png',
    bannerUrl:
        'https://images.weserv.nl/?url=https://images.unsplash.com/photo-1497215728101-856f4ea42174?q=80&w=2070&auto=format&fit=crop',
    screenshots: [],
    version: '1.2.0',
    rating: 4.5,
    downloadSize: '12 MB',
    techStack: ['Kotlin', 'Laravel', 'PostgreSQL', 'QR Code'],
    completionDate: '2024',
    repoUrl: 'https://github.com/Windstrom5/WorkHubs',
    primaryLanguage: 'Kotlin',
    platform: 'Android',
    status: ProjectStatus.production,
  ),
  ProjectModel(
    id: 'Go-Fit-android',
    title: 'Go-Fit',
    shortDescription: 'Gym management app for class booking and member tracking.',
    description:
        'A gym management system with an Android app (Kotlin) for members and a Vue.js web admin panel. Supports class scheduling, instructor assignment, and member activity tracking, powered by a Laravel backend.',
    iconUrl:
        'https://raw.githubusercontent.com/Windstrom5/Go-Fit-android/master/app/src/main/res/drawable/logo.png',
    bannerUrl:
        'https://images.weserv.nl/?url=https://opengraph.githubassets.com/1/Windstrom5/Go-Fit-android',
    screenshots: [],
    version: '2.1.0',
    rating: 4.8,
    downloadSize: '15 MB',
    techStack: ['Kotlin', 'Laravel', 'Vue.js', 'REST API'],
    completionDate: '2023 - 2024',
    repoUrl: 'https://github.com/Windstrom5/Go-Fit-android',
    primaryLanguage: 'Kotlin',
    platform: 'Android',
    status: ProjectStatus.production,
  ),
  ProjectModel(
    id: 'karaoke-app',
    title: 'Karaoke AI',
    shortDescription: 'Karaoke app with AI-based vocal separation and lyrics generation.',
    description:
        'A multiplatform karaoke app (Compose) that uses Python ML models (Demucs) to separate vocals from instrumentals and Whisper for automatic lyric generation. Currently in early development.',
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
    shortDescription: 'UE5 Roguelike game with D&D-inspired mechanics.',
    description:
        'A Roguelike game built in Unreal Engine 5 with tile-based movement, dice-rolling mechanics inspired by Dungeons & Dragons, and procedurally generated levels. Currently a work in progress.',
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
    shortDescription: 'Android app showcasing Japanese tourism destinations.',
    description:
        'An Android app built with Kotlin that presents information about popular Japanese travel destinations. Focused on clean navigation and content presentation.',
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
    shortDescription: 'Auto-updates GitHub profile with Steam gaming stats.',
    description:
        'A small Node.js tool that uses GitHub Actions to automatically fetch Steam playtime data and display it on a GitHub profile README. Runs on a schedule via GitHub Actions.',
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
