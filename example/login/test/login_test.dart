// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:joker_state/joker_state.dart';
// import 'package:joker_state_login_example/main.dart';

// void main() {
//   setUp(() {
//     Circus.ringMaster();
//   });

//   tearDown(() {
//     Circus.ringMaster().reset();
//   });

//   group('LoginScreen', () {
//     testWidgets('logs in and shows success SnackBar', (tester) async {
//       await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

//       await tester.pumpAndSettle();

//       await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
//       await tester.enterText(find.byType(TextField).at(1), 'password123');

//       await tester.tap(find.byKey(const ValueKey('login-button')));
//       await tester.pump();
//       await tester.pump(const Duration(milliseconds: 300));

//       expect(
//         find.text('🎉 user@example.com logged in.'),
//         findsOneWidget,
//       );
//     });

//     testWidgets('shows SnackBar when account is not found', (tester) async {
//       await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

//       await tester.pumpAndSettle();

//       await tester.enterText(find.byType(TextField).at(0), 'unknown@mail.com');
//       await tester.enterText(find.byType(TextField).at(1), 'guess');

//       await tester.tap(find.byKey(const ValueKey('login-button')));
//       await tester.pump();
//       await tester.pump(const Duration(milliseconds: 300));

//       expect(
//         find.text('❌ Login failed: Account not found'),
//         findsOneWidget,
//       );
//     });

//     testWidgets('shows SnackBar when password is incorrect', (tester) async {
//       await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

//       await tester.pumpAndSettle();

//       await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
//       await tester.enterText(find.byType(TextField).at(1), 'wrong_pw');

//       await tester.tap(find.byKey(const ValueKey('login-button')));
//       await tester.pump();
//       await tester.pump(const Duration(milliseconds: 300));

//       expect(
//         find.text('❌ Login failed: Password incorrect'),
//         findsOneWidget,
//       );
//     });
//   });
// }
