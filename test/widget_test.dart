import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_flutter/login_screen.dart'; // Adjust if needed

void main() {
  testWidgets('Login screen has email, password, and login button', (WidgetTester tester) async {
    // Load the LoginPage widget
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    // Check that there are two text form fields
    expect(find.byType(TextFormField), findsNWidgets(2));

    // Check that there's a login button with the text "Login"
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });
}
