package org.qooapps.wear_os_plugin;

import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.icu.util.LocaleData;
import android.icu.util.ULocale;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;

import androidx.annotation.NonNull;

import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import java.util.Timer;
import java.util.TimerTask;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * WearOsPlugin
 */
public class WearOsPlugin implements FlutterPlugin, ActivityAware, MethodCallHandler {
    static final String CHANNEL_METHOD = "wear_os_plugin/method";
    static final String CHANNEL_MOTION_EVENTS = "wear_os_plugin/motionEvents";
    static final String CHANNEL_KEY_EVENTS = "wear_os_plugin/keyEvents";
    static final String CHANNEL_LIFECYCLE_EVENTS = "wear_os_plugin/lifecycleEvents";

    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private Context mContext;
    private MethodChannel channel;
    private EventChannel.EventSink mMotionEventsSink;
    private EventChannel.EventSink mKeyEventsSink;
    private EventChannel.EventSink mLifecycleEventsSink;
    private final Handler mHandler = new Handler();
    private Window mWindow = null;
    private View mMainView = null;

    private float mBrightnessOriginal = -1;
    private Timer mBrightnessTimeout = null;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        mContext = flutterPluginBinding.getApplicationContext();
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL_METHOD);
        channel.setMethodCallHandler(this);

        new EventChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL_MOTION_EVENTS).setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object o, EventChannel.EventSink eventSink) {
                mMotionEventsSink = eventSink;
            }

            @Override
            public void onCancel(Object o) {
                mMotionEventsSink = null;
            }
        });

        new EventChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL_KEY_EVENTS).setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object o, EventChannel.EventSink eventSink) {
                mKeyEventsSink = eventSink;
            }

            @Override
            public void onCancel(Object o) {
                mKeyEventsSink = null;
            }
        });

        new EventChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL_LIFECYCLE_EVENTS).setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object o, EventChannel.EventSink eventSink) {
                mLifecycleEventsSink = eventSink;
            }

            @Override
            public void onCancel(Object o) {
                mLifecycleEventsSink = null;
            }
        });
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        mContext = null;
    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        Activity activity = binding.getActivity();
        // get all lifecycle events:
        activity.registerActivityLifecycleCallbacks(new LifecycleCallbacks(this));
        // using transparent background so the round screen will be seen:
        activity.getIntent().putExtra("background_mode", "transparent");
        // set motion (means rotary) event listener for main view:
        mWindow = activity.getWindow();
        if (mWindow != null) {
            mMainView = mWindow.findViewById(android.R.id.content);
            // get all motion and key events:
            mWindow.setCallback(new WindowCallbacks(mWindow.getCallback(), this));
        }
    }

    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    }

    @Override
    public void onDetachedFromActivity() {
        // restore brightness:
        if (mBrightnessTimeout!=null) {
            mBrightnessTimeout.cancel();
            mBrightnessTimeout = null;
            WindowManager.LayoutParams params = mWindow.getAttributes();
            params.screenBrightness = mBrightnessOriginal;
            mWindow.setAttributes(params);
        }

        mMainView = null;
        mWindow = null;
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method != null ? call.method : "") {
            case "getPlatformSDK" -> {
                result.success(Build.VERSION.SDK_INT);
            }
            case "getManufacturer" -> {
                result.success(Build.MANUFACTURER);
            }
            case "getModel" -> {
                result.success(Build.MODEL);
            }
            case "getAppVersion" -> {
                try {
                    PackageInfo pInfo = mContext.getPackageManager().getPackageInfo(mContext.getPackageName(), 0);
                    result.success(pInfo.versionName);
                } catch (PackageManager.NameNotFoundException e) {
                    result.success(null);
                }
            }
            case "isScreenRound" -> {
                Configuration c = mContext.getResources().getConfiguration();
                result.success(c.isScreenRound());
            }
            case "getMeasurementSystem" -> {
                ULocale current = ULocale.getDefault();
                if (LocaleData.getMeasurementSystem(current) == LocaleData.MeasurementSystem.US) {
                    result.success("US");
                } else if (LocaleData.getMeasurementSystem(current) == LocaleData.MeasurementSystem.UK) {
                    result.success("UK");
                }
                result.success("SI");
            }
            case "vibrate" -> {
                Integer duration = call.argument("duration");
                Integer amplitude = call.argument("amplitude");
                String effect = call.argument("effect");
                Vibrator v = (Vibrator) mContext.getSystemService(Context.VIBRATOR_SERVICE);
                switch (Objects.requireNonNull(effect)) {
                    case "click" -> {
                        v.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK));
                    }
                    case "tick" ->
                            v.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_TICK));
                    case "double_click" ->
                            v.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_DOUBLE_CLICK));
                    case "heavy_click" ->
                            v.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_HEAVY_CLICK));
                    case "tap" -> v.vibrate(VibrationEffect.createOneShot(50, 100));
                    default -> v.vibrate(VibrationEffect.createOneShot(duration!=null ? duration : 100, amplitude!=null ? amplitude : 100));
                }
                result.success(null);
            }
            case "setAppAlpha" -> {
                if (mMainView != null) {
                    Double alpha = call.argument("alpha");
                    mMainView.setAlpha(alpha != null ? alpha.floatValue() : 1.0f);
                }
                result.success(null);
            }
            case "setKeepScreenOn" -> {
                if (mWindow != null) {
                    Boolean keepScreenOn = call.argument("keepScreenOn");
                    if (keepScreenOn != null && keepScreenOn) {
                        mWindow.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
                    } else {
                        mWindow.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
                    }
                }
                result.success(null);
            }
            case "setScreenBrightness" -> {
                if (mWindow != null) {
                    Double brightness = call.argument("brightness");
                    Integer timeoutInMillis = call.argument("timeout");
                    WindowManager.LayoutParams params = mWindow.getAttributes();

                    if (mBrightnessTimeout!=null) {
                        mBrightnessTimeout.cancel();
                        mBrightnessTimeout = null;
                    } else {
                        mBrightnessOriginal = params.screenBrightness;
                    }

                    if (timeoutInMillis!=null && timeoutInMillis>0) {
                        mBrightnessTimeout = new Timer();
                        mBrightnessTimeout.schedule(new TimerTask(){
                            @Override
                            public void run(){
                                runOnMainThread(() -> {
                                    WindowManager.LayoutParams params = mWindow.getAttributes();
                                    params.screenBrightness = mBrightnessOriginal;
                                    mWindow.setAttributes(params);
                                    mBrightnessTimeout = null;
                                });
                            }
                        },timeoutInMillis);
                    }

                    params.screenBrightness = brightness != null ? brightness.floatValue() : -1;
                    mWindow.setAttributes(params);
                }
            }
            default -> result.notImplemented();
        }
    }

    // start runnable in main thread:
    private void runOnMainThread(Runnable runnable) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            runnable.run();
        } else {
            mHandler.post(runnable);
        }
    }

    public void sendGenericMotionEvent(MotionEvent event) {
        if (mMotionEventsSink != null) {
            Map<String, Object> msg = new HashMap<>(1);
            msg.put("scroll", event.getAxisValue(MotionEvent.AXIS_SCROLL));
            runOnMainThread(() -> mMotionEventsSink.success(msg));
        }
    }

    public void sendKeyEvent(KeyEvent event) {
        if (mKeyEventsSink != null) {
            Map<String, Object> msg = new HashMap<>(2);
            msg.put("keyCode", event.getKeyCode());
            msg.put("down", event.getAction() == KeyEvent.ACTION_DOWN);
            runOnMainThread(() -> mKeyEventsSink.success(msg));
        }
    }

    public void sendLifecycleEvent(String action) {
        if (mLifecycleEventsSink != null) {
            Map<String, Object> msg = new HashMap<>(1);
            msg.put("action", action);
            runOnMainThread(() -> mLifecycleEventsSink.success(msg));
        }
    }
}
