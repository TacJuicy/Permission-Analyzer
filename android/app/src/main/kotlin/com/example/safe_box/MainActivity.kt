import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Bundle
import android.util.Base64
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app_info_channel"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    try {
                        val appInfoHelper = AppInfoHelper(this)
                        val appsData = appInfoHelper.getInstalledAppsWithPermissions()
                        result.success(appsData)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error fetching installed apps: ${e.message}", e)
                        result.error("APP_INFO_ERROR", "Failed to retrieve installed apps", e.message)
                    }
                }

                "getAppPermissions" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        try {
                            val appPermissions = getAppPermissions(packageName)
                            result.success(appPermissions)
                        } catch (e: Exception) {
                            Log.e("MainActivity", "Error fetching permissions for $packageName: ${e.message}", e)
                            result.error("APP_PERMISSION_ERROR", "Failed to retrieve permissions for $packageName", e.message)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is missing", null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    // This function returns the Base64 encoded app icon
    private fun getAppIconBase64(packageManager: PackageManager, packageName: String): String {
        return try {
            val drawable = packageManager.getApplicationIcon(packageName)
            val bitmap = if (drawable is BitmapDrawable) {
                drawable.bitmap
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
            Log.e("AppInfo", "Error getting app icon: ${e.message}")
            ""  // return empty string if there's an error
        }
    }

    // This is where you gather the list of installed apps, including their icon in Base64 format
    private fun getInstalledAppsWithPermissions(): List<Map<String, Any>> {
        val packageManager = applicationContext.packageManager
        val appsList = mutableListOf<Map<String, Any>>()

        val packages = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
        for (packageInfo in packages) {
            val appName = packageManager.getApplicationLabel(packageInfo).toString()
            val packageName = packageInfo.packageName
            val iconBase64 = getAppIconBase64(packageManager, packageName)

            // Add more app data as needed
            val appData = mapOf(
                "appName" to appName,
                "packageName" to packageName,
                "icon" to iconBase64
            )
            appsList.add(appData)
        }
        return appsList
    }

    private fun getAppPermissions(packageName: String): List<String> {
        val packageManager = applicationContext.packageManager
        return try {
            val packageInfo = packageManager.getPackageInfo(packageName, PackageManager.GET_PERMISSIONS)
            packageInfo.requestedPermissions?.toList() ?: emptyList()
        } catch (e: PackageManager.NameNotFoundException) {
            emptyList()
        }
    }
}
