// Lokasi file: lib/ui/watchlist_view.dart
import 'package:flutter/material.dart';
import 'package:movie_watchlist/ui/movie_card.dart';

class WatchlistView extends StatelessWidget {
  final List<dynamic> items; // Data dari Page
  final Function(int id, bool isMovie) onItemTap; // Callback navigasi

  const WatchlistView({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Tampilan jika Kosong
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_remove_outlined,
              size: 80,
              color: Colors.grey[800],
            ),
            const SizedBox(height: 16),
            Text(
              'Watchlist kamu masih kosong',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    // 2. Tampilan Grid Data
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 0.6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        
        // Parsing data yang aman
        // ID dokumen firestore adalah ID film/tv
        final int itemId = int.tryParse(item['id'].toString()) ?? 0;
        
        // Cek tipe media (disimpan saat 'add to watchlist')
        // Default ke 'movie' (true) jika data lama tidak punya field ini
        final bool isMovie = (item['media_type'] ?? 'movie') == 'movie';

        return GestureDetector(
          onTap: () => onItemTap(itemId, isMovie),
          child: MovieCard(item: item),
        );
      },
    );
  }
}