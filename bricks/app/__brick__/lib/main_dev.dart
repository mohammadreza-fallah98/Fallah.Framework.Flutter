import 'package:{{project_name.snakeCase()}}/bootstrap.dart';
import 'package:{{project_name.snakeCase()}}/core/config/app_config.dart';

Future<void> main() => bootstrap(AppConfig.fromEnvironment());
