import 'package:fallah_api/fallah_api.dart';
import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_ui/fallah_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:{{project_name.snakeCase()}}/core/auth/can.dart';
import 'package:{{project_name.snakeCase()}}/core/l10n/l10n_extension.dart';
import 'package:{{project_name.snakeCase()}}/core/widgets/async_body.dart';
import 'package:{{project_name.snakeCase()}}/core/widgets/dialogs.dart';
import 'package:{{project_name.snakeCase()}}/features/attachments/presentation/attachment_providers.dart';
import 'package:{{project_name.snakeCase()}}/features/attachments/presentation/attachment_tile.dart';
import 'package:{{project_name.snakeCase()}}/features/chat/presentation/chat_providers.dart';
import 'package:{{project_name.snakeCase()}}/features/profile/presentation/profile_screen.dart';

/// Messages + composer for one conversation. Embed it in any screen:
/// `ChatThread(thread: ChatThreadKey(subject: 'order', subjectId: id))`.
class ChatThread extends ConsumerStatefulWidget {
  const ChatThread({required this.thread, super.key});

  final ChatThreadKey thread;

  @override
  ConsumerState<ChatThread> createState() => _ChatThreadState();
}

class _ChatThreadState extends ConsumerState<ChatThread> {
  final _text = TextEditingController();
  final _files = <PlatformFile>[];
  final _markedSeen = <int>{};
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _attach() async {
    final picked = await pickFiles();
    if (picked.isNotEmpty) setState(() => _files.addAll(picked));
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);

    final failure = await ref
        .read(chatMessagesProvider(widget.thread).notifier)
        .send(text, List.of(_files));
    if (!mounted) return;

    setState(() => _sending = false);
    if (failure != null) return showFailure(context, failure);
    setState(() {
      _text.clear();
      _files.clear();
    });
  }

  /// Marks messages from others as seen once they are on screen.
  void _markIncomingSeen(List<Chat> items, int? myId) {
    if (myId == null) return;
    final unseen = [
      for (final c in items)
        if (!c.isSeen && c.audit.createdBy != myId && _markedSeen.add(c.id)) c.id,
    ];
    if (unseen.isEmpty) return;
    final notifier = ref.read(chatMessagesProvider(widget.thread).notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final id in unseen) {
        notifier.markSeen(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = chatMessagesProvider(widget.thread);
    final myId = ref.watch(profileProvider).value?.id;

    return Column(
      children: [
        Expanded(
          child: AsyncBody<PagedState<Chat>>(
            value: ref.watch(provider),
            onRetry: () => ref.invalidate(provider),
            data: (state) {
              if (state.items.isEmpty) {
                return AppEmptyView(message: l10n.chatEmpty);
              }
              _markIncomingSeen(state.items, myId);
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  // Reaching the oldest loaded message asks for older ones.
                  if (index == state.items.length - 1 && state.hasMore) {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => ref.read(provider.notifier).loadMore(),
                    );
                  }
                  final chat = state.items[index];
                  return _Bubble(
                    chat: chat,
                    mine: myId != null && chat.audit.createdBy == myId,
                  );
                },
              );
            },
          ),
        ),
        if (ref.can('chat:create')) ...[
          if (_files.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: [
                  for (final f in _files)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: AppSpacing.sm,
                      ),
                      child: InputChip(
                        label: Text(f.name),
                        onDeleted: _sending
                            ? null
                            : () => setState(() => _files.remove(f)),
                      ),
                    ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.chatAttach,
                    icon: const Icon(Icons.attach_file),
                    onPressed: _sending ? null : _attach,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      enabled: !_sending,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 4000,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: l10n.chatHint,
                        counterText: '',
                      ),
                    ),
                  ),
                  _sending
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          tooltip: l10n.chatSend,
                          icon: const Icon(Icons.send),
                          onPressed: _send,
                        ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.chat, required this.mine});

  final Chat chat;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final created = chat.audit.createdAt;

    return Align(
      alignment:
          mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Card(
          color: mine ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!mine && chat.audit.createdByName != null)
                  Text(
                    chat.audit.createdByName!,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                Text(chat.message),
                for (final a in chat.attachments) AttachmentTile(attachment: a),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (created != null)
                      Text(
                        formatJalali(created, withTime: true),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    if (mine) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        chat.isSeen ? Icons.done_all : Icons.done,
                        size: 14,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
