package com.example.zane_bible_lockscreen

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.WallpaperManager
import android.net.Uri
import java.io.File
import android.content.pm.PackageManager
import android.os.Build

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.zane_bible_lockscreen/wallpaper"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setWallpaper" -> {
                    val path = call.argument<String>("path")
                    val location = call.argument<String>("location") ?: "lockScreen"
                    
                    if (path != null) {
                        try {
                            val file = File(path)
                            if (!file.exists()) {
                                result.error("FILE_NOT_FOUND", "Wallpaper file not found: $path", null)
                                return@setMethodCallHandler
                            }
                            
                            val wallpaperManager = WallpaperManager.getInstance(this)
                            val fileInputStream = file.inputStream()
                            
                            try {
                                // Set wallpaper for lock screen
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                    when (location) {
                                        "lockScreen" -> wallpaperManager.setStream(fileInputStream, null, true, WallpaperManager.FLAG_LOCK)
                                        "homeScreen" -> wallpaperManager.setStream(fileInputStream, null, true, WallpaperManager.FLAG_SYSTEM)
                                        "both" -> wallpaperManager.setStream(fileInputStream)
                                        else -> wallpaperManager.setStream(fileInputStream, null, true, WallpaperManager.FLAG_LOCK)
                                    }
                                } else {
                                    @Suppress("DEPRECATION")
                                    wallpaperManager.setStream(fileInputStream)
                                }
                                
                                fileInputStream.close()
                                result.success(true)
                            } catch (e: Exception) {
                                fileInputStream.close()
                                result.error("WALLPAPER_ERROR", "Failed to set wallpaper: ${e.message}", e.printStackTrace().toString())
                            }
                        } catch (e: Exception) {
                            result.error("ERROR", "Error setting wallpaper: ${e.message}", e.printStackTrace().toString())
                        }
                    } else {
                        result.error("INVALID_ARGS", "Path argument is required", null)
                    }
                }
                
                "setWallpaperUri" -> {
                    val uri = call.argument<String>("uri")
                    
                    if (uri != null) {
                        try {
                            val wallpaperManager = WallpaperManager.getInstance(this)
                            val contentUri = Uri.parse(uri)
                            val inputStream = contentResolver.openInputStream(contentUri)
                            
                            if (inputStream != null) {
                                try {
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                        wallpaperManager.setStream(inputStream, null, true, WallpaperManager.FLAG_LOCK)
                                    } else {
                                        @Suppress("DEPRECATION")
                                        wallpaperManager.setStream(inputStream)
                                    }
                                    
                                    inputStream.close()
                                    result.success(true)
                                } catch (e: Exception) {
                                    inputStream.close()
                                    result.error("WALLPAPER_ERROR", "Failed to set wallpaper: ${e.message}", null)
                                }
                            } else {
                                result.error("STREAM_ERROR", "Failed to open input stream for URI", null)
                            }
                        } catch (e: Exception) {
                            result.error("ERROR", "Error setting wallpaper from URI: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "URI argument is required", null)
                    }
                }
                
                "hasWallpaperPermission" -> {
                    // Check if SET_WALLPAPER permission is granted
                    val permission = android.Manifest.permission.SET_WALLPAPER
                    val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
                    } else {
                        true
                    }
                    result.success(hasPermission)
                }
                
                else -> result.notImplemented()
            }
        }
    }
}

