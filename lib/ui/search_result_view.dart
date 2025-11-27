import 'package:flutter/material.dart';
import 'package:movie_watchlist/ui/movie_card.dart';
import 'package:movie_watchlist/ui/search_category_tabs.dart'; // Untuk Enum SearchCategory

class SearchResultView extends StatelessWidget {
  final bool isLoading;
  final bool hasSearched;
  final String currentQuery;
  final List<dynamic> results;
  final SearchCategory selectedCategory;
  final Function(int id, bool isMovie) onItemTap; // Callback navigasi

  const SearchResultView({
    super.key,
    required this.isLoading,
    required this.hasSearched,
    required this.currentQuery,
    required this.results,
    required this.selectedCategory,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Loading State
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Initial State (Belum cari)
    if (!hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded, size: 80, color: Colors.grey[800]),
            const SizedBox(height: 16),
            Text(
              'Mulai mencari film atau serial TV',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    // 3. Empty State (Tidak ketemu)
    if (results.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada hasil untuk "$currentQuery"',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    // 4. Result Grid State
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 0.6,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        final int itemId = item['id'] as int;

        // Logika isMovie dipindahkan ke UI agar lebih rapi
        bool isMovie;
        if (selectedCategory == SearchCategory.film) {
          isMovie = true;
        } else if (selectedCategory == SearchCategory.serialTv) {
          isMovie = false;
        } else {
          isMovie = item['media_type'] == 'movie';
        }

        return GestureDetector(
          onTap: () => onItemTap(itemId, isMovie),
          child: MovieCard(item: item),
        );
      },
    );
  }
}