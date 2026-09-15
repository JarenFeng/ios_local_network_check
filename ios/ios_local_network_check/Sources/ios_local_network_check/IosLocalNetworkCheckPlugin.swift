import Darwin
import Flutter
import Network
import UIKit

enum NativePermissionStatus: String {
  case ready
  case denied
  case waiting
  case unknown
}

struct LocalNetworkPermissionState {
  private(set) var applicationIsActive: Bool
  private(set) var observedInactive = false
  private(set) var localNetworkIsDenied = false

  mutating func reset(applicationIsActive: Bool) {
    self.applicationIsActive = applicationIsActive
    observedInactive = false
    localNetworkIsDenied = false
  }

  mutating func markReady() -> NativePermissionStatus {
    localNetworkIsDenied = false
    return .ready
  }

  mutating func markLocalNetworkDenied() -> NativePermissionStatus? {
    localNetworkIsDenied = true
    if applicationIsActive {
      return nil
    }
    observedInactive = true
    return .waiting
  }

  mutating func clearLocalNetworkDenied() {
    localNetworkIsDenied = false
  }

  mutating func applicationWillResignActive() -> NativePermissionStatus? {
    applicationIsActive = false
    guard localNetworkIsDenied else {
      return nil
    }
    observedInactive = true
    return .waiting
  }

  mutating func applicationDidBecomeActive() -> Bool {
    applicationIsActive = true
    return observedInactive && localNetworkIsDenied
  }

  func confirmedDenied(pathIsStillDenied: Bool) -> NativePermissionStatus? {
    guard applicationIsActive, localNetworkIsDenied, pathIsStillDenied else {
      return nil
    }
    return .denied
  }

  func timedOut() -> NativePermissionStatus {
    if localNetworkIsDenied && !applicationIsActive {
      return .waiting
    }
    return .unknown
  }
}

public final class IosLocalNetworkCheckPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private enum Transport: String {
    case tcp
    case udp
  }

  private let stateQueue = DispatchQueue(label: "dev.flutter.ios-local-network-check.state")
  private var eventSink: FlutterEventSink?
  private var connection: NWConnection?
  private var timeoutWorkItem: DispatchWorkItem?
  private var denialWorkItem: DispatchWorkItem?
  private var lifecycleObservers: [NSObjectProtocol] = []
  private var permissionState = LocalNetworkPermissionState(applicationIsActive: false)
  private var lastEmittedStatus: NativePermissionStatus?
  private var isFinished = false

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = IosLocalNetworkCheckPlugin()
    let eventChannel = FlutterEventChannel(
      name: "ios_local_network_check/events",
      binaryMessenger: registrar.messenger()
    )
    eventChannel.setStreamHandler(instance)
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    guard let request = arguments as? [String: Any],
          let ipAddress = request["ipAddress"] as? String,
          isIPAddress(ipAddress),
          let portNumber = request["port"] as? NSNumber,
          (1...65535).contains(portNumber.intValue),
          let transportName = request["protocol"] as? String,
          let transport = Transport(rawValue: transportName),
          let timeoutNumber = request["timeoutMilliseconds"] as? NSNumber,
          timeoutNumber.doubleValue > 0 else {
      return FlutterError(
        code: "invalid_arguments",
        message: "A valid IP address, port, protocol, and positive timeout are required.",
        details: nil
      )
    }

    var reserved = false
    stateQueue.sync {
      if eventSink == nil {
        eventSink = events
        reserved = true
      }
    }
    guard reserved else {
      return FlutterError(
        code: "check_in_progress",
        message: "A local network permission check is already running.",
        details: nil
      )
    }

    let appIsActive = UIApplication.shared.applicationState == .active
    stateQueue.async { [weak self] in
      self?.startCheck(
        ipAddress: ipAddress,
        port: UInt16(portNumber.intValue),
        transport: transport,
        timeout: timeoutNumber.doubleValue / 1000,
        appIsActive: appIsActive
      )
    }
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    stateQueue.async { [weak self] in
      self?.cancelCurrentCheck()
    }
    return nil
  }

  private func startCheck(
    ipAddress: String,
    port: UInt16,
    transport: Transport,
    timeout: TimeInterval,
    appIsActive: Bool
  ) {
    isFinished = false
    permissionState.reset(applicationIsActive: appIsActive)
    lastEmittedStatus = nil

    guard appIsActive else {
      finish(with: .unknown)
      return
    }

    observeApplicationLifecycle()

    let parameters: NWParameters = transport == .tcp ? .tcp : .udp
    let endpointPort = NWEndpoint.Port(rawValue: port)!
    let newConnection = NWConnection(
      host: NWEndpoint.Host(ipAddress),
      port: endpointPort,
      using: parameters
    )
    connection = newConnection
    newConnection.stateUpdateHandler = { [weak self, weak newConnection] state in
      guard let self, let newConnection else {
        return
      }
      self.handleConnectionState(state, connection: newConnection)
    }

    let timeoutItem = DispatchWorkItem { [weak self] in
      self?.handleTimeout()
    }
    timeoutWorkItem = timeoutItem
    stateQueue.asyncAfter(deadline: .now() + timeout, execute: timeoutItem)
    newConnection.start(queue: stateQueue)
  }

  private func handleConnectionState(
    _ state: NWConnection.State,
    connection: NWConnection
  ) {
    guard !isFinished else {
      return
    }

    switch state {
    case .ready:
      finish(with: permissionState.markReady())
    case .waiting:
      if connection.currentPath?.unsatisfiedReason == .localNetworkDenied {
        handleLocalNetworkDenied()
      } else {
        permissionState.clearLocalNetworkDenied()
        denialWorkItem?.cancel()
        denialWorkItem = nil
      }
    case .failed:
      if connection.currentPath?.unsatisfiedReason == .localNetworkDenied {
        handleLocalNetworkDenied()
      } else {
        finish(with: .unknown)
      }
    case .cancelled:
      if !isFinished {
        finish(with: .unknown)
      }
    case .setup, .preparing:
      break
    @unknown default:
      finish(with: .unknown)
    }
  }

  private func handleLocalNetworkDenied() {
    if let status = permissionState.markLocalNetworkDenied() {
      denialWorkItem?.cancel()
      denialWorkItem = nil
      emit(status)
      return
    }

    scheduleDeniedConfirmation(after: 2)
  }

  private func scheduleDeniedConfirmation(after delay: TimeInterval) {
    denialWorkItem?.cancel()
    let workItem = DispatchWorkItem { [weak self] in
      guard let self,
            !self.isFinished,
            self.permissionState.applicationIsActive,
            self.permissionState.localNetworkIsDenied else {
        return
      }

      let pathIsStillDenied =
        self.connection?.currentPath?.unsatisfiedReason == .localNetworkDenied
      if let status = self.permissionState.confirmedDenied(
        pathIsStillDenied: pathIsStillDenied
      ) {
        self.finish(with: status)
      }
    }
    denialWorkItem = workItem
    stateQueue.asyncAfter(deadline: .now() + delay, execute: workItem)
  }

  private func observeApplicationLifecycle() {
    let notificationCenter = NotificationCenter.default
    lifecycleObservers = [
      notificationCenter.addObserver(
        forName: UIApplication.willResignActiveNotification,
        object: nil,
        queue: nil
      ) { [weak self] _ in
        self?.stateQueue.async { [weak self] in
          guard let self, !self.isFinished else {
            return
          }
          if let status = self.permissionState.applicationWillResignActive() {
            self.denialWorkItem?.cancel()
            self.denialWorkItem = nil
            self.emit(status)
          }
        }
      },
      notificationCenter.addObserver(
        forName: UIApplication.didBecomeActiveNotification,
        object: nil,
        queue: nil
      ) { [weak self] _ in
        self?.stateQueue.async { [weak self] in
          guard let self, !self.isFinished else {
            return
          }
          guard self.permissionState.applicationDidBecomeActive() else {
            return
          }
          self.connection?.restart()
          self.scheduleDeniedConfirmation(after: 2)
        }
      }
    ]
  }

  private func handleTimeout() {
    guard !isFinished else {
      return
    }
    finish(with: permissionState.timedOut())
  }

  private func emit(_ status: NativePermissionStatus) {
    guard lastEmittedStatus != status, let sink = eventSink else {
      return
    }
    lastEmittedStatus = status
    DispatchQueue.main.async {
      sink(status.rawValue)
    }
  }

  private func finish(with status: NativePermissionStatus) {
    guard !isFinished, let sink = eventSink else {
      return
    }
    isFinished = true

    let shouldEmitStatus = lastEmittedStatus != status
    lastEmittedStatus = status
    releaseNativeResources()
    eventSink = nil

    DispatchQueue.main.async {
      if shouldEmitStatus {
        sink(status.rawValue)
      }
      sink(FlutterEndOfEventStream)
    }
  }

  private func cancelCurrentCheck() {
    guard eventSink != nil else {
      return
    }
    isFinished = true
    releaseNativeResources()
    eventSink = nil
  }

  private func releaseNativeResources() {
    timeoutWorkItem?.cancel()
    timeoutWorkItem = nil
    denialWorkItem?.cancel()
    denialWorkItem = nil

    connection?.stateUpdateHandler = nil
    connection?.cancel()
    connection = nil

    let notificationCenter = NotificationCenter.default
    lifecycleObservers.forEach(notificationCenter.removeObserver)
    lifecycleObservers.removeAll()
  }

  private func isIPAddress(_ value: String) -> Bool {
    var ipv4Address = in_addr()
    if value.withCString({ inet_pton(AF_INET, $0, &ipv4Address) }) == 1 {
      return true
    }

    var ipv6Address = in6_addr()
    return value.withCString({ inet_pton(AF_INET6, $0, &ipv6Address) }) == 1
  }
}
