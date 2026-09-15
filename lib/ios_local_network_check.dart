import 'dart:io';

import 'ios_local_network_check_platform_interface.dart';
import 'ios_local_network_check_types.dart';

export 'ios_local_network_check_types.dart';

/// 使用指定端点检查 iOS 本地网络权限
class IosLocalNetworkCheck {
  const IosLocalNetworkCheck();

  /// 开始检查并持续返回权限状态
  ///
  /// 同一时间只能运行一个检查，取消订阅会同步取消原生网络操作
  Stream<LocalNetworkPermissionStatus> check({
    required String ipAddress,
    required int port,
    required LocalNetworkProtocol protocol,
    Duration timeout = const Duration(seconds: 30),
  }) {
    if (InternetAddress.tryParse(ipAddress) == null) {
      throw ArgumentError.value(
        ipAddress,
        'ipAddress',
        'Must be a valid IPv4 or IPv6 address literal.',
      );
    }
    if (port < 1 || port > 65535) {
      throw ArgumentError.value(port, 'port', 'Must be between 1 and 65535.');
    }
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(
        timeout,
        'timeout',
        'Must be greater than zero.',
      );
    }

    return IosLocalNetworkCheckPlatform.instance.check(
      ipAddress: ipAddress,
      port: port,
      protocol: protocol,
      timeout: timeout,
    );
  }
}
