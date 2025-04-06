import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  String getGoogleApiKey() {
    // Access the environment variable
    String apiKey = dotenv.env['API_KEY'] ?? 'Default API Key';
    return apiKey;
  }
}