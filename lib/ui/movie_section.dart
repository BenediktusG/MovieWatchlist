import 'package:flutter/material.dart';
import 'package:movie_watchlist/ui/movie_card.dart';

class MovieSection extends StatelessWidget {
  final String title;
  final List<dynamic> movies;
  final Function(int movieId) onMovieTap; // Callback untuk navigasi

  const MovieSection({
    super.key,
    required this.title,
    required this.movies,
    required this.onMovieTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              final int movieId = movie['id'] as int;

              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 16.0 : 8.0,
                  right: index == movies.length - 1 ? 16.0 : 0,
                ),
                child: SizedBox(
                  width: 140,
                  child: GestureDetector(
                    onTap: () => onMovieTap(movieId), // Panggil callback
                    child: MovieCard(
                      item: movie,
                      // Asumsikan true karena ini home page (movie section)
                      // Jika nanti ada TV section, bisa ditambahkan parameter isMovie
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}