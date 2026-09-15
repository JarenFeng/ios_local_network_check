import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ios_local_network_check/ios_local_network_check.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('在进入原生层前校验 IP 地址', (tester) async {
    const plugin = IosLocalNetworkCheck();

    expect(
      () => plugin.check(
        ipAddress: 'router.local',
        port: 9,
        protocol: LocalNetworkProtocol.udp,
      ),
      throwsArgumentError,
    );
  });
}
