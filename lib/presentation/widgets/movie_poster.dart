import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class MoviePoster extends StatelessWidget {
  const MoviePoster({super.key, required this.movie});
  final Map<String, dynamic> movie;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final poster = '${movie['poster_path'] ?? ''}'.trim();
    if (poster.isEmpty) {
      return ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Center(child: Icon(Icons.movie_outlined, size: 32, color: scheme.outline)),
      );
    }
    return CachedNetworkImage(
      imageUrl: poster,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 320),
      fadeInCurve: Curves.easeOut,
      placeholder: (context, _) => Shimmer.fromColors(
        baseColor: scheme.surfaceContainerHighest,
        highlightColor: scheme.surfaceContainer,
        child: Container(color: Colors.white),
      ),
      errorWidget: (context, url, error) => ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Center(child: Icon(Icons.broken_image_outlined, color: scheme.outline)),
      ),
    );
  }
}
