class CorsUtils {
  // dedicated high-performance image proxy (CORS-friendly)
  static const String imageProxy = 'https://images.weserv.nl/?url=';
  
  // Fallback for non-image assets or XML data (more reliable than allorigins)
  static const String generalProxy = 'https://corsproxy.io/?';
  
  // JSON-based proxy for more reliable HTML/XML scraping
  static const String jsonProxy = 'https://api.allorigins.win/get?url=';

  // Additional CORS proxies for fallback/redundancy (thingproxy is dead, removed)
  static const List<String> dataProxies = [
    'https://corsproxy.io/?',
    'https://api.allorigins.win/get?url=',
    'https://api.codetabs.com/v1/proxy?quest=',
  ];

  static String proxify(String url) {
    if (url.isEmpty) return url;
    
    // Domains that already have stable CORS and don't need proxying
    final corsFriendlyDomains = [
      'ui-avatars.com',
      'api.dicebear.com',
      'placeholder.com',
      'cdn.myanimelist.net',
      'avatars.akamai.steamstatic.com',
      'community.akamai.steamstatic.com',
    ];

    bool isFriendly = corsFriendlyDomains.any((domain) => url.contains(domain));
    if (isFriendly) return url;

    // XML data requests (like Steam profiles) need the general data proxy, not weserv
    if (url.toLowerCase().contains('.xml') || url.toLowerCase().contains('?xml=1')) {
      return '$generalProxy${Uri.encodeComponent(url)}';
    }

    // Premier League SVG badges handle better with a general proxy
    if (url.toLowerCase().contains('.svg')) {
      return '$generalProxy${Uri.encodeComponent(url)}';
    }

    // Use images.weserv.nl for all other sports assets (ESPN, La Liga photos)
    // It's much more reliable than general cors proxies for image data.
    return '$imageProxy${Uri.encodeComponent(url)}';
  }
}
