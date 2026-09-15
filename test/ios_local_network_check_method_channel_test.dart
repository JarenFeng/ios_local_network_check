import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ios_local_network_check/ios_local_network_check.dart';
import 'package:ios_local_network_check/ios_local_network_check_method_channel.dart';

void main() {
  test('解析四种原生权限状态', () async {
    final platform = MethodChannelIosLocalNetworkCheck(
      eventStreamFactory:
          (_) => Stream.fromIterable(const [
            'waiting',
            'ready',
            'denied',
            'unknown',
          ]),
    );

    await expectLater(
      platform.check(
        ipAddress: '192.168.1.1',
        port: 9,
        protocol: LocalNetworkProtocol.udp,
        timeout: const Duration(seconds: 30),
      ),
      emitsInOrder([
        LocalNetworkPermissionStatus.waiting,
        LocalNetworkPermissionStatus.ready,
        LocalNetworkPermissionStatus.denied,
        LocalNetworkPermissionStatus.unknown,
        emitsDone,
      ]),
    );
  });

  test('向原生事件通道传递检查参数', () async {
    Object? receivedArguments;
    final platform = MethodChannelIosLocalNetworkCheck(
      eventStreamFactory: (arguments) {
        receivedArguments = arguments;
        return Stream.value('ready');
      },
    );

    await platform
        .check(
          ipAddress: '10.0.0.2',
          port: 8080,
          protocol: LocalNetworkProtocol.tcp,
          timeout: const Duration(seconds: 5),
        )
        .drain<void>();

    expect(receivedArguments, {
      'ipAddress': '10.0.0.2',
      'port': 8080,
      'protocol': 'tcp',
      'timeoutMilliseconds': 5000,
    });
  });

  test('拒绝同时运行第二个检查', () async {
    final source = StreamController<dynamic>();
    final platform = MethodChannelIosLocalNetworkCheck(
      eventStreamFactory: (_) => source.stream,
    );
    final firstSubscription = platform
        .check(
          ipAddress: '192.168.1.1',
          port: 9,
          protocol: LocalNetworkProtocol.udp,
          timeout: const Duration(seconds: 30),
        )
        .listen((_) {});

    await expectLater(
      platform.check(
        ipAddress: '192.168.1.2',
        port: 9,
        protocol: LocalNetworkProtocol.udp,
        timeout: const Duration(seconds: 30),
      ),
      emitsError(isA<StateError>()),
    );

    await firstSubscription.cancel();
    await source.close();
  });

  test('取消状态流时取消原生事件订阅', () async {
    var wasCancelled = false;
    final source = StreamController<dynamic>(
      onCancel: () {
        wasCancelled = true;
      },
    );
    final platform = MethodChannelIosLocalNetworkCheck(
      eventStreamFactory: (_) => source.stream,
    );
    final subscription = platform
        .check(
          ipAddress: '192.168.1.1',
          port: 9,
          protocol: LocalNetworkProtocol.udp,
          timeout: const Duration(seconds: 30),
        )
        .listen((_) {});

    await subscription.cancel();

    expect(wasCancelled, isTrue);
    await source.close();
  });

  test('无法识别的原生状态返回格式错误', () async {
    final platform = MethodChannelIosLocalNetworkCheck(
      eventStreamFactory: (_) => Stream.value('unexpected'),
    );

    await expectLater(
      platform.check(
        ipAddress: '192.168.1.1',
        port: 9,
        protocol: LocalNetworkProtocol.udp,
        timeout: const Duration(seconds: 30),
      ),
      emitsError(isA<FormatException>()),
    );
  });
}
