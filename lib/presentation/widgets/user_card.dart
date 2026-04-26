import 'package:flutter/material.dart';

import '../pages/movies_page.dart';
import 'save_count_chip.dart';

class UserCard extends StatelessWidget {
  const UserCard({super.key, required this.user});
  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = '${user['first_name']} ${user['last_name']}'.trim();
    final taste = '${user['movie_taste'] ?? ''}'.trim();
    final avatar = user['avatar'] as String?;
    final pending = (user['pending_sync'] as int? ?? 0) == 1;
    final savedCount = user['saved_count'] as int? ?? 0;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MoviesPage(activeUser: user)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Hero(
                tag: 'avatar-${user['local_id']}',
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: scheme.primaryContainer,
                  backgroundImage: avatar == null || avatar.isEmpty ? null : NetworkImage(avatar),
                  child: avatar == null || avatar.isEmpty
                      ? Text(
                          name.isEmpty ? '?' : name[0].toUpperCase(),
                          style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name.isEmpty ? 'Unknown user' : name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (pending) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: 'Sync pending',
                            child: Icon(Icons.sync_problem_rounded, size: 16, color: scheme.tertiary),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      taste.isEmpty ? 'No preference set' : taste,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SaveCountChip(count: savedCount),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
