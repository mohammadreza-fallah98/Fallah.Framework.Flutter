import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:{{project_name.snakeCase()}}/core/auth/can.dart';
import 'package:{{project_name.snakeCase()}}/core/l10n/l10n_extension.dart';
import 'package:{{project_name.snakeCase()}}/core/widgets/async_body.dart';
import 'package:{{project_name.snakeCase()}}/core/widgets/dialogs.dart';
import 'package:{{project_name.snakeCase()}}/features/attachments/presentation/attachment_providers.dart';
import 'package:{{project_name.snakeCase()}}/features/attachments/presentation/attachment_tile.dart';

/// Uploaded files (`attachment:read`); upload needs `attachment:create`,
/// delete needs `attachment:delete`.
class AttachmentsScreen extends ConsumerWidget {
  const AttachmentsScreen({super.key});

  Future<void> _upload(BuildContext context, WidgetRef ref) async {
    final files = await pickFiles();
    if (files.isEmpty || !context.mounted) return;
    final failure =
        await ref.read(attachmentActionsProvider.notifier).upload(files);
    if (!context.mounted) return;
    if (failure != null) return showFailure(context, failure);
    showMessage(context, context.l10n.attachmentUploaded);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, int id) async {
    if (!await confirmDelete(context) || !context.mounted) return;
    final failure =
        await ref.read(attachmentActionsProvider.notifier).remove(id);
    if (!context.mounted) return;
    if (failure != null) return showFailure(context, failure);
    showMessage(context, context.l10n.deleted);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final busy = ref.watch(attachmentActionsProvider).isLoading;
    final notifier = ref.read(attachmentListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.attachmentsTitle),
        bottom: busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      floatingActionButton: ref.can('attachment:create')
          ? FloatingActionButton(
              tooltip: l10n.attachmentUpload,
              onPressed: busy ? null : () => _upload(context, ref),
              child: const Icon(Icons.upload_file),
            )
          : null,
      body: PagedAsyncList(
        value: ref.watch(attachmentListProvider),
        emptyMessage: l10n.attachmentsEmpty,
        onLoadMore: notifier.loadMore,
        onRefresh: () => ref.refresh(attachmentListProvider.future),
        itemBuilder: (context, attachment) => Card(
          child: AttachmentTile(
            attachment: attachment,
            trailing: ref.can('attachment:delete')
                ? IconButton(
                    tooltip: l10n.delete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed:
                        busy ? null : () => _delete(context, ref, attachment.id),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
