import 'package:flutter/material.dart';

class DetailActionButtons extends StatelessWidget {
  final int userRating;
  final bool isInWatchlist;
  final VoidCallback onRatingPressed;
  final VoidCallback onWatchlistPressed;

  const DetailActionButtons({
    super.key,
    required this.userRating,
    required this.isInWatchlist,
    required this.onRatingPressed,
    required this.onWatchlistPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Rating Button
        OutlinedButton(
          onPressed: onRatingPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            side: BorderSide(color: Colors.grey[800]!),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
          ),
          child: Row(
            children: [
              Icon(Icons.star, color: Colors.blue[300]),
              const SizedBox(width: 12),
              Text(
                userRating > 0
                    ? 'Rating Anda: $userRating Bintang'
                    : 'Beri Rating',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < userRating ? Icons.star : Icons.star_border,
                    color: index < userRating ? Colors.blue[300] : Colors.grey,
                    size: 20,
                  );
                }),
              )
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Watchlist Button
        ElevatedButton(
          onPressed: onWatchlistPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isInWatchlist ? Colors.grey[800] : Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isInWatchlist ? Icons.check : Icons.add,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                isInWatchlist ? 'Sudah di Watchlist' : 'Tambah ke Watchlist',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}