package com.example.world_of_iot

import android.accessibilityservice.AccessibilityService
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/**
 * Android Accessibility Service for ClipSync.
 *
 * Provides real-time background clipboard detection across third-party apps:
 * 1. Tracks text selection ranges to capture candidate text before copy commands
 * 2. Hooks system OnPrimaryClipChangedListener
 * 3. Catches Copy actions in context menus and toolbars
 * 4. Dispatches text directly to Flutter via MethodChannel bridge
 */
class ClipSyncAccessibilityService : AccessibilityService() {

    companion object {
        var instance: ClipSyncAccessibilityService? = null
        var lastSyncedText: String? = null
        var lastCapturedSelection: String? = null
        var onClipboardChangedListener: ((String) -> Unit)? = null

        fun isRunning(): Boolean = instance != null

        fun notifyTextCopied(text: String) {
            val clean = text.trim()
            if (clean.isNotEmpty() && clean != lastSyncedText) {
                lastSyncedText = clean
                onClipboardChangedListener?.invoke(clean)
            }
        }
    }

    private var clipboardManager: ClipboardManager? = null
    private val clipListener = ClipboardManager.OnPrimaryClipChangedListener {
        checkAndNotifyClipboard()
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        initClipboardManager()
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        initClipboardManager()
    }

    private fun initClipboardManager() {
        try {
            if (clipboardManager == null) {
                clipboardManager = getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
            }
            clipboardManager?.removePrimaryClipChangedListener(clipListener)
            clipboardManager?.addPrimaryClipChangedListener(clipListener)
        } catch (_: Exception) {}
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        when (event.eventType) {
            AccessibilityEvent.TYPE_VIEW_TEXT_SELECTION_CHANGED -> {
                val source = event.source
                if (source != null) {
                    try {
                        val start = source.textSelectionStart
                        val end = source.textSelectionEnd
                        val fullText = source.text
                        if (fullText != null && start >= 0 && end > start && end <= fullText.length) {
                            val selected = fullText.subSequence(start, end).toString().trim()
                            if (selected.isNotEmpty()) {
                                lastCapturedSelection = selected
                            }
                        }
                    } catch (_: Exception) {
                    } finally {
                        source.recycle()
                    }
                }
            }

            AccessibilityEvent.TYPE_VIEW_CLICKED -> {
                val source = event.source
                if (source != null) {
                    try {
                        val text = source.text?.toString() ?: ""
                        val desc = source.contentDescription?.toString() ?: ""
                        val isCopy = text.contains("Copy", ignoreCase = true) ||
                                     desc.contains("Copy", ignoreCase = true) ||
                                     text.contains("copy", ignoreCase = true)
                        if (isCopy) {
                            val candidate = lastCapturedSelection
                            if (!candidate.isNullOrEmpty()) {
                                notifyTextCopied(candidate)
                            } else {
                                checkAndNotifyClipboard()
                            }
                        }
                    } catch (_: Exception) {
                    } finally {
                        source.recycle()
                    }
                }
            }

            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
            AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED -> {
                checkAndNotifyClipboard()
            }
        }
    }

    private fun checkAndNotifyClipboard() {
        try {
            val clip = clipboardManager?.primaryClip
            if (clip != null && clip.itemCount > 0) {
                val text = clip.getItemAt(0)?.coerceToText(this)?.toString()?.trim()
                if (!text.isNullOrEmpty()) {
                    notifyTextCopied(text)
                    return
                }
            }
        } catch (_: Exception) {}

        // Fallback to last captured selection if primaryClip is guarded by Samsung background rules
        val candidate = lastCapturedSelection
        if (!candidate.isNullOrEmpty() && candidate != lastSyncedText) {
            notifyTextCopied(candidate)
        }
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
