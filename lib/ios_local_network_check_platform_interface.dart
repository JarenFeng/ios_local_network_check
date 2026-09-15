import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ios_local_network_check_method_channel.dart';
import 'ios_local_network_check_types.dart';

abstract class IosLocalNetworkCheckPlatform extends PlatformInterface {
  IosLocalNetworkCheckPlatform() : super(token: _token);

  static final Object _token = Object();

  static IosLocalNetworkCheckPlatform _instance =
      MethodChannelIosLocalNetworkCheck();

  static IosLocalNetworkCheckPlatform get instance => _instance;

  static set instance(IosLocalNetworkCheckPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<LocalNetworkPermissionStatus> check({
    required String ipAddress,
    required int port,
    required LocalNetworkProtocol protocol,
    required Duration timeout,
  }) {
    throw UnimplementedError('check() has not been implemented.');
  }
}
