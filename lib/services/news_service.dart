import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsService {
  // Remplace par l'URL de l'API de ton site
  // Exemple WordPress : 'https://tonsite.com/wp-json/wp/v2/posts'
  final String apiUrl = 'http://10.0.2.2:8000/api/actus';

  Future<List<dynamic>> getSiteNews() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      print("Erreur fetch news: $e");
      return [];
    }
  }
}
