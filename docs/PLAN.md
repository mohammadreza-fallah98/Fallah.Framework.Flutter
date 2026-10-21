# پلن کامل فریم‌ورک Fallah Flutter

> تاریخ: 2026-10-17 · وضعیت: **منتظر تأیید شما — هیچ بخشی اجرا نشده**
> این سند نتیجهٔ بازبینی دوبارهٔ همهٔ کدهای فاز ۱ تا ۳، محیط توسعه، و قوانین سراسری شما (`CLAUDE.md`، `flutter-conventions`، `core-entities`، `architecture-docs`) است.

---

## ✅ پیشرفت اجرا (به‌روزرسانی 2026-10-17)

- **فاز A و B انجام شد:** Flutter 3.47.6 با mirror اجرا می‌شود، `flutter analyze` صفر issue.
- **فاز C انجام شد:** B1 تا B10 رفع شد، `uploadBytes` اضافه شد، `AppErrorView(message:)` اضافه شد، lint روی `very_good_analysis` رفت. تست‌ها: core 10 · network 16 · auth 15 · ui 7، همه سبز.
- **عمداً انجام نشد در C:** فونت Vazirmatn داخل `fallah_ui` و تاریخ جلالی (نیاز به دانلود فونت/پکیج، منتظر تأیید)، `Can` (در brick اپ می‌آید)، B4 (طبق Q4 نگاشت code به فیلد در اپ).
- **«بک‌اند» (لایه‌های بدون UI) انجام شد (2026-10-17):** `ResourceClient` در `fallah_network` و پکیج جدید `fallah_api` (۹ موجودیت پایه + `AuthApi` + upload) طبق `core-entities.md`. تست‌ها: core 10 · network 21 · auth 15 · api 13 · ui 7، همه سبز.
- **فرض‌هایی که باید با DTO واقعی بک‌اند تطبیق داده شوند:** (۱) پاسخ login/otp/refresh = `data: {accessToken, refreshToken}`؛ (۲) بدنهٔ `change-password` = `{currentPassword, newPassword}`؛ (۳) بدنهٔ `logout` = `{refreshToken}`؛ (۴) نوع JSON فیلد `rowVersion` (به‌صورت opaque نگه داشته می‌شود)؛ (۵) پاسخ `by-role/{id}` شبیه لیست صفحه‌ای است؛ (۶) پاسخ `with-attachments` فیلد `attachments` دارد؛ (۷) فیلدهای فیلتر audit-log (`From`/`To`).
- **فاز D/E تأیید شد (اجرای واقعی با mason 0.1.4):** `flutter create` سپس `mason make app` + `feature product` + `api_service province` → `pub get`، `gen-l10n`، `build_runner`، `flutter analyze` (۰ خطا، ۴ info سبکی) و `flutter test` (۱۵ از ۱۵ سبز). کشف مهم: Mason فقط `{{name.snakeCase()}}` را رندر می‌کند (بدون پرانتز خالی می‌شود) و همهٔ bricks اصلاح شدند. هنوز تأیید نشده: `flutter build apk --flavor dev` و `flutter build web`، و اجرای hookهای flavor روی پروژهٔ واقعی با Gradle.
- **فرانت (2026-10-18):** فونت Samim داخل `fallah_ui`؛ ارقام فارسی و تاریخ شمسی (`shamsi_date`) در `fallah_core`؛ `PagedState`/`nextPage`/`getOrThrow` در core؛ brick اپ روی `fallah_api` با صفحهٔ ورود (رمز + OTP) و منوی خانه بر اساس مجوز؛ brick جدید `base_features` (پروفایل، کاربران، مناطق، نقش‌ها با ماتریس دسترسی، لاگ‌ها) که مسیر، منو و رشته‌های fa/en را خودش ثبت می‌کند. تأیید با اجرای واقعی: ۰ خطا، ۴ info سبکی، ۱۵ تست سبز.
- **چت و پیوست‌ها انجام شد (2026-10-18):** `base_features` حالا گفتگوی پشتیبانی (`ChatThread` قابل‌جاسازی با `ChatThreadKey`، پیوست، دیده‌شدن، صفحه‌بندی پیام‌های قدیمی) و صفحهٔ فایل‌ها (آپلود با `file_picker`، باز کردن با `url_launcher`) را هم دارد. تأیید اجرایی: ۰ خطا، ۷ info سبکی، ۱۵ تست سبز.
- **باقی‌مانده فرانت:** تست‌های اختصاصی `base_features`، `flutter build apk --flavor dev` و `flutter build web`، commit، CI.
- بعدی (قدیمی): فرانت (فونت Samim، ویجت‌ها، bricks، featureهای UI).
- بقیه فازها (D تا H) هنوز کامل نشده‌اند. آخرین commit وجود ندارد.

