import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// Static content for one app-tour slide.
class TourSlideData {
  const TourSlideData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

const List<TourSlideData> tourSlides = [
  TourSlideData(
    icon: Icons.auto_awesome,
    title: 'Welcome to SkillPath',
    description:
        'Your all-in-one space to grow your skills, plan your career, '
        'and build real projects along the way.',
  ),
  TourSlideData(
    icon: Icons.space_dashboard_outlined,
    title: 'Your dashboard',
    description:
        'See your career progress, roadmap completion, and active '
        'projects at a glance, every time you open the app.',
  ),
  TourSlideData(
    icon: Icons.psychology_outlined,
    title: 'Track your skills',
    description:
        'Add skills you already know, or prove them with a quick, '
        'AI-generated skill check.',
  ),
  TourSlideData(
    icon: Icons.alt_route_rounded,
    title: 'Follow your roadmap',
    description:
        'A personalized path of steps between where you are now and '
        'your career goal.',
  ),
  TourSlideData(
    icon: Icons.flag_outlined,
    title: 'Set your career goal',
    description:
        'Pick a role and specialization, then see exactly which '
        'skills you still need to close the gap.',
  ),
  TourSlideData(
    icon: Icons.school_outlined,
    title: 'Chat with your tutor',
    description:
        'Ask your AI tutor to explain any skill, then test yourself '
        'with a skill check when you feel ready.',
  ),
  TourSlideData(
    icon: Icons.groups_outlined,
    title: 'Build with a team',
    description:
        'Browse open projects, request to join one, or start your '
        'own and recruit teammates.',
  ),
  TourSlideData(
    icon: Icons.emoji_events_outlined,
    title: 'Earn achievements',
    description:
        'Unlock achievements and keep your streak alive as you make '
        'progress across the app.',
  ),
  TourSlideData(
    icon: Icons.smart_toy_outlined,
    title: 'Ask the assistant',
    description:
        "A general AI assistant is always a tap away for questions "
        "about your career or the app itself.",
  ),
];

/// One full-bleed slide: a large icon in a circle, title, and description —
/// matching the visual language of OnboardingSummaryStep's "you're all set"
/// icon treatment.
class TourSlide extends StatelessWidget {
  const TourSlide({super.key, required this.data});

  final TourSlideData data;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: p.indigoLight,
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: p.indigo, size: 44),
          ),
          const SizedBox(height: 28),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: p.textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }
}
