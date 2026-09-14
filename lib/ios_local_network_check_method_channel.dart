import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ios_local_network_check_platform_interface.dart';

/// An implementation of [IosLocalNetworkCheckPlatform] that uses method channels.
class MethodChannelIosLocalNetworkCheck extends IosLocalNetworkCheckPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ios_local_network_check');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
