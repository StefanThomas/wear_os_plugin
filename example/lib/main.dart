import 'package:flutter/material.dart';

import 'package:wear_os_plugin/wear_os_app.dart';
import 'package:wear_os_plugin/wear_os_clipper.dart';
import 'package:wear_os_plugin/wear_os_plugin.dart';
import 'package:wear_os_plugin/wear_os_scroll_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // get some useful data from plugin:
  String? appVersion = await WearOsPlugin.instance.getAppVersion();
  String? deviceModel = await WearOsPlugin.instance.getModel();

  // start the app:
  runApp(WearOsApp(
    screenBuilder: (context) {
      return MyApp(
        appVersion: appVersion,
        deviceModel: deviceModel,
      );
    },
  ));
}

class MyApp extends StatefulWidget {
  final String? appVersion;
  final String? deviceModel;

  const MyApp({super.key, required this.appVersion, required this.deviceModel});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  _buildList(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    List<Widget> items = [];

    // top with icon and intro text:
    items.add(SizedBox(
      height: screenHeight / 2,
      child: Center(
        child: Text('Device:\n${widget.deviceModel}', textAlign: TextAlign.center,),
      ),
    ));

    // fill list with 30 rows:
    for (int index = 1; index <= 30; index++) {
      items.add(Container(
          color: (index & 1 == 0)
              ? const Color(0xff404040)
              : const Color(0xff202020),
          height: 40,
          child: Center(child: Text('Row #$index'))));
    }

    // bottom space:
    items.add(SizedBox(
      height: screenHeight / 2,
      child: Center(
        child: Text('App: ${widget.appVersion}'),
      ),
    ));

    return WearOsScrollView(
      controller: scrollController,
      child: ListView(
        controller: scrollController,
        children: items,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WearOsClipper(
      child: Scaffold(backgroundColor: Colors.black, body: _buildList(context)),
    );
  }
}
