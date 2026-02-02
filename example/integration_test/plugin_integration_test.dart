// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:agora_rtc/agora_rtc.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('controller smoke test', (WidgetTester tester) async {
    final AgoraRtcController controller = AgoraRtcController(appId: 'appId');
    expect(controller, isA<AgoraRtcController>());
  });
}
