import 'package:flutter/material.dart';

import 'wear_os_clipper.dart';

/// [WearOsApp] is the main [StatelessWidget] that take care of the screen shapes.
class WearOsApp extends StatelessWidget {
  /// called before the main widget is starting to be build
  final Function(BuildContext context)? onStarted;

  /// called to create the main widget
  final Function(BuildContext context) screenBuilder;

  /// the asset path for the Splash Icon, if null then a timer icon is shown
  final Widget? splashIconWidget;

  /// the asset path for the Splash Icon, if null then a timer icon is shown
  final String? splashIcon;

  /// the background color for the Splash Screen
  final Color splashBackgroundColor;

  /// the duration for the Splash Screen
  final Duration splashDuration;

  /// the App Theme
  final ThemeData? theme;

  WearOsApp(
      {super.key,
      required this.screenBuilder,
      this.splashIconWidget,
      this.splashIcon,
      this.splashBackgroundColor = Colors.black,
      this.onStarted,
      this.splashDuration = const Duration(seconds: 1),
      this.theme}) {
    //init();
  }

  _buildSplash(BuildContext context) {
    // final w = MediaQuery.of(context).size.width;
    return WearOsClipper(
        child: Container(
            color: splashBackgroundColor,
            child: Center(
                child: splashIconWidget ??
                    (splashIcon != null
                        ? Image.asset(splashIcon!, width: 48) // icon with 48dp
                        : const Icon(Icons.timer, color: Colors.white)))));
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme ??
          ThemeData(
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
                    screenBuilder(context),
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
