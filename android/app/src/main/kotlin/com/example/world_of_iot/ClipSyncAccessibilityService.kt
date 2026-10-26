package com.example.world_of_iot

import android.accessibilityservice.AccessibilityService
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.view.accessibility.AccessibilityEvent

/**
 * Android Accessibility Service for ClipSync.
 *
 * Exemption from Android 10+ background clipboard restrictions:
 * Allows detecting clipboard copy events instantly across all third-party apps
 * without requiring the ClipSync app to be focused or in foreground.
 */
class ClipSyncAccessibilityService : AccessibilityService() {

    companion object {
        var instance: ClipSyncAccessibilityService? = null
        var lastSyncedText: String? = null
        var onClipboardChangedListener: ((String) -> Unit)? = null

        fun isRunning(): Boolean = instance != null
    }

    private var clipboardManager: ClipboardManager? = null
    private val clipListener = ClipboardManager.OnPrimaryClipChangedListener {
        checkAndNotifyClipboard()
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        clipboardManager = getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
        try {
            clipboardManager?.addPrimaryClipChangedListener(clipListener)
        } catch (_: Exception) {}
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        when (event.eventType) {
            AccessibilityEvent.TYPE_VIEW_TEXT_SELECTION_CHANGED,
            AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED,
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                checkAndNotifyClipboard()
            }
        }
    }

    private fun checkAndNotifyClipboard() {
        try {
            val clip = clipboardManager?.primaryClip
            if (clip != null && clip.itemCount > 0) {
                val text = clip.getItemAt(0)?.coerceToText(this)?.toString()?.trim()
                if (!text.isNullOrEmpty() && text != lastSyncedText) {
                    lastSyncedText = text
                    onClipboardChangedListener?.invoke(text)
                }
            }
        } catch (_: Exception) {}
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        try {
            clipboardManager?.removePrimaryClipChangedListener(clipListener)
        } catch (_: Exception) {}
        instance = null
        super.onDestroy()
    }
}
