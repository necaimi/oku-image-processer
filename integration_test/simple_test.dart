import 'package:flutter_test/flutter_test.dart';
import 'package:oku_image_processer/main.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const OkuApp());
    expect(find.byType(OkuApp), findsOneWidget);
  });
}
