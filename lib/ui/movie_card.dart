// Lokasi file: lib/widgets/movie_card.dart
import 'package:flutter/material.dart';
import 'package:movie_watchlist/constants.dart'; // Impor konstanta baru kita

class MovieCard extends StatelessWidget {
  final dynamic item;
  final bool isMovie; // Tambahan untuk handle judul (movie vs tv)

  const MovieCard({
    super.key,
    required this.item,
    this.isMovie = true, // Defaultnya adalah movie
  });

  @override
  Widget build(BuildContext context) {
    // Logika untuk judul: 'title' untuk film, 'name' untuk serial TV
    final String title = item['title'] ?? item['name'] ?? 'Judul Tidak Tersedia';
    final String? posterPath = item['poster_path'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: posterPath != null
                ? Image.network(
                    '$imageBaseUrl$posterPath', // Gunakan konstanta
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[900],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: Icon(
                            Icons.movie_creation_outlined,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: Icon(
                        Icons.movie_creation_outlined,
                        color: Colors.grey,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}