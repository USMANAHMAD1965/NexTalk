import 'package:chat_app/src/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders login screen after startup', (tester) async {
    await tester.pumpWidget(ChatApp(repository: ChatRepository.offline()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
  });
}
