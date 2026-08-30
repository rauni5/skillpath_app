import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';

/// Small circular avatar used beside chat bubbles.
///
/// For the user's side, shows their profile photo if set, otherwise falls
/// back to initials on a tinted circle — this is a placeholder for photo
/// upload landing app-wide, so it lights up automatically once a user has
/// an `avatarUrl` with no further changes needed here.
///
/// For the other side of the conversation, shows a plain icon badge
/// (defaults to a generic assistant icon; pass a different [icon] to
/// distinguish e.g. a per-skill tutor from the general assistant).
class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    this.isUser = false,
    this.avatarUrl,
    this.name,
    this.icon = Icons.support_agent,
  });

  final bool isUser;
  final String? avatarUrl;
  final String? name;
  final IconData icon;

  String get _initials {
    final n = (name ?? '').trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    if (!isUser) {
      return CircleAvatar(
        radius: 14,
        backgroundColor: p.indigo,
        child: Icon(icon, size: 15, color: Colors.white),
      );
    }

    final hasPhoto = avatarUrl != null && avatarUrl!.isNotEmpty;
    return CircleAvatar(
      radius: 14,
      backgroundColor: p.indigoLight,
      backgroundImage: hasPhoto ? NetworkImage(avatarUrl!) : null,
      child: hasPhoto
          ? null
          : Text(
              _initials,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: p.indigo,
              ),
            ),
    );
  }
}
