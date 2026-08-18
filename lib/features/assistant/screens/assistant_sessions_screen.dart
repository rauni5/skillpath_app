import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/assistant_chat_session.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/assistant_chat_provider.dart';

class AssistantSessionsScreen extends StatefulWidget {
  const AssistantSessionsScreen({super.key});

  @override
  State<AssistantSessionsScreen> createState() =>
      _AssistantSessionsScreenState();
}

class _AssistantSessionsScreenState extends State<AssistantSessionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      context.read<AssistantChatProvider>().loadSessions(userId);
    }
  }

  Future<void> _openSession(AssistantChatSession session) async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    await context.read<AssistantChatProvider>().loadMessages(userId, session);
    if (!mounted) return;
    context.push('/assistant/session', extra: session);
  }

  Future<void> _startNewChat() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    final session = await context.read<AssistantChatProvider>().startNewSession(
      userId,
    );
    if (session == null || !mounted) return;
    await context.read<AssistantChatProvider>().loadMessages(userId, session);
    if (!mounted) return;
    context.push('/assistant/session', extra: session);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final provider = context.watch<AssistantChatProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('SkillPath Assistant')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewChat,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('New chat'),
      ),
      body: _buildBody(context, p, provider),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppPalette p,
    AssistantChatProvider provider,
  ) {
    switch (provider.sessionsState) {
      case SessionsLoadState.initial:
      case SessionsLoadState.loading:
        return const LoadingView();
      case SessionsLoadState.error:
        return ErrorView(
          message: provider.sessionsError ?? 'Something went wrong.',
          onRetry: _load,
        );
      case SessionsLoadState.loaded:
        if (provider.sessions.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 60),
              Icon(Icons.support_agent, size: 36, color: p.textMuted),
              const SizedBox(height: 14),
              Text(
                'Ask the assistant how to use any part of SkillPath, or for '
                'help with your own roadmap and progress.',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted, fontSize: 13),
              ),
            ],
          );
        }
        return RefreshIndicator(
          onRefresh: () async => _load(),
          child: ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: provider.sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final s = provider.sessions[i];
              return _SessionTile(session: s, onTap: () => _openSession(s));
            },
          ),
        );
    }
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.onTap});
  final AssistantChatSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: session.active ? p.indigoLight : p.surface1,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                session.active ? Icons.chat_bubble : Icons.history,
                size: 18,
                color: session.active ? p.indigo : p.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: p.textPrimary,
                          ),
                        ),
                      ),
                      if (session.active)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: p.greenLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: p.greenText,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (session.lastMessagePreview != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      session.lastMessagePreview!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: p.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 18, color: p.textMuted),
          ],
        ),
      ),
    );
  }
}
