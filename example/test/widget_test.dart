import 'package:flutter_test/flutter_test.dart';
import 'package:nw_media_picker_example/main.dart';

void main() {
  testWidgets('home screen renders the demo actions', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();

    expect(find.text('NW Media Picker'), findsWidgets);
    expect(find.text('Pick Image'), findsOneWidget);
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Capability Test'), findsOneWidget);
    expect(find.text('Clear Cache'), findsOneWidget);
  });
}
