package com.nomosi9a.app.engine

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import com.nomosi9a.app.MainActivity
import com.nomosi9a.app.R
import com.nomosi9a.app.platform.Setup

/**
 * Invisible activity used by the quick settings tile: Android only hands out
 * capture consent to an activity. With the PROJECT_MEDIA app-op granted
 * during setup, the system approves instantly without showing a dialog.
 */
class ProjectionActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!Setup.isReady(this)) {
            Toast.makeText(this, R.string.toast_setup_needed, Toast.LENGTH_LONG).show()
            startActivity(Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            finish()
            return
        }
        // Recreated (e.g. rotation) while the consent is showing: wait for its result.
        if (savedInstanceState != null) return
        @Suppress("DEPRECATION")
        startActivityForResult(Setup.projectionIntent(this), REQUEST)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST) {
            if (resultCode == RESULT_OK && data != null) {
                EngineService.start(this, resultCode, data)
            } else {
                Toast.makeText(this, R.string.toast_projection_denied, Toast.LENGTH_SHORT).show()
            }
        }
        finish()
    }

    private companion object {
        const val REQUEST = 1
    }
}
