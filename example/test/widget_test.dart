import 'package:flutter_test/flutter_test.dart';
import 'package:ios_local_network_check_example/main.dart';

void main() {
  testWidgets('展示权限检查表单', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('iOS 本地网络权限检查'), findsOneWidget);
    expect(find.text('本地网络 IP'), findsOneWidget);
    expect(find.text('端口'), findsOneWidget);
    expect(find.text('开始检查'), findsOneWidget);
    expect(find.text('权限状态：尚未检查'), findsOneWidget);
  });
}
