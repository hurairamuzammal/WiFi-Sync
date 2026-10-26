package com.example.world_of_iot

import android.content.BroadcastReceiver
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.widget.Toast

/**
 * Handles quick "Send to Laptop" notification action.
 * Allows instantaneous user-initiated clipboard dispatch on Android 10+
 * directly from the system notification bar without opening the app window.
 */
class ClipSyncActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_SYNC_CLIPBOARD) {
            val cm = context.getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
            val clip = cm?.primaryClip
            if (clip != null && clip.itemCount > 0) {
                val text = clip.getItemAt(0)?.coerceToText(context)?.toString()?.trim()
                if (!text.isNullOrEmpty()) {
                    ClipSyncAccessibilityService.notifyTextCopied(text)
                    Handler(Looper.getMainLooper()).post {
                        Toast.makeText(context, "ClipSync: Sent to laptop", Toast.LENGTH_SHORT).show()
                    }
                } else {
                    Handler(Looper.getMainLooper()).post {
                        Toast.makeText(context, "ClipSync: Clipboard is empty", Toast.LENGTH_SHORT).show()
                    }
                }
            } else {
                Handler(Looper.getMainLooper()).post {
                    Toast.makeText(context, "ClipSync: Clipboard is empty", Toast.LENGTH_SHORT).show()
                }
            }
        }
    }

    companion object {
        const val ACTION_SYNC_CLIPBOARD = "com.example.world_of_iot.ACTION_SYNC_CLIPBOARD"
    }
}
