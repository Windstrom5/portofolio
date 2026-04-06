import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:universal_html/parsing.dart';

class OfficialLeagueScraper {
  static const List<String> proxies = [
    'https://api.codetabs.com/v1/proxy?quest=',
    'https://api.allorigins.win/raw?url=',
  ];

  /// Premier League Assets via Pulselive API
  static Future<Map<String, String>> fetchPremierLeagueLogos() async {
    final Map<String, String> logos = {};
    const targetUrl = 'https://sdp-prem-prod.premier-league-prod.pulselive.com/api/v5/competitions/8/seasons/2025/standings?live=false';

    try {
      final response = await http.get(Uri.parse(targetUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tables = data['tables'] as List;
        if (tables.isNotEmpty) {
          final entries = tables[0]['entries'] as List;
          for (var entry in entries) {
            final team = entry['team'];
            final name = team['name'] as String;
            final id = team['id'].toString();
            // Official high-res SVG badges
            logos[name] = 'https://resources.premierleague.com/premierleague25/badges/$id.svg';
          }
        }
      }
    } catch (e) {
      print("Error fetching PL logos from API: $e");
    }
    return logos;
  }

  static Future<String?> fetchPremierLeaguePlayerPhoto(String playerName) async {
    // For PL, we can try to guess the ID or use the search API if we find one.
    // However, the predictable pattern is: https://resources.premierleague.com/premierleague/photos/players/250x250/p{ID}.png
    // We can still use the search scrape as a fallback or if we can't find a JSON search endpoint.
    final query = Uri.encodeComponent(playerName);
    const searchUrl = 'https://www.premierleague.com/players?search=';
    
    for (var proxy in proxies) {
      try {
        final response = await http.get(Uri.parse('$proxy$searchUrl$query')).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final document = parseHtmlDocument(response.body);
          final img = document.querySelector('.player-index__photo');
          if (img != null) {
            final src = img.attributes['src'] ?? "";
            if (src.isNotEmpty) {
              final fullSrc = src.startsWith('//') ? 'https:$src' : src;
              return fullSrc.replaceFirst('40x40', '250x250');
            }
          }
        }
      } catch (e) {}
    }
    return null;
  }

  /// La Liga Assets via APIM
  static Future<Map<String, String>> fetchLaLigaLogos() async {
    final Map<String, String> logos = {};
    // Matchday 1 is fine for just getting team names and logos
    const targetUrl = 'https://apim.laliga.com/webview/api/web/subscriptions/laliga-easports-2025/standing?week=1&contentLanguage=en&subscription-key=ee7fcd5c543f4485ba2a48856fc7ece9';

    try {
      final response = await http.get(Uri.parse(targetUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final standings = data['standings'] as List;
        for (var entry in standings) {
          final team = entry['team'];
          final name = team['name'] as String;
          final shield = team['shield'];
          if (shield != null && shield['url'] != null) {
            logos[name] = shield['url'] as String;
          }
        }
      }
    } catch (e) {
      print("Error fetching La Liga logos from API: $e");
    }
    return logos;
  }

  static Future<String?> fetchLaLigaPlayerPhoto(String playerName) async {
    // La Liga Rankings API contains player photos
    const targetUrl = 'https://apim.laliga.com/public-service/api/v1/subscriptions/laliga-easports-2025/players/rankings?limit=50&contentLanguage=en&subscription-key=c13c3a8e2f6b46da9c5c425cf61fab3e';

    try {
      final response = await http.get(Uri.parse(targetUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rankings = data['rankings'] as List;
        for (var player in rankings) {
          final person = player['player']['person'];
          final fullName = "${person['name']} ${person['nickname'] ?? person['last_name']}";
          if (fullName.toLowerCase().contains(playerName.toLowerCase())) {
            final photos = person['photos'];
            return photos['512x556'] ?? photos['256x278'] ?? photos['128x139'];
          }
        }
      }
    } catch (e) {
      print("Error fetching La Liga player photo: $e");
    }
    return null;
  }

  /// Generic Assets fetcher
  static Future<Map<String, String>> fetchLeagueLogos(String leagueName) async {
    if (leagueName.toUpperCase() == "PREMIER LEAGUE") {
      return await fetchPremierLeagueLogos();
    } else if (leagueName.toUpperCase() == "LA LIGA") {
      return await fetchLaLigaLogos();
    }
    return {};
  }
}
