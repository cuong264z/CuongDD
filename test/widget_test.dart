import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoang_hung_cuong_kt/app/theme.dart';
import 'package:hoang_hung_cuong_kt/screens/login_screen.dart';
import 'package:hoang_hung_cuong_kt/widgets/auth_shell.dart';

void main() {
  testWidgets('màn đăng nhập kiểm tra dữ liệu trước khi gọi server', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: buildTheme(), home: const LoginScreen()));
    expect(find.text('Đăng nhập'), findsOneWidget);

    await tester.tap(find.text('Tiếp tục'));
    await tester.pump();
    expect(find.text('Email không hợp lệ'), findsOneWidget);
    expect(find.text('Nhập mật khẩu'), findsOneWidget);
  });

  test('luật mật khẩu giống server', () {
    expect(validatePassword('abc'), isNotNull);
    expect(validatePassword('abcdef'), isNotNull); // thiếu chữ số
    expect(validatePassword('123456'), isNotNull); // thiếu chữ thường
    expect(validatePassword('matkhau1'), isNull);
  });
}
