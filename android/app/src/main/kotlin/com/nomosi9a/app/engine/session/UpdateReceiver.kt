package com.nomosi9a.app.engine.session

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import kotlin.concurrent.thread

/**
 * An app update kills our process without warning. Waking up right after it
 * lets [OrphanSweeper] unmute whatever the old process was muting.
 */
class UpdateReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_MY_PACKAGE_REPLACED) return
        val pending = goAsync()
        val app = context.applicationContext
        thread(name = "NoMosi9a-update-sweep") {
            try {
                OrphanSweeper.sweep(app)
            } finally {
                pending.finish()
            }
        }
    }
}
