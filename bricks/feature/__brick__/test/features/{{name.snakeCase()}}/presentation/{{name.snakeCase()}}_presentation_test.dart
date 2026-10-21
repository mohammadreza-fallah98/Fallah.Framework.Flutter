import 'package:dio/dio.dart';
import 'package:fallah_auth/fallah_auth.dart';
import 'package:fallah_core/fallah_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:{{package.snakeCase()}}/core/auth/auth_providers.dart';
import 'package:{{package.snakeCase()}}/features/{{name.snakeCase()}}/domain/entities/{{name.snakeCase()}}.dart';
import 'package:{{package.snakeCase()}}/features/{{name.snakeCase()}}/domain/repositories/{{name.snakeCase()}}_repository.dart';
import 'package:{{package.snakeCase()}}/features/{{name.snakeCase()}}/presentation/providers/{{name.snakeCase()}}_providers.dart';
import 'package:{{package.snakeCase()}}/features/{{name.snakeCase()}}/presentation/screens/{{name.snakeCase()}}_list_screen.dart';
import 'package:{{package.snakeCase()}}/l10n/app_localizations.dart';

class _MockRepo extends Mock implements {{name.pascalCase()}}Repository {}

const _a = {{name.pascalCase()}}(id: 1, title: 'Alpha');
const _b = {{name.pascalCase()}}(id: 2, title: 'Beta');

PagedList<{{name.pascalCase()}}> _page(
  List<{{name.pascalCase()}}> items, {
  int total = 2,
  int page = 1,
  int pageSize = 20,
}) =>
    PagedList(items: items, totalCount: total, page: page, pageSize: pageSize);

void main() {
  late _MockRepo repo;

  setUpAll(() {
    registerFallbackValue(const PageQuery());
    registerFallbackValue(const {{name.pascalCase()}}(id: 0, title: ''));
  });

  setUp(() => repo = _MockRepo());

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [{{name.camelCase()}}RepositoryProvider.overrideWithValue(repo)],
      retry: (_, __) => null,
    );
    addTearDown(c.dispose);
    return c;
  }

  group('{{name.pascalCase()}}List provider', () {
    test('loads the first page then appends the next', () async {
      when(() => repo.getList(any())).thenAnswer((invocation) async {
        final q = invocation.positionalArguments.first as PageQuery;
        return Result.success(
          q.page == 1
              ? _page([_a], pageSize: 1)
              : _page([_b], page: 2, pageSize: 1),
        );
      });
      final c = container();

      final first = await c.read({{name.camelCase()}}ListProvider.future);
      expect(first.items, [_a]);
      expect(first.hasMore, isTrue);

      await c.read({{name.camelCase()}}ListProvider.notifier).loadMore();
      final all = c.read({{name.camelCase()}}ListProvider).requireValue;
      expect(all.items, [_a, _b]);
      expect(all.hasMore, isFalse);
    });

    test('a failed first page surfaces the Failure as the error', () async {
      when(() => repo.getList(any()))
          .thenAnswer((_) async => const Result.error(NetworkFailure('x')));
      final c = container();

      await expectLater(
        c.read({{name.camelCase()}}ListProvider.future),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('a failed load-more keeps the current items', () async {
      var calls = 0;
      when(() => repo.getList(any())).thenAnswer((_) async {
        calls++;
        return calls == 1
            ? Result.success(_page([_a], pageSize: 1))
            : const Result.error(NetworkFailure('x'));
      });
      final c = container();
      await c.read({{name.camelCase()}}ListProvider.future);

      await c.read({{name.camelCase()}}ListProvider.notifier).loadMore();

      expect(c.read({{name.camelCase()}}ListProvider).requireValue.items, [_a]);
    });
  });

  group('{{name.pascalCase()}}Mutation provider', () {
    test('save returns null on success and invalidates the list', () async {
      when(() => repo.getList(any()))
          .thenAnswer((_) async => Result.success(_page([_a])));
      when(() => repo.add(any())).thenAnswer((_) async => const Result.success(7));
      final c = container();
      await c.read({{name.camelCase()}}ListProvider.future);

      final failure = await c
          .read({{name.camelCase()}}MutationProvider.notifier)
          .save(const {{name.pascalCase()}}(id: 0, title: 'New'), isNew: true);

      expect(failure, isNull);
      verify(() => repo.add(any())).called(1);
    });

    test('save returns the Failure (e.g. 409 conflict)', () async {
      when(() => repo.edit(any())).thenAnswer(
        (_) async => const Result.error(ConflictFailure('changed')),
      );
      final c = container();

      final failure = await c
          .read({{name.camelCase()}}MutationProvider.notifier)
          .save(_a, isNew: false);

      expect(failure, isA<ConflictFailure>());
    });
  });

  group('{{name.pascalCase()}}ListScreen', () {
    Future<void> pump(
      WidgetTester tester, {
      Set<String> permissions = const {},
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            {{name.camelCase()}}RepositoryProvider.overrideWithValue(repo),
            authStateProvider.overrideWith(
              (ref) => Stream.value(
                AuthState(AuthStatus.authenticated, permissions: permissions),
              ),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const {{name.pascalCase()}}ListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows items; add button hidden without permission',
        (tester) async {
      when(() => repo.getList(any()))
          .thenAnswer((_) async => Result.success(_page([_a, _b], page: 1, total: 2)));

      await pump(tester);

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('add button shown with {{name.paramCase()}}:create', (tester) async {
      when(() => repo.getList(any()))
          .thenAnswer((_) async => Result.success(_page([_a], total: 1)));

      await pump(tester, permissions: {'{{name.paramCase()}}:create'});

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('empty list shows the empty view', (tester) async {
      when(() => repo.getList(any())).thenAnswer(
        (_) async => const Result.success(PagedList.empty()),
      );

      await pump(tester);

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('failure shows the error view with retry', (tester) async {
      when(() => repo.getList(any())).thenAnswer(
        (_) async => Result.error(
          NetworkFailure(
            'x',
            code: 'offline',
            cause: DioException(requestOptions: RequestOptions(path: '/')),
          ),
        ),
      );

      await pump(tester);

      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('No internet connection'), findsOneWidget);
    });
  });
}