---

## ۰. خلاصهٔ وضعیت فعلی (قبل از اجرا)

| بخش | وضعیت | اجرا/تست‌شده؟ |
|---|---|---|
| `fallah_core` (Result، Failure، PagedList، Logger، Validators) | نوشته شده | فقط `dart analyze lib` (صفر خطا) |
| `fallah_network` (Dio، ApiResponse، ErrorMapper، ۵ interceptor) | نوشته شده | ❌ |
| `fallah_auth` (SessionManager، Guard، SecureTokenStore) | نوشته شده | ❌ |
| `fallah_ui` (Theme، Tokens، ۶ ویجت) | نوشته شده | ❌ |
| bricks: `app`، `feature`، `api_service` | نوشته شده | ❌ |
| `example/`، CI، Git، نسخه‌بندی، مستندات استاندارد | **ساخته نشده** | — |
| featureهای موجودیت‌های پایه (auth، users، roles، ...) | **ساخته نشده** | — |

**نتیجه:** حدود ۷۰٪ اسکلت نوشته شده، ولی **هیچ خطی کامپایل یا تست نشده**. اولین کار باید راه‌اندازی محیط و اجرای واقعی باشد، نه کد بیشتر.

---

## ۱. یافته‌های محیط (علت اینکه تا الان چیزی اجرا نشد)

| # | یافته | شواهد | راه‌حل |
|---|---|---|---|
| E1 | **pub.dev با 403 مسدود است** (تحریم جغرافیایی، نه مشکل توکن) | `Invoke-WebRequest https://pub.dev/...` → 403 · `pub.flutter-io.cn` → 200 | متغیرهای `PUB_HOSTED_URL=https://pub.flutter-io.cn` و `FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn` (یا VPN/پروکسی) |
| E2 | `flutter.bat` داخل sandbox من اجرا نمی‌شود («The system cannot find the path specified» / «WHERE is not recognized») | Flutter در `D:\Programming\Android\flutter` نصب است؛ Dart 3.13.5 کار می‌کند | شما یک بار `flutter doctor -v` را در ترمینال خودتان اجرا کنید؛ اگر سالم بود، مشکل sandbox است و برای اجرای `flutter` باید اجازهٔ اجرای خارج از sandbox بدهید |
| E3 | Android SDK در `D:\Programming\Android\sdk` است، نه `C:\Android\Sdk` که قوانین شما می‌گوید | `ANDROID_HOME=D:\Programming\Android\sdk` | در brick و سند به‌عنوان «تفاوت عمدی» ثبت شود یا قانون سراسری اصلاح شود |
| E4 | پوشه Git نیست | محیط: `Is a git repository: false` · git در `D:\Programming\Git` هست | `git init` + `.gitignore` + اولین commit + تگ `v0.1.0` (وابستگی git اپ‌ها به تگ نیاز دارد) |

---

## ۲. نقص‌های پیدا شده در کد موجود

### ۲.۱ باگ و ناسازگاری با قرارداد API (اولویت بالا)

