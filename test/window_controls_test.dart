import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonicall/ui/widgets/window_controls.dart';

void main() {
  testWidgets('WindowControlsWidget renders buttons cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              Spacer(),
              WindowControlsWidget(height: 48),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify buttons are rendered
    expect(find.byType(WindowControlsWidget), findsOneWidget);
    expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
    expect(find.byIcon(Icons.crop_square_rounded), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });
}

