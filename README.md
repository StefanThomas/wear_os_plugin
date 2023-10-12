# wear_os_plugin
A Flutter plugin with basic Wear OS functionality, like scrollable view with rotary input or circular screen support

**Round Screen**
By default all apps are Fullscreen and this means rectangular. To have round shaped apps, the app needs to have transparent backgrounds. Round screens will be visible, when you swipe away an app like this:

<img src="https://www.qooapps.com/images/wear_os_plugin/screenshot_round_screen.png" alt="Round Screen" style="zoom:50%;" />

Beside the general transparent behavior of the app, all widgets must be clipped which is handled automatically by the the [`WearOsClipper`](https://pub.dev/documentation/wear_os_plugin/latest/wear_os_clipper/wear_os_clipper-library.html) class.

The general information about the screen shape is handled by the [`WearOsApp`](https://pub.dev/documentation/wear_os_plugin/latest/wear_os_app/wear_os_app-library.html) class. It has static and listenable member value to hold the information about round shape etc. 

These values will be initialized by using the [`WearOsApp`](https://pub.dev/documentation/wear_os_plugin/latest/wear_os_app/wear_os_app-library.html) or by calling the static `init` method.



**Round Scrollbar**
The default scrollbars are rectangular, like the basic screen layout. 

The class  [`WearOsScrollView`](https://pub.dev/documentation/wear_os_plugin/latest/wear_os_scroll_view/WearOsScrollView-class.html) takes care of scrollbars:

|                      rectangular watch                       |                         round watch                          |
| :----------------------------------------------------------: | :----------------------------------------------------------: |
| <img src="https://www.qooapps.com/images/wear_os_plugin/screenshot_rectangular_scrollbar.png" alt="Rectangular" style="zoom:50%;"/> | <img src="https://www.qooapps.com/images/wear_os_plugin/screenshot_round_scrollbar.png" alt="Round" style="zoom:50%;" /> |

## Getting Started

### Wear OS
Change the following in your Wear OS (Android) Project:

android/app/build.gradle:

`minSdkVersion 30`

android/app/src/main/AndroidManifest.xml:
```xml
	<application
	...>
        <meta-data
            android:name="com.google.android.wearable.standalone"
            android:value="true" />
	...            
```
Maybe change the launch theme directly to the normal theme, to avoid the system splash screen:
```xml
	<application
		...
		android:theme="@style/LaunchTheme"
		->
		android:theme="@style/NormalTheme"
	...
```

Permission for Vibration and Watch Feature is already set.