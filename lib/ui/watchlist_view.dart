import 'package:flutter/material.dart';
import 'package:movie_watchlist/ui/movie_card.dart';

class WatchlistView extends StatelessWidget {
  final List<dynamic> items; 
  final Function(int id, bool isMovie) onItemTap;

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
        
        final int itemId = int.tryParse(item['id'].toString()) ?? 0;
        final bool isMovie = item['isMovie'] ?? true; 

        return GestureDetector(
          onTap: () => onItemTap(itemId, isMovie),
          child: MovieCard(item: item),
        );
      },
    );
  }
}