import 'package:flutter_test/flutter_test.dart';
import 'package:ios_local_network_check/ios_local_network_check.dart';
import 'package:ios_local_network_check/ios_local_network_check_platform_interface.dart';
import 'package:ios_local_network_check/ios_local_network_check_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakeIosLocalNetworkCheckPlatform
    with MockPlatformInterfaceMixin
    implements IosLocalNetworkCheckPlatform {
  String? ipAddress;
  int? port;
  LocalNetworkProtocol? protocol;
  Duration? timeout;

  @override
  Stream<LocalNetworkPermissionStatus> check({
    required String ipAddress,
    required int port,
    required LocalNetworkProtocol protocol,
    required Duration timeout,
  }) {
    this.ipAddress = ipAddress;
    this.port = port;
    this.protocol = protocol;
    this.timeout = timeout;
    return Stream.fromIterable(const [
      LocalNetworkPermissionStatus.waiting,
      LocalNetworkPermissionStatus.ready,
    ]);
  }
}

void main() {
  final initialPlatform = IosLocalNetworkCheckPlatform.instance;

  tearDown(() {
    IosLocalNetworkCheckPlatform.instance = initialPlatform;
  });

  test('默认使用 EventChannel 平台实现', () {
    expect(initialPlatform, isInstanceOf<MethodChannelIosLocalNetworkCheck>());
  });

  test('向平台层传递参数并返回状态流', () async {
    final platform = FakeIosLocalNetworkCheckPlatform();
    IosLocalNetworkCheckPlatform.instance = platform;
    const plugin = IosLocalNetworkCheck();

    await expectLater(
      plugin.check(
        ipAddress: '192.168.1.10',
        port: 9000,
        protocol: LocalNetworkProtocol.tcp,
        timeout: const Duration(seconds: 12),
      ),
      emitsInOrder([
        LocalNetworkPermissionStatus.waiting,
        LocalNetworkPermissionStatus.ready,
        emitsDone,
      ]),
    );
    expect(platform.ipAddress, '192.168.1.10');
    expect(platform.port, 9000);
    expect(platform.protocol, LocalNetworkProtocol.tcp);
    expect(platform.timeout, const Duration(seconds: 12));
  });

  test('拒绝无效 IP 地址', () {
    const plugin = IosLocalNetworkCheck();

    expect(
      () => plugin.check(
        ipAddress: 'router.local',
        port: 9000,
        protocol: LocalNetworkProtocol.udp,
      ),
      throwsArgumentError,
    );
  });

  test('拒绝无效端口', () {
    const plugin = IosLocalNetworkCheck();

    expect(
      () => plugin.check(
        ipAddress: '192.168.1.10',
        port: 0,
        protocol: LocalNetworkProtocol.udp,
      ),
      throwsArgumentError,
    );
    expect(
      () => plugin.check(
        ipAddress: '192.168.1.10',
        port: 65536,
        protocol: LocalNetworkProtocol.udp,
      ),
      throwsArgumentError,
    );
  });

  test('拒绝非正数超时时间', () {
    const plugin = IosLocalNetworkCheck();

    expect(
      () => plugin.check(
        ipAddress: '192.168.1.10',
        port: 9000,
        protocol: LocalNetworkProtocol.udp,
        timeout: Duration.zero,
      ),
      throwsArgumentError,
    );
  });
}
