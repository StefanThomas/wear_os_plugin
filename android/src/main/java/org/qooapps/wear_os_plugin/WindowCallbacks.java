package org.qooapps.wear_os_plugin;

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

import androidx.annotation.NonNull;

public class WindowCallbacks implements Window.Callback {
    private WearOsPlugin mPlugin;
    private Window.Callback mSystemCallback;

    WindowCallbacks(@NonNull Window.Callback systemCallback, @NonNull WearOsPlugin plugin) {
        mPlugin = plugin;
        mSystemCallback = systemCallback;
    }

    @Override
    public boolean dispatchKeyEvent(KeyEvent keyEvent) {
        mPlugin.sendKeyEvent(keyEvent);
        if (keyEvent.getKeyCode() == KeyEvent.KEYCODE_BACK
                || keyEvent.getKeyCode() == KeyEvent.KEYCODE_STEM_PRIMARY) {
            // prevent BACK or PRIMARY STEM key from using in Wear OS
            return true;
        }
        return mSystemCallback.dispatchKeyEvent(keyEvent);
    }

    @Override
    public boolean dispatchKeyShortcutEvent(KeyEvent keyEvent) {
        return mSystemCallback.dispatchKeyShortcutEvent(keyEvent);
    }

    @Override
    public boolean dispatchTouchEvent(MotionEvent motionEvent) {
        return mSystemCallback.dispatchTouchEvent(motionEvent);
    }

    @Override
    public boolean dispatchTrackballEvent(MotionEvent motionEvent) {
        return mSystemCallback.dispatchTrackballEvent(motionEvent);
    }

    @Override
    public boolean dispatchGenericMotionEvent(MotionEvent motionEvent) {
        mPlugin.sendGenericMotionEvent(motionEvent);
        return mSystemCallback.dispatchGenericMotionEvent(motionEvent);
    }

    @Override
    public boolean dispatchPopulateAccessibilityEvent(AccessibilityEvent accessibilityEvent) {
        return mSystemCallback.dispatchPopulateAccessibilityEvent(accessibilityEvent);
    }

    @Override
    public View onCreatePanelView(int i) {
        return mSystemCallback.onCreatePanelView(i);
    }

    @Override
    public boolean onCreatePanelMenu(int i, Menu menu) {
        return mSystemCallback.onCreatePanelMenu(i, menu);
    }

    @Override
    public boolean onPreparePanel(int i, View view, Menu menu) {
        return mSystemCallback.onPreparePanel(i, view, menu);
    }

    @Override
    public boolean onMenuOpened(int i, Menu menu) {
        return mSystemCallback.onMenuOpened(i, menu);
    }

    @Override
    public boolean onMenuItemSelected(int i, MenuItem menuItem) {
        return mSystemCallback.onMenuItemSelected(i, menuItem);
    }

    @Override
    public void onWindowAttributesChanged(WindowManager.LayoutParams layoutParams) {
        mSystemCallback.onWindowAttributesChanged(layoutParams);
    }

    @Override
    public void onContentChanged() {
        mSystemCallback.onContentChanged();
    }

    @Override
    public void onWindowFocusChanged(boolean b) {
        mSystemCallback.onWindowFocusChanged(b);
    }

    @Override
    public void onAttachedToWindow() {
        mSystemCallback.onAttachedToWindow();
    }

    @Override
    public void onDetachedFromWindow() {
        mSystemCallback.onDetachedFromWindow();
    }

    @Override
    public void onPanelClosed(int i, Menu menu) {
        mSystemCallback.onPanelClosed(i, menu);
    }

    @Override
    public boolean onSearchRequested() {
        return mSystemCallback.onSearchRequested();
    }

    @Override
    public boolean onSearchRequested(SearchEvent searchEvent) {
        return mSystemCallback.onSearchRequested(searchEvent);
    }

    @Override
    public ActionMode onWindowStartingActionMode(ActionMode.Callback callback) {
        return mSystemCallback.onWindowStartingActionMode(callback);
    }

    @Override
    public ActionMode onWindowStartingActionMode(ActionMode.Callback callback, int i) {
        return mSystemCallback.onWindowStartingActionMode(callback, i);
    }

    @Override
    public void onActionModeStarted(ActionMode actionMode) {
        mSystemCallback.onActionModeStarted(actionMode);
    }

    @Override
    public void onActionModeFinished(ActionMode actionMode) {
        mSystemCallback.onActionModeFinished(actionMode);
    }
}
