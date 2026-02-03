import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter_main/core/app/app_providers_wrapper.dart';
import 'package:frontend_flutter_main/core/app/app_root.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(child: AppProvidersWrapper(child: AppRoot())),
    );

    // Verify that the app starts
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
