import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_palette.dart';

/// Route-aware skeleton loading widget.
class LoadingView extends StatefulWidget {
  const LoadingView({super.key});

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final route = GoRouterState.of(context).matchedLocation;

    // Do not change the Admin loading experience.
    if (route.startsWith('/admin')) {
      return _SpinnerLoading(palette: palette);
    }

    // Small/embedded loading states should remain compact.
    if (route == '/onboarding' ||
        route == '/login' ||
        route == '/register' ||
        route == '/forgot-password' ||
        route == '/verify-email' ||
        route == '/splash') {
      return _SpinnerLoading(palette: palette);
    }

    if (route == '/dashboard') {
      return _DashboardSkeleton(controller: _controller, palette: palette);
    }

    if (route == '/roadmap') {
      return _RoadmapSkeleton(controller: _controller, palette: palette);
    }

    if (route == '/profile') {
      return _ProfileSkeleton(controller: _controller, palette: palette);
    }

    if (route == '/profile/skills') {
      return _SkillsSkeleton(controller: _controller, palette: palette);
    }

    if (route == '/profile/career-goal') {
      return _CareerSkeleton(controller: _controller, palette: palette);
    }

    if (route == '/projects') {
      return _ProjectsSkeleton(controller: _controller, palette: palette);
    }

    if (route == '/projects/mine') {
      return _MyProjectsSkeleton(controller: _controller, palette: palette);
    }

    if (route == '/projects/invites') {
      return _InvitesSkeleton(controller: _controller, palette: palette);
    }

    if (route.startsWith('/projects/') && route.endsWith('/discussion')) {
      return _DiscussionSkeleton(controller: _controller, palette: palette);
    }

    if (route.startsWith('/projects/') && route.contains('/post/')) {
      return _PostDetailSkeleton(controller: _controller, palette: palette);
    }

    if (route.startsWith('/projects/') && route.contains('/edit')) {
      return _ProjectFormSkeleton(controller: _controller, palette: palette);
    }

    if (route.startsWith('/projects/mine/')) {
      return _ProjectManageSkeleton(controller: _controller, palette: palette);
    }

    if (route.startsWith('/projects/')) {
      return _ProjectDetailSkeleton(controller: _controller, palette: palette);
    }

    if (route == '/notifications') {
      return _NotificationsSkeleton(controller: _controller, palette: palette);
    }

    if (route.startsWith('/assistant')) {
      return _ChatSkeleton(controller: _controller, palette: palette);
    }

    if (route.startsWith('/roadmap/skill/')) {
      return _ChatSkeleton(controller: _controller, palette: palette);
    }

    return _GenericSkeleton(controller: _controller, palette: palette);
  }
}

class _SpinnerLoading extends StatelessWidget {
  const _SpinnerLoading({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(color: palette.indigo, strokeWidth: 2.5),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.controller,
    required this.palette,
    this.width,
    this.height = 14,
    this.radius = 8,
  });

  final Animation<double> controller;
  final AppPalette palette;
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    final baseColor = isLight
        ? const Color(0xFFE1E4E8)
        : const Color(0xFF292D33);

    final highlightColor = isLight
        ? const Color(0xFFF7F8F9)
        : const Color(0xFF454A52);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final position = (controller.value * 2.4) - 0.7;

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
                (position - 0.18).clamp(0.0, 1.0),
                position.clamp(0.0, 1.0),
                (position + 0.18).clamp(0.0, 1.0),
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
    required this.controller,
    required this.palette,
    required this.size,
  });

  final Animation<double> controller;
  final AppPalette palette;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    final baseColor = isLight
        ? const Color(0xFFE1E4E8)
        : const Color(0xFF292D33);

    final highlightColor = isLight
        ? const Color(0xFFF7F8F9)
        : const Color(0xFF454A52);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final position = (controller.value * 2.4) - 0.7;

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
                (position - 0.18).clamp(0.0, 1.0),
                position.clamp(0.0, 1.0),
                (position + 0.18).clamp(0.0, 1.0),
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
    required this.controller,
    required this.palette,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Animation<double> controller;
  final AppPalette palette;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border.withValues(alpha: 0.45)),
      ),
      child: child,
    );
  }
}

class _SkeletonTextBlock extends StatelessWidget {
  const _SkeletonTextBlock({
    required this.controller,
    required this.palette,
    this.lines = 3,
  });

