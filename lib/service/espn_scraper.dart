import 'package:http/http.dart' as http;
import 'package:universal_html/parsing.dart';

class PlayerStat {
  final String rank;
  final String name;
  final String team;
  final String stat; // Goals or Assists
  String imageUrl;

  PlayerStat({
    required this.rank,
    required this.name,
    required this.team,
    required this.stat,
    required this.imageUrl,
  });
}

class TeamStanding {
  final int pos;
  final String name;
  final int p;
  final int pts;
  final String zone;
  String logoUrl;

  TeamStanding({
    required this.pos,
    required this.name,
    required this.p,
    required this.pts,
    required this.zone,
    required this.logoUrl,
  });
}

class ESPNScraper {
  static const Map<String, String> leagueIds = {
    "PREMIER LEAGUE": "ENG.1",
    "LA LIGA": "ESP.1",
    "SERIE A": "ITA.1",
    "BUNDESLIGA": "GER.1",
  };

  static const List<String> proxies = [
    'https://api.codetabs.com/v1/proxy?quest=',
    'https://api.allorigins.win/raw?url=',
  ];

  static Future<Map<String, List<PlayerStat>>> fetchStats(String leagueName) async {
    final leagueId = leagueIds[leagueName];
    if (leagueId == null) return {"scorers": [], "assists": []};

    final targetUrl = 'https://www.espn.com/soccer/stats/_/league/$leagueId/view/scoring';
    
    for (var proxy in proxies) {
      try {
        final response = await http.get(Uri.parse('$proxy$targetUrl')).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final document = parseHtmlDocument(response.body);
          final tables = document.querySelectorAll('.Table');
          
          List<PlayerStat> scorers = [];
          List<PlayerStat> assists = [];

          if (tables.isNotEmpty) {
            scorers = _parseTable(tables[0]);
          }
          if (tables.length > 1) {
            assists = _parseTable(tables[1]);
          }

          return {
            "scorers": scorers,
            "assists": assists,
          };
        }
      } catch (e) {
        print("Error scraping ESPN Stats with $proxy: $e");
      }
    }
    
    return {"scorers": [], "assists": []};
  }

  static Future<List<TeamStanding>> fetchStandings(String leagueName) async {
    final leagueId = leagueIds[leagueName];
    if (leagueId == null) return [];

    final targetUrl = 'https://www.espn.com/soccer/standings/_/league/$leagueId';
    
    for (var proxy in proxies) {
      try {
        final response = await http.get(Uri.parse('$proxy$targetUrl')).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final document = parseHtmlDocument(response.body);
          
          final nameTable = document.querySelector('.Table--fixed-left');
          final statsTable = document.querySelector('.Table__Scroller');

          if (nameTable != null && statsTable != null) {
            final nameRows = nameTable.querySelectorAll('tbody tr');
            final statsRows = statsTable.querySelectorAll('tbody tr');
            
            final List<TeamStanding> standings = [];
            for (int i = 0; i < nameRows.length && i < statsRows.length; i++) {
              final nameCells = nameRows[i].querySelectorAll('td');
              final statsCells = statsRows[i].querySelectorAll('td');

              if (nameCells.isNotEmpty && statsCells.length >= 8) {
                final teamNameElement = nameCells[0].querySelector('.hide-mobile');
                final logoElement = nameCells[0].querySelector('img');
                
                final String name = teamNameElement?.text?.trim() ?? nameCells[0].text?.trim() ?? "Unknown";
                final String logoUrl = logoElement?.attributes['src'] ?? "";
                final int pos = i + 1; 
                
                standings.add(TeamStanding(
                  pos: pos,
                  name: name,
                  p: int.tryParse(statsCells[0].text?.trim() ?? "0") ?? 0,
                  pts: int.tryParse(statsCells[7].text?.trim() ?? "0") ?? 0,
                  zone: _getZone(pos, leagueId),
                  logoUrl: logoUrl,
                ));
              }
            }
            return standings;
          }
        }
      } catch (e) {
        print("Error scraping ESPN Standings with $proxy: $e");
      }
    }
    return [];
  }

  static String _getZone(int pos, String leagueName) {
    if (leagueName == "PREMIER LEAGUE" || leagueName == "LA LIGA") {
      if (pos <= 4) return "Q"; // Champions League
      if (pos == 5) return "E"; // Europa League
      if (pos >= 18) return "R"; // Relegation
    }
    if (leagueName == "BUNDESLIGA") {
      if (pos <= 4) return "Q";
      if (pos >= 16) return "R";
    }
    if (leagueName == "SERIE A") {
      if (pos <= 4) return "Q";
      if (pos >= 18) return "R";
    }
    return "";
  }

  static List<PlayerStat> _parseTable(var tableElement) {
    final List<PlayerStat> stats = [];
    final rows = tableElement.querySelectorAll('tbody tr');
    
    for (var row in rows) {
      final cells = row.querySelectorAll('td');
      if (cells.length >= 5) {
        final nameCell = cells[1];
        final teamCell = cells[2];
        final statCell = cells[cells.length - 1];

        // Extract player ID from link to get headshot
        // Example: /soccer/player/_/id/253989/erling-haaland
        final link = nameCell.querySelector('a')?.attributes['href'] ?? "";
        String imageUrl = "";
        final regExp = RegExp(r'/id/(\d+)/');
        final match = regExp.firstMatch(link);
        if (match != null) {
          final playerId = match.group(1);
          imageUrl = "https://a.espncdn.com/i/headshots/soccer/players/full/$playerId.png";
        } else {
          // Fallback to silhouette if no ID found
          imageUrl = "https://a.espncdn.com/i/headshots/nophoto.png";
        }

        stats.add(PlayerStat(
          rank: cells[0].text?.trim() ?? "",
          name: nameCell.text?.trim() ?? "Unknown",
          team: teamCell.text?.trim() ?? "",
          stat: statCell.text?.trim() ?? "0",
          imageUrl: imageUrl,
        ));
      }
    }
    return stats;
  }
}

