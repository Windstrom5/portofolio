import 'package:http/http.dart' as http;
import 'package:universal_html/parsing.dart';

class NewsArticle {
  final String title;
  final String url;
  final String source; // "TECHNOLOGY" or "ANIME"

  NewsArticle({
    required this.title,
    required this.url,
    required this.source,
  });
}

class NewsScraper {
  static const String vergeUrl = "https://www.theverge.com";
  static const String malNewsUrl = "https://myanimelist.net/news";
  static const String proxyPrefix = "https://api.codetabs.com/v1/proxy?quest=";

  static Future<List<NewsArticle>> fetchAllNews() async {
    final List<NewsArticle> tech = await fetchTechNews();
    final List<NewsArticle> anime = await fetchAnimeNews();
    return [...tech, ...anime];
  }

  static Future<List<NewsArticle>> fetchTechNews() async {
    try {
      final response = await http.get(Uri.parse("$proxyPrefix$vergeUrl"));
      if (response.statusCode == 200) {
        final document = parseHtmlDocument(response.body);
        // Using the selector identified by the research
        final elements = document.querySelectorAll('a._1lkmsmo0');
        
        return elements.take(10).map((e) {
          String href = e.attributes['href'] ?? "";
          if (href.startsWith('/')) href = vergeUrl + href;
          return NewsArticle(
            title: e.text?.trim() ?? "",
            url: href,
            source: "TECHNOLOGY",
          );
        }).where((a) => a.title.isNotEmpty).toList();
      }
    } catch (e) {
      print("Error fetching tech news: $e");
    }
    return [];
  }

  static Future<List<NewsArticle>> fetchAnimeNews() async {
    try {
      final response = await http.get(Uri.parse("$proxyPrefix$malNewsUrl"));
      if (response.statusCode == 200) {
        final document = parseHtmlDocument(response.body);
        final elements = document.querySelectorAll('.news-unit p.title a');
        
        return elements.take(10).map((e) {
          String href = e.attributes['href'] ?? "";
          return NewsArticle(
            title: e.text?.trim() ?? "",
            url: href,
            source: "ANIME",
          );
        }).where((a) => a.title.isNotEmpty).toList();
      }
    } catch (e) {
      print("Error fetching anime news: $e");
    }
    return [];
  }
}
