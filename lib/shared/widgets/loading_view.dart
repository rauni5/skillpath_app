import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';

/// Route-aware skeleton loading widget.
class LoadingView extends StatefulWidget {
  const LoadingView({super.key});

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name ?? '';
    final palette = AppPalette.of(context);

    if (_isDashboard(route)) {
      return _DashboardSkeleton(
        animation: _animationController,
        palette: palette,
      );
    }

    if (_isProjects(route)) {
      return _ProjectsSkeleton(
        animation: _animationController,
        palette: palette,
      );
    }

    if (_isProfile(route)) {
      return _ProfileSkeleton(
        animation: _animationController,
        palette: palette,
      );
    }

    if (_isRoadmap(route)) {
      return _RoadmapSkeleton(
        animation: _animationController,
        palette: palette,
      );
    }

    if (_isSkills(route)) {
      return _SkillsSkeleton(animation: _animationController, palette: palette);
    }

    if (_isCareer(route)) {
      return _CareerSkeleton(animation: _animationController, palette: palette);
    }

    if (_isNotifications(route)) {
      return _NotificationsSkeleton(
        animation: _animationController,
        palette: palette,
      );
    }

    if (_isAssistant(route)) {
      return _ChatSkeleton(animation: _animationController, palette: palette);
    }

    // Generic fallback for screens that don't need a specialised layout.
    return _GenericSkeleton(animation: _animationController, palette: palette);
  }

  bool _isDashboard(String route) {
    return route == '/dashboard';
  }

  bool _isProjects(String route) {
    return route.startsWith('/projects');
  }

  bool _isProfile(String route) {
    return route.startsWith('/profile') || route.contains('/portfolio');
  }

  bool _isRoadmap(String route) {
    return route.startsWith('/roadmap');
  }

  bool _isSkills(String route) {
    return route == '/profile/skills';
  }

  bool _isCareer(String route) {
    return route == '/profile/career-goal';
  }

  bool _isNotifications(String route) {
    return route == '/notifications';
  }

  bool _isAssistant(String route) {
    return route.startsWith('/assistant');
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.animation,
    required this.palette,
    this.width,
    this.height = 14,
    this.radius = 8,
  });

  final Animation<double> animation;
  final AppPalette palette;
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    final baseColor = isLight
        ? const Color(0xFFE1E4E8)
        : const Color(0xFF2A2D32);

    final highlightColor = isLight
        ? const Color(0xFFF4F5F6)
        : const Color(0xFF41454C);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Move the highlight from left → right.
        final position = (animation.value * 2.5) - 0.75;

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                baseColor,
                highlightColor,
                baseColor,
                baseColor,
              ],
              stops: [
                (position - 0.45).clamp(0.0, 1.0),
                (position - 0.20).clamp(0.0, 1.0),
                position.clamp(0.0, 1.0),
                (position + 0.20).clamp(0.0, 1.0),
                (position + 0.45).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle({
    required this.animation,
    required this.palette,
    required this.size,
  });

  final Animation<double> animation;
  final AppPalette palette;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    final baseColor = isLight
        ? const Color(0xFFE1E4E8)
        : const Color(0xFF2A2D32);

    final highlightColor = isLight
        ? const Color(0xFFF4F5F6)
        : const Color(0xFF41454C);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final position = (animation.value * 2.5) - 0.75;

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                baseColor,
                highlightColor,
                baseColor,
                baseColor,
              ],
              stops: [
                (position - 0.45).clamp(0.0, 1.0),
                (position - 0.20).clamp(0.0, 1.0),
                position.clamp(0.0, 1.0),
                (position + 0.20).clamp(0.0, 1.0),
                (position + 0.45).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle),
          ),
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({
    required this.animation,
    required this.palette,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Animation<double> animation;
  final AppPalette palette;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: palette.surface0,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border.withValues(alpha: 0.45)),
      ),
      child: child,
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton({required this.animation, required this.palette});

  final Animation<double> animation;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            _SkeletonCircle(animation: animation, palette: palette, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(
                    animation: animation,
                    palette: palette,
                    width: 145,
                    height: 16,
                  ),
                  const SizedBox(height: 8),
                  _SkeletonBox(
                    animation: animation,
                    palette: palette,
                    width: 210,
                    height: 11,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _SkeletonCard(
          animation: animation,
          palette: palette,
          child: Row(
            children: [
              _SkeletonCircle(animation: animation, palette: palette, size: 68),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(
                      animation: animation,
                      palette: palette,
                      width: 130,
                      height: 16,
                    ),
                    const SizedBox(height: 10),
                    _SkeletonBox(
                      animation: animation,
                      palette: palette,
                      height: 10,
                    ),
                    const SizedBox(height: 7),
                    _SkeletonBox(
                      animation: animation,
                      palette: palette,
                      width: 170,
                      height: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: _SkeletonStatCard(animation: animation, palette: palette),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SkeletonStatCard(animation: animation, palette: palette),
            ),
          ],
        ),

        const SizedBox(height: 14),

        _SkeletonCard(
          animation: animation,
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(
                animation: animation,
                palette: palette,
                width: 145,
                height: 17,
              ),
              const SizedBox(height: 18),
              _SkeletonBox(animation: animation, palette: palette, height: 11),
              const SizedBox(height: 9),
              _SkeletonBox(
                animation: animation,
                palette: palette,
                width: 260,
                height: 11,
              ),
              const SizedBox(height: 18),
              _SkeletonBox(
                animation: animation,
                palette: palette,
                width: 120,
                height: 34,
                radius: 10,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        _SkeletonCard(
          animation: animation,
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(
                animation: animation,
                palette: palette,
                width: 125,
                height: 16,
              ),
              const SizedBox(height: 16),
              ...List.generate(
                3,
                (index) => Padding(
                  padding: EdgeInsets.only(bottom: index == 2 ? 0 : 14),
                  child: Row(
                    children: [
                      _SkeletonCircle(
                        animation: animation,
                        palette: palette,
                        size: 38,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SkeletonBox(
                          animation: animation,
                          palette: palette,
                          height: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkeletonStatCard extends StatelessWidget {
  const _SkeletonStatCard({required this.animation, required this.palette});

  final Animation<double> animation;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return _SkeletonCard(
      animation: animation,
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(
            animation: animation,
            palette: palette,
            width: 70,
            height: 10,
          ),
          const SizedBox(height: 12),
          _SkeletonBox(
            animation: animation,
            palette: palette,
            width: 90,
            height: 23,
          ),
        ],
      ),
    );
  }
}

class _ProjectsSkeleton extends StatelessWidget {
  const _ProjectsSkeleton({required this.animation, required this.palette});

  final Animation<double> animation;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: _SkeletonBox(
                animation: animation,
                palette: palette,
                height: 44,
                radius: 12,
              ),
            ),
            const SizedBox(width: 10),
            _SkeletonBox(
              animation: animation,
              palette: palette,
              width: 48,
              height: 44,
              radius: 12,
            ),
          ],
        ),
        const SizedBox(height: 18),

        Row(
          children: [
            _SkeletonBox(
              animation: animation,
              palette: palette,
              width: 80,
              height: 32,
              radius: 16,
            ),
            const SizedBox(width: 8),
            _SkeletonBox(
              animation: animation,
              palette: palette,
              width: 95,
              height: 32,
              radius: 16,
            ),
            const SizedBox(width: 8),
            _SkeletonBox(
              animation: animation,
              palette: palette,
              width: 75,
              height: 32,
              radius: 16,
            ),
          ],
        ),

        const SizedBox(height: 16),

        ...List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ProjectCardSkeleton(animation: animation, palette: palette),
          ),
        ),
      ],
    );
  }
}

class _ProjectCardSkeleton extends StatelessWidget {
  const _ProjectCardSkeleton({required this.animation, required this.palette});

  final Animation<double> animation;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return _SkeletonCard(
      animation: animation,
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SkeletonBox(
                  animation: animation,
                  palette: palette,
                  width: 170,
                  height: 17,
                ),
              ),
              _SkeletonBox(
                animation: animation,
                palette: palette,
                width: 64,
                height: 24,
                radius: 12,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SkeletonBox(animation: animation, palette: palette, height: 10),
          const SizedBox(height: 8),
          _SkeletonBox(
            animation: animation,
            palette: palette,
            width: 250,
            height: 10,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SkeletonBox(
                animation: animation,
                palette: palette,
                width: 62,
                height: 24,
                radius: 12,
              ),
              const SizedBox(width: 7),
              _SkeletonBox(
                animation: animation,
                palette: palette,
                width: 72,
                height: 24,
                radius: 12,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SkeletonCircle(animation: animation, palette: palette, size: 30),
              const SizedBox(width: 8),
              _SkeletonBox(
                animation: animation,
                palette: palette,
                width: 110,
                height: 10,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton({required this.animation, required this.palette});

  final Animation<double> animation;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SkeletonCard(
          animation: animation,
          palette: palette,
          child: Column(
            children: [
              _SkeletonCircle(animation: animation, palette: palette, size: 86),
              const SizedBox(height: 14),
              _SkeletonBox(
                animation: animation,
                palette: palette,
                width: 145,
                height: 18,
              ),
              const SizedBox(height: 9),
              _SkeletonBox(
                animation: animation,
                palette: palette,
                width: 200,
                height: 11,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SkeletonBox(
                    animation: animation,
                    palette: palette,
                    width: 80,
                    height: 32,
                    radius: 16,
                  ),
                  const SizedBox(width: 8),
                  _SkeletonBox(
                    animation: animation,
                    palette: palette,
                    width: 80,
                    height: 32,
                    radius: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _ProfileSectionSkeleton(
          animation: animation,
          palette: palette,
          titleWidth: 100,
        ),
        const SizedBox(height: 14),
        _ProfileSectionSkeleton(
          animation: animation,
          palette: palette,
          titleWidth: 130,
        ),
        const SizedBox(height: 14),
        _ProfileSectionSkeleton(
          animation: animation,
          palette: palette,
          titleWidth: 85,
        ),
      ],
    );
  }
}

class _ProfileSectionSkeleton extends StatelessWidget {
  const _ProfileSectionSkeleton({
    required this.animation,
    required this.palette,
    required this.titleWidth,
  });

  final Animation<double> animation;
  final AppPalette palette;
  final double titleWidth;

  @override
  Widget build(BuildContext context) {
    return _SkeletonCard(
      animation: animation,
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(
            animation: animation,
            palette: palette,
            width: titleWidth,
            height: 16,
          ),
          const SizedBox(height: 16),
          _SkeletonBox(animation: animation, palette: palette, height: 10),
          const SizedBox(height: 8),
          _SkeletonBox(
            animation: animation,
            palette: palette,
            width: 245,
            height: 10,
          ),
          const SizedBox(height: 14),
          _SkeletonBox(
            animation: animation,
            palette: palette,
            width: 125,
            height: 10,
          ),
        ],
      ),
    );
  }
}

class _RoadmapSkeleton extends StatelessWidget {
  const _RoadmapSkeleton({required this.animation, required this.palette});

  final Animation<double> animation;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SkeletonBox(
          animation: animation,
          palette: palette,
          width: 150,
          height: 20,
        ),
        const SizedBox(height: 9),
        _SkeletonBox(
          animation: animation,
          palette: palette,
          width: 260,
          height: 10,
        ),
        const SizedBox(height: 22),
        ...List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    _SkeletonCircle(
                      animation: animation,
                      palette: palette,
                      size: 36,
                    ),
                    if (index != 4)
                      Container(width: 2, height: 54, color: palette.surface2),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SkeletonCard(
                    animation: animation,
                    palette: palette,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBox(
                          animation: animation,
                          palette: palette,
                          width: 150,
                          height: 15,
                        ),
                        const SizedBox(height: 10),
                        _SkeletonBox(
                          animation: animation,
                          palette: palette,
                          height: 10,
                        ),
                        const SizedBox(height: 7),
                        _SkeletonBox(
                          animation: animation,
                          palette: palette,
                          width: 190,
                          height: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SkillsSkeleton extends StatelessWidget {
  const _SkillsSkeleton({required this.animation, required this.palette});

  final Animation<double> animation;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SkeletonBox(
          animation: animation,
          palette: palette,
          width: 140,
          height: 20,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _SkeletonBox(
              animation: animation,
              palette: palette,
              width: 82,
              height: 32,
              radius: 16,
            ),
            const SizedBox(width: 8),
            _SkeletonBox(
              animation: animation,
              palette: palette,
              width: 96,
              height: 32,
              radius: 16,
            ),
            const SizedBox(width: 8),
            _SkeletonBox(
              animation: animation,
              palette: palette,
              width: 75,
              height: 32,
              radius: 16,
            ),
          ],
        ),
        const SizedBox(height: 18),
        ...List.generate(
          6,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SkeletonCard(
              animation: animation,
              palette: palette,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _SkeletonCircle(
                    animation: animation,
                    palette: palette,
                    size: 42,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBox(
                          animation: animation,
                          palette: palette,
                          width: 125,
                          height: 14,
                        ),
                        const SizedBox(height: 8),
                        _SkeletonBox(
                          animation: animation,
                          palette: palette,
                          width: 190,
                          height: 9,
                        ),
                      ],
                    ),
                  ),
                  _SkeletonBox(
                    animation: animation,
                    palette: palette,
                    width: 45,
                    height: 22,
                    radius: 11,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CareerSkeleton extends StatelessWidget {
  const _CareerSkeleton({required this.animation, required this.palette});

  final Animation<double> animation;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SkeletonBox(
          animation: animation,
          palette: palette,
          width: 180,
          height: 21,
        ),
        const SizedBox(height: 10),
        _SkeletonBox(
          animation: animation,
          palette: palette,
          width: 275,
          height: 10,
        ),
        const SizedBox(height: 20),
        _SkeletonCard(
          animation: animation,
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(
                animation: animation,
                palette: palette,
                width: 125,
                height: 16,
              ),
              const SizedBox(height: 16),
              _SkeletonBox(
                animation: animation,
                palette: palette,
                height: 44,
                radius: 12,
              ),
              const SizedBox(height: 12),
              _SkeletonBox(
                animation: animation,
                palette: palette,
                height: 44,
                radius: 12,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SkeletonCard(
              animation: animation,
              palette: palette,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(
                    animation: animation,
                    palette: palette,
                    width: 150,
                    height: 16,
                  ),
                  const SizedBox(height: 10),
                  _SkeletonBox(
                    animation: animation,
                    palette: palette,
                    height: 10,
                  ),
                  const SizedBox(height: 7),
                  _SkeletonBox(
                    animation: animation,
                    palette: palette,
                    width: 220,
                    height: 10,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton({
    required this.animation,
    required this.palette,
  });

  final Animation<double> animation;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 7,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _SkeletonCard(
          animation: animation,
          palette: palette,
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonCircle(animation: animation, palette: palette, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(
                      animation: animation,
                      palette: palette,
                      width: 155,
                      height: 13,
                    ),
                    const SizedBox(height: 8),
                    _SkeletonBox(
                      animation: animation,
                      palette: palette,
                      height: 10,
                    ),
                    const SizedBox(height: 6),
                    _SkeletonBox(
                      animation: animation,
                      palette: palette,
                      width: 200,
                      height: 10,
                    ),
                    const SizedBox(height: 9),
                    _SkeletonBox(
                      animation: animation,
                      palette: palette,
                      width: 70,
                      height: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatSkeleton extends StatelessWidget {
  const _ChatSkeleton({required this.animation, required this.palette});

  final Animation<double> animation;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _ChatBubbleSkeleton(
            animation: animation,
            palette: palette,
            width: 250,
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: _ChatBubbleSkeleton(
            animation: animation,
            palette: palette,
            width: 190,
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: _ChatBubbleSkeleton(
            animation: animation,
            palette: palette,
            width: 285,
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: _ChatBubbleSkeleton(
            animation: animation,
            palette: palette,
            width: 220,
          ),
        ),
      ],
    );
  }
}

class _ChatBubbleSkeleton extends StatelessWidget {
  const _ChatBubbleSkeleton({
    required this.animation,
    required this.palette,
    required this.width,
  });

  final Animation<double> animation;
  final AppPalette palette;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(animation: animation, palette: palette, height: 10),
          const SizedBox(height: 7),
          _SkeletonBox(
            animation: animation,
            palette: palette,
            width: width * 0.65,
            height: 10,
          ),
        ],
      ),
    );
  }
}

class _GenericSkeleton extends StatelessWidget {
  const _GenericSkeleton({required this.animation, required this.palette});

  final Animation<double> animation;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SkeletonBox(
          animation: animation,
          palette: palette,
          width: 180,
          height: 20,
        ),
        const SizedBox(height: 18),
        ...List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SkeletonCard(
              animation: animation,
              palette: palette,
              child: Row(
                children: [
                  _SkeletonCircle(
                    animation: animation,
                    palette: palette,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBox(
                          animation: animation,
                          palette: palette,
                          width: 145,
                          height: 14,
                        ),
                        const SizedBox(height: 8),
                        _SkeletonBox(
                          animation: animation,
                          palette: palette,
                          height: 10,
                        ),
                        const SizedBox(height: 6),
                        _SkeletonBox(
                          animation: animation,
                          palette: palette,
                          width: 180,
                          height: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
