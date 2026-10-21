import 'dart:convert';
import 'dart:io';

import 'package:mason/mason.dart';

/// Inserts [addition] above the line containing [anchor] in [path] unless
/// [ifMissing] is already in the file. False means "do it by hand".
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

const _en = <String, String>{
  'usersTitle': 'Users',
  'usersEmpty': 'No users yet',
  'userNew': 'New user',
  'userEditTitle': 'Edit user',
  'userDetailTitle': 'User',
  'userUsername': 'Username',
  'userPassword': 'Password',
  'userFirstName': 'First name',
  'userLastName': 'Last name',
  'userMobile': 'Mobile',
  'userNationalCode': 'National code',
  'userEmail': 'Email',
  'userRole': 'Role',
  'userProvince': 'Province',
  'userCity': 'City',
  'userActive': 'Active',
  'userInactive': 'Inactive',
  'userCreatedAt': 'Created at',
  'invalidNationalCode': 'Enter a valid national code',
  'regionsTitle': 'Regions',
  'provincesTab': 'Provinces',
  'citiesTab': 'Cities',
  'provinceNew': 'New province',
  'provinceEdit': 'Edit province',
  'cityNew': 'New city',
  'cityEdit': 'Edit city',
  'regionName': 'Name',
  'regionsEmpty': 'Nothing here yet',
  'selectProvince': 'Select a province',
  'rolesTitle': 'Roles',
  'roleNew': 'New role',
  'roleEdit': 'Edit role',
  'roleName': 'Name',
  'roleDescription': 'Description',
  'rolesEmpty': 'No roles yet',
  'roleScopesTitle': 'Permissions',
  'scopeEntity': 'Entity name (e.g. user)',
  'scopeRead': 'Read',
  'scopeCreate': 'Create',
  'scopeUpdate': 'Update',
  'scopeDelete': 'Delete',
  'scopeVisibility': 'Row visibility',
  'visibilityOwn': 'Own records',
  'visibilityRoles': 'Same roles',
  'visibilityAssigned': 'Assigned',
  'visibilityAll': 'All records',
  'scopeNew': 'New permission',
  'scopesEmpty': 'No permissions defined',
  'auditTitle': 'Audit log',
  'auditEntityFilter': 'Entity name',
  'auditEmpty': 'No records',
  'auditBefore': 'Before',
  'auditAfter': 'After',
  'auditAdded': 'Added',
  'auditModified': 'Modified',
  'auditDeleted': 'Deleted',
  'profileTitle': 'Profile',
  'profileLanguage': 'Language',
  'languageFa': 'فارسی',
  'languageEn': 'English',
  'changePassword': 'Change password',
  'currentPassword': 'Current password',
  'newPassword': 'New password',
  'confirmPassword': 'Confirm new password',
  'passwordMismatch': 'Passwords do not match',
  'passwordChanged': 'Password changed',
  'supportTitle': 'Support',
  'chatHint': 'Write a message',
  'chatSend': 'Send',
  'chatAttach': 'Attach a file',
  'chatEmpty': 'No messages yet',
  'attachmentsTitle': 'Files',
  'attachmentsEmpty': 'No files uploaded',
  'attachmentUpload': 'Upload a file',
  'attachmentUploaded': 'File uploaded',
  'attachmentOpenFailed': 'Could not open the file',
};

