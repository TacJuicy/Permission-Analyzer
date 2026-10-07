
//1st itration of risk caculation
package com.example.safe_box

import android.app.AppOpsManager
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.drawable.BitmapDrawable
import android.util.Base64
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream

class AppInfoHelper(private val context: Context) {

    private fun isSystemApp(app: android.content.pm.ApplicationInfo): Boolean {
        return (app.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
    }

    private fun isLaunchableApp(pm: PackageManager, packageName: String): Boolean {
        val launchIntent = pm.getLaunchIntentForPackage(packageName)
        return launchIntent != null
    }


    fun getInstalledAppsWithPermissions(): String {
        val packageManager = context.packageManager
        val installedApps = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)

        val appsArray = JSONArray()

        for (app in installedApps) {

//<<<<<<< HEAD
////            if ((app.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0) {
////                continue
////            }
//            if (isSystemApp(app) || !isLaunchableApp(packageManager, app.packageName)) {
//=======
            if ((app.flags and ApplicationInfo.FLAG_SYSTEM) != 0) {
//>>>>>>> origin/home_screen
                continue
            }

            val permissions = getAppPermissions(packageManager, app.packageName)
            val riskScore = calculateRiskScore(packageManager, app, permissions)

            val appObject = JSONObject()
            appObject.put("appName", app.loadLabel(packageManager).toString())
            appObject.put("packageName", app.packageName)
            appObject.put("permissions", JSONArray(permissions))
            appObject.put("riskScore", riskScore)
            appObject.put("icon", getAppIconBase64(packageManager, app.packageName))

            appsArray.put(appObject)
        }

        return appsArray.toString()
    }

    private fun getAppPermissions(packageManager: PackageManager, packageName: String): List<String> {
        return try {
            val packageInfo: PackageInfo = packageManager.getPackageInfo(packageName, PackageManager.GET_PERMISSIONS)
            packageInfo.requestedPermissions?.toList() ?: emptyList()
        } catch (e: PackageManager.NameNotFoundException) {
            emptyList()
        }
    }

    private fun getAppIconBase64(packageManager: PackageManager, packageName: String): String {
        return try {
            val drawable = packageManager.getApplicationIcon(packageName)
            val bitmap = if (drawable is BitmapDrawable) {
                drawable.bitmap.copy(Bitmap.Config.ARGB_8888, true)
            } else {
                val bitmap = Bitmap.createBitmap(
                    drawable.intrinsicWidth,
                    drawable.intrinsicHeight,
                    Bitmap.Config.ARGB_8888
                )
                val canvas = android.graphics.Canvas(bitmap)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
                bitmap
            }


            val outputStream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
            val byteArray = outputStream.toByteArray()
            Base64.encodeToString(byteArray, Base64.NO_WRAP)
        } catch (e: Exception) {
            ""
        }
    }

    private fun calculateRiskScore(
        packageManager: PackageManager,
        appInfo: ApplicationInfo,
        permissions: List<String>
    ): Int {
        val dangerousPermissions = listOf(
            "android.permission.READ_CONTACTS",
            "android.permission.ACCESS_FINE_LOCATION",
            "android.permission.RECORD_AUDIO",
            "android.permission.CAMERA",
            "android.permission.SEND_SMS",
            "android.permission.READ_SMS",
            "android.permission.READ_PHONE_STATE",
            "android.permission.WRITE_EXTERNAL_STORAGE"
        )

        var score = 0

        // 1. Internet permission
        if (permissions.contains("android.permission.INTERNET")) {
            score += 15
        }

        // 2. Number of permissions
        score += permissions.size * 2

        // 3. Dangerous permissions count
        val dangerousCount = permissions.count { it in dangerousPermissions }
        score += dangerousCount * 10

        // 4. Obscure developer/package name
        if (!appInfo.packageName.startsWith("com.") && !appInfo.packageName.startsWith("org.")) {
            score += 10
        }

        // 5. System vs User app
        if ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) == 0) {
            score += 5
        }

        return score
    }
}


