# wear_os_plugin
A Flutter plugin with basic Wear OS functionality, like scrollable view with rotary input or circular screen support

**Round Screen**
By default all apps are Fullscreen and this means rectangular. To have round shaped apps, the app needs to have transparent backgrounds. Round screens will be visible, when you swipe away an app like this:

<img src="https://github.com/StefanThomas/wear_os_plugin/blob/main/.doc/screenshot_round_screen.png" alt="Round Screen" style="zoom:50%;" />

Beside the general transparent behavior of the app, all widgets must be clipped which is handled automatically by the the `WearOsClipper` class.

The general information about the screen shape is handled by the `WearOsApp` class. It has static and listenable member value to hold the information about round shape etc. 

These values will be initialized by using the `WearOsApp` or by calling the static `init` method.



**Round Scrollbar**
The default scrollbars are rectangular, like the basic screen layout. 
The class `WearOsScrollbar` takes care of normal scrollbars for rectangular shaped watches:

<img src="https://github.com/StefanThomas/wear_os_plugin/blob/main/.doc/screenshot_rectangular_scrollbar.png" alt="Rectangular" style="zoom:50%;"/>
 and round watches:
<img src="https://github.com/StefanThomas/wear_os_plugin/blob/main/.doc/screenshot_round_scrollbar.png" alt="Round" style="zoom:50%;" />



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