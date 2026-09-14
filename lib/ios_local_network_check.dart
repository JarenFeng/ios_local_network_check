
import 'ios_local_network_check_platform_interface.dart';

class IosLocalNetworkCheck {
  Future<String?> getPlatformVersion() {
    return IosLocalNetworkCheckPlatform.instance.getPlatformVersion();
  }
}
