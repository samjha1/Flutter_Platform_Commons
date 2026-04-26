import 'package:flutter/material.dart';

import '../../data/app_repository.dart';

class BookmarkButton extends StatelessWidget {
  const BookmarkButton({
    super.key,
    required this.movie,
    required this.userLocalId,
    required this.repo,
    required this.onToggle,
  });

  final Map<String, dynamic> movie;
  final int userLocalId;
  final AppRepository repo;
  final Future<void> Function() onToggle;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: repo.dataChanged.stream,
      initialData: 0,
      builder: (context, _) {
        return FutureBuilder<bool>(
          future: repo.isMovieSaved(userLocalId: userLocalId, movieId: movie['id'] as int),
          builder: (context, snapshot) {
            final saved = snapshot.data ?? false;
            final scheme = Theme.of(context).colorScheme;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Material(
                key: ValueKey(saved),
                color: saved ? scheme.primary : scheme.surface.withValues(alpha: 0.85),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onToggle,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      saved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                      size: 20,
                      color: saved ? scheme.onPrimary : scheme.onSurface,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
