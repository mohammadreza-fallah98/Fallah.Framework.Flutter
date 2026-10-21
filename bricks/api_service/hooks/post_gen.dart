import 'dart:io';

import 'package:mason/mason.dart';

void run(HookContext context) {
  final log = context.logger;
  final name = context.vars['name'] as String;
  final plural = context.vars['plural'] as String;
  final pc = plural.camelCase;

  final file = File('lib/core/network/endpoints.dart');
  var registered = false;
  if (file.existsSync()) {
    final lines = file.readAsLinesSync();
    if (lines.any((l) => l.contains('static const $pc '))) {
      registered = true;
    } else {
      final index = lines.indexWhere((l) => l.contains('// fallah:endpoints'));
      if (index != -1) {
        final indent = RegExp(r'^\s*').stringMatch(lines[index]) ?? '';
        lines.insert(
          index,
          "${indent}static const $pc = '/${plural.paramCase}';",
        );
        file.writeAsStringSync('${lines.join('\n')}\n');
        registered = true;
      }
    }
  }

  log
    ..info('')
    ..success('API service "$name" generated.')
    ..info(
      registered
          ? 'Registered the endpoint in core/network/endpoints.dart.'
          : "Add to core/network/endpoints.dart: static const $pc = '/${plural.paramCase}';",
    )
    ..info('Adjust the entity/model fields (id/title are placeholders).')
    ..info('Expose it with a provider, e.g.')
    ..info('  @riverpod ${name.pascalCase}Repository ${name.camelCase}Repository(Ref ref) =>')
    ..info('      ${name.pascalCase}RepositoryImpl(${name.pascalCase}RemoteDataSource(ref.watch(dioProvider)));')
    ..info('Then: dart run build_runner build -d && flutter test');
}
