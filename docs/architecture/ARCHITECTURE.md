# معماری فریم‌ورک Fallah (نسخه اصلاح‌شده)

## جواب کوتاه
بله، ساختن فریم‌ورک مشترک درست است. ولی **فریم‌ورک نباید یک لایهٔ انتزاعی روی همه‌چیز باشد**؛ باید مجموعه‌ای از «تصمیم‌های از پیش گرفته‌شده + پکیج‌های کوچک + قالب پروژه» باشد که روی کتابخانه‌های معروف (dio, go_router, riverpod, ...) سوار می‌شود، نه جایگزین آن‌ها.

## اصلاحاتی که روی پیشنهاد اولیه اعمال شد

| # | پیشنهاد اولیه | مشکل | اصلاح |
|---|---|---|---|
| 1 | نام پکیج‌ها `app_*` | بسیار عمومی؛ با پکیج‌های pub.dev و اپ‌ها تداخل ذهنی/نام دارد | پیشوند `fallah_` (مثلاً `fallah_core`) |
| 2 | `app_routing` پکیج مستقل | مسیرها مال هر اپ‌اند؛ فقط Guard و کمک‌کننده‌ها مشترک است. پکیج تقریباً خالی می‌شود | حذف پکیج. `AuthGuard` (تابع redirect مستقل از روتر) داخل `fallah_auth`؛ تعریف مسیرها داخل brick/feature |
| 3 | `app_auth` شامل OTP و ... | هر پروژه روش ورود متفاوتی دارد؛ پیاده‌سازی ثابت = قفل شدن | فقط **اینترفیس‌ها** (`AuthRepository`, `TokenStore`, `SessionManager`) + تمدید خودکار توکن + پیاده‌سازی اختیاری OTP در پوشهٔ جدا |
| 4 | `templates/` و `bricks/` هر دو | هم‌پوشانی؛ دو منبع حقیقت برای ساخت پروژه | فقط **Mason bricks** (از جمله brick `app`). پوشهٔ `templates/` حذف شد |
| 5 | `admin_app` از روز اول | YAGNI؛ بدون نیاز واقعی طراحی نادرست می‌شود | بعد از دو پروژهٔ واقعی اضافه شود |
| 6 | `app_storage` پکیج مستقل | خیلی کوچک و وابسته به auth/network | فعلاً داخل `fallah_core` به‌صورت اینترفیس `KeyValueStore`/`SecureStore`؛ پیاده‌سازی با `flutter_secure_storage` در `fallah_auth` |
| 7 | نبودن پروژهٔ نمونه | فریم‌ورک بدون مصرف‌کننده واقعی تست نمی‌شود | پوشهٔ `example/` = اپ مرجع که همهٔ پکیج‌ها را مصرف می‌کند (تست یکپارچه زنده) |
| 8 | نبودن مدیریت نسخه | تغییر فریم‌ورک پروژه‌های قدیمی را می‌شکند | SemVer + CHANGELOG + تگ Git؛ پروژه‌ها با `git: ref: vX.Y.Z` وابسته می‌شوند، نه `path` |
| 9 | نبودن ابزار | کار دستی زیاد | Pub workspaces (Dart 3.6+) + Melos برای اسکریپت‌ها، Mason برای تولید کد |
| 10 | نبودن مدل خطا/Result | «مدیریت خطا» فقط ذکر شده | `Result<T>` و `Failure` sealed در `fallah_core` (پیاده‌سازی‌شده) |

## ساختار نهایی

```
Fallah Framework Flutter/
├── pubspec.yaml            # workspace + اسکریپت‌های melos
├── analysis_options.yaml   # قوانین lint مشترک
├── packages/
│   ├── fallah_core/        # Result, Failure, Logger, Validators, Pagination, Env, KeyValueStore   (Pure Dart)
│   ├── fallah_network/     # Dio client, interceptors (header/token/retry/log), ErrorMapper       (Pure Dart)
│   ├── fallah_auth/        # اینترفیس‌ها، refresh توکن، AuthGuard، (اختیاری) OTP، SecureTokenStore
│   ├── fallah_ui/          # Design tokens, Theme (RTL/فونت فارسی), Button/Form/Dialog/State widgets
│   └── fallah_l10n/        # رشته‌های مشترک (fa/en) و فرمت تاریخ/عدد
├── bricks/
│   ├── app/                # ساخت پروژهٔ جدید با env، flavor، router، DI آماده
│   ├── feature/            # data/domain/presentation + تست
│   └── api_service/        # data/domain فقط‌خواندنی بدون UI
├── example/                # اپ مرجع (مصرف‌کنندهٔ همهٔ پکیج‌ها)
└── docs/
    ├── architecture/       # این سند + ADRها
    ├── standards/          # قرارداد نام‌گذاری، ساختار Feature، قوانین PR
    └── examples/
```

قانون وابستگی (یک‌طرفه):
`fallah_core` ← `fallah_network` ← `fallah_auth` ؛ `fallah_ui` ← `fallah_core` ؛ هیچ پکیجی به اپ وابسته نیست.
پکیج‌هایی که Flutter لازم ندارند (core, network) **Pure Dart** بمانند تا تست سریع و قابل استفاده در سرور/CLI باشند.

## تصمیم‌های فنی (ADR)

