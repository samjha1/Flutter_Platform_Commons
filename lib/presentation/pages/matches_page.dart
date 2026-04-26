import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../widgets/avatar_bubble.dart';
import '../widgets/empty_state.dart';
import '../widgets/movie_poster.dart';
import '../widgets/save_count_chip.dart';
import '../widgets/staggered_item.dart';
import 'movie_detail_page.dart';

class MatchesPage extends ConsumerWidget {
  const MatchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: StreamBuilder<int>(
        stream: repo.dataChanged.stream,
        initialData: 0,
        builder: (context, _) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: repo.matches(),
            builder: (context, matchesSnapshot) {
              final data = matchesSnapshot.data ?? [];
              if (matchesSnapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (data.isEmpty) {
                return const EmptyState(
                  icon: Icons.handshake_rounded,
                  title: 'No matches yet',
                  message:
                      'A match appears when two or more users save the same movie. Add users and start saving!',
                );
              }
              return FutureBuilder<int>(
                future: repo.userCount(),
                builder: (context, userCountSnap) {
                  final totalUsers = userCountSnap.data ?? 0;
                  final topCount = data.first['save_count'] as int;
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: data.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final movie = data[index];
                      final saveCount = movie['save_count'] as int;
                      final isTopPick = saveCount == topCount &&
                          totalUsers >= 1 &&
                          saveCount == totalUsers;
                      return StaggeredItem(
                        index: index,
                        child: _MatchTile(
                          movie: movie,
                          saveCount: saveCount,
                          isTopPick: isTopPick,
                          schemeSurface: scheme.surfaceContainerHigh,
                          loadUsers: () => repo.usersForMovie(movie['id'] as int),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.movie,
    required this.saveCount,
    required this.isTopPick,
    required this.schemeSurface,
    required this.loadUsers,
  });

  final Map<String, dynamic> movie;
  final int saveCount;
  final bool isTopPick;
  final Color schemeSurface;
  final Future<List<Map<String, dynamic>>> Function() loadUsers;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: loadUsers(),
      builder: (context, usersSnapshot) {
        final users = usersSnapshot.data ?? [];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: isTopPick
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.amber.shade400, Colors.deepOrange.shade300],
                  )
                : null,
            color: isTopPick ? null : schemeSurface,
          ),
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: schemeSurface,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  final firstSaver = users.isNotEmpty ? users.first : null;
                  if (firstSaver == null) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MovieDetailPage(
                        activeUser: firstSaver,
                        movie: movie,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 70,
                          height: 96,
                          child: Hero(
                            tag: 'poster-${movie['id']}',
                            child: MoviePoster(movie: movie),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${movie['title']}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                if (isTopPick) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade600,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.emoji_events_rounded,
                                            size: 12, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text(
                                          'TOP PICK',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                SaveCountChip(count: saveCount),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SizedBox(
                                    height: 28,
                                    child: Stack(
                                      children: [
                                        for (int i = 0;
                                            i < users.take(5).length;
                                            i++)
                                          Positioned(
                                            left: i * 18.0,
                                            child: AvatarBubble(user: users[i]),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
