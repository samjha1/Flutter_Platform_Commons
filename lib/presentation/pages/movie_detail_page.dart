import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../widgets/avatar_bubble.dart';
import '../widgets/meta_chip.dart';
import '../widgets/movie_poster.dart';
import '../widgets/section_title.dart';

class MovieDetailPage extends ConsumerStatefulWidget {
  const MovieDetailPage({
    super.key,
    required this.activeUser,
    required this.movie,
  });

  final Map<String, dynamic> activeUser;
  final Map<String, dynamic> movie;

  @override
  ConsumerState<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends ConsumerState<MovieDetailPage> {
  late Future<Map<String, dynamic>> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture =
        ref.read(repositoryProvider).getMovieDetail(widget.movie);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final repo = ref.watch(repositoryProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailFuture,
        builder: (context, snapshot) {
          final movie = snapshot.data ?? widget.movie;
          final title = '${movie['title']}';
          final year =
              '${movie['release_date'] ?? ''}'.split('-').first.split(' ').last;
          final overview = '${movie['overview'] ?? ''}'.trim();
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                stretch: true,
                expandedHeight: 360,
                backgroundColor: scheme.surface,
                surfaceTintColor: scheme.surfaceTint,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.fadeTitle,
                  ],
                  titlePadding: const EdgeInsetsDirectional.only(
                      start: 56, end: 16, bottom: 14),
                  title: LayoutBuilder(
                    builder: (context, constraints) {
                      final collapsed = constraints.biggest.height < 110;
                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: collapsed ? 1 : 0,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'poster-${movie['id']}',
                        child: MoviePoster(movie: movie),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.25),
                              Colors.transparent,
                              scheme.surface.withValues(alpha: 0.45),
                              scheme.surface,
                            ],
                            stops: const [0.0, 0.4, 0.85, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (year.isNotEmpty)
                            MetaChip(
                                icon: Icons.calendar_today_rounded,
                                label: year),
                          StreamBuilder<int>(
                            stream: repo.dataChanged.stream,
                            initialData: 0,
                            builder: (context, _) => FutureBuilder<int>(
                              future: repo.movieSaveCount(movie['id'] as int),
                              builder: (context, snap) {
                                final c = snap.data ?? 0;
                                return MetaChip(
                                  icon: Icons.bookmark_rounded,
                                  label: '$c saved',
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const SectionTitle(label: 'Description'),
                      const SizedBox(height: 8),
                      Text(
                        overview.isEmpty
                            ? 'No description available.'
                            : overview,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 22),
                      const SectionTitle(label: 'Who saved this'),
                      const SizedBox(height: 8),
                      StreamBuilder<int>(
                        stream: repo.dataChanged.stream,
                        initialData: 0,
                        builder: (context, _) =>
                            FutureBuilder<List<Map<String, dynamic>>>(
                          future: repo.usersForMovie(movie['id'] as int),
                          builder: (context, usersSnap) {
                            final users = usersSnap.data ?? [];
                            if (users.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.lightbulb_outline_rounded,
                                        color: scheme.onSurfaceVariant),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Be the first to save this.',
                                        style: TextStyle(
                                            color: scheme.onSurfaceVariant),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return Row(
                              children: [
                                SizedBox(
                                  width:
                                      24.0 * users.take(5).length.clamp(1, 5) +
                                          12,
                                  height: 32,
                                  child: Stack(
                                    children: [
                                      for (int i = 0;
                                          i < users.take(5).length;
                                          i++)
                                        Positioned(
                                          left: i * 22.0,
                                          child:
                                              AvatarBubble(user: users[i]),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${users.length} ${users.length == 1 ? 'user wants' : 'users want'} to watch this',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 110),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: StreamBuilder<int>(
            stream: repo.dataChanged.stream,
            initialData: 0,
            builder: (context, _) => FutureBuilder<bool>(
              future: repo.isMovieSaved(
                userLocalId: widget.activeUser['local_id'] as int,
                movieId: widget.movie['id'] as int,
              ),
              builder: (context, snap) {
                final saved = snap.data ?? false;
                return FilledButton.icon(
                  onPressed: () async {
                    await state.toggleSave(
                      userLocalId: widget.activeUser['local_id'] as int,
                      movie: widget.movie,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          saved ? 'Removed from saved' : 'Saved to your list',
                        ),
                      ),
                    );
                  },
                  icon: Icon(saved
                      ? Icons.bookmark_remove_rounded
                      : Icons.bookmark_add_rounded),
                  label: Text(saved
                      ? 'Remove from saved'
                      : "Save for ${widget.activeUser['first_name']}"),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor:
                        saved ? scheme.errorContainer : scheme.primary,
                    foregroundColor:
                        saved ? scheme.onErrorContainer : scheme.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
