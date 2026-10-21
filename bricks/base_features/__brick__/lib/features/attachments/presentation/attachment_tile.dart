import 'package:fallah_api/fallah_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:{{project_name.snakeCase()}}/core/l10n/l10n_extension.dart';
import 'package:{{project_name.snakeCase()}}/core/widgets/dialogs.dart';
import 'package:{{project_name.snakeCase()}}/features/attachments/presentation/attachment_providers.dart';

/// `1536` -> `1.5 KB`.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// One attachment: icon, name and size. Tapping opens it with the system
/// (browser / viewer) through the server's short-lived URL.
class AttachmentTile extends ConsumerWidget {
  const AttachmentTile({required this.attachment, this.trailing, super.key});

  final Attachment attachment;
  final Widget? trailing;

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    try {
      final url = await ref.read(attachmentUrlProvider(attachment.id).future);
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme) throw const FormatException();
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        showMessage(context, l10n.attachmentOpenFailed);
      }
    } on Object {
      if (context.mounted) showMessage(context, l10n.attachmentOpenFailed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
        dense: true,
        leading: Icon(
          attachment.isImage ? Icons.image_outlined : Icons.attach_file,
        ),
        title: Text(
          attachment.title ?? attachment.fileName,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(formatBytes(attachment.size)),
        trailing: trailing,
        onTap: () => _open(context, ref),
      );
}
