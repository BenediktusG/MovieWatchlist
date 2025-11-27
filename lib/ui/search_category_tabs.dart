import 'package:flutter/material.dart';

// Kita pindahkan Enum ke sini agar bisa dipakai oleh Page dan UI
enum SearchCategory { semua, film, serialTv }

class SearchCategoryTabs extends StatelessWidget {
  final SearchCategory selectedCategory;
  final Function(SearchCategory) onCategoryChanged;

  const SearchCategoryTabs({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
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
    final bool isActive = selectedCategory == category;
    return ElevatedButton(
      onPressed: () => onCategoryChanged(category),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.blue : Colors.grey[850],
        foregroundColor: isActive ? Colors.white : Colors.grey[400],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      child: Text(text),
    );
  }
}