import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loading_text_shifter/loading_text_shifter.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('shows the first message immediately and advances to the next', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        LoadingTextShifter(
          messages: const ['one', 'two', 'three'],
          shiftDuration: const Duration(milliseconds: 100),
          animationDuration: const Duration(milliseconds: 50),
          loop: false,
        ),
      ),
    );

    expect(find.text('one'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 110)); // shiftDuration
    await tester.pump(const Duration(milliseconds: 60)); // animationDuration
    expect(find.text('two'), findsWidgets);
  });

  testWidgets('holdAt gates advancement and can stop the cycle', (
    tester,
  ) async {
    final visited = <int>[];
    await tester.pumpWidget(
      host(
        LoadingTextShifter(
          messages: const ['a', 'b', 'c'],
          animationDuration: const Duration(milliseconds: 20),
          loop: false,
          holdAt: (index, _) async {
            visited.add(index);
            return index < 1; // advance only from 0 → 1, then stop
          },
        ),
      ),
    );

    await tester.pump(); // post-frame initial onShift
    await tester.pump(const Duration(milliseconds: 30)); // animation
    await tester.pump(); // settle

    expect(visited, [0, 1]);
    expect(find.text('b'), findsWidgets);
  });

  testWidgets('does not throw when disposed mid-hold', (tester) async {
    await tester.pumpWidget(
      host(
        LoadingTextShifter(
          messages: const ['x', 'y'],
          holdAt: (_, _) async {
            await Future.delayed(const Duration(seconds: 5));
            return true;
          },
        ),
      ),
    );

    await tester.pumpWidget(host(const SizedBox.shrink()));
    await tester.pump(const Duration(seconds: 6));
  });
}
