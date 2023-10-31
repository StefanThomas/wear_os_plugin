import 'dart:async';
import 'package:flutter/services.dart';

class WearOsPlugin {
  /// The method channel used to interact with the native platform.
  static WearOsPlugin instance = WearOsPlugin._();
  static const String channelMethod = "wear_os_plugin/method";
  static const String channelMotionEvents = "wear_os_plugin/motionEvents";
  static const String channelKeyEvents = "wear_os_plugin/keyEvents";
  static const String channelLifecycleEvents = "wear_os_plugin/lifecycleEvents";

  // data, which is static over the complete plugin runtime:
  static int? platformSDK;
  static String? manufacturer;
  static String? model;
  static String? appVersion;
  static bool? screenRound;

  final methodChannel = const MethodChannel(channelMethod);
  final List<StreamController<MotionData>> _motionEventsStreamController = [];
  StreamController<KeyData>? _keyEventsStreamController;
  StreamController<String>? _lifecycleEventsStreamController;

  WearOsPlugin._() {
    const EventChannel(channelMotionEvents)
        .receiveBroadcastStream()
        .listen(_onMotionEvent, onError: _onMotionEventError);

    const EventChannel(channelKeyEvents)
        .receiveBroadcastStream()
        .listen(_onKeyEvent, onError: _onKeyEventError);

    const EventChannel(channelLifecycleEvents)
        .receiveBroadcastStream()
        .listen(_onLifecycleEvent, onError: _onLifecycleEventError);

    // request the static data for the plugin runtime on startup:
    methodChannel
        .invokeMethod<int>('getPlatformSDK')
        .then((rc) => platformSDK = rc);
    methodChannel
        .invokeMethod<String>('getManufacturer')
        .then((rc) => manufacturer = rc);
    methodChannel.invokeMethod<String>('getModel').then((rc) => model = rc);
    methodChannel
        .invokeMethod<String>('getAppVersion')
        .then((rc) => appVersion = rc);
    methodChannel
        .invokeMethod<bool?>('isScreenRound')
        .then((rc) => screenRound = rc);
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

  /// get the measurement system: SI, UK or US (SI is metrical system)
  Future<String?> getMeasurementSystem() async {
    return await methodChannel.invokeMethod<String>('getMeasurementSystem');
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
    for (StreamController<MotionData> controller
        in _motionEventsStreamController) {
      controller.close();
    }
    _motionEventsStreamController.clear();
    _keyEventsStreamController?.close();
    _keyEventsStreamController = null;
    _lifecycleEventsStreamController?.close();
    _lifecycleEventsStreamController = null;
  }

  /// get a stream of all motion events, including the rotary events
  Stream<MotionData> get motionEvents {
    StreamController<MotionData> controller =
        StreamController<MotionData>(); // create new stream
    _motionEventsStreamController.add(controller);
    return controller.stream;
  }

  /// get a stream of all key events, including the BACK button
  Stream<KeyData>? get keyEvents {
    _keyEventsStreamController?.close(); // close old stream before
    _keyEventsStreamController =
        StreamController<KeyData>(); // create new stream
    return _keyEventsStreamController?.stream;
  }

  /// get a stream of all key events, including the BACK button
  Stream<String>? get lifecycleEvents {
    _lifecycleEventsStreamController?.close(); // close old stream before
    _lifecycleEventsStreamController =
        StreamController<String>(); // create new stream
    return _lifecycleEventsStreamController?.stream;
  }

  Future<void> setAppAlpha(double alpha) async {
    return await methodChannel
        .invokeMethod<void>('setAppAlpha', {'alpha': alpha});
  }

  // callbacks ----------------------------------------------------------------
  void _onMotionEvent(dynamic message) {
    for (StreamController<MotionData> controller
        in _motionEventsStreamController) {
      controller.add(MotionData(scroll: message['scroll']));
    }
  }

  void _onMotionEventError(dynamic error) {
    for (StreamController<MotionData> controller
        in _motionEventsStreamController) {
      controller.addError(error);
    }
  }

  void _onKeyEvent(dynamic message) {
    if (_keyEventsStreamController != null) {
      _keyEventsStreamController!
          .add(KeyData(keyCode: message['keyCode'], down: message['down']));
    }
  }

  void _onKeyEventError(dynamic error) {
    if (_keyEventsStreamController != null) {
      _keyEventsStreamController!.addError(error);
    }
  }

  void _onLifecycleEvent(dynamic message) {
    if (_lifecycleEventsStreamController != null) {
      _lifecycleEventsStreamController!.add(message['action']);
    }
  }

  void _onLifecycleEventError(dynamic error) {
    if (_lifecycleEventsStreamController != null) {
      _lifecycleEventsStreamController!.addError(error);
    }
  }
}

class MotionData {
  // amount of scrolling, taken from AXIS_SCROLL
  final double? scroll;

  MotionData({this.scroll});
}

class KeyData {
  static const int KEYCODE_BACK = 4;
  static const int KEYCODE_TEMP_PRIMARY = 264;

  final int keyCode;
  final bool down;

  KeyData({required this.keyCode, required this.down});
}
