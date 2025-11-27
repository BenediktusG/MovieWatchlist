import 'package:flutter/material.dart';

class DetailInfo extends StatelessWidget {
  final String year;
  final int runtime;
  final String genres;
  final String overview;

  const DetailInfo({
    super.key,
    required this.year,
    required this.runtime,
    required this.genres,
    required this.overview,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metadata Row
        Row(
          children: [
            Text(year, style: TextStyle(color: Colors.grey[400])),
            const SizedBox(width: 8),
            Text('•', style: TextStyle(color: Colors.grey[400])),
            const SizedBox(width: 8),
            Text('$runtime min', style: TextStyle(color: Colors.grey[400])),
            const SizedBox(width: 8),
            Text('•', style: TextStyle(color: Colors.grey[400])),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                genres,
                style: TextStyle(color: Colors.grey[400]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Synopsis
        Text(
          'Sinopsis',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          overview,
          style: TextStyle(color: Colors.grey[300], height: 1.5),
        ),
      ],
    );
  }
}