  final Animation<double> controller;
  final AppPalette palette;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        lines,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == lines - 1 ? 0 : 8),
          child: _SkeletonBox(
            controller: controller,
            palette: palette,
            width: index == lines - 1 ? 180 : double.infinity,
            height: 10,
          ),
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton({required this.controller, required this.palette});

  final Animation<double> controller;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            _SkeletonCircle(controller: controller, palette: palette, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(
                    controller: controller,
                    palette: palette,
                    width: 150,
                    height: 17,
                  ),
                  const SizedBox(height: 8),
                  _SkeletonBox(
                    controller: controller,
                    palette: palette,
                    width: 210,
                    height: 10,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        _SkeletonCard(
          controller: controller,
          palette: palette,
          child: Row(
            children: [
              _SkeletonCircle(
                controller: controller,
                palette: palette,
                size: 64,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(
                      controller: controller,
                      palette: palette,
                      width: 140,
                      height: 17,
                    ),
                    const SizedBox(height: 10),
                    _SkeletonBox(
                      controller: controller,
                      palette: palette,
                      height: 10,
                    ),
                    const SizedBox(height: 7),
                    _SkeletonBox(
                      controller: controller,
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

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: _DashboardStatSkeleton(
                controller: controller,
                palette: palette,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DashboardStatSkeleton(
                controller: controller,
                palette: palette,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        _SkeletonCard(
          controller: controller,
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(
                controller: controller,
                palette: palette,
                width: 130,
                height: 17,
              ),
              const SizedBox(height: 18),
              _SkeletonBox(
                controller: controller,
                palette: palette,
                height: 10,
              ),
              const SizedBox(height: 8),
              _SkeletonBox(
                controller: controller,
                palette: palette,
                width: 260,
                height: 10,
              ),
              const SizedBox(height: 18),
              _SkeletonBox(
                controller: controller,
                palette: palette,
                width: 115,
                height: 34,
                radius: 10,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        _SkeletonCard(
          controller: controller,
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(
                controller: controller,
                palette: palette,
                width: 120,
                height: 17,
              ),
              const SizedBox(height: 16),
              ...List.generate(
                3,
                (index) => Padding(
                  padding: EdgeInsets.only(bottom: index == 2 ? 0 : 14),
                  child: Row(
                    children: [
                      _SkeletonCircle(
                        controller: controller,
                        palette: palette,
                        size: 38,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SkeletonBox(
                          controller: controller,
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

class _DashboardStatSkeleton extends StatelessWidget {
  const _DashboardStatSkeleton({
    required this.controller,
    required this.palette,
  });

  final Animation<double> controller;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return _SkeletonCard(
      controller: controller,
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(
            controller: controller,
            palette: palette,
            width: 70,
            height: 10,
          ),
          const SizedBox(height: 12),
          _SkeletonBox(
            controller: controller,
            palette: palette,
            width: 85,
            height: 22,
          ),
        ],
      ),
    );
  }
}

class _ProjectsSkeleton extends StatelessWidget {
  const _ProjectsSkeleton({required this.controller, required this.palette});

  final Animation<double> controller;
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
                controller: controller,
                palette: palette,
                height: 44,
                radius: 12,
              ),
            ),
            const SizedBox(width: 10),
            _SkeletonBox(
              controller: controller,
              palette: palette,
              width: 48,
              height: 44,
              radius: 12,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _SkeletonBox(
              controller: controller,
              palette: palette,
              width: 75,
              height: 30,
              radius: 15,
            ),
            const SizedBox(width: 8),
            _SkeletonBox(
              controller: controller,
              palette: palette,
              width: 90,
              height: 30,
              radius: 15,
            ),
            const SizedBox(width: 8),
            _SkeletonBox(
              controller: controller,
              palette: palette,
              width: 72,
              height: 30,
              radius: 15,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(
          4,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ProjectCardSkeleton(
              controller: controller,
              palette: palette,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectCardSkeleton extends StatelessWidget {
  const _ProjectCardSkeleton({required this.controller, required this.palette});

  final Animation<double> controller;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return _SkeletonCard(
      controller: controller,
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SkeletonBox(
                  controller: controller,
                  palette: palette,
                  width: 150,
                  height: 17,
                ),
              ),
              _SkeletonBox(
                controller: controller,
                palette: palette,
                width: 65,
                height: 24,
                radius: 12,
              ),
            ],
          ),
          const SizedBox(height: 13),
          _SkeletonBox(controller: controller, palette: palette, height: 10),
          const SizedBox(height: 7),
          _SkeletonBox(
            controller: controller,
            palette: palette,
            width: 240,
            height: 10,
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _SkeletonBox(
                controller: controller,
                palette: palette,
                width: 62,
                height: 23,
                radius: 12,
              ),
              const SizedBox(width: 7),
              _SkeletonBox(
                controller: controller,
                palette: palette,
                width: 70,
                height: 23,
                radius: 12,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _SkeletonCircle(
                controller: controller,
                palette: palette,
                size: 30,
              ),
              const SizedBox(width: 8),
              _SkeletonBox(
                controller: controller,
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

class _MyProjectsSkeleton extends StatelessWidget {
  const _MyProjectsSkeleton({required this.controller, required this.palette});

  final Animation<double> controller;
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
                controller: controller,
                palette: palette,
                width: 170,
                height: 20,
              ),
            ),
            _SkeletonBox(
              controller: controller,
              palette: palette,
              width: 44,
              height: 40,
              radius: 10,
            ),
          ],
        ),
        const SizedBox(height: 18),
        ...List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ProjectCardSkeleton(
              controller: controller,
              palette: palette,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectDetailSkeleton extends StatelessWidget {
  const _ProjectDetailSkeleton({
    required this.controller,
    required this.palette,
  });

  final Animation<double> controller;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SkeletonBox(
          controller: controller,
          palette: palette,
          width: 220,
          height: 23,
        ),
        const SizedBox(height: 10),
        _SkeletonBox(
          controller: controller,
          palette: palette,
          width: 100,
          height: 25,
          radius: 13,
        ),
        const SizedBox(height: 18),
        _SkeletonCard(
          controller: controller,
          palette: palette,
          child: _SkeletonTextBlock(
            controller: controller,
            palette: palette,
            lines: 4,
          ),
        ),
        const SizedBox(height: 14),
        _SkeletonCard(
          controller: controller,
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(
                controller: controller,
                palette: palette,
                width: 110,
                height: 17,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _SkeletonCircle(
                    controller: controller,
                    palette: palette,
                    size: 40,
                  ),
                  const SizedBox(width: 10),
                  _SkeletonBox(
                    controller: controller,
                    palette: palette,
                    width: 130,
                    height: 11,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _SkeletonCircle(
                    controller: controller,
                    palette: palette,
                    size: 40,
                  ),
                  const SizedBox(width: 10),
                  _SkeletonBox(
                    controller: controller,
                    palette: palette,
                    width: 155,
                    height: 11,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProjectManageSkeleton extends StatelessWidget {
  const _ProjectManageSkeleton({
    required this.controller,
    required this.palette,
  });

  final Animation<double> controller;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SkeletonBox(
          controller: controller,
          palette: palette,
          width: 200,
          height: 22,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _SkeletonBox(
                controller: controller,
                palette: palette,
                height: 42,
                radius: 10,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SkeletonBox(
                controller: controller,
                palette: palette,
                height: 42,
                radius: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SkeletonCard(
          controller: controller,
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(
                controller: controller,
                palette: palette,
                width: 130,
                height: 16,
              ),
              const SizedBox(height: 16),
              ...List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Row(
                    children: [
                      _SkeletonCircle(
                        controller: controller,
                        palette: palette,
                        size: 38,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SkeletonBox(
                          controller: controller,
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

class _ProjectFormSkeleton extends StatelessWidget {
  const _ProjectFormSkeleton({required this.controller, required this.palette});

  final Animation<double> controller;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SkeletonBox(
          controller: controller,
          palette: palette,
          width: 180,
          height: 22,
        ),
        const SizedBox(height: 22),
        ...List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _SkeletonBox(
              controller: controller,
              palette: palette,
              height: index == 2 ? 110 : 48,
              radius: 10,
            ),
          ),
        ),
        _SkeletonBox(
          controller: controller,
          palette: palette,
          width: 120,
          height: 44,
          radius: 10,
        ),
      ],
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton({required this.controller, required this.palette});

  final Animation<double> controller;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SkeletonCard(
          controller: controller,
          palette: palette,
          child: Column(
            children: [
              _SkeletonCircle(
                controller: controller,
                palette: palette,
                size: 88,
              ),
              const SizedBox(height: 14),
              _SkeletonBox(
                controller: controller,
                palette: palette,
                width: 150,
                height: 19,
              ),
              const SizedBox(height: 8),
              _SkeletonBox(
                controller: controller,
                palette: palette,
                width: 200,
                height: 10,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SkeletonBox(
                    controller: controller,
                    palette: palette,
                    width: 82,
                    height: 32,
                    radius: 16,
                  ),
                  const SizedBox(width: 8),
                  _SkeletonBox(
                    controller: controller,
                    palette: palette,
                    width: 82,
                    height: 32,
                    radius: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _SkeletonCard(
              controller: controller,
              palette: palette,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(
                    controller: controller,
                    palette: palette,
                    width: 110 + (index * 15),
                    height: 16,
                  ),
                  const SizedBox(height: 16),
                  _SkeletonTextBlock(
                    controller: controller,
                    palette: palette,
                    lines: 3,
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

class _SkillsSkeleton extends StatelessWidget {
  const _SkillsSkeleton({required this.controller, required this.palette});

  final Animation<double> controller;
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
                controller: controller,
                palette: palette,
                width: 150,
                height: 20,
              ),
            ),
            _SkeletonBox(
              controller: controller,
              palette: palette,
              width: 42,
              height: 40,
              radius: 10,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _SkeletonBox(
              controller: controller,
              palette: palette,
              width: 82,
              height: 30,
              radius: 15,
            ),
            const SizedBox(width: 8),
            _SkeletonBox(
              controller: controller,
              palette: palette,
              width: 95,
              height: 30,
              radius: 15,
            ),
          ],
        ),
        const SizedBox(height: 18),
        ...List.generate(
          6,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SkeletonCard(
              controller: controller,
              palette: palette,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _SkeletonCircle(
                    controller: controller,
                    palette: palette,
                    size: 42,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBox(
                          controller: controller,
                          palette: palette,
                          width: 130,
                          height: 14,
                        ),
                        const SizedBox(height: 8),
                        _SkeletonBox(
                          controller: controller,
                          palette: palette,
                          width: 180,
                          height: 9,
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

class _CareerSkeleton extends StatelessWidget {
  const _CareerSkeleton({required this.controller, required this.palette});

  final Animation<double> controller;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SkeletonBox(
          controller: controller,
          palette: palette,
          width: 175,
          height: 21,
        ),
        const SizedBox(height: 9),
        _SkeletonBox(
          controller: controller,
          palette: palette,
          width: 270,
          height: 10,
        ),
        const SizedBox(height: 20),
        _SkeletonCard(
          controller: controller,
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(
                controller: controller,
                palette: palette,
                width: 125,
                height: 16,
              ),
              const SizedBox(height: 16),
              _SkeletonBox(
                controller: controller,
                palette: palette,
                height: 45,
                radius: 11,
              ),
              const SizedBox(height: 10),
              _SkeletonBox(
                controller: controller,
                palette: palette,
                height: 45,
                radius: 11,
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
              controller: controller,
              palette: palette,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(
                    controller: controller,
                    palette: palette,
                    width: 155,
                    height: 16,
                  ),
                  const SizedBox(height: 11),
                  _SkeletonTextBlock(
                    controller: controller,
                    palette: palette,
                    lines: 2,
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

class _RoadmapSkeleton extends StatelessWidget {
  const _RoadmapSkeleton({required this.controller, required this.palette});

  final Animation<double> controller;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SkeletonBox(
          controller: controller,
          palette: palette,
          width: 150,
          height: 21,
        ),
        const SizedBox(height: 9),
        _SkeletonBox(
          controller: controller,
          palette: palette,
          width: 260,
          height: 10,
        ),
        const SizedBox(height: 22),
        ...List.generate(
          5,
          (index) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _SkeletonCircle(
                    controller: controller,
                    palette: palette,
                    size: 36,
                  ),
                  if (index < 4)
                    Container(width: 2, height: 62, color: palette.surface2),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SkeletonCard(
                    controller: controller,
                    palette: palette,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBox(
                          controller: controller,
                          palette: palette,
                          width: 150,
                          height: 15,
                        ),
                        const SizedBox(height: 10),
                        _SkeletonBox(
                          controller: controller,
                          palette: palette,
                          height: 10,
                        ),
                        const SizedBox(height: 7),
                        _SkeletonBox(
                          controller: controller,
                          palette: palette,
                          width: 190,
                          height: 10,
                        ),
                      ],
                    ),
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

class _InvitesSkeleton extends StatelessWidget {
  const _InvitesSkeleton({required this.controller, required this.palette});

  final Animation<double> controller;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SkeletonBox(
          controller: controller,
          palette: palette,
          width: 150,
          height: 21,
        ),
        const SizedBox(height: 18),
        ...List.generate(
          4,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SkeletonCard(
              controller: controller,
              palette: palette,
              child: Row(
                children: [
                  _SkeletonCircle(
                    controller: controller,
                    palette: palette,
                    size: 48,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBox(
                          controller: controller,
                          palette: palette,
                          width: 145,
                          height: 14,
                        ),
                        const SizedBox(height: 8),
                        _SkeletonBox(
                          controller: controller,
                          palette: palette,
                          width: 190,
                          height: 10,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _SkeletonBox(
                              controller: controller,
                              palette: palette,
                              width: 70,
                              height: 28,
                              radius: 14,
                            ),
                            const SizedBox(width: 8),
                            _SkeletonBox(
                              controller: controller,
                              palette: palette,
                              width: 70,
                              height: 28,
                              radius: 14,
                            ),
                          ],
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

class _DiscussionSkeleton extends StatelessWidget {
  const _DiscussionSkeleton({required this.controller, required this.palette});

  final Animation<double> controller;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SkeletonBox(
          controller: controller,
          palette: palette,
          width: 180,
          height: 21,
        ),
        const SizedBox(height: 18),
        ...List.generate(
          4,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SkeletonCard(
              controller: controller,
              palette: palette,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonCircle(
                    controller: controller,
                    palette: palette,
                    size: 42,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBox(
                          controller: controller,
                          palette: palette,
                          width: 130,
                          height: 14,
                        ),
                        const SizedBox(height: 9),
                        _SkeletonBox(
                          controller: controller,
                          palette: palette,
                          height: 10,
                        ),
                        const SizedBox(height: 7),
                        _SkeletonBox(
                          controller: controller,
                          palette: palette,
                          width: 220,
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

class _PostDetailSkeleton extends StatelessWidget {
  const _PostDetailSkeleton({required this.controller, required this.palette});

  final Animation<double> controller;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SkeletonCard(
          controller: controller,
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SkeletonCircle(
                    controller: controller,
                    palette: palette,
                    size: 44,
                  ),
                  const SizedBox(width: 10),
                  _SkeletonBox(
                    controller: controller,
                    palette: palette,
                    width: 130,
                    height: 13,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SkeletonBox(
                controller: controller,
                palette: palette,
                width: 200,
                height: 18,
              ),
              const SizedBox(height: 13),
              _SkeletonTextBlock(
                controller: controller,
                palette: palette,
                lines: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SkeletonBox(
          controller: controller,
          palette: palette,
          width: 100,
          height: 17,
        ),
        const SizedBox(height: 12),
        ...List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SkeletonCard(
              controller: controller,
              palette: palette,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonCircle(
                    controller: controller,
                    palette: palette,
                    size: 34,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SkeletonTextBlock(
                      controller: controller,
                      palette: palette,
                      lines: 2,
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

class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton({
    required this.controller,
    required this.palette,
  });

  final Animation<double> controller;
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
          controller: controller,
          palette: palette,
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonCircle(
                controller: controller,
                palette: palette,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(
                      controller: controller,
                      palette: palette,
                      width: 150,
                      height: 13,
                    ),
                    const SizedBox(height: 8),
                    _SkeletonBox(
                      controller: controller,
                      palette: palette,
                      height: 10,
                    ),
                    const SizedBox(height: 6),
                    _SkeletonBox(
                      controller: controller,
                      palette: palette,
                      width: 200,
                      height: 10,
                    ),
                    const SizedBox(height: 8),
                    _SkeletonBox(
                      controller: controller,
                      palette: palette,
                      width: 65,
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
  const _ChatSkeleton({required this.controller, required this.palette});

  final Animation<double> controller;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _ChatBubble(
            controller: controller,
            palette: palette,
            width: 250,
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: _ChatBubble(
            controller: controller,
            palette: palette,
            width: 190,
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: _ChatBubble(
            controller: controller,
            palette: palette,
            width: 285,
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.controller,
    required this.palette,
    required this.width,
  });

  final Animation<double> controller;
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
          _SkeletonBox(controller: controller, palette: palette, height: 10),
          const SizedBox(height: 7),
          _SkeletonBox(
            controller: controller,
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
  const _GenericSkeleton({required this.controller, required this.palette});

  final Animation<double> controller;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SkeletonBox(
          controller: controller,
          palette: palette,
          width: 180,
          height: 21,
        ),
        const SizedBox(height: 18),
        ...List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SkeletonCard(
              controller: controller,
              palette: palette,
              child: Row(
                children: [
                  _SkeletonCircle(
                    controller: controller,
                    palette: palette,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SkeletonTextBlock(
                      controller: controller,
                      palette: palette,
                      lines: 3,
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