| # | فایل | مشکل | اثر | اصلاح |
|---|---|---|---|---|
| B1 | [error_mapper.dart:1](../packages/fallah_network/lib/src/error_mapper.dart) | `import 'dart:io'` | **build وب می‌شکند** (هدف شما اندروید + وب است) | حذف `SocketException`؛ Dio خطای سوکت را خودش به `connectionError` تبدیل می‌کند |
| B2 | [paged_list.dart:50](../packages/fallah_core/lib/src/paged_list.dart) | `SortType` = `desc/asc` و `SortBy` تکی | قرارداد `CLAUDE.md`: `SortBy[]` و `Desc/Asc` | `sortBy: List<String>` و مقدار `Desc`/`Asc` |
| B3 | [error_mapper.dart:34](../packages/fallah_network/lib/src/error_mapper.dart) | پیام‌های محلی انگلیسی hardcode (`No connection`، `Request timed out`) | قانون «پیام کاربر فقط از resource fa/en» نقض می‌شود؛ کاربر فارسی متن انگلیسی می‌بیند | `Failure.code` پایدار (`offline`، `timeout`، ...) + تابع `failureMessage(failure, l10n)` در brick اپ؛ `AppErrorView` پارامتر `message` بگیرد |
| B4 | [error_mapper.dart](../packages/fallah_network/lib/src/error_mapper.dart) | خطای فیلدی را از کلید `field` می‌خواند | قرارداد فقط `errorMessages: [{code?, message}]` است؛ `field` وجود ندارد | پرسش Q4؛ پیش‌فرض: نمایش عمومی + نگاشت `code` به فیلد در اپ |
| B5 | [auth_interceptor.dart:73](../packages/fallah_network/lib/src/interceptors/auth_interceptor.dart) | refresh با خطای 5xx هم session را پاک می‌کند | قطعی موقت سرور = خروج کاربر | فقط 400/401/403 روی refresh → expire؛ بقیه → نگه‌داشتن session |
| B6 | [app_paged_list.dart:48](../packages/fallah_ui/lib/src/widgets/app_paged_list.dart) | `onLoadMore` برای هر سه آیتم آخر در هر build صدا زده می‌شود | چند درخواست صفحهٔ بعد همزمان | `ScrollController`/`NotificationListener` و فراخوانی یک‌باره |
| B7 | [session_manager.dart:31](../packages/fallah_auth/lib/src/session_manager.dart) | `restore()` خطای `tokenStore.read()` را نمی‌گیرد | خرابی شناخته‌شدهٔ secure storage اندروید بعد از reinstall → **گیر کردن روی splash** | try/catch → clear + unauthenticated |
| B8 | [session_manager.dart](../packages/fallah_auth/lib/src/session_manager.dart) | اگر بارگیری مجوزها آفلاین شکست بخورد، دیگر تکرار نمی‌شود | کاربر تا اجرای بعدی هیچ دکمهٔ نوشتنی نمی‌بیند | متد `reloadPermissions()` + فراخوانی بعد از اتصال دوباره |
| B9 | [secure_token_store.dart:31](../packages/fallah_auth/lib/src/secure_token_store.dart) | دو کلید جدا، خواندن از secure storage در **هر** درخواست | ذخیرهٔ غیراتمی + کندی | یک کلید JSON + کش در حافظه |
| B10 | [analysis_options.yaml:1](../analysis_options.yaml) | ریشه `package:lints` را include می‌کند ولی `fallah_ui` آن را ندارد؛ قوانین شما `very_good_analysis` می‌خواهد | هشدار include و lint ناهمسان | `very_good_analysis` برای همهٔ پکیج‌ها |

### ۲.۲ کمبود نسبت به `flutter-conventions` و `core-entities`

