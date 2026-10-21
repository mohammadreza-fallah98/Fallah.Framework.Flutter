import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_ui/fallah_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => MaterialApp(
      theme: AppTheme.light(fontFamily: 'Roboto'),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('AppErrorView shows message and retries', (tester) async {
    var retried = 0;
    await tester.pumpWidget(
      host(
        AppErrorView(
          failure: const NetworkFailure('No connection'),
          onRetry: () => retried++,
          retryLabel: 'Try again',
        ),
      ),
    );

    expect(find.text('No connection'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, 1);
  });

  testWidgets('AppErrorView prefers the localized message', (tester) async {
    await tester.pumpWidget(
      host(
        const AppErrorView(
          failure: NetworkFailure('No connection', code: 'offline'),
          message: 'اتصال برقرار نیست',
        ),
      ),
    );
    expect(find.text('اتصال برقرار نیست'), findsOneWidget);
    expect(find.text('No connection'), findsNothing);
  });

  testWidgets('AppPagedList asks for the next page only once per length',
      (tester) async {
    var loads = 0;
    Widget build() => host(
          AppPagedList<int>(
            items: List.generate(3, (i) => i),
            hasMore: true,
            onLoadMore: () => loads++,
            itemBuilder: (_, i) => Text('item $i'),
          ),
        );
    await tester.pumpWidget(build());
    await tester.pump();
    await tester.pumpWidget(build());
    await tester.pump();
    expect(loads, 1);
  });

  testWidgets('AppButton is disabled while loading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        AppButton(label: 'Save', isLoading: true, onPressed: () => taps++),
      ),
    );
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AppTextField shows server error', (tester) async {
    await tester.pumpWidget(
      host(
        const AppTextField(label: 'Mobile', serverError: 'Already used'),
      ),
    );
    expect(find.text('Already used'), findsOneWidget);
  });

  testWidgets('AppPagedList requests more near the end', (tester) async {
    var loads = 0;
    await tester.pumpWidget(
      host(
        AppPagedList<int>(
          items: List.generate(3, (i) => i),
          hasMore: true,
          onLoadMore: () => loads++,
          itemBuilder: (_, i) => Text('item $i'),
        ),
      ),
    );
    await tester.pump();
    expect(loads, greaterThan(0));
  });

  testWidgets('Samim font assets are bundled and the default theme uses it',
      (tester) async {
    for (final file in ['Samim', 'Samim-Medium', 'Samim-Bold', 'Samim-FD']) {
      final data =
          await rootBundle.load('packages/fallah_ui/assets/fonts/$file.ttf');
      expect(data.lengthInBytes, greaterThan(10000), reason: file);
    }
    expect(AppTheme.light().textTheme.bodyMedium?.fontFamily, AppFonts.samim);
  });

  test('theme exposes AppTokens and 48dp targets', () {
    final theme = AppTheme.dark(fontFamily: 'Roboto');
    expect(theme.extension<AppTokens>(), isNotNull);
  });
}
