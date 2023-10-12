import 'package:flutter/material.dart';

import 'wear_os_plugin.dart';
import 'wear_os_clipper.dart';

/// [WearOsApp] is the main [StatelessWidget] that take care of the screen shapes.
class WearOsApp extends StatelessWidget {
  /// static listenable [ValueNotifier] for the info about the screen shape, initially null, elsewhere true or false
  static ValueNotifier<bool?> isRound = ValueNotifier(null);

  /// static listenable [ValueNotifier] for device model name, initially null
  static ValueNotifier<String?> model = ValueNotifier(null);

  /// static listenable [ValueNotifier] for the info, if the app is running on emulator and then have limited hardware capabilities and is maybe for debugging only
  static ValueNotifier<bool> isEmulator = ValueNotifier(false);

  /// static listenable [ValueNotifier] for app version name, initially null
  static ValueNotifier<String?> appVersion = ValueNotifier(null);

  /// static method to initialize global stuff, needs to be called only once per app lifetime
  static init() async {
    if (isRound.value == null) {
      WearOsPlugin.instance
          .isScreenRound()
          .then((value) => isRound.value = value);
    }
    if (model.value == null) {
      WearOsPlugin.instance.getModel().then((value) {
        model.value = value;
        isEmulator.value = (value ?? '')
            .startsWith('sdk_gwear'); // every emulator starts with this naming
      });
    }
    if (appVersion.value == null) {
      WearOsPlugin.instance
          .getAppVersion()
          .then((value) => appVersion.value = value);
    }
  }

  /// called before the main widget is starting to be build
  final Function(BuildContext context)? onStarted;

  /// called to create the main widget
  final Function(BuildContext context)? screenBuilder;

  /// the asset path for the Splash Icon, if null then a timer icon is shown
  final String? splashIcon;

  /// the background color for the Splash Screen
  final Color splashBackgroundColor;

  /// the duration for the Splash Screen
  final Duration splashDuration;

  WearOsApp(
      {super.key,
      this.screenBuilder,
      this.splashIcon,
      this.splashBackgroundColor = Colors.black,
      this.onStarted,
      this.splashDuration = const Duration(seconds: 1)}) {
    init();
  }

  _buildSplash(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return WearOsClipper(
        child: Container(
            color: splashBackgroundColor,
            child: Center(
                child: splashIcon != null
                    ? Image.asset(splashIcon!, width: w / 4)
                    : const Icon(Icons.timer, color: Colors.white))));
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        /// Wear OS apps should have dark background, regarding the guidelines
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: LayoutBuilder(
        builder: (BuildContext context, _) {
          // use this LayoutBuilder only as helper
          // to get correct BuildContext
          Future.delayed(splashDuration, () {
            if (onStarted != null) onStarted!(context);
            Navigator.pushReplacement(
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
