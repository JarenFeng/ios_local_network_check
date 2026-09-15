import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ios_local_network_check_platform_interface.dart';
import 'ios_local_network_check_types.dart';

/// 基于 EventChannel 的平台实现
class MethodChannelIosLocalNetworkCheck extends IosLocalNetworkCheckPlatform {
  MethodChannelIosLocalNetworkCheck({
    EventChannel? eventChannel,
    @visibleForTesting
    Stream<dynamic> Function(Object? arguments)? eventStreamFactory,
  }) : eventChannel =
           eventChannel ?? const EventChannel('ios_local_network_check/events'),
       _eventStreamFactory = eventStreamFactory;

  @visibleForTesting
  final EventChannel eventChannel;

  final Stream<dynamic> Function(Object? arguments)? _eventStreamFactory;
  bool _hasActiveCheck = false;

  @override
  Stream<LocalNetworkPermissionStatus> check({
    required String ipAddress,
    required int port,
    required LocalNetworkProtocol protocol,
    required Duration timeout,
  }) {
    late final StreamController<LocalNetworkPermissionStatus> controller;
    StreamSubscription<dynamic>? platformSubscription;
    var ownsActiveCheck = false;

    void releaseActiveCheck() {
      if (!ownsActiveCheck) {
        return;
      }
      ownsActiveCheck = false;
      _hasActiveCheck = false;
    }

    controller = StreamController<LocalNetworkPermissionStatus>(
      onListen: () {
        if (_hasActiveCheck) {
          controller.addError(
            StateError('A local network permission check is already running.'),
          );
          unawaited(controller.close());
          return;
        }

        _hasActiveCheck = true;
        ownsActiveCheck = true;
        final arguments = <String, Object>{
          'ipAddress': ipAddress,
          'port': port,
          'protocol': protocol.name,
          'timeoutMilliseconds': timeout.inMilliseconds,
        };
        final eventStream =
            _eventStreamFactory?.call(arguments) ??
            eventChannel.receiveBroadcastStream(arguments);

        platformSubscription = eventStream.listen(
          (dynamic event) {
            final status = _decodeStatus(event);
            if (status == null) {
              controller.addError(
                FormatException(
                  'Unknown local network permission status: $event',
                ),
              );
              return;
            }
            controller.add(status);
          },
          onError: controller.addError,
          onDone: () {
            releaseActiveCheck();
            unawaited(controller.close());
          },
        );
      },
      onPause: () => platformSubscription?.pause(),
      onResume: () => platformSubscription?.resume(),
      onCancel: () async {
        await platformSubscription?.cancel();
        releaseActiveCheck();
      },
    );

    return controller.stream;
  }

  LocalNetworkPermissionStatus? _decodeStatus(dynamic event) {
    return switch (event) {
      'ready' => LocalNetworkPermissionStatus.ready,
      'denied' => LocalNetworkPermissionStatus.denied,
      'waiting' => LocalNetworkPermissionStatus.waiting,
      'unknown' => LocalNetworkPermissionStatus.unknown,
      _ => null,
    };
  }
}
