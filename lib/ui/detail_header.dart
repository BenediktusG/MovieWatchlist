import 'package:flutter/material.dart';
import 'package:movie_watchlist/constants.dart';

class DetailHeader extends StatelessWidget {
  final String posterPath;
  final String title;
  final double tmdbRating;
  final double appRating;
  final int appVoteCount;

  const DetailHeader({
    super.key,
    required this.posterPath,
    required this.title,
    required this.tmdbRating,
    required this.appRating,
    required this.appVoteCount,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Image
        if (posterPath.isNotEmpty)
          Image.network(
            '$imageBaseUrl$posterPath',
            width: double.infinity,
            height: 250,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(height: 250, color: Colors.grey[900]),
          )
        else
          Container(height: 250, color: Colors.grey[900]),

        // Dark Overlay
        Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.black.withOpacity(0.8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Content
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Small Poster
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: posterPath.isNotEmpty
                    ? Image.network(
                        '$imageBaseUrl$posterPath',
                        height: 120,
                        width: 80,
                        fit: BoxFit.cover,
                      )
                    : Container(height: 120, width: 80, color: Colors.grey),
              ),
              const SizedBox(width: 16),

              // Title & Ratings
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),

                    // Dual Rating Badges
                    Row(
                      children: [
                        _buildRatingBadge(
                          'TMDB',
                          Colors.amber,
                          tmdbRating.toStringAsFixed(1),
                        ),
                        const SizedBox(width: 8),
                        _buildRatingBadge(
                          'App',
                          Colors.blue,
                          appRating > 0 ? appRating.toStringAsFixed(1) : '-',
                          count: appVoteCount,
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingBadge(String label, Color color, String rating,
      {int count = 0}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Text('$label ',
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          Icon(Icons.star, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            rating,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          if (count > 0)
            Text(
              ' ($count)',
              style: TextStyle(color: Colors.grey[400], fontSize: 10),
            ),
        ],
      ),
    );
  }
}