| # | محل | کمبود |
|---|---|---|
| G1 | brick `feature` | فقط صفحهٔ لیست دارد؛ قرارداد: `list` + `detail` + `form` screen و `widgets/<x>_card.dart`، `<x>_form.dart` |
| G2 | brick `feature` | فیلدهای مشترک (`createdBy`، `createdAt`، `updatedBy`، `updatedAt`، `rowVersion`، `createdByName`) در model نیست؛ edit باید `rowVersion` بفرستد و 409 را نشان دهد |
| G3 | brick `feature` | پنهان کردن کنترل نوشتن بدون مجوز (`<x>:create/update/delete`) و گارد مسیر وجود ندارد |
| G4 | brick `feature` | صفحه‌بندی واقعی (load more) و `invalidate` بعد از mutation وجود ندارد |
| G5 | brick `feature` | تست provider (`ProviderContainer`) و widget (چهار حالت، فرم، مجوز) وجود ندارد؛ فقط تست data |
| G6 | brick `app` | **flavorهای اندروید** (`productFlavors` در `build.gradle.kts`) تنظیم نشده؛ دستور `--flavor dev` شکست می‌خورد |
| G7 | brick `app` | `.gitignore` (برای `key.properties`، `env/prd.json` واقعی)، `android/local.properties`، `.fvmrc` |
| G8 | brick `app` | فونت Vazirmatn، تاریخ جلالی (`shamsi_date`)، فرمت ارقام فارسی، ویجت `Can`، کلیدهای ARB خطاها |
| G9 | brick `app` | فقط تست هم‌ترازی ARB؛ تست router (هر مسیر گارد دارد)، smoke test اپ |
| G10 | فریم‌ورک | آپلود multipart با progress (در لیست اولیهٔ خود شما بود) |
| G11 | فریم‌ورک | ۷ feature موجودیت پایه (auth رمز+OTP، users، roles+ماتریس scope، regions، chat، attachments، audit_logs) — **اجباری وقتی بک‌اند .NET است** |
| G12 | مستندات | سند معماری باید `docs/ARCHITECTURE.md` با اسکلت ۲۳ بخشی (بیزینس + فنی) باشد؛ الان `docs/architecture/ARCHITECTURE.md` است و ساختار را ندارد |
| G13 | زیرساخت | `example/`، CI، CHANGELOG، تگ نسخه، اسکریپت اجرای همهٔ تست‌ها |

### ۲.۳ ریسک‌هایی که فقط با اجرای واقعی معلوم می‌شوند

| # | ریسک | راستی‌آزمایی |
|---|---|---|
| R1 | سازگاری نسخه‌های Riverpod 3 / riverpod_generator 3 / freezed 3 / json_serializable / go_router با Flutter نصب‌شده | `flutter pub get` روی اپ تولیدشده |
| R2 | مصرف پکیج‌های workspace (`resolution: workspace`) از طریق git در اپ بیرونی | ساخت `example/` با وابستگی git |
| R3 | قالب‌های Mustache (مثلاً `'${Endpoints.{{plural.camelCase}}}/$id'`) و extensionهای `camelCase` در hookها | `mason make` واقعی |
| R4 | `Error` در `Result` نام `Error` در `dart:core` را می‌پوشاند | analyze روی اپ نمونه |
| R5 | ذخیرهٔ توکن روی **وب** (`flutter_secure_storage` روی وب = WebCrypto + localStorage، در برابر XSS امن نیست) | پرسش Q5 |

---

## ۳. پلن اجرا (به ترتیب)

اندازه: S = کوچک · M = متوسط · L = بزرگ. هر فاز فقط وقتی تمام است که «معیار پایان» آن برقرار باشد.

### فاز A — محیط و Git (S) · پیش‌نیاز همه چیز

1. تنظیم mirror برای pub (فقط برای session، یا دائمی با اجازهٔ شما) — E1
2. رفع اجرای `flutter` — E2 (طبق پاسخ Q1)
3. `git init`، `.gitignore` (build، `.dart_tool`، `*.g.dart`؟ — پیشنهاد: فایل‌های تولیدی commit نشوند)، اولین commit
4. **معیار پایان:** `flutter --version` و `flutter pub get` در ریشه موفق.

### فاز B — اجرای واقعی و سبز کردن کد موجود (M)

1. `flutter pub get` در ریشهٔ workspace
2. `dart format .` · `flutter analyze` روی هر چهار پکیج → رفع همهٔ خطاها
3. `flutter test` در هر پکیج → رفع شکست‌ها
4. اسکریپت `tool/check.ps1` (format + analyze + test همهٔ پکیج‌ها) یا Melos 7 (پیشنهاد: **Melos**، چون انتشار نسخه و changelog را هم پوشش می‌دهد)
5. **معیار پایان:** صفر issue در analyze و همهٔ تست‌ها سبز؛ خروجی واقعی در گزارش.

