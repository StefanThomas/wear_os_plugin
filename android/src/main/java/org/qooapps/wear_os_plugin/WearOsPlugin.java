package org.qooapps.wear_os_plugin;

import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.view.MotionEvent;
import android.view.View;

import androidx.annotation.NonNull;

import java.util.HashMap;
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
    static final String CHANNEL_EVENT = "wear_os_plugin/event";

    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private Context mContext;
    private MethodChannel channel;
    private static EventChannel.EventSink mEventSink;
    private static final Handler mHandler = new Handler();

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        mContext = flutterPluginBinding.getApplicationContext();
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL_METHOD);
        channel.setMethodCallHandler(this);

        new EventChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL_EVENT).setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object o, EventChannel.EventSink eventSink) {
                mEventSink = eventSink;
            }

            @Override
            public void onCancel(Object o) {
                mEventSink = null;
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
        // using transparent background so the round screen will be seen:
        activity.getIntent().putExtra("background_mode", "transparent");

        Configuration c = activity.getResources().getConfiguration();
        result.success(c.isScreenRound());

        // set motion (means rotary) event listener for main view:
        if (activity.getWindow() != null) {
            View mainView = activity.getWindow().findViewById(android.R.id.content);
            if (mainView == null) mainView = activity.getWindow().getDecorView();
            if (mainView.getRootView() != null) mainView = mainView.getRootView();

            if (mainView != null) {
                // mainView.setAlpha(0.5f);
                mainView.setOnGenericMotionListener((view, motionEvent) -> {
                    return WearOsPlugin.onGenericMotionEvent(motionEvent);
                });
            }
        }
    }

    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    }

    @Override
    public void onDetachedFromActivity() {
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
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    Configuration c = mContext.getResources().getConfiguration();
                    result.success(c.isScreenRound());
                } else {
                    result.success(null);
                }
            }
            break;
            case "vibrate": {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    int duration = call.argument("duration");
                    int amplitude = call.argument("amplitude");
                    String effect = call.argument("effect");
                    Vibrator v = (Vibrator) mContext.getSystemService(Context.VIBRATOR_SERVICE);
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
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
                    } else {
                        switch (Objects.requireNonNull(effect)) {
                            case "double_click":
                            case "heavy_click":
                            case "tick":
                            case "click": {
                                v.vibrate(VibrationEffect.createOneShot(20, 50));
                            }
                            break;
                            default:
                                v.vibrate(VibrationEffect.createOneShot(duration, amplitude));
                                break;
                        }

                    }
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
    private static void runOnMainThread(Runnable runnable) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            runnable.run();
        } else {
            mHandler.post(runnable);
        }
    }

    public static boolean onGenericMotionEvent(MotionEvent event) {
        if (mEventSink != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Map<String, Object> msg = new HashMap<>(1);
                msg.put("scroll", event.getAxisValue(MotionEvent.AXIS_SCROLL));
                runOnMainThread(() -> mEventSink.success(msg));
                return true;
            }
        }
        return false;
    }
}
