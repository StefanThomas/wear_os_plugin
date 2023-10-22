import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      /// handling the BACK button properly on Wear OS 4:
      WearOsPlugin.instance.keyEvents?.listen((event) {
        log('key event: key code = ${event.keyCode} ${event.down?'down':'up'}');
        /// on BACK, close the topmost view or the complete app:
        if (event.keyCode == KeyData.KEYCODE_BACK && event.down == false) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            SystemNavigator.pop();
          }
        }
      });
      return MyApp(
        appVersion: appVersion,
        deviceModel: deviceModel,
      );
    },
  ));
}

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WearOsClipper(
      child: Scaffold(
          backgroundColor: Colors.blue,
          body: Center(
              child: Text(
            'Close this view\n'
            'by using the\n'
            'BACK button\n'
            'on the side',
            textAlign: TextAlign.center,
          ))),
    );
  }
}

class MyApp extends StatefulWidget {
  final String? appVersion;
  final String? deviceModel;

  const MyApp({super.key, this.appVersion, this.deviceModel});

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
        child: Text(
          'Device:\n${widget.deviceModel}',
          textAlign: TextAlign.center,
        ),
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
        child: ElevatedButton(
            child: const Text('Second Screen'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SecondScreen()),
              );
            }),
      ),
    ));

    return WearOsScrollView(
      controller: scrollController,
      autoHide: true, // if set to false, it shows the scrollbar all the time
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
