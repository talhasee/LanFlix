package com.example.streamer

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import com.sun.net.httpserver.HttpExchange
import com.sun.net.httpserver.HttpHandler
import com.sun.net.httpserver.HttpServer
import java.io.*
import java.net.InetAddress
import java.net.InetSocketAddress
import java.nio.ByteBuffer
import java.nio.channels.FileChannel
import java.net.NetworkInterface
import java.util.concurrent.Executors
import java.util.logging.Logger

class MainActivity: FlutterActivity() {
    private val CHANNEL = "http.server"
    private val videoServer = VideoServer

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startVideoStream") {
                val videoPath = call.argument<String>("videoPath")
                val port = call.argument<Int>("port")
                videoServer.startServer(videoPath, port)
                // Invoke the Java application here
                // You might need to use a different approach to run the Java application from Android
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}

object VideoServer {

    private val LOGGER = Logger.getLogger(VideoServer::class.java.name)

    @Throws(IOException::class)
    fun startServer(videoFilePath: String, port: Int) {
        // Get the IP address of the machine
        val ipAddress = getLocalIPAddress() ?: run {
            println("Failed to find a network interface with a valid IP address.")
            System.exit(1)
        }

        // Create the server with the IP address and port
        val server = HttpServer.create(InetSocketAddress(ipAddress, port), 0)

        // Create a thread pool for handling client requests
        server.executor = Executors.newCachedThreadPool()

        server.createContext("/", HttpHandler { exchange ->
            handleRequest(videoFilePath, exchange)
        })

        server.start()
        LOGGER.info("Server is listening on ${ipAddress.hostAddress}:$port")
    }

    @Throws(IOException::class)
    private fun handleRequest(videoFilePath: String, exchange: HttpExchange) {
        val clientAddress = exchange.remoteAddress.address
        LOGGER.info("Client connected from: ${clientAddress.hostAddress}")

        val file = File(videoFilePath)
        if (file.exists() && !file.isDirectory) {
            exchange.responseHeaders.add("Content-Type", "video/mkv")
            exchange.sendResponseHeaders(200, file.length())

            exchange.responseBody.use { os ->
                FileInputStream(file).use { fs ->
                    FileChannel.open(file.toPath()).use { channel ->
                        val fileSize = channel.size()
                        val buffer = ByteArray(64 * 1024) // 64 KB buffer
                        var bytesRead: Int
                        while (channel.read(ByteBuffer.wrap(buffer)).also { bytesRead = it } != -1) {
                            os.write(buffer, 0, bytesRead)
                        }
                    }
                }
            }
        } else {
            // Respond with 404 Not Found if the file doesn't exist.
            val response = "File not found."
            exchange.sendResponseHeaders(404, response.toByteArray().size.toLong())
            exchange.responseBody.use { os ->
                os.write(response.toByteArray())
            }
        }
    }

    private fun getLocalIPAddress(): InetAddress? {
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
                    if (addr is java.net.Inet4Address) return addr
                }
            }
            null
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    // @JvmStatic
    // @Throws(IOException::class)
    // fun main(args: Array<String>) {
    //     if (args.size < 2) {
    //         println("Usage: java VideoServer <videoFilePath> <port>")
    //         System.exit(1)
    //     }

    //     val videoFilePath = args[0]
    //     val port = args[1].toInt()

    //     startServer(videoFilePath, port)
    // }
}