### فاز C — رفع نقص‌های پکیج‌ها (M)

1. B1 تا B10 (جدول ۲.۱)، هر کدام با تست
2. `fallah_network`: `uploadFile()` با `FormData` و `onSendProgress` (G10)؛ لاگ `X-Correlation-Id` پاسخ
3. `fallah_ui`: فونت Vazirmatn داخل پکیج (مجوز OFL اجازه می‌دهد) تا هر اپ آن را اضافه نکند؛ `AppErrorView(message:)`؛ ویجت `Can(permission:)`؛ `formatJalali` با `shamsi_date` و `toPersianDigits`
4. `fallah_core`: `PageQuery` مطابق قرارداد (B2)
5. CHANGELOG برای هر پکیج
6. **معیار پایان:** فاز B دوباره سبز؛ هر باگ یک تست دارد.

### فاز D — تکمیل bricks (L)

1. `feature`: صفحه‌های detail و form، `<x>_card.dart`، `<x>_form.dart`، فیلدهای مشترک + `rowVersion`، paged notifier با `loadMore`، `invalidate` بعد از mutation، پنهان‌سازی کنترل بدون مجوز، `context.mounted`، دکمهٔ ارسال غیرفعال حین ارسال، خطای فیلدی سرور روی فیلد (G1–G5)
2. `feature`: تست provider و widget (چهار حالت، فرم، مجوز)
3. `app`: flavorهای اندروید dev/stg/prd با `applicationIdSuffix` (G6) — به‌صورت فایل `build.gradle.kts` کامل یا دستورالعمل hook (پیشنهاد: hook فایل را patch کند)
4. `app`: `.gitignore`، `local.properties` با مسیر SDK شما، `.fvmrc`، `failureMessage` + کلیدهای ARB خطا، `Can`، گارد مجوز مسیر، تست router و smoke (G7–G9)
5. `api_service`: هماهنگ با تغییرات `feature`
6. **معیار پایان:** فاز E.

### فاز E — اپ نمونه `example/` (M) · اثبات اینکه همه چیز با هم کار می‌کند

1. `mason make app` → `example/` (با وابستگی `path` به پکیج‌ها برای توسعهٔ محلی)
2. `mason make feature --name product` + `mason make api_service --name province`
3. بک‌اند ساختگی: `FakeAdapter` با پاسخ‌های قرارداد (envelope، 400، 401+refresh، 409، 429)
4. `build_runner` · `gen-l10n` · analyze · test · `integration_test` (ورود → لیست → افزودن → ویرایش → حذف)
5. `flutter build apk --flavor dev` و `flutter build web`
6. **معیار پایان:** همهٔ موارد بالا موفق؛ اسکرین‌شات اپ روی وب.

### فاز F — featureهای موجودیت‌های پایه (L) · فقط اگر Q3 = بله

پیشنهاد معماری: **یک پکیج `fallah_core_entities`** (Pure Dart: model، datasource، repository برای ۹ موجودیت دقیقاً مطابق قرارداد .NET) **+ brick‌های UI** که صفحه‌ها را داخل اپ تولید می‌کنند (چون UI هر پروژه فرق دارد ولی قرارداد API یکی است).

| feature | endpointها (از `core-entities`) | ترتیب |
|---|---|---|
| auth | `users/login` · `otp/send` · `otp/login` · `refresh-token` · `logout` · `me` · `change-password` | ۱ |
| regions | `provinces` · `cities?ProvinceId=` (کش محلی) | ۲ |
| attachments | `attachments/upload` (multipart) · `{id}/url` · `{id}/download` | ۳ |
| users | CRUD + `PATCH status` | ۴ |
| roles | `roles` · `role-scopes` · `by-role/{id}` (ماتریس) | ۵ |
| chat | `chats` · `with-attachments` · `{id}/seen` | ۶ |
| audit_logs | `GET` با فیلتر (فقط ادمین) | ۷ |

**معیار پایان:** هر feature با تست در `example/`؛ اپ تولیدی از brick `app` با یک فلگ آن‌ها را دارد.

