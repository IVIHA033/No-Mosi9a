package com.nomosi9a.app.engine

import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

/** Quick settings tile: switch music removal on/off without leaving YouTube. */
class ToggleTileService : TileService() {

    private val listener: (EngineStatus.Snapshot) -> Unit = { refresh() }

    override fun onStartListening() {
        super.onStartListening()
        EngineStatus.addListener(listener)
    }

    override fun onStopListening() {
        EngineStatus.removeListener(listener)
        super.onStopListening()
    }

    override fun onClick() {
        super.onClick()
        if (EngineStatus.isActive) {
            EngineService.stop(this)
            return
        }
        val launch = { openProjection() }
        if (isLocked) unlockAndRun(launch) else launch()
    }

    private fun openProjection() {
        val intent = Intent(this, ProjectionActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (Build.VERSION.SDK_INT >= 34) {
            startActivityAndCollapse(
                PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE),
            )
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }

    private fun refresh() {
        val tile = qsTile ?: return
        tile.state = if (EngineStatus.isActive) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.updateTile()
    }
}
