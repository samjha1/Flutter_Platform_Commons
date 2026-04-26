import 'package:flutter/material.dart';

import '../../data/app_repository.dart';
import '../pages/movie_detail_page.dart';
import 'bookmark_button.dart';
import 'movie_poster.dart';
import 'save_count_chip.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({
    super.key,
    required this.movie,
    required this.activeUser,
    required this.repo,
    required this.onToggleSave,
  });

  final Map<String, dynamic> movie;
  final Map<String, dynamic> activeUser;
  final AppRepository repo;
  final Future<void> Function() onToggleSave;

  @override
  Widget build(BuildContext context) {
    final title = '${movie['title']}';
    final year = '${movie['release_date'] ?? ''}'.split('-').first.split(' ').last;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MovieDetailPage(activeUser: activeUser, movie: movie),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'poster-${movie['id']}',
              child: MoviePoster(movie: movie),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                      Colors.black.withValues(alpha: 0.92),
                    ],
                    stops: const [0.0, 0.45, 0.78, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: StreamBuilder<int>(
                stream: repo.dataChanged.stream,
                initialData: 0,
                builder: (context, _) {
                  return FutureBuilder<int>(
                    future: repo.movieSaveCount(movie['id'] as int),
                    builder: (context, countSnap) {
                      final c = countSnap.data ?? 0;
                      if (c == 0) return const SizedBox.shrink();
                      return SaveCountChip(count: c, dense: true);
                    },
                  );
                },
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: BookmarkButton(
                movie: movie,
                userLocalId: activeUser['local_id'] as int,
                repo: repo,
                onToggle: onToggleSave,
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  if (year.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      year,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
