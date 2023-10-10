import 'dart:async';
import 'package:flutter/services.dart';

class WearOsPlugin {
  /// The method channel used to interact with the native platform.
  static WearOsPlugin instance = WearOsPlugin._();
  static const String channelMethod = "wear_os_plugin/method";
  static const String channelEvent = "wear_os_plugin/event";

  final methodChannel = const MethodChannel(channelMethod);
  StreamController<MotionData>? _scanResultStreamController;

  WearOsPlugin._() {
    const EventChannel(channelEvent)
        .receiveBroadcastStream()
        .listen(_onToDart, onError: _onToDartError);
  }

  // methods ------------------------------------------------------------------
  Future<int?> getPlatformSDK() async {
    return await methodChannel.invokeMethod<int>('getPlatformSDK');
  }

  Future<String?> getManufacturer() async {
    return await methodChannel.invokeMethod<String>('getManufacturer');
  }

  Future<String?> getModel() async {
    return await methodChannel.invokeMethod<String>('getModel');
  }

  Future<String?> getAppVersion() async {
    return await methodChannel.invokeMethod<String>('getAppVersion');
  }

  Future<bool?> isScreenRound() async {
    return await methodChannel.invokeMethod<bool?>('isScreenRound');
  }

  Future<void> vibrate(
      {Duration duration = const Duration(milliseconds: 100),
        int amplitude = 100,
        String effect = ""}) async {
    return await methodChannel.invokeMethod<void>('vibrate', {
      'duration': duration.inMilliseconds,
      'amplitude': amplitude,
      'effect': effect,
    });
  }

  void done() {
    _scanResultStreamController?.close();
    _scanResultStreamController = null;
  }

  Stream<MotionData>? get motionEvents {
    _scanResultStreamController =
        StreamController<MotionData>(onListen: () {}, onCancel: () {});
    return _scanResultStreamController?.stream;
  }

  // callbacks ----------------------------------------------------------------
  void _onToDart(dynamic message) {
    if (_scanResultStreamController != null) {
      _scanResultStreamController!.add(MotionData(message['scroll']));
    }
  }

  void _onToDartError(dynamic error) {
    // print(error);
  }
}

class MotionData {
  final double? scroll;

  MotionData(this.scroll);
}
