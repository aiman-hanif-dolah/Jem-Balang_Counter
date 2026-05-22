import 'package:flutter_test/flutter_test.dart';
import 'package:jembalang_counter/main.dart';


void main() {
  testWidgets('Dashboard UI renders successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BeverageSalesTrackerApp());
    await tester.pump();

    // Verify that our app header renders.
    expect(find.text('JEM-BALANG'), findsOneWidget);
    expect(find.text('Sales Dashboard'), findsOneWidget);

    // Verify that beverage cards render.
    expect(find.text('Thai Tea'), findsAtLeast(1));
    expect(find.text('Green Tea'), findsAtLeast(1));

    // Verify that Total Sales displays.
    expect(find.text('TOTAL SALES'), findsOneWidget);
  });
}

