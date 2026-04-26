import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

class ReconnectingBanner extends ConsumerWidget {
  const ReconnectingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<bool>(
      stream: repo.reconnecting.stream,
      initialData: false,
      builder: (context, snapshot) {
        final reconnecting = snapshot.data ?? false;
        return AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: reconnecting
                ? Container(
                    key: const ValueKey('reconnecting'),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                    color: scheme.tertiaryContainer,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(scheme.onTertiaryContainer),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Reconnecting…',
                          style: TextStyle(color: scheme.onTertiaryContainer, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(key: ValueKey('idle'), height: 0, width: double.infinity),
          ),
        );
      },
    );
  }
}
