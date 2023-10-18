import 'dart:async';
import 'package:flutter/services.dart';

class WearOsPlugin {
  /// The method channel used to interact with the native platform.
  static WearOsPlugin instance = WearOsPlugin._();
  static const String channelMethod = "wear_os_plugin/method";
  static const String channelEvent = "wear_os_plugin/event";

  static bool? isRound;

  final methodChannel = const MethodChannel(channelMethod);
  StreamController<MotionData>? _scanResultStreamController;

  WearOsPlugin._() {
    const EventChannel(channelEvent)
        .receiveBroadcastStream()
        .listen(_onToDart, onError: _onToDartError);

    // request some data on startup:
    methodChannel.invokeMethod<bool?>('isScreenRound').then((rc) {
      isRound = rc;
      print('Wear OS Plugin: round=$rc');
    });
  }

  // methods ------------------------------------------------------------------

  /// get the android platform SDK, for example 33 is Android 13
  Future<int?> getPlatformSDK() async {
    return await methodChannel.invokeMethod<int>('getPlatformSDK');
  }

  /// get the android device manufacturer name
  Future<String?> getManufacturer() async {
    return await methodChannel.invokeMethod<String>('getManufacturer');
  }

  /// get the android device model name
  Future<String?> getModel() async {
    return await methodChannel.invokeMethod<String>('getModel');
  }

  /// get the app version string
  Future<String?> getAppVersion() async {
    return await methodChannel.invokeMethod<String>('getAppVersion');
  }

  /// true if the device is round, false if its rectangular/square, null for any errors
  Future<bool?> isScreenRound() async {
    return await methodChannel.invokeMethod<bool?>('isScreenRound');
  }

  /// vibrate with a given duration and amplitude, or with a given effect like 'click' (Android SDK 29+)
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

  /// close the rotary input stream
  void done() {
    _scanResultStreamController?.close();
    _scanResultStreamController = null;
  }

  /// get a stream of all motion events, including the rotary events
  Stream<MotionData>? get motionEvents {
    _scanResultStreamController?.close(); // close old stream before
    _scanResultStreamController =
        StreamController<MotionData>(); // create new stream
    return _scanResultStreamController?.stream;
  }

  // callbacks ----------------------------------------------------------------
  void _onToDart(dynamic message) {
    if (_scanResultStreamController != null) {
      _scanResultStreamController!.add(MotionData(message['scroll']));
    }
  }

  void _onToDartError(dynamic error) {
    if (_scanResultStreamController != null) {
      _scanResultStreamController!.addError(error);
    }
  }
}

class MotionData {
  // amount of scrolling, taken from AXIS_SCROLL
  final double? scroll;

  MotionData(this.scroll);
}
