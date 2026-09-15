/// 检查权限时使用的传输协议
enum LocalNetworkProtocol { tcp, udp }

/// 本地网络权限状态
enum LocalNetworkPermissionStatus {
  /// 网络操作已通过本地网络权限检查
  ready,

  /// 本地网络权限已拒绝
  denied,

  /// 正在等待用户处理系统权限弹窗
  waiting,

  /// 无法可靠判断权限状态
  unknown,
}
