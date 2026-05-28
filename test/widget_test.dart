import 'package:chat_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders login screen after startup', (tester) async {
    await tester.pumpWidget(
      ChatApp(repository: ChatRepository.demo(), showSplash: false),
    );
    await tester.pump();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
    expect(find.text('Phone Number (+923001234567)'), findsOneWidget);
  });
}
