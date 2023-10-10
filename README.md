# wear_os_plugin
A Flutter plugin with basic Wear OS functionality, like scrollable view with rotary input or circular screen support

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