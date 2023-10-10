import 'package:flutter/material.dart';

import 'wear_os_plugin.dart';
import 'wear_os_clipper.dart';

class WearOsApp extends StatelessWidget {
  static ValueNotifier<bool?> isRound = ValueNotifier(null);
  static ValueNotifier<String?> model = ValueNotifier(null);
  static ValueNotifier<bool> isEmulator = ValueNotifier(false);
  static ValueNotifier<String?> appVersion = ValueNotifier(null);

  // init global stuff:
  static init() async {
    if (isRound.value == null) {
      WearOsPlugin.instance
          .isScreenRound()
          .then((value) => isRound.value = value);
    }
    if (model.value == null) {
      WearOsPlugin.instance.getModel().then((value) {
        model.value = value;
        isEmulator.value = (value ?? '').startsWith('sdk_gwear');
      });
    }
    if (appVersion.value == null) {
      WearOsPlugin.instance
          .getAppVersion()
          .then((value) => appVersion.value = value);
    }
  }

  final Function(BuildContext context)? onStarted;
  final Function(BuildContext context)? screenBuilder;
  final String? splashIcon;
  final Color splashBackgroundColor;
  final Duration splashDuration;

  WearOsApp(
      {super.key,
      this.screenBuilder,
      this.splashIcon,
      this.splashBackgroundColor = Colors.black,
      this.onStarted,
      this.splashDuration = const Duration(seconds: 1)});

  final ValueNotifier<int> notify = ValueNotifier(0);

  _buildSplash(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return WearOsClipper(
        child: Container(
            color: splashBackgroundColor,
            child: Center(
                child: splashIcon != null
                    ? Image.asset(splashIcon!, width: w / 4)
                    : null)));
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: AnimatedBuilder(
        animation: notify,
        builder: (BuildContext context, Widget? child) {
          Future.delayed(splashDuration, () {
            if (onStarted != null) onStarted!(context);
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    screenBuilder!(context),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
              ),
            );
          });
          return _buildSplash(context);
        },
      ),
    );
  }
}