### فاز G — نسخه‌بندی، انتشار و CI (M)

1. SemVer + CHANGELOG + تگ `v0.1.0`؛ قاعدهٔ breaking change
2. CI طبق Q2 (GitHub Actions / GitLab CI): format، analyze، test، `mason make` + build نمونه
3. بلندمدت: pub server خصوصی به‌جای `git` + `dependency_overrides`
4. **معیار پایان:** pipeline سبز روی اولین PR.

### فاز H — مستندات (M)

1. انتقال به `docs/ARCHITECTURE.md` با اسکلت اجباری ۲۳ بخشی: قسمت بیزینس (فریم‌ورک چه مشکلی را حل می‌کند، مخاطبان، جریان ساخت پروژه) + قسمت فنی (برای هر الگو: نیاز، ابزار+نسخه، مسیر، نام‌گذاری، قالب کد، قواعد، تنظیمات، استفاده)
2. §۲۱ تفاوت‌های عمدی (مسیر SDK، `Error` در `Result`، ...) و §۲۲ شکاف‌ها (همین جدول‌ها)
3. `README.md` ریشه (شروع سریع در ۵ دقیقه) و `CLAUDE.md` پروژه
4. **معیار پایان:** یک دولوپر تازه فقط با README یک اپ بسازد و اجرا کند.

---

## ۴. چیزهایی که از شما لازم دارم

| # | پرسش | پیشنهاد من | چرا مهم است |
|---|---|---|---|
| Q1 | اجرای `flutter`: اجازه می‌دهید دستورات flutter/dart را خارج از sandbox اجرا کنم، یا خودتان اجرا می‌کنید و خروجی را می‌فرستید؟ | اجازه به من (سریع‌تر؛ هر دستور را تأیید می‌کنید) | بدون آن هیچ چیز تأیید نمی‌شود |
| Q2 | مخزن Git کجا می‌رود؟ (GitHub / GitLab / Azure DevOps / سرور داخلی) و آدرس آن | — | `framework_git_url` در brick، نوع CI، نیاز CI به mirror |
| Q3 | بک‌اند پروژه‌ها Fallah.Framework روی .NET Core است؟ | بله → فاز F لازم است | طبق قوانین شما featureهای موجودیت پایه اجباری می‌شوند |
| Q4 | خطای اعتبارسنجی فیلدی از بک‌اند چطور می‌آید؟ (قرارداد فقط `{code?, message}` دارد) | نگاشت `code` به فیلد در اپ | B4 |
| Q5 | وب برای همهٔ اپ‌ها هدف است؟ توکن روی وب کجا ذخیره شود؟ | بله؛ روی وب refresh token در کوکی HttpOnly (نیازمند تغییر بک‌اند) یا پذیرش ریسک | امنیت (R5) |
| Q6 | mirror pub را دائمی (متغیر محیطی کاربر) تنظیم کنم یا فقط در هر session؟ | دائمی | E1؛ تغییر تنظیمات سیستم است، پس اجازه می‌خواهم |
| Q7 | Sentry (یا ابزار گزارش خطای دیگر) استفاده می‌شود؟ (sentry.io ممکن است از ایران مسدود باشد) | فعلاً فقط اینترفیس `AppLogger`؛ پیاده‌سازی بعداً | وابستگی brick اپ |
| Q8 | iOS الان لازم است؟ (روی ویندوز build نمی‌شود) | خیر؛ فقط اندروید + وب، iOS بعداً | دامنهٔ flavor و تست |

---

## ۵. ترتیب پیشنهادی و نقطه‌های توقف

```
A ──► B ──► C ──► D ──► E ──► (توقف: بازبینی شما) ──► F ──► G ──► H
```

- بعد از **B** و بعد از **E** گزارش واقعی (خروجی تست/build) می‌دهم و منتظر تأیید می‌مانم.
- هر فاز یک commit جدا دارد تا بازگشت آسان باشد.
- تا وقتی Q1 و Q6 جواب نگرفته‌اند، فقط فاز A قابل شروع است.
