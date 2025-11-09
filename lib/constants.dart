// Lokasi file: lib/constants.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Ambil API key dari file .env
final String tmdbApiKey =
    dotenv.env['TMDB_API_KEY'] ?? 'API_KEY_TIDAK_DITEMUKAN';

// URL dasar untuk API
const String tmdbBaseUrl = 'https://api.themoviedb.org/3';

// URL dasar untuk gambar poster
const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';