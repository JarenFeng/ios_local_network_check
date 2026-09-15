# ios_local_network_check

通过指定的 TCP 或 UDP 本地网络端点，检查 Flutter 应用在 iOS 上的本地网络权限状态。

## 配置

宿主应用必须在 `Info.plist` 中添加权限用途说明：

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>用于检查并连接同一局域网内的设备</string>
```

## 使用

```dart
import 'package:ios_local_network_check/ios_local_network_check.dart';

const checker = IosLocalNetworkCheck();

final subscription = checker
    .check(
      ipAddress: '192.168.1.1',
      port: 9,
      protocol: LocalNetworkProtocol.udp,
    )
    .listen((status) {
      switch (status) {
        case LocalNetworkPermissionStatus.ready:
          break;
        case LocalNetworkPermissionStatus.denied:
          break;
        case LocalNetworkPermissionStatus.waiting:
          break;
        case LocalNetworkPermissionStatus.unknown:
          break;
      }
    });

await subscription.cancel();
```

`check` 返回单订阅状态流。同一时间只能运行一个检查，状态流关闭代表本次检查结束。默认超时时间为 30 秒，也可以通过 `timeout` 修改。

状态含义：

- `ready`：网络操作已通过本地网络权限限制
- `denied`：权限已拒绝，且当前没有待处理的系统弹窗
- `waiting`：正在等待用户处理系统权限弹窗
- `unknown`：网络、目标端点、应用状态或系统信息不足以可靠判断权限

## TCP 与 UDP

建议优先使用 UDP 检查。UDP 没有连接握手，插件只建立 endpoint，不发送业务数据，也不要求对端监听指定端口或返回数据，因此检查结果不依赖对端服务是否启动。`ready` 仅表示本地网络操作已通过权限限制，不表示目标设备或 UDP 服务可达。

TCP 必须成功连接到正在监听的本地端口才能返回 `ready`。端口关闭、目标不可达或其他非权限错误都会返回 `unknown`。

传入的地址必须属于设备当前连接的本地网络。公网地址和 loopback 地址不能用于检查本地网络权限。

## 系统限制

iOS 没有直接查询本地网络权限的公开 API。弹窗尚未处理与此前已拒绝都可能暂时表现为 `NWConnection.waiting` 和 `localNetworkDenied`。插件会结合连接路径及应用生命周期进行保守判断，证据不足时返回 `unknown`。

权限检查本身可能触发系统弹窗，建议只在用户主动进入需要本地网络的功能后调用。

权限行为需要在真实设备上测试，模拟器不支持本地网络隐私权限流程。更多系统行为参见 [Apple TN3179](https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy)。
