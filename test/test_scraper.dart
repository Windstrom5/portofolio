import 'package:project_test/service/official_league_scraper.dart';

void main() async {
  print("--- Testing Official League Scraper ---");
  
  print("Testing Premier League Logos...");
  final plLogos = await OfficialLeagueScraper.fetchPremierLeagueLogos();
  print("Found ${plLogos.length} logos.");
  if (plLogos.isNotEmpty) {
    print("Example logo (Arsenal): ${plLogos['Arsenal']}");
  }

  print("\nTesting Premier League Player Photo (Haaland)...");
  final haalandPhoto = await OfficialLeagueScraper.fetchPremierLeaguePlayerPhoto("Erling Haaland");
  print("Haaland Photo: $haalandPhoto");

  print("\nTesting La Liga Logos...");
  final laLigaLogos = await OfficialLeagueScraper.fetchLaLigaLogos();
  print("Found ${laLigaLogos.length} logos.");
  
  print("\n--- Test Complete ---");
}
