import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/cors_utils.dart';

/// Data model for Steam game
class SteamGame {
  final String appId;
  final String name;
  final double playtimeTotal;
  final double? playtime2Weeks;
  final String imageUrl;

  SteamGame({
    required this.appId,
    required this.name,
    required this.playtimeTotal,
    this.playtime2Weeks,
    required this.imageUrl,
  });
}

/// Data model for Steam profile
class SteamProfile {
  final String steamId;
  final String personaName;
  final String onlineState; // 'online', 'offline', 'in-game'
  final String stateMessage;
  final String avatarUrl;
  final String realName;
  final String memberSince;
  final String summary;
  final List<SteamGame> games;
  final double totalPlaytime;
  final String? currentGameAppId;
  final String? currentGameName;

  SteamProfile({
    required this.steamId,
    required this.personaName,
    required this.onlineState,
    required this.stateMessage,
    required this.avatarUrl,
    required this.realName,
    required this.memberSince,
    required this.summary,
    this.games = const [],
    this.totalPlaytime = 0,
    this.currentGameAppId,
    this.currentGameName,
  });
}

/// Data model for MAL favorite anime
class MalFavoriteAnime {
  final int malId;
  final String title;
  final String imageUrl;
  final String type;
  final int startYear;

  MalFavoriteAnime({
    required this.malId,
    required this.title,
    required this.imageUrl,
    required this.type,
    required this.startYear,
  });
}

/// Data model for MAL favorite character
class MalFavoriteCharacter {
  final int malId;
  final String name;
  final String imageUrl;

  MalFavoriteCharacter({
    required this.malId,
    required this.name,
    required this.imageUrl,
  });
}

/// Data model for MAL profile
class MalProfile {
  final String username;
  final String? imageUrl;
  final String joinedDate;
  final int animeCompleted;
  final int animeWatching;
  final int animePlanToWatch;
  final int totalEntries;
  final double meanScore;
  final double daysWatched;
  final int episodesWatched;
  final List<MalFavoriteAnime> favoriteAnime;
  final List<MalFavoriteCharacter> favoriteCharacters;

  MalProfile({
    required this.username,
    this.imageUrl,
    required this.joinedDate,
    required this.animeCompleted,
    required this.animeWatching,
    required this.animePlanToWatch,
    required this.totalEntries,
    required this.meanScore,
    required this.daysWatched,
    required this.episodesWatched,
    required this.favoriteAnime,
    required this.favoriteCharacters,
  });
}

/// Combined showcase data
class ShowcaseData {
  final SteamProfile? steam;
  final MalProfile? mal;
  final DateTime fetchedAt;

  ShowcaseData({this.steam, this.mal, DateTime? fetchedAt})
      : fetchedAt = fetchedAt ?? DateTime.now();
}

/// Service that fetches Steam + MAL data with aggressive caching
/// and robust proxy rotation for CORS bypass
class ShowcaseScraper {
  static const String _steamId = '76561198881808539';
  static const String _malUsername = 'Ambakushin';

  // Cache: only fetch once per session (60 min TTL)
  static ShowcaseData? _cache;
  static DateTime? _lastFetch;
  static const Duration _cacheDuration = Duration(minutes: 60);
  static bool _isFetching = false;

  /// Main entry point - returns cached data or fetches fresh
  static Future<ShowcaseData> fetchShowcase() async {
    if (_cache != null && _lastFetch != null) {
      final age = DateTime.now().difference(_lastFetch!);
      if (age < _cacheDuration) {
        return _cache!;
      }
    }

    if (_isFetching) {
      while (_isFetching) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
      return _cache ?? ShowcaseData();
    }

    _isFetching = true;

    try {
      final results = await Future.wait([
        _fetchSteamProfile(),
        _fetchMalProfile(),
      ]);

      _cache = ShowcaseData(
        steam: results[0] as SteamProfile?,
        mal: results[1] as MalProfile?,
      );
      _lastFetch = DateTime.now();
    } catch (e) {
      print('ShowcaseScraper error: $e');
      _cache ??= ShowcaseData();
    } finally {
      _isFetching = false;
    }

    return _cache!;
  }

