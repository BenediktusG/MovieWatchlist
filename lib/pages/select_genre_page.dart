import 'package:flutter/material.dart';

class SelectGenrePage extends StatefulWidget {
  final Set<String> initialGenres;
  // Callback untuk mengirim data kembali ke parent
  final Function(Set<String>) onSave;

  const SelectGenrePage({
    super.key,
    this.initialGenres = const {},
    required this.onSave,
  });

  @override
  State<SelectGenrePage> createState() => _SelectGenrePageState();
}

class _SelectGenrePageState extends State<SelectGenrePage> {
  // Daftar semua genre yang tersedia
  final List<String> _allGenres = [
    'Action',
    'Adventure',
    'Animation',
    'Comedy',
    'Crime',
    'Documentary',
    'Drama',
    'Fantasy',
    'History',
    'Horror',
    'Music',
    'Mystery',
    'Romance',
    'Science Fiction',
    'TV Movie',
    'Thriller',
    'War',
    'Western',
  ];

  // Set untuk menyimpan genre yang sedang dipilih
  late Set<String> _selectedGenres;

  @override
  void initState() {
    super.initState();
    // Inisialisasi genre yang dipilih dari data yang dikirim
    _selectedGenres = Set.from(widget.initialGenres);
  }

  // Fungsi untuk menambah/menghapus genre saat diklik
  void _toggleGenre(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else {
        _selectedGenres.add(genre);
      }
    });
  }

  // Fungsi untuk menyimpan pilihan
  void _saveSelection() {
    // Panggil fungsi callback dari parent
    widget.onSave(_selectedGenres);
  }

  @override
  Widget build(BuildContext context) {
    // Kita tidak menggunakan Scaffold di sini
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. Kartu Header
            _buildHeaderCard(),
            const SizedBox(height: 24),

            // 2. Grid Genre (dibuat bisa scroll)
            Expanded(child: _buildGenreGrid()),
            const SizedBox(height: 16),

            // 3. Tombol Simpan (selalu di bawah)
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Genre Favorit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih genre yang Anda sukai untuk rekomendasi yang lebih baik',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreGrid() {
    return GridView.builder(
      itemCount: _allGenres.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 kolom
        crossAxisSpacing: 12.0, // Jarak horizontal
        mainAxisSpacing: 12.0, // Jarak vertikal
        childAspectRatio: 2.8, // Rasio tombol (lebar : tinggi)
      ),
      itemBuilder: (context, index) {
        final genre = _allGenres[index];
        final isSelected = _selectedGenres.contains(genre);

        if (isSelected) {
          return ElevatedButton(
            onPressed: () => _toggleGenre(genre),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue, // Warna terpilih
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: Text(
              genre,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );
        } else {
          return OutlinedButton(
            onPressed: () => _toggleGenre(genre),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white, // Warna teks
              backgroundColor: Colors.grey[900], // Warna tidak terpilih
              side: BorderSide(color: Colors.grey[800]!), // Border
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: Text(
              genre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }
      },
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity, // Buat tombol jadi full-width
      child: ElevatedButton(
        onPressed: _saveSelection, // Panggil fungsi simpan
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: const Text(
          'Simpan Pilihan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
