// Lokasi file: lib/pages/watchlist_page.dart
import 'package:flutter/material.dart';
import 'package:movie_watchlist/widgets/movie_card.dart';

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  // Data "dummy" (palsu)
  final List<Map<String, dynamic>> dummyWatchlistItems = const [
    {
      "id": 299534,
      "title": "Avengers: Endgame",
      "poster_path": "/or06FN3Dka5tukK1e9sl16pB3iy.jpg",
      "media_type": "movie",
    },
    {
      "id": 299534,
      "title": "Avengers: Endgame",
      "poster_path": "/or06FN3Dka5tukK1e9sl16pB3iy.jpg",
      "media_type": "movie",
    },
    {
      "id": 299534,
      "title": "Avengers: Endgame",
      "poster_path": "/or06FN3Dka5tukK1e9sl16pB3iy.jpg",
      "media_type": "movie",
    },
    {
      "id": 299534,
      "title": "Avengers: Endgame",
      "poster_path": "/or06FN3Dka5tukK1e9sl16pB3iy.jpg",
      "media_type": "movie",
    },
    {
      "id": 299534,
      "title": "Avengers: Endgame",
      "poster_path": "/or06FN3Dka5tukK1e9sl16pB3iy.jpg",
      "media_type": "movie",
    },
    {
      "id": 299534,
      "title": "Avengers: Endgame",
      "poster_path": "/or06FN3Dka5tukK1e9sl16pB3iy.jpg",
      "media_type": "movie",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist Saya'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: dummyWatchlistItems.isEmpty
            ? Center(
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
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 0.6,
                ),
                itemCount: dummyWatchlistItems.length,
                itemBuilder: (context, index) {
                  final item = dummyWatchlistItems[index];
                  final bool isMovie =
                      (item['media_type'] ?? 'movie') == 'movie';

                  return MovieCard(item: item, isMovie: isMovie);
                },
              ),
      ),
    );
  }
}
