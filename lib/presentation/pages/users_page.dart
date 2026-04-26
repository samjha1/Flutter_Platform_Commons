import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/reconnecting_banner.dart';
import '../widgets/shimmers.dart';
import '../widgets/staggered_item.dart';
import '../widgets/user_card.dart';
import 'add_user_page.dart';
import 'matches_page.dart';

class UsersPage extends ConsumerWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final repo = ref.watch(repositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Matcher'),
        actions: [
          IconButton(
            tooltip: 'Matches',
            icon: const Icon(Icons.groups_2_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MatchesPage()),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'toggle_weak') {
                repo.weakConnectionMode = !repo.weakConnectionMode;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Weak network mode: ${repo.weakConnectionMode ? 'ON' : 'OFF'}',
                    ),
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              CheckedPopupMenuItem<String>(
                value: 'toggle_weak',
                checked: repo.weakConnectionMode,
                child: const Text('Simulate weak network'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const ReconnectingBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Text(
                  'Pick someone to start',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                if (state.users.isNotEmpty)
                  Text(
                    '${state.users.length} users',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: state.loadingUsers
                ? const UsersListShimmer()
                : RefreshIndicator(
                    onRefresh: state.refreshUsers,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.pixels > n.metrics.maxScrollExtent - 80) {
                          unawaited(state.loadMoreUsers());
                        }
                        return false;
                      },
                      child: state.users.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 100),
                                EmptyState(
                                  icon: Icons.people_outline_rounded,
                                  title: 'No users yet',
                                  message:
                                      'Pull down to refresh or add a new user from the button below.',
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: state.users.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final user = state.users[index];
                                return StaggeredItem(
                                  index: index,
                                  child: UserCard(user: user),
                                );
                              },
                            ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddUserPage()),
        ),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add user'),
      ),
    );
  }
}
