import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:movie_watchlist/pages/movie_detail_page.dart';
import 'package:movie_watchlist/ui/search_category_tabs.dart';
import 'package:movie_watchlist/ui/search_input_field.dart';
import 'package:movie_watchlist/ui/search_result_view.dart';

final String tmdbApiKey =
    dotenv.env['TMDB_API_KEY'] ?? 'API_KEY_TIDAK_DITEMUKAN';
const String tmdbBaseUrl = 'https://api.themoviedb.org/3';

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
  void _navigateToDetail(int movieId, bool isMovie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MovieDetailPage(movieId: movieId, isMovie: isMovie),
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
            // 1. Search Bar
            SearchInputField(controller: _searchController),
            
            // 2. Category Tabs
            SearchCategoryTabs(
              selectedCategory: _selectedCategory,
              onCategoryChanged: _changeCategory,
            ),
            
            // 3. Result View (Expanded)
            Expanded(
              child: SearchResultView(
                isLoading: _isLoading,
                hasSearched: _hasSearched,
                currentQuery: _currentQuery,
                results: _results,
                selectedCategory: _selectedCategory,
                onItemTap: _navigateToDetail, // Kirim fungsi navigasi
              ),
            ),
          ],
        ),
      ),
    );
  }
}