const _fa = <String, String>{
  'usersTitle': 'کاربران',
  'usersEmpty': 'هنوز کاربری وجود ندارد',
  'userNew': 'کاربر جدید',
  'userEditTitle': 'ویرایش کاربر',
  'userDetailTitle': 'کاربر',
  'userUsername': 'نام کاربری',
  'userPassword': 'رمز عبور',
  'userFirstName': 'نام',
  'userLastName': 'نام خانوادگی',
  'userMobile': 'موبایل',
  'userNationalCode': 'کد ملی',
  'userEmail': 'ایمیل',
  'userRole': 'نقش',
  'userProvince': 'استان',
  'userCity': 'شهر',
  'userActive': 'فعال',
  'userInactive': 'غیرفعال',
  'userCreatedAt': 'تاریخ ایجاد',
  'invalidNationalCode': 'کد ملی معتبر وارد کنید',
  'regionsTitle': 'مناطق',
  'provincesTab': 'استان‌ها',
  'citiesTab': 'شهرها',
  'provinceNew': 'استان جدید',
  'provinceEdit': 'ویرایش استان',
  'cityNew': 'شهر جدید',
  'cityEdit': 'ویرایش شهر',
  'regionName': 'نام',
  'regionsEmpty': 'موردی وجود ندارد',
  'selectProvince': 'یک استان انتخاب کنید',
  'rolesTitle': 'نقش‌ها',
  'roleNew': 'نقش جدید',
  'roleEdit': 'ویرایش نقش',
  'roleName': 'نام',
  'roleDescription': 'توضیحات',
  'rolesEmpty': 'هنوز نقشی وجود ندارد',
  'roleScopesTitle': 'دسترسی‌ها',
  'scopeEntity': 'نام موجودیت (مثلاً user)',
  'scopeRead': 'مشاهده',
  'scopeCreate': 'ایجاد',
  'scopeUpdate': 'ویرایش',
  'scopeDelete': 'حذف',
  'scopeVisibility': 'سطح دید رکورد',
  'visibilityOwn': 'رکوردهای خود',
  'visibilityRoles': 'نقش‌های مرتبط',
  'visibilityAssigned': 'ارجاع‌شده',
  'visibilityAll': 'همهٔ رکوردها',
  'scopeNew': 'دسترسی جدید',
  'scopesEmpty': 'دسترسی‌ای تعریف نشده است',
  'auditTitle': 'گزارش تغییرات',
  'auditEntityFilter': 'نام موجودیت',
  'auditEmpty': 'موردی ثبت نشده است',
  'auditBefore': 'قبل',
  'auditAfter': 'بعد',
  'auditAdded': 'افزودن',
  'auditModified': 'ویرایش',
  'auditDeleted': 'حذف',
  'profileTitle': 'پروفایل',
  'profileLanguage': 'زبان',
  'languageFa': 'فارسی',
  'languageEn': 'English',
  'changePassword': 'تغییر رمز عبور',
  'currentPassword': 'رمز فعلی',
  'newPassword': 'رمز جدید',
  'confirmPassword': 'تکرار رمز جدید',
  'passwordMismatch': 'رمزها یکسان نیستند',
  'passwordChanged': 'رمز عبور تغییر کرد',
  'supportTitle': 'پشتیبانی',
  'chatHint': 'پیام خود را بنویسید',
  'chatSend': 'ارسال',
  'chatAttach': 'پیوست فایل',
  'chatEmpty': 'هنوز پیامی وجود ندارد',
  'attachmentsTitle': 'فایل‌ها',
  'attachmentsEmpty': 'فایلی بارگذاری نشده است',
  'attachmentUpload': 'بارگذاری فایل',
  'attachmentUploaded': 'فایل بارگذاری شد',
  'attachmentOpenFailed': 'باز کردن فایل ممکن نشد',
};

void run(HookContext context) {
  final log = context.logger;
  final package = (context.vars['project_name'] as String).snakeCase;

  final importOk = _insertAboveAnchor(
    log,
    'lib/core/router/app_router.dart',
    '// fallah:imports',
    "import 'package:$package/features/base_routes.dart';",
    ifMissing: 'base_routes.dart',
  );
  final routesOk = _insertAboveAnchor(
    log,
    'lib/core/router/app_router.dart',
    '// fallah:routes',
    '...baseFeatureRoutes(),',
    ifMissing: 'baseFeatureRoutes()',
  );

  const entries = <(String, String)>[
    (
      "_HomeEntry(Icons.person_outline, l10n.profileTitle, '/profile'),",
      '/profile',
    ),
    (
      "_HomeEntry(Icons.people_outline, l10n.usersTitle, '/users', "
          "permission: 'user:read'),",
      '/users',
    ),
    (
      "_HomeEntry(Icons.map_outlined, l10n.regionsTitle, '/regions', "
          "permission: 'province:read'),",
      '/regions',
    ),
    (
      "_HomeEntry(Icons.admin_panel_settings_outlined, l10n.rolesTitle, "
          "'/roles', permission: 'role:read'),",
      '/roles',
    ),
    (
      "_HomeEntry(Icons.history, l10n.auditTitle, '/audit-logs', "
          "permission: 'audit-log:read'),",
      '/audit-logs',
    ),
    (
      "_HomeEntry(Icons.support_agent, l10n.supportTitle, '/support', "
          "permission: 'chat:read'),",
      '/support',
    ),
    (
      "_HomeEntry(Icons.folder_outlined, l10n.attachmentsTitle, "
          "'/attachments', permission: 'attachment:read'),",
      '/attachments',
    ),
  ];
  var homeOk = true;
  for (final (line, path) in entries) {
    homeOk &= _insertAboveAnchor(
      log,
      'lib/features/home/presentation/screens/home_screen.dart',
      '// fallah:home-entries',
      line,
      ifMissing: "'$path'",
    );
  }

  _addArbKeys('lib/l10n/app_en.arb', _en);
  _addArbKeys('lib/l10n/app_fa.arb', _fa);

  log
    ..info('')
    ..success('Base features generated: profile, users, regions, roles '
        '(permission matrix), audit logs.')
    ..info(
      importOk && routesOk && homeOk
          ? 'Registered: routes, home menu, fa/en strings.'
          : 'Some registration steps need manual work (see warnings above).',
    )
    ..info('Screens appear in the home menu only for users who hold the '
        'matching permission (user:read, province:read, role:read, '
        'audit-log:read).')
    ..info('Next: dart run build_runner build -d && flutter gen-l10n '
        '&& flutter test');
}
