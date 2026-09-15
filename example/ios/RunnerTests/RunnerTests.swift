import Flutter
import XCTest

@testable import ios_local_network_check

final class RunnerTests: XCTestCase {
  func testAllowSequence() {
    var state = LocalNetworkPermissionState(applicationIsActive: true)

    XCTAssertNil(state.markLocalNetworkDenied())
    XCTAssertEqual(state.applicationWillResignActive(), .waiting)
    XCTAssertTrue(state.applicationDidBecomeActive())
    XCTAssertEqual(state.markReady(), .ready)
  }

  func testDenySequence() {
    var state = LocalNetworkPermissionState(applicationIsActive: true)

    XCTAssertNil(state.markLocalNetworkDenied())
    XCTAssertEqual(state.applicationWillResignActive(), .waiting)
    XCTAssertTrue(state.applicationDidBecomeActive())
    XCTAssertEqual(state.confirmedDenied(pathIsStillDenied: true), .denied)
  }

  func testExistingDenial() {
    var state = LocalNetworkPermissionState(applicationIsActive: true)

    XCTAssertNil(state.markLocalNetworkDenied())
    XCTAssertEqual(state.confirmedDenied(pathIsStillDenied: true), .denied)
  }

  func testAmbiguousPathRemainsUnknown() {
    var state = LocalNetworkPermissionState(applicationIsActive: true)

    XCTAssertNil(state.markLocalNetworkDenied())
    XCTAssertNil(state.confirmedDenied(pathIsStillDenied: false))
    XCTAssertEqual(state.timedOut(), .unknown)
  }

  func testTimeoutWhilePromptIsVisibleRemainsWaiting() {
    var state = LocalNetworkPermissionState(applicationIsActive: true)

    XCTAssertNil(state.markLocalNetworkDenied())
    XCTAssertEqual(state.applicationWillResignActive(), .waiting)
    XCTAssertEqual(state.timedOut(), .waiting)
  }

  func testRejectsInvalidArguments() {
    let plugin = IosLocalNetworkCheckPlugin()

    let error = plugin.onListen(withArguments: [:]) { _ in }

    XCTAssertEqual(error?.code, "invalid_arguments")
  }
}
