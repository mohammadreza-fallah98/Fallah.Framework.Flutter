import 'dart:convert';
import 'dart:io';

import 'package:mason/mason.dart';

/// Inserts [addition] (without indentation) above the line containing
/// [anchor] in [path], unless [ifMissing] is already in the file.
/// Returns false when the step must be done by hand.
bool _insertAboveAnchor(
  Logger log,
  String path,
  String anchor,
  String addition, {
  required String ifMissing,
}) {
  final file = File(path);
  if (!file.existsSync()) {
    log.warn('$path not found - add manually: $addition');
    return false;
  }
  final lines = file.readAsLinesSync();
  if (lines.any((l) => l.contains(ifMissing))) return true;
  final index = lines.indexWhere((l) => l.contains(anchor));
  if (index == -1) {
    log.warn('Anchor "$anchor" not found in $path - add manually: $addition');
    return false;
  }
  final indent = RegExp(r'^\s*').stringMatch(lines[index]) ?? '';
  lines.insert(index, '$indent$addition');
  file.writeAsStringSync('${lines.join('\n')}\n');
  return true;
}

/// Adds missing keys to an ARB file, keeping existing order.
void _addArbKeys(String path, Map<String, String> keys) {
  final file = File(path);
  if (!file.existsSync()) return;
  final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  var changed = false;
  keys.forEach((key, value) {
    if (!map.containsKey(key)) {
      map[key] = value;
      changed = true;
    }
  });
  if (changed) {
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(map)}\n',
    );
  }
}

void run(HookContext context) {
  final log = context.logger;
  final name = context.vars['name'] as String;
  final plural = context.vars['plural'] as String;
  final package = (context.vars['package'] as String).snakeCase;
  final snake = name.snakeCase;
  final nc = name.camelCase;
  final pc = plural.camelCase;

  final endpoint = _insertAboveAnchor(
    log,
    'lib/core/network/endpoints.dart',
    '// fallah:endpoints',
    "static const $pc = '/${plural.paramCase}';",
    ifMissing: 'static const $pc ',
  );
  final routerImport = _insertAboveAnchor(
    log,
    'lib/core/router/app_router.dart',
    '// fallah:imports',
    "import 'package:$package/features/$snake/presentation/${snake}_routes.dart';",
    ifMissing: '${snake}_routes.dart',
  );
  final routerEntry = _insertAboveAnchor(
    log,
    'lib/core/router/app_router.dart',
    '// fallah:routes',
    '...${nc}Routes(),',
    ifMissing: '...${nc}Routes()',
  );

  final title = plural.titleCase;
  final en = <String, String>{
    '${pc}Title': title,
    '${pc}Empty': 'No ${plural.sentenceCase.toLowerCase()} yet',
    '${nc}New': 'New ${name.sentenceCase.toLowerCase()}',
    '${nc}EditTitle': 'Edit ${name.sentenceCase.toLowerCase()}',
    '${nc}DetailTitle': name.titleCase,
    '${nc}FieldTitle': 'Title',
  };
  _addArbKeys('lib/l10n/app_en.arb', en);
  // Persian text must be translated by hand; keys are added so the app builds.
  _addArbKeys('lib/l10n/app_fa.arb', en);

  log
    ..info('')
    ..success('Feature "$name" generated.')
    ..info(
      endpoint && routerImport && routerEntry
          ? 'Registered: endpoint, route list, ARB keys.'
          : 'Some registration steps need manual work (see warnings above).',
    )
    ..warn(
      'Translate the new keys in lib/l10n/app_fa.arb '
      '(${en.keys.join(', ')}) - they hold English placeholders.',
    )
    ..info('Next: adjust the fields of the entity/model (id/title are placeholders).')
    ..info('Then: dart run build_runner build -d && flutter gen-l10n && flutter test')
    ..info('Permissions used: $snake:read, $snake:create, $snake:update, '
        '$snake:delete (kebab-case of the entity name).');
}
