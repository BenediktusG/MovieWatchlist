// Lokasi file: lib/pages/home.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movie_watchlist/constants.dart';
import 'package:movie_watchlist/widgets/movie_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _popularMovies = [];
  List<dynamic> _nowPlayingMovies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final popularResponse = await http.get(Uri.parse(
          '$tmdbBaseUrl/movie/popular?api_key=$tmdbApiKey&language=id-ID'));
          
      final nowPlayingResponse = await http.get(Uri.parse(
          '$tmdbBaseUrl/movie/now_playing?api_key=$tmdbApiKey&language=id-ID'));

      if (popularResponse.statusCode == 200 &&
          nowPlayingResponse.statusCode == 200) {
        setState(() {
          _popularMovies = json.decode(popularResponse.body)['results'];
          _nowPlayingMovies = json.decode(nowPlayingResponse.body)['results'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    _buildMovieSection(
                      title: 'Sedang Populer',
                      movies: _popularMovies,
                    ),
                    _buildMovieSection(
                      title: 'Rilis Terbaru',
                      movies: _nowPlayingMovies,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        readOnly: true,
        decoration: InputDecoration(
          hintText: 'Cari film atau serial TV...',
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildMovieSection({required String title, required List<dynamic> movies}) {
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
          height: 240, // Atur tinggi agar pas
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 16.0 : 8.0,
                  right: index == movies.length - 1 ? 16.0 : 0,
                ),
                child: SizedBox(
                  width: 140,
                  child: MovieCard(
                    item: movie,
                    isMovie: true,
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