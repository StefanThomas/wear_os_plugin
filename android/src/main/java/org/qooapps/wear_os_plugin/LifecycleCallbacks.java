package org.qooapps.wear_os_plugin;

import android.app.Activity;
import android.app.Application;
import android.os.Bundle;
import android.util.Log;
import android.view.Window;

import androidx.annotation.NonNull;

public class LifecycleCallbacks implements Application.ActivityLifecycleCallbacks {
    private WearOsPlugin mPlugin;

    LifecycleCallbacks(@NonNull WearOsPlugin plugin) {
        mPlugin = plugin;
    }

    public void onActivityCreated(Activity activity, Bundle bundle) {
        mPlugin.sendLifecycleEvent("created");
    }

    @Override
    public void onActivityStarted(Activity activity) {
        mPlugin.sendLifecycleEvent("started");
    }

    @Override
    public void onActivityResumed(Activity activity) {
        mPlugin.sendLifecycleEvent("resumed");
    }

    @Override
    public void onActivityPaused(Activity activity) {
        mPlugin.sendLifecycleEvent("paused");
    }

    @Override
    public void onActivityStopped(Activity activity) {
        mPlugin.sendLifecycleEvent("stopped");
    }

    @Override
    public void onActivitySaveInstanceState(Activity activity, Bundle bundle) {
        mPlugin.sendLifecycleEvent("saveInstanceState");
    }

    @Override
    public void onActivityDestroyed(Activity activity) {
        mPlugin.sendLifecycleEvent("destroyed");
    }
}
