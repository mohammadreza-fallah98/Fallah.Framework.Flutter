import 'package:flutter/material.dart';

import 'package:{{project_name.snakeCase()}}/core/l10n/l10n_extension.dart';
import 'package:{{project_name.snakeCase()}}/features/chat/presentation/chat_providers.dart';
import 'package:{{project_name.snakeCase()}}/features/chat/presentation/chat_thread.dart';

/// Support conversation (`subject = support`). Users see their own messages;
/// roles with a wider `chat:read` visibility see the whole queue.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.supportTitle)),
        body: const ChatThread(thread: ChatThreadKey()),
      );
}
