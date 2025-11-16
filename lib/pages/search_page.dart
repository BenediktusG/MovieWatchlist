import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:movie_watchlist/pages/movie_detail_page.dart';

final String tmdbApiKey =
    dotenv.env['TMDB_API_KEY'] ?? 'API_KEY_TIDAK_DITEMUKAN';
const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

// Enum untuk mengelola kategori pencarian
enum SearchCategory { semua, film, serialTv }

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  SearchCategory _selectedCategory = SearchCategory.semua;
  List<dynamic> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false; // Untuk membedakan state awal dan "no results"
  String _currentQuery = ""; // Untuk menampilkan query di "no results"

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.trim().isEmpty) {
        _clearSearch();
      } else {
        _fetchResults();
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _results = [];
      _hasSearched = false;
      _currentQuery = "";
    });
  }

  Future<void> _fetchResults() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _currentQuery = query;
    });

    String endpoint;
    switch (_selectedCategory) {
      case SearchCategory.film:
        endpoint = 'search/movie';
        break;
      case SearchCategory.serialTv:
        endpoint = 'search/tv';
        break;
      default:
        endpoint = 'search/multi';
        break;
    }

    try {
      final response = await http.get(
        Uri.parse(
          '$tmdbBaseUrl/$endpoint?api_key=$tmdbApiKey&query=$query&language=id-ID',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['results'] as List;

        // Filter hasil 'semua' untuk hanya film dan serial TV (bukan 'person')
        if (_selectedCategory == SearchCategory.semua) {
          setState(() {
            _results = data
                .where(
                  (item) =>
                      item['media_type'] == 'movie' ||
                      item['media_type'] == 'tv',
                )
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _results = data;
            _isLoading = false;
          });
        }
      } else {
        // Handle error
        setState(() {
          _isLoading = false;
          _results = [];
        });
      }
    } catch (e) {
      // Handle exception
      setState(() {
        _isLoading = false;
        _results = [];
      });
    }
  }

  void _changeCategory(SearchCategory category) {
    setState(() {
      _selectedCategory = category;
    });
    // Lakukan pencarian ulang dengan kategori baru jika ada teks di search bar
    if (_searchController.text.trim().isNotEmpty) {
      _fetchResults();
    }
  }

  // BARU : Fungsi untuk navigasi ke halaman detail film
  void _navigateToDetail(int movieId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailPage(movieId: movieId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Atur background color di main.dart via ThemeData
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildCategoryTabs(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Cari film atau serial TV...',
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[900], // Warna field
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(
              color: Colors.blue,
            ), // Warna saat aktif
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildCategoryButton(SearchCategory.semua, 'Semua'),
          const SizedBox(width: 8),
          _buildCategoryButton(SearchCategory.film, 'Film'),
          const SizedBox(width: 8),
          _buildCategoryButton(SearchCategory.serialTv, 'Serial TV'),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(SearchCategory category, String text) {
    final bool isActive = _selectedCategory == category;
    return ElevatedButton(
      onPressed: () => _changeCategory(category),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive
            ? Colors.blue
            : Colors.grey[850], // Warna tombol
        foregroundColor: isActive
            ? Colors.white
            : Colors.grey[400], // Warna teks
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      child: Text(text),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      // State Awal
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

    if (_results.isEmpty) {
      // State Tidak Ada Hasil
      return Center(
        child: Text(
          'Tidak ada hasil untuk "$_currentQuery"',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    // State Ada Hasil
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 0.6,
      ),
      itemCount: _results.length,
      
      itemBuilder: (context, index) {
        final item = _results[index];
        final int itemId = item['id'] as int;

        // Logika untuk menentukan apakah item ini adalah film
        bool isMovie = false;
        if (_selectedCategory == SearchCategory.film) {
          isMovie = true;
        } else if (_selectedCategory == SearchCategory.semua) {
          isMovie = item['media_type'] == 'movie';
        }

        return GestureDetector(
          onTap: () {
            if (isMovie) {
              _navigateToDetail(itemId);
            } else {
              debugPrint('Serial TV (ID: $itemId) diklik. Belum ada halaman detail.');
            }
          },
          child: MovieCard(item: item),
        );
      },
    );
  }
}

class MovieCard extends StatelessWidget {
  final dynamic item;
  const MovieCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // TMDB menggunakan 'title' untuk film dan 'name' untuk serial TV
    final String title =
        item['title'] ?? item['name'] ?? 'Judul Tidak Tersedia';
    final String? posterPath = item['poster_path'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: posterPath != null
                ? Image.network(
                    '$imageBaseUrl$posterPath',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    // Loading builder untuk menampilkan loading saat gambar di-load
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
                    // Error builder untuk jika gambar gagal di-load
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
                // Placeholder jika tidak ada poster
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
