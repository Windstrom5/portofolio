import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DiscordActivity {
  final String? gameName;
  final String? details;
  final String? state;
  final String? largeImage;
  final int? startTimestamp;
  final String discordStatus; // online, idle, dnd, offline

  DiscordActivity({
    this.gameName,
    this.details,
    this.state,
    this.largeImage,
    this.startTimestamp,
    required this.discordStatus,
  });

  factory DiscordActivity.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final activities = data['activities'] as List<dynamic>?;

    // Filter for real game activities (type 0)
    final game = activities?.firstWhere(
      (a) => a['type'] == 0,
      orElse: () => null,
    );

    String? largeImg;
    if (game != null &&
        game['assets'] != null &&
        game['assets']['large_image'] != null) {
      String assetId = game['assets']['large_image'];
      if (assetId.startsWith('mp:external')) {
        largeImg =
            "https://images.weserv.nl/?url=${assetId.split('https/').last}";
      } else {
        largeImg =
            "https://cdn.discordapp.com/app-assets/${game['application_id']}/$assetId.png";
      }
    }

    return DiscordActivity(
      gameName: game?['name'],
      details: game?['details'],
      state: game?['state'],
      largeImage: largeImg,
      startTimestamp: game?['timestamps']?['start'],
      discordStatus: data['discord_status'] ?? 'offline',
    );
  }

  bool get isPlaying => gameName != null;
}

class DiscordService {
  static const String _userId = '411135817449340929';
  static const String _apiUrl = 'https://api.lanyard.rest/v1/users/$_userId';

  final _activityController = StreamController<DiscordActivity>.broadcast();
  Stream<DiscordActivity> get activityStream => _activityController.stream;

  Timer? _timer;

  void start() {
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _fetch());
  }

  void stop() {
    _timer?.cancel();
  }

  Future<void> _fetch() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      print(
          'DiscordService: Fetching status for user $_userId... Code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final activity = DiscordActivity.fromJson(jsonDecode(response.body));
        print(
            'DiscordService: Activity updated. Status: ${activity.discordStatus}, Playing: ${activity.gameName}');
        _activityController.add(activity);
      } else {
        print('DiscordService: Failed to fetch data. Body: ${response.body}');
      }
    } catch (e) {
      print('DiscordService Error: $e');
    }
  }

  void dispose() {
    stop();
    _activityController.close();
  }
}
