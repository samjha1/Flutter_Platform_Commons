import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/movie_card.dart';
import '../widgets/save_count_chip.dart';
import '../widgets/staggered_item.dart';

class SavedMoviesPage extends ConsumerWidget {
  const SavedMoviesPage({super.key, required this.activeUser});
  final Map<String, dynamic> activeUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    final state = ref.watch(appStateProvider);
    final scheme = Theme.of(context).colorScheme;
    final fullName = '${activeUser['first_name']} ${activeUser['last_name']}'.trim();
    final taste = '${activeUser['movie_taste'] ?? ''}'.trim();
    final avatar = activeUser['avatar'] as String?;
    return Scaffold(
      appBar: AppBar(title: const Text('Saved movies')),
      body: StreamBuilder<int>(
        stream: repo.dataChanged.stream,
        initialData: 0,
        builder: (context, _) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: repo.getSavedMoviesForUser(activeUser['local_id'] as int),
            builder: (context, moviesSnapshot) {
              final saved = moviesSnapshot.data ?? [];
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              scheme.primaryContainer,
                              scheme.tertiaryContainer,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Hero(
                              tag: 'avatar-${activeUser['local_id']}',
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: scheme.surface,
                                backgroundImage: (avatar == null || avatar.isEmpty)
                                    ? null
                                    : NetworkImage(avatar),
                                child: (avatar == null || avatar.isEmpty)
                                    ? Text(
                                        fullName.isEmpty
                                            ? '?'
                                            : fullName[0].toUpperCase(),
                                        style: TextStyle(
                                          color: scheme.primary,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName.isEmpty ? 'Unknown user' : fullName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: scheme.onPrimaryContainer,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    taste.isEmpty ? 'No preference set' : taste,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: scheme.onPrimaryContainer
                                              .withValues(alpha: 0.85),
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  SaveCountChip(count: saved.length),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (saved.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.bookmark_outline_rounded,
                        title: 'No saved movies yet',
                        message:
                            "Browse the discover tab and tap the bookmark on any movie ${activeUser['first_name']} likes.",
                        action: FilledButton.tonalIcon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.movie_outlined),
                          label: const Text('Browse movies'),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.62,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final movie = saved[index];
                            return StaggeredItem(
                              index: index,
                              child: MovieCard(
                                movie: movie,
                                activeUser: activeUser,
                                repo: repo,
                                onToggleSave: () async {
                                  await state.toggleSave(
                                    userLocalId: activeUser['local_id'] as int,
                                    movie: movie,
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Saved movies updated'),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          childCount: saved.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
