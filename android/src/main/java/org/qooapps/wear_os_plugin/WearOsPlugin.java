package org.qooapps.wear_os_plugin;

import static android.window.OnBackInvokedDispatcher.PRIORITY_OVERLAY;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.icu.util.LocaleData;
import android.icu.util.ULocale;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.util.Log;
import android.view.ActionMode;
import android.view.KeyEvent;
import android.view.Menu;
import android.view.MenuItem;
import android.view.MotionEvent;
import android.view.SearchEvent;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.view.accessibility.AccessibilityEvent;
import android.window.OnBackInvokedCallback;

import androidx.annotation.NonNull;

import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;

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
    private View mMainView = null;

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

    @SuppressLint("NewApi")
    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        Activity activity = binding.getActivity();
        // get all lifecycle events:
        activity.registerActivityLifecycleCallbacks(new LifecycleCallbacks(this));
        // using transparent background so the round screen will be seen:
        activity.getIntent().putExtra("background_mode", "transparent");
        // set motion (means rotary) event listener for main view:
        Window window = activity.getWindow();
        if (window != null) {
            View mainView = window.findViewById(android.R.id.content);
            // if (mainView == null) mainView = window.getDecorView();
            // if (mainView.getRootView() != null) mainView = mainView.getRootView();

            mMainView = mainView;
            /*
            
            final WearOsPlugin plugin = this;
            if (mainView != null) {
                // mainView.setAlpha(0.5f);
                mainView.setOnGenericMotionListener((v, motionEvent) -> {
                    Log.i("EVENT", "motionEvent");
                    plugin.sendGenericMotionEvent(motionEvent);
                    return true;
                });
                mainView.setOnKeyListener(new View.OnKeyListener() {
                    @Override
                    public boolean onKey(View view, int i, KeyEvent keyEvent) {
                        Log.i("EVENT", "keyEvent");
                        return false;
                    }
                });
            }
            */

            // get all motion and key events:
            window.setCallback(new WindowCallbacks(window.getCallback(), this));
        }
    }

    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    }

    @Override
    public void onDetachedFromActivity() {
        mMainView = null;
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "getPlatformSDK": {
                result.success(Build.VERSION.SDK_INT);
            }
            break;
            case "getManufacturer": {
                result.success(Build.MANUFACTURER);
            }
            break;
            case "getModel": {
                result.success(Build.MODEL);
            }
            break;
            case "getAppVersion": {
                try {
                    PackageInfo pInfo = mContext.getPackageManager().getPackageInfo(mContext.getPackageName(), 0);
                    result.success(pInfo.versionName);
                } catch (PackageManager.NameNotFoundException e) {
                    result.success(null);
                }
            }
            break;
            case "isScreenRound": {
                Configuration c = mContext.getResources().getConfiguration();
                result.success(c.isScreenRound());
            }
            break;
            case "getMeasurementSystem": {
                ULocale current = ULocale.getDefault();
                if (LocaleData.getMeasurementSystem(current) == LocaleData.MeasurementSystem.US) {
                    result.success("US");
                } else if (LocaleData.getMeasurementSystem(current) == LocaleData.MeasurementSystem.UK) {
                    result.success("UK");
                }
                result.success("SI");
            }
            break;
            case "vibrate": {
                int duration = call.argument("duration");
                int amplitude = call.argument("amplitude");
                String effect = call.argument("effect");
                Vibrator v = (Vibrator) mContext.getSystemService(Context.VIBRATOR_SERVICE);
                switch (Objects.requireNonNull(effect)) {
                    case "click": {
                        v.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK));
                    }
                    break;
                    case "tick":
                        v.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_TICK));
                        break;
                    case "double_click":
                        v.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_DOUBLE_CLICK));
                        break;
                    case "heavy_click":
                        v.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_HEAVY_CLICK));
                        break;
                    default:
                        v.vibrate(VibrationEffect.createOneShot(duration, amplitude));
                        break;
                }
                result.success(null);
            }
            break;
            case "setAppAlpha": {
                if (mMainView != null) {
                    double alpha = call.argument("alpha");
                    mMainView.setAlpha((float) alpha);
                }
                result.success(null);
            }
            break;
            default:
                result.notImplemented();
                break;
        }
    }

    /*
        private void sendSuccessMsgToEventChannel(Object msg) {
            if (mEventSink != null)
                runOnMainThread(() -> mEventSink.success(msg));
        }

        private void sendFailMsgToEventChannel(String errCode, String errMsg, Object errDetail) {
            if (mEventSink != null)
                runOnMainThread(() -> mEventSink.error(errCode, errMsg, errDetail));
        }
    */
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