  /// Helper for robust fetching with proxy rotation
  static Future<String?> _fetchWithFallback(String rawUrl) async {
    for (final proxyBase in CorsUtils.dataProxies) {
      try {
        final fullUrl = '$proxyBase${Uri.encodeComponent(rawUrl)}';
        final response = await http.get(Uri.parse(fullUrl))
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final jsonBody = jsonDecode(response.body);
          final content = jsonBody['contents'] ?? jsonBody['data'] ?? response.body;
          if (content is String && content.isNotEmpty) return content;
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Fetch Steam profile via public XML or fallback to HTML Scraping
  static Future<SteamProfile?> _fetchSteamProfile() async {
    try {
      final rawUrl = 'https://steamcommunity.com/profiles/$_steamId/?xml=1';
      final body = await _fetchWithFallback(rawUrl) ?? '';
      
      if (body.isEmpty) return null;

      if (body.contains('<profile>')) {
        String extractTag(String tag) {
          final regex = RegExp('<$tag>(?:<!\\[CDATA\\[)?(.*?)(?:\\]\\]>)?</$tag>', dotAll: true);
          final match = regex.firstMatch(body);
          return match?.group(1)?.trim() ?? '';
        }

        final gamesData = await _fetchSteamGames();

        return SteamProfile(
          steamId: extractTag('steamID64'),
          personaName: extractTag('steamID'),
          onlineState: extractTag('onlineState'),
          stateMessage: extractTag('stateMessage'),
          avatarUrl: extractTag('avatarFull'),
          realName: extractTag('realname'),
          memberSince: extractTag('memberSince'),
          summary: extractTag('summary').replaceAll(RegExp('<[^>]*>'), ''),
          games: gamesData.games,
          totalPlaytime: gamesData.totalPlaytime,
        );
      } 
      else if (body.contains('actual_persona_name')) {
        String scrape(String regexStr) {
          final regex = RegExp(regexStr, dotAll: true);
          final match = regex.firstMatch(body);
          return match?.group(1)?.trim() ?? '';
        }

        final personaName = scrape(r'actual_persona_name">(.*?)</span>');
        final status = scrape(r'profile_in_game_header">(.*?)</div>');
        final avatar = scrape(r'playerAvatarAutoSizeInner"><img src="(.*?)"');
        final realName = scrape(r'header_realname">(.*?)</span>');
        final summary = scrape(r'profile_summary">(.*?)</div>').replaceAll(RegExp('<[^>]*>'), '');

        String? currentGameName;
        String? currentGameAppId;
        
        if (status.toLowerCase().contains('in-game')) {
           currentGameName = scrape(r'profile_in_game_name">(.*?)</div>');
           final appIdMatch = RegExp(r'steam://run/(\d+)').firstMatch(body);
           currentGameAppId = appIdMatch?.group(1);
        }

        if (personaName.isEmpty) return null;

        final gamesData = await _fetchSteamGames();

        return SteamProfile(
          steamId: _steamId,
          personaName: personaName,
          onlineState: status.toLowerCase().contains('in-game') ? 'in-game' : 
                       (status.toLowerCase().contains('online') || status.toLowerCase().contains('playing')) ? 'online' : 'offline',
          stateMessage: status.isEmpty ? 'Offline' : status,
          avatarUrl: avatar,
          realName: realName,
          memberSince: 'N/A',
          summary: summary,
          games: gamesData.games,
          totalPlaytime: gamesData.totalPlaytime,
          currentGameAppId: currentGameAppId,
          currentGameName: currentGameName,
        );
      }
      return null;
    } catch (e) {
      print('Steam fetch error: $e');
      return null;
    }
  }

  static Future<({List<SteamGame> games, double totalPlaytime})> _fetchSteamGames() async {
    try {
      final recentUrl = 'https://steamcommunity.com/profiles/$_steamId/games/?tab=recent';
      final body = await _fetchWithFallback(recentUrl) ?? '';
      
      if (body.isEmpty) return (games: <SteamGame>[], totalPlaytime: 0.0);

      final List<SteamGame> games = [];
      double totalTime = 0;

      final rgGamesMatch = RegExp(r'var rgGames = (\[.*?\]);', dotAll: true).firstMatch(body);
      
      if (rgGamesMatch != null) {
        final gamesJson = rgGamesMatch.group(1);
        if (gamesJson != null) {
          final List<dynamic> gamesList = jsonDecode(gamesJson);
          for (var g in gamesList) {
            final double playtime = double.tryParse(g['hours_forever']?.toString() ?? '0') ?? 0.0;
            totalTime += playtime;
            
            games.add(SteamGame(
              appId: g['appid'].toString(),
              name: g['name'] ?? 'Unknown Game',
              playtimeTotal: playtime,
              playtime2Weeks: double.tryParse(g['hours']?.toString() ?? '0'),
              imageUrl: 'https://cdn.cloudflare.steamstatic.com/steam/apps/${g['appid']}/header.jpg',
            ));
          }
        }
      } else {
        final gameRegex = RegExp(r'game_(\d+)">.*?gameListRowItemName">(.*?)<.*?hours_forever">(.*?) hrs', dotAll: true);
        final matches = gameRegex.allMatches(body);
        
        for (var m in matches) {
          final appId = m.group(1) ?? '';
          final name = m.group(2) ?? '';
          final playtime = double.tryParse(m.group(3)?.replaceAll(',', '') ?? '0') ?? 0.0;
          totalTime += playtime;
          
          games.add(SteamGame(
            appId: appId,
            name: name,
            playtimeTotal: playtime,
            imageUrl: 'https://cdn.cloudflare.steamstatic.com/steam/apps/$appId/header.jpg',
          ));
        }
      }

      games.sort((a,b) => b.playtimeTotal.compareTo(a.playtimeTotal));
      return (games: games, totalPlaytime: totalTime);
    } catch (e) {
      print('Steam games fetch error: $e');
      return (games: <SteamGame>[], totalPlaytime: 0.0);
    }
  }

  static Future<MalProfile?> _fetchMalProfile() async {
    try {
      final url = 'https://api.jikan.moe/v4/users/$_malUsername/full';
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      final data = json['data'];
      if (data == null) return null;

      final stats = data['statistics']?['anime'];
      final favorites = data['favorites'];

      final List<MalFavoriteAnime> favAnime = [];
      if (favorites?['anime'] != null) {
        for (var a in favorites['anime']) {
          favAnime.add(MalFavoriteAnime(
            malId: a['mal_id'] ?? 0,
            title: a['title'] ?? '',
            imageUrl: a['images']?['jpg']?['image_url'] ?? '',
            type: a['type'] ?? '',
            startYear: a['start_year'] ?? 0,
          ));
        }
      }

      final List<MalFavoriteCharacter> favChars = [];
      if (favorites?['characters'] != null) {
        for (var c in favorites['characters']) {
          favChars.add(MalFavoriteCharacter(
            malId: c['mal_id'] ?? 0,
            name: c['name'] ?? '',
            imageUrl: c['images']?['jpg']?['image_url'] ?? '',
          ));
        }
      }

      final joinedRaw = data['joined'] ?? '';
      String joinedFormatted = '';
      if (joinedRaw.isNotEmpty) {
        try {
          final dt = DateTime.parse(joinedRaw);
          joinedFormatted = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        } catch (_) {
          joinedFormatted = joinedRaw;
        }
      }

      return MalProfile(
        username: data['username'] ?? _malUsername,
        imageUrl: data['images']?['jpg']?['image_url'],
        joinedDate: joinedFormatted,
        animeCompleted: stats?['completed'] ?? 0,
        animeWatching: stats?['watching'] ?? 0,
        animePlanToWatch: stats?['plan_to_watch'] ?? 0,
        totalEntries: stats?['total_entries'] ?? 0,
        meanScore: (stats?['mean_score'] ?? 0).toDouble(),
        daysWatched: (stats?['days_watched'] ?? 0).toDouble(),
        episodesWatched: stats?['episodes_watched'] ?? 0,
        favoriteAnime: favAnime,
        favoriteCharacters: favChars,
      );
    } catch (e) {
      print('MAL fetch error: $e');
      return null;
    }
  }
}
