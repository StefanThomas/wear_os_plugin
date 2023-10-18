import 'package:flutter/material.dart';

import 'wear_os_app.dart';
import 'wear_os_plugin.dart';

/// the wrapper that clips the widget according the isRound value in the [WearOsApp]
class WearOsClipper extends StatelessWidget {
  final Widget child;

  const WearOsClipper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
        clipBehavior: WearOsPlugin.screenRound == true
            ? Clip.antiAliasWithSaveLayer
            : Clip.none,
        child: child);
  }
}
