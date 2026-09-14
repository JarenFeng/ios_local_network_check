import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ios_local_network_check_method_channel.dart';

abstract class IosLocalNetworkCheckPlatform extends PlatformInterface {
  /// Constructs a IosLocalNetworkCheckPlatform.
  IosLocalNetworkCheckPlatform() : super(token: _token);

  static final Object _token = Object();

  static IosLocalNetworkCheckPlatform _instance = MethodChannelIosLocalNetworkCheck();

  /// The default instance of [IosLocalNetworkCheckPlatform] to use.
  ///
  /// Defaults to [MethodChannelIosLocalNetworkCheck].
  static IosLocalNetworkCheckPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [IosLocalNetworkCheckPlatform] when
  /// they register themselves.
  static set instance(IosLocalNetworkCheckPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
