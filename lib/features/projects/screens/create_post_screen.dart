import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/discussion_post.dart';
import '../../../core/theme/app_palette.dart';
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
    if (post != null && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final provider = context.watch<DiscussionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.channel == DiscussionChannel.public
              ? 'New public post'
              : 'New team post',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TAG',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: p.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: PostTag.values.map((t) {
                    final selected = t == _tag;
                    return ChoiceChip(
                      label: Text(t.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _tag = t),
                      selectedColor: p.indigoLight,
                      labelStyle: TextStyle(
                        color: selected ? p.indigo : p.textSecondary,
                        fontSize: 12.5,
                      ),
                      side: BorderSide(color: selected ? p.indigo : p.border),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: provider.isCreatingPost ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: p.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: provider.isCreatingPost
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Post'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
