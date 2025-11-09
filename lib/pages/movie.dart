// lib/models/movie.dart

import 'package:flutter/foundation.dart';

/// Model data untuk sebuah film, berdasarkan Class Diagram.
@immutable
class Movie {
  final String movieId;
  final String title;
  final String posterUri;
  final String overview;
  final DateTime releaseDate;

  const Movie({
    required this.movieId,
    required this.title,
    required this.posterUri,
    required this.overview,
    required this.releaseDate,
  });
}