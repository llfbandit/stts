package com.llfbandit.stts.stt.permission

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener

fun interface SttPermissionResultCallback {
  fun onResult(granted: Boolean)
}

class SttPermissionManager : RequestPermissionsResultListener {
  private var resultCallback: SttPermissionResultCallback? = null
  private var activity: Activity? = null

  fun setActivity(activity: Activity?) {
    this.activity = activity
  }

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<String>,
    grantResults: IntArray
  ): Boolean {
    if (requestCode == RECORD_AUDIO_REQUEST_CODE && resultCallback != null) {
      val granted =
        grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
      resultCallback!!.onResult(granted)
      resultCallback = null
      return true
    }
    return false
  }

  fun hasPermission(resultCallback: SttPermissionResultCallback) {
    if (activity == null) {
      resultCallback.onResult(false)
      return
    }

    if (!isPermissionGranted(activity!!)) {
      this.resultCallback = resultCallback
      ActivityCompat.requestPermissions(
        activity!!, arrayOf(Manifest.permission.RECORD_AUDIO),
        RECORD_AUDIO_REQUEST_CODE
      )
    } else {
      resultCallback.onResult(true)
    }
  }

  private fun isPermissionGranted(activity: Activity): Boolean {
    val result = ActivityCompat.checkSelfPermission(activity, Manifest.permission.RECORD_AUDIO)
    return result == PackageManager.PERMISSION_GRANTED
  }

  companion object {
    private const val RECORD_AUDIO_REQUEST_CODE = 1001
  }
}