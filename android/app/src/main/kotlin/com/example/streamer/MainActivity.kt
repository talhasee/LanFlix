package com.example.streamer
import androidx.annotation.NonNull
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import fi.iki.elonen.NanoHTTPD
import java.io.File
import java.io.FileInputStream
import java.net.InetAddress
import java.net.NetworkInterface

class MainActivity : FlutterActivity() {
    private val CHANNEL = "http.server"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startVideoStream") {
                val videoPath = call.argument<String>("videoPath")
                val port = call.argument<Int>("port")

                if (videoPath != null && port != null) {
                    // Log.d("MainActivity", "STARTING SERVER!!!!")
                    Log.d("MainActivity", "Started video server for $videoPath at $port");
                    startVideoServer(videoPath, port)
                    result.success(null)
                } else {
                    result.error("invalid_arguments", "Invalid arguments provided", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun startVideoServer(videoFilePath: String, port: Int) {
        try {
            val server = VideoServer(videoFilePath, port)
            val localAddress = server.getLocalIPAddress()
            server.start(NanoHTTPD.SOCKET_READ_TIMEOUT, false)
            val actualPort = server.listeningPort
            Log.d("MainActivity", "Video server started on $localAddress:$actualPort")
        } catch (e: Exception) {
            Log.d("MainActivity", "Error starting video server: ${e.message}")
            e.printStackTrace()
        }
    }

    private class VideoServer(private val videoFilePath: String, port: Int) : NanoHTTPD(0) {
        override fun serve(session: IHTTPSession): Response {
            // val clientAddress = session.remoteAddress.address
            // Log.d("VideoServer", "New client connected from: $clientAddress")

            Log.d("VideoServer", "Serving video request")
            val file = File(videoFilePath)

            return if (file.exists() && !file.isDirectory) {
                val response = newChunkedResponse(
                    Response.Status.OK,
                    "video/mp4",
                    FileInputStream(file)
                )
                response.addHeader("Content-Length", file.length().toString())
                response
            } else {
                Log.d("VideoServer", "Video file not found")
                newFixedLengthResponse(Response.Status.NOT_FOUND, MIME_PLAINTEXT, "File not found.")
            }
        }

        fun getLocalIPAddress(): String {
            return try {
                val interfaces = NetworkInterface.getNetworkInterfaces()
                while (interfaces.hasMoreElements()) {
                    val iface = interfaces.nextElement()
                    // Filter out 127.0.0.1 and inactive interfaces
                    if (iface.isLoopback || !iface.isUp) continue

                    val addresses = iface.inetAddresses
                    while (addresses.hasMoreElements()) {
                        val addr = addresses.nextElement()
                        // Filter out IPv6 addresses
                        if (addr is java.net.Inet4Address) return addr.hostAddress
                    }
                }
                "Unknown"
            } catch (e: Exception) {
                Log.d("VideoServer", "Error getting local IP address: ${e.message}")
                e.printStackTrace()
                "Unknown"
            }
        }
    }
}