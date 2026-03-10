// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:runner_scan/main.dart';
import 'package:runner_scan/providers/app_state.dart';

void main() {
  testWidgets('Home screen displays correctly', (WidgetTester tester) async {
    // Create a mock AppState
    final appState = AppState();
    await appState.init();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const RunnerScanApp(),
      ),
    );

    // Verify that the app title is displayed.
    expect(find.text('Runner Scan'), findsOneWidget);
    
    // Verify that Start Session button is displayed.
    expect(find.text('Start Session'), findsOneWidget);
  });
}
