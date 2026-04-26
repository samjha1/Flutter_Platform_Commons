import 'package:flutter/material.dart';

class AvatarBubble extends StatelessWidget {
  const AvatarBubble({super.key, required this.user});
  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avatar = user['avatar'] as String?;
    final firstName = '${user['first_name'] ?? ''}';
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: scheme.surface, width: 2),
      ),
      child: CircleAvatar(
        radius: 14,
        backgroundColor: scheme.primaryContainer,
        backgroundImage: (avatar == null || avatar.isEmpty) ? null : NetworkImage(avatar),
        child: (avatar == null || avatar.isEmpty)
            ? Text(
                firstName.isEmpty ? '?' : firstName[0].toUpperCase(),
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              )
            : null,
      ),
    );
  }
}
