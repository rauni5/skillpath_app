import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/discussion_post.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../providers/discussion_provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    super.key,
    required this.projectId,
    required this.channel,
  });

  final int projectId;
  final DiscussionChannel channel;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  PostTag _tag = PostTag.general;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<DiscussionProvider>();
    final post = await provider.createPost(
      widget.projectId,
      channel: widget.channel,
      tag: _tag,
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
    );
    if (!mounted) return;
    if (post != null) {
      context.pop();
    } else if (provider.createPostError != null) {
      showErrorDialog(
        context,
        provider.createPostError!,
        title: 'Failed to create post',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final provider = context.watch<DiscussionProvider>();

    return Scaffold(
      backgroundColor: p.surface0,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          widget.channel == DiscussionChannel.public
              ? 'New public post'
              : 'New team post',
        ),
        actions: [
          if (provider.isCreatingPost)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _submit,
              child: Text(
                'Post',
                style: TextStyle(fontWeight: FontWeight.bold, color: p.indigo),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            Text(
              'TAG',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: p.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PostTag.values
                  .map(
                    (t) => _TagOption(
                      tag: t,
                      selected: t == _tag,
                      onTap: () => setState(() => _tag = t),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
              maxLength: 200,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(
                labelText: 'What do you want to say?',
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              maxLength: 5000,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            if (provider.createPostError != null) ...[
              const SizedBox(height: 6),
              Text(
                provider.createPostError!,
                style: TextStyle(color: p.red, fontSize: 12.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TagOption extends StatelessWidget {
  const _TagOption({
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  final PostTag tag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final (fg, bg) = switch (tag) {
      PostTag.question => (p.indigo, p.indigoLight),
      PostTag.update => (p.greenText, p.greenLight),
      PostTag.announcement => (p.amberText, p.amberLight),
      PostTag.general => (p.textMuted, p.surface1),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? bg : p.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? fg : p.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check_circle_rounded, size: 14, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              tag.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? fg : p.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
