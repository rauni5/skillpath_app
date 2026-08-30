import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.avatarUrl,
    required this.initials,
    this.radius = 20,
    this.ringColor,
    this.ringWidth = 0,
  });

  final String? avatarUrl;
  final String initials;
  final double radius;

  /// Optional border ring (e.g. the page background color, so the avatar
  /// looks like it "punches through" a banner behind it).
  final Color? ringColor;
  final double ringWidth;

  Widget _initialsAvatar(AppPalette p) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: p.indigoLight,
      child: Text(
        initials,
        style: TextStyle(
          color: p.indigo,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.55,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final hasPhoto = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    final avatar = !hasPhoto
        ? _initialsAvatar(p)
        : ClipOval(
            child: Image.network(
              avatarUrl!,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              // Show initials while loading and if the photo fails to
              // load, instead of a spinner/broken-image icon or (worse)
              // both layers stacked on top of each other.
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _initialsAvatar(p),
              errorBuilder: (context, error, stackTrace) => _initialsAvatar(p),
            ),
          );

    if (ringWidth <= 0) return avatar;
    return Container(
      padding: EdgeInsets.all(ringWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ringColor ?? p.surface0,
      ),
      child: avatar,
    );
  }
}