| تصمیم | انتخاب پیشنهادی | دلیل | وضعیت |
|---|---|---|---|
| State management | **Riverpod** (+ `riverpod_generator` اختیاری) | DI و state در یک ابزار، تست‌پذیر، بدون وابستگی به context | **پیشنهادی - نیاز به تأیید شما** (جایگزین: Bloc) |
| Routing | **go_router** | پشتیبانی رسمی Flutter، redirect/guard، وب | پیشنهادی |
| HTTP | **dio** | interceptor، cancel، timeout | پیشنهادی |
| مدل‌ها | **freezed + json_serializable** | immutability، union | پیشنهادی |
| ذخیرهٔ امن | **flutter_secure_storage** | استاندارد de-facto | پیشنهادی |
| لاگ | **talker** یا `logger` پشت اینترفیس `AppLogger` | قابل تعویض | پیشنهادی |
| تولید پروژه | **Mason** | brick قابل نسخه‌بندی | پیشنهادی |
| Monorepo | **Pub workspaces + Melos** | رسمی و سبک | پیشنهادی |
| تست | `flutter_test` + `mocktail` (+ `patrol` برای E2E) | | پیشنهادی |

> فهرست awesome-flutter را در این مرحله مستقیم باز نکردم؛ انتخاب‌ها از شناخت خودم است. قبل از قفل کردن نسخه‌ها، فعال بودن و آخرین نسخهٔ هر پکیج را در pub.dev چک کنید.

## اصول طراحی
1. **ترکیب به‌جای ارث‌بری**: اپ‌ها فقط چیزی را import می‌کنند که لازم دارند.
2. **اینترفیس در فریم‌ورک، پیاده‌سازی قابل تعویض**.
3. **هیچ منطق دامنهٔ کسب‌وکار در فریم‌ورک نباشد** (فقط زیرساخت).
4. **هر قابلیت = تست + مثال در `example/`** تا وارد فریم‌ورک شود.
5. **قانون سه‌تا**: چیزی که در سه پروژه تکرار شد، وارد فریم‌ورک شود؛ زودتر نه.

## نقشهٔ راه
- **فاز ۱ (انجام شد، تست‌نشده)**: workspace، `fallah_core` (Result/Failure/PagedList/Logger)، `fallah_network` (Dio، ApiResponse، ErrorMapper، interceptorهای Auth/Language/Correlation/Retry/Logging)
  - هم‌راستا با قراردادهای `flutter-conventions`: `Result` = `Success/Error`، خانوادهٔ `Failure` (Forbidden/NotFound/Conflict/RateLimit/Validation)، هدرهای `X-Language` و `X-Correlation-Id`، refresh یک‌بارِ همزمان، retry فقط GET.
  - State management: **Riverpod** (تأیید شد).
- **فاز ۲ (انجام شد، تست‌نشده)**:
  - `fallah_auth` (Pure Dart): `SessionManager` + `AuthState` (permissionهای `entity:action`)، `authRedirect`/`permissionRedirect` مستقل از روتر، `SecureTokenStore` روی اینترفیس `SecureKeyValue` (آداپتور `flutter_secure_storage` ۱۰ خط در اپ/brick)، اینترفیس‌های `PasswordAuthRepository` و `OtpAuthRepository`.
  - `fallah_ui` (Flutter): `AppTheme` (M3، فونت پارامتری، هدف لمسی ۴۸dp)، `AppTokens`، ویجت‌های `AppButton/AppTextField/AppErrorView/AppEmptyView/AppSkeleton/AppPagedList`. متن‌ها پارامتر ورودی‌اند تا به l10n اپ وابسته نباشد.
  - `fallah_core`: افزودن `Validators` (موبایل، کد ملی، کد پستی، نرمال‌سازی ارقام فارسی).
  - توجه: چون `fallah_ui` به Flutter وابسته است، کل workspace را باید با `flutter pub get` و `flutter test` اجرا کرد (نه `dart pub get`).
- **فاز ۲**: `fallah_auth` + `fallah_ui` (theme/توکن‌ها/ویجت‌های پایه) + `example/`
- **فاز ۳ (bricks انجام شد، تست‌نشده؛ CI و مستندات باقی است)**: `mason.yaml` در ریشه سه brick را ثبت می‌کند:
  - `app`: پروژهٔ کامل (flavor/env، bootstrap با Riverpod، Dio با refresh توکن، go_router با splash+guard، l10n fa/en، تست هم‌ترازی ARB). وابستگی به فریم‌ورک با `git` + `ref` (تگ) و `dependency_overrides` (چون پکیج‌های فریم‌ورک با هم وابسته‌اند).
  - `feature`: برش کامل data/domain/presentation (entity، model، datasource، repository، ۵ usecase، provider، صفحهٔ لیست با حالت‌های Skeleton→Error→Empty→Content) + تست.
  - `api_service`: فقط data/domain فقط‌خواندنی (لیست/جزئیات) بدون UI؛ برای داده‌ای که feature دیگری لازم دارد.
  - brick `page` حذف شد (feature صفحه را دارد). hook هر brick مراحل بعدی (endpoint، کلید ARB، route، build_runner) را چاپ می‌کند.
  - استفاده: `mason get` سپس `mason make feature --name product --plural products --package my_app`.
  - **ریسک‌ها**: (۱) نسخهٔ پکیج‌های `pubspec` brick (Riverpod 3، freezed 3، go_router) حل/تأیید نشده؛ بعد از ساخت `flutter pub upgrade --major-versions`. (۲) وابستگی git بین پکیج‌ها موقتی است؛ بهتر است پکیج‌ها روی pub server خصوصی منتشر شوند. (۳) Riverpod 3 به‌طور پیش‌فرض provider ناموفق را retry می‌کند؛ bootstrap آن را خاموش کرده تا خطای API به UI برسد.
- **فاز ۴**: انتشار نسخهٔ 0.1.0، استفاده در اولین پروژهٔ واقعی، بازبینی بر اساس تجربه
