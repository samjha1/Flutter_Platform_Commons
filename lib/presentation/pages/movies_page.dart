import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/movie_card.dart';
import '../widgets/reconnecting_banner.dart';
import '../widgets/shimmers.dart';
import '../widgets/staggered_item.dart';
import 'saved_movies_page.dart';

class MoviesPage extends ConsumerWidget {
  const MoviesPage({super.key, required this.activeUser});
  final Map<String, dynamic> activeUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final repo = ref.watch(repositoryProvider);
    final scheme = Theme.of(context).colorScheme;
    final showShimmer = !state.initialMoviesLoaded && state.movies.isEmpty;
    final firstName = '${activeUser['first_name'] ?? ''}';
    return Scaffold(
      appBar: AppBar(
        title: Text('Discover · $firstName'),
        actions: [
          IconButton(
            tooltip: "$firstName's saved",
            icon: const Icon(Icons.bookmarks_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SavedMoviesPage(activeUser: activeUser),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const ReconnectingBanner(),
          Expanded(
            child: showShimmer
                ? const MoviesGridShimmer()
                  : RefreshIndicator(
                    onRefresh: () => state.fetchNextMovies(reset: true),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (state.hasMoreMovies &&
                            !state.loadingMovies &&
                            n.metrics.pixels >=
                                n.metrics.maxScrollExtent - 200) {
                          unawaited(state.fetchNextMovies());
                        }
                        return false;
                      },
                      child: state.movies.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 100),
                                EmptyState(
                                  icon: Icons.movie_filter_outlined,
                                  title: 'No movies cached',
                                  message:
                                      'Connect to the internet to load trending movies.',
                                ),
                              ],
                            )
                          : CustomScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                SliverPadding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                                        final movie = state.movies[index];
                                        return StaggeredItem(
                                          index: index,
                                          child: MovieCard(
                                            movie: movie,
                                            activeUser: activeUser,
                                            repo: repo,
                                            onToggleSave: () async {
                                              await state.toggleSave(
                                                userLocalId: activeUser['local_id']
                                                    as int,
                                                movie: movie,
                                              );
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Saved movies updated'),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                      childCount: state.movies.length,
                                    ),
                                  ),
                                ),
                                if (state.loadingMovies && state.hasMoreMovies)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 24),
                                      child: Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            valueColor: AlwaysStoppedAnimation(
                                                scheme.primary),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (!state.hasMoreMovies &&
                                    state.movies.isNotEmpty)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 24),
                                      child: Center(
                                        child: Text(
                                          "You've reached the end",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                const SliverToBoxAdapter(
                                    child: SizedBox(height: 24)),
                              ],
                            ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
