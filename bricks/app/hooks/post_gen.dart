import 'dart:io';

import 'package:mason/mason.dart';

/// Removes the `flutter create` sample files that the brick replaces.
void _removeSamples(Logger log) {
  final main = File('lib/main.dart');
  if (main.existsSync() && main.readAsStringSync().contains('MyHomePage')) {
    main.deleteSync();
    log.detail('Removed the sample lib/main.dart');
  }
  final test = File('test/widget_test.dart');
  if (test.existsSync() && test.readAsStringSync().contains('Counter')) {
    test.deleteSync();
    log.detail('Removed the sample test/widget_test.dart');
  }
}

/// Adds dev/stg/prd Android flavors to the Kotlin DSL build file.
bool _addAndroidFlavors(Logger log, String appTitle) {
  final gradle = File('android/app/build.gradle.kts');
  if (!gradle.existsSync()) return false;
  final text = gradle.readAsStringSync();
  if (text.contains('productFlavors')) return true;

  final marker = RegExp(r'^(\s*)buildTypes\s*\{', multiLine: true);
  final match = marker.firstMatch(text);
  if (match == null) {
    log.warn('Could not find buildTypes in build.gradle.kts - add flavors manually.');
    return false;
  }
  final i = match.group(1)!;
  final block = '''
${i}flavorDimensions += "env"
${i}productFlavors {
$i    create("dev") {
$i        dimension = "env"
$i        applicationIdSuffix = ".dev"
$i        manifestPlaceholders["appName"] = "$appTitle Dev"
$i    }
$i    create("stg") {
$i        dimension = "env"
$i        applicationIdSuffix = ".stg"
$i        manifestPlaceholders["appName"] = "$appTitle Stg"
$i    }
$i    create("prd") {
$i        dimension = "env"
$i        manifestPlaceholders["appName"] = "$appTitle"
$i    }
$i}

''';
  gradle.writeAsStringSync(text.replaceRange(match.start, match.start, block));

  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (manifest.existsSync()) {
    final xml = manifest.readAsStringSync();
    manifest.writeAsStringSync(
      xml.replaceFirst(
        RegExp(r'android:label="[^"]*"'),
        'android:label="\${appName}"',
      ),
    );
  }
  return true;
}

/// Highest Android platform installed in the SDK, or null when unknown.
int? _installedPlatform() {
  final home =
      Platform.environment['ANDROID_HOME'] ?? Platform.environment['ANDROID_SDK_ROOT'];
  if (home == null) return null;
  final dir = Directory('$home/platforms');
  if (!dir.existsSync()) return null;
  final levels = <int>[
    for (final e in dir.listSync())
      if (RegExp(r'android-(\d+)$').firstMatch(e.path) case final m?)
        int.parse(m.group(1)!),
  ]..sort();
  return levels.isEmpty ? null : levels.last;
}

/// Some plugins pin an older compileSdk whose platform may not be installed
/// (Gradle fails with "Failed to find Platform SDK"). Compile every module
/// against the newest installed platform instead.
bool _alignPluginCompileSdk(Logger log) {
  final file = File('android/build.gradle.kts');
  if (!file.existsSync()) return false;
  if (file.readAsStringSync().contains('fallah:compileSdk')) return true;
  final level = _installedPlatform();
  if (level == null) {
    log.detail('ANDROID_HOME not set: compileSdk alignment skipped.');
    return false;
  }
  file.writeAsStringSync(
    '''

// fallah:compileSdk - some plugins pin an older compileSdk whose platform is
// not installed; compile every module against the installed platform.
subprojects {
    val alignCompileSdk: Project.() -> Unit = {
        extensions.findByName("android")?.let { ext ->
            ext.javaClass
                .getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                .invoke(ext, $level)
        }
    }
    if (state.executed) alignCompileSdk() else afterEvaluate { alignCompileSdk() }
}
''',
    mode: FileMode.append,
  );
  return true;
}
/// Kotlin's incremental compiler crashes on Windows when the project and the
/// Pub cache are on different drives ("this and base files have different
/// roots"). Turn it off only in that case.
bool _disableKotlinIncrementalOnSplitDrives(Logger log) {
  if (!Platform.isWindows) return false;
  final props = File('android/gradle.properties');
  if (!props.existsSync()) return false;
  final local = Platform.environment['LOCALAPPDATA'] ?? '';
  final pubCache = Platform.environment['PUB_CACHE'] ?? '$local\\Pub\\Cache';
  final projectDrive = Directory.current.path.substring(0, 1).toLowerCase();
  if (pubCache.isEmpty || pubCache.substring(0, 1).toLowerCase() == projectDrive) {
    return false;
  }
  final text = props.readAsStringSync();
  if (text.contains('kotlin.incremental')) return true;
  props.writeAsStringSync(
    '$text${text.endsWith('\n') ? '' : '\n'}'
    '# Project and Pub cache are on different drives (Kotlin incremental bug).\n'
    'kotlin.incremental=false\n',
  );
  log.detail('kotlin.incremental=false added (project and pub cache on different drives).');
  return true;
}
/// Opt-in: mirror Google Maven / Maven Central through Aliyun for networks
/// where dl.google.com is blocked. Covers the app's repositories and the
/// `buildscript` repositories that plugin modules declare themselves.
bool _addAndroidMavenMirror(Logger log) {
  final file = File('android/build.gradle.kts');
  if (!file.existsSync()) return false;
  var text = file.readAsStringSync();
  if (text.contains('fallah:maven-mirror')) return true;

  const mirror = '''
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
''';
  final repos = RegExp(r'(allprojects\s*\{\s*repositories\s*\{\s*\n)');
  if (repos.hasMatch(text)) {
    text = text.replaceFirstMapped(
      repos,
      (m) => '${m.group(1)}        // fallah:maven-mirror\n$mirror',
    );
  }
  text += '''

// fallah:maven-mirror-buildscript - plugin modules declare their own
// buildscript repositories (google()); mirror those too.
subprojects {
    buildscript {
        repositories {
            maven { url = uri("https://maven.aliyun.com/repository/google") }
            maven { url = uri("https://maven.aliyun.com/repository/public") }
            maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
        }
    }
}
''';
  file.writeAsStringSync(text);
  log.detail('Aliyun Maven mirrors added to android/build.gradle.kts.');
  return true;
}
void run(HookContext context) {
  final log = context.logger;
  final title = (context.vars['project_name'] as String).titleCase;

  _removeSamples(log);
  final flavors = _addAndroidFlavors(log, title);
  if (flavors) {
    _alignPluginCompileSdk(log);
    _disableKotlinIncrementalOnSplitDrives(log);
    if (context.vars['android_maven_mirror'] == true) _addAndroidMavenMirror(log);
  }

  log
    ..info('')
    ..success('App generated.')
    ..info(
      flavors
          ? 'Android flavors dev/stg/prd added to android/app/build.gradle.kts.'
          : 'No android/ folder yet: run "flutter create --project-name '
              '${context.vars['project_name']} --platforms=android,web ." and '
              're-run this brick (--on-conflict overwrite) to add the flavors.',
    )
    ..info('Next:')
    ..info('  flutter pub get && flutter gen-l10n')
    ..info('  dart run build_runner build -d')
    ..info('  flutter run --flavor dev -t lib/main_dev.dart '
        '--dart-define-from-file=env/dev.json')
    ..info('Set real URLs in env/*.json (keep prd values in CI).')
    ..warn('Package versions in pubspec.yaml are unverified: run '
        '"flutter pub upgrade --major-versions" and fix any conflicts.');
}
