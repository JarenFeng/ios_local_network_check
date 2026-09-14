import 'package:flutter_test/flutter_test.dart';
import 'package:ios_local_network_check/ios_local_network_check.dart';
import 'package:ios_local_network_check/ios_local_network_check_platform_interface.dart';
import 'package:ios_local_network_check/ios_local_network_check_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockIosLocalNetworkCheckPlatform
    with MockPlatformInterfaceMixin
    implements IosLocalNetworkCheckPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final IosLocalNetworkCheckPlatform initialPlatform = IosLocalNetworkCheckPlatform.instance;

  test('$MethodChannelIosLocalNetworkCheck is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelIosLocalNetworkCheck>());
  });

  test('getPlatformVersion', () async {
    IosLocalNetworkCheck iosLocalNetworkCheckPlugin = IosLocalNetworkCheck();
    MockIosLocalNetworkCheckPlatform fakePlatform = MockIosLocalNetworkCheckPlatform();
    IosLocalNetworkCheckPlatform.instance = fakePlatform;

    expect(await iosLocalNetworkCheckPlugin.getPlatformVersion(), '42');
  });
}
