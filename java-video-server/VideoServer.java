// import com.sun.net.httpserver.HttpServer;
// import com.sun.net.httpserver.HttpExchange;
// import com.sun.net.httpserver.HttpHandler;

// import java.io.File;
// import java.io.FileInputStream;
// import java.io.OutputStream;
// import java.net.InetSocketAddress;
// import java.io.IOException;
// import java.nio.ByteBuffer; // Import statement for ByteBuffer
// import java.nio.channels.FileChannel;

// public class VideoServer {

//     public static void startServer(String videoFilePath, int port) throws IOException {
//         HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);

//         server.createContext("/", new HttpHandler() {
//             @Override
//             public void handle(HttpExchange exchange) throws IOException {
//                 File file = new File(videoFilePath);
//                 if (file.exists() && !file.isDirectory()) {
//                     exchange.getResponseHeaders().add("Content-Type", "video/mp4");
//                     exchange.sendResponseHeaders(200, file.length());

//                     try (OutputStream os = exchange.getResponseBody();
//                          FileInputStream fs = new FileInputStream(file);
//                          FileChannel channel = fs.getChannel()) {
//                         final long fileSize = channel.size();
//                         final byte[] buffer = new byte[64 * 1024]; // 64 KB buffer
//                         int bytesRead;
//                         while ((bytesRead = channel.read(ByteBuffer.wrap(buffer))) != -1) {
//                             os.write(buffer, 0, bytesRead);
//                         }
//                     }
//                 } else {
//                     // Respond with 404 Not Found if the file doesn't exist.
//                     String response = "File not found.";
//                     exchange.sendResponseHeaders(404, response.getBytes().length);
//                     try (OutputStream os = exchange.getResponseBody()) {
//                         os.write(response.getBytes());
//                     }
//                 }
//             }
//         });

//         server.start();
//         System.out.println("Server is listening on port " + port);
//     }

//     public static void main(String[] args) throws IOException {
//         if (args.length < 2) {
//             System.out.println("Usage: java VideoServer <videoFilePath> <port>");
//             System.exit(1);
//         }

//         String videoFilePath = args[0];
//         int port = Integer.parseInt(args[1]);

//         startServer(videoFilePath, port);
//     }
// }

//***********************************************************/
//FOR HANDLING MULTIPLE CLIENTS
//*********************************************************/

import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;

import java.io.File;
import java.io.FileInputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.net.NetworkInterface;
import java.util.Enumeration;
import java.util.concurrent.Executors;
import java.net.InetAddress;
import java.util.logging.Logger;

public class VideoServer {

    private static final Logger LOGGER = Logger.getLogger(VideoServer.class.getName());

    public static void startServer(String videoFilePath, int port) throws IOException {
        // Get the IP address of the machine
        InetAddress ipAddress = getLocalIPAddress();
        if (ipAddress == null) {
            System.out.println("Failed to find a network interface with a valid IP address.");
            System.exit(1);
        }

        // Create the server with the IP address and port
        HttpServer server = HttpServer.create(new InetSocketAddress(ipAddress, port), 0);

        // Create a thread pool for handling client requests
        server.setExecutor(Executors.newCachedThreadPool());

        server.createContext("/", new HttpHandler() {
            @Override
            public void handle(HttpExchange exchange) throws IOException {
                handleRequest(videoFilePath, exchange);
            }
        });

        server.start();
        LOGGER.info("Server is listening on " + ipAddress.getHostAddress() + ":" + port);
    }

    private static void handleRequest(String videoFilePath, HttpExchange exchange) throws IOException {
        InetAddress clientAddress = exchange.getRemoteAddress().getAddress();
        LOGGER.info("Client connected from: " + clientAddress.getHostAddress());

        File file = new File(videoFilePath);
        if (file.exists() && !file.isDirectory()) {
            exchange.getResponseHeaders().add("Content-Type", "video/mkv");
            exchange.sendResponseHeaders(200, file.length());

            try (OutputStream os = exchange.getResponseBody();
                 FileInputStream fs = new FileInputStream(file);
                 FileChannel channel = fs.getChannel()) {
                final long fileSize = channel.size();
                final byte[] buffer = new byte[64 * 1024]; // 64 KB buffer
                int bytesRead;
                while ((bytesRead = channel.read(ByteBuffer.wrap(buffer))) != -1) {
                    os.write(buffer, 0, bytesRead);
                }
            }
        } else {
            // Respond with 404 Not Found if the file doesn't exist.
            String response = "File not found.";
            exchange.sendResponseHeaders(404, response.getBytes().length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(response.getBytes());
            }
        }
    }

    private static InetAddress getLocalIPAddress() {
        try {
            Enumeration<NetworkInterface> interfaces = NetworkInterface.getNetworkInterfaces();
            while (interfaces.hasMoreElements()) {
                NetworkInterface iface = interfaces.nextElement();
                // Filter out 127.0.0.1 and inactive interfaces
                if (iface.isLoopback() || !iface.isUp())
                    continue;

                Enumeration<InetAddress> addresses = iface.getInetAddresses();
                while(addresses.hasMoreElements()) {
                    InetAddress addr = addresses.nextElement();
                    // Filter out IPv6 addresses
                    if (addr instanceof java.net.Inet4Address)
                        return addr;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public static void main(String[] args) throws IOException {
        if (args.length < 2) {
            System.out.println("Usage: java VideoServer <videoFilePath> <port>");
            System.exit(1);
        }

        String videoFilePath = args[0];
        int port = Integer.parseInt(args[1]);

        startServer(videoFilePath, port);
    }
}


// import com.sun.net.httpserver.HttpServer;
// import com.sun.net.httpserver.HttpExchange;
// import com.sun.net.httpserver.HttpHandler;

// import java.io.File;
// import java.io.FileInputStream;
// import java.io.OutputStream;
// import java.net.InetSocketAddress;
// import java.io.IOException;
// import java.nio.ByteBuffer;
// import java.nio.channels.FileChannel;
// import java.net.NetworkInterface;
// import java.util.Enumeration;
// import java.net.InetAddress;

// public class VideoServer {

//     public static void startServer(String inputVideoPath, String videoFolderPath, int port) throws IOException {
//         // Get the IP address of the machine
//         InetAddress ipAddress = getLocalIPAddress();
//         if (ipAddress == null) {
//             System.out.println("Failed to find a network interface with a valid IP address.");
//             System.exit(1);
//         }

//         // Start video encoding in a separate thread
//         Thread encodingThread = new Thread(() -> {
//             String outputVideoPath = videoFolderPath + "/output/video.mp4"; // Output path within the video folder

//             boolean encodingSuccess = VideoEncoder.encodeVideo(inputVideoPath, outputVideoPath);
//             if (!encodingSuccess) {
//                 System.out.println("Video encoding failed.");
//             } else {
//                 System.out.println("Video encoded successfully.");
//             }
//         });
//         encodingThread.start();

//         // Create the server with the IP address and port
//         HttpServer server = HttpServer.create(new InetSocketAddress(ipAddress, port), 0);

//         server.createContext("/", new HttpHandler() {
//             @Override
//             public void handle(HttpExchange exchange) throws IOException {
//                 // Assuming videoFolderPath contains the encoded HLS segments and manifest files
//                 File manifestFile = new File(videoFolderPath + "/master.m3u8");
//                 if (manifestFile.exists() && !manifestFile.isDirectory()) {
//                     exchange.getResponseHeaders().add("Content-Type", "application/vnd.apple.mpegurl");
//                     exchange.sendResponseHeaders(200, manifestFile.length());

//                     try (OutputStream os = exchange.getResponseBody();
//                          FileInputStream fs = new FileInputStream(manifestFile)) {
//                         final byte[] buffer = new byte[64 * 1024]; // 64 KB buffer
//                         int bytesRead;
//                         while ((bytesRead = fs.read(buffer)) != -1) {
//                             os.write(buffer, 0, bytesRead);
//                         }
//                     }
//                 } else {
//                     // Respond with 404 Not Found if the manifest file doesn't exist.
//                     String response = "Manifest file not found.";
//                     exchange.sendResponseHeaders(404, response.getBytes().length);
//                     try (OutputStream os = exchange.getResponseBody()) {
//                         os.write(response.getBytes());
//                     }
//                 }
//             }
//         });

//         server.start();
//         System.out.println("Server is listening on " + ipAddress.getHostAddress() + ":" + port);
//     }

//     private static InetAddress getLocalIPAddress() {
//         try {
//             Enumeration<NetworkInterface> interfaces = NetworkInterface.getNetworkInterfaces();
//             while (interfaces.hasMoreElements()) {
//                 NetworkInterface iface = interfaces.nextElement();
//                 // Filter out 127.0.0.1 and inactive interfaces
//                 if (iface.isLoopback() || !iface.isUp())
//                     continue;

//                 Enumeration<InetAddress> addresses = iface.getInetAddresses();
//                 while(addresses.hasMoreElements()) {
//                     InetAddress addr = addresses.nextElement();
//                     // Filter out IPv6 addresses
//                     if (addr instanceof java.net.Inet4Address)
//                         return addr;
//                 }
//             }
//         } catch (Exception e) {
//             e.printStackTrace();
//         }
//         return null;
//     }

//     public static void main(String[] args) throws IOException {
//         if (args.length < 3) {
//             System.out.println("Usage: java VideoServer <inputVideoPath> <videoFolderPath> <port>");
//             System.exit(1);
//         }

//         String inputVideoPath = args[0];
//         String videoFolderPath = args[1];
//         int port = Integer.parseInt(args[2]);

//         startServer(inputVideoPath, videoFolderPath, port);
//     }
// }

// import com.sun.net.httpserver.HttpServer;
// import com.sun.net.httpserver.HttpExchange;
// import com.sun.net.httpserver.HttpHandler;

// import java.io.File;
// import java.io.FileInputStream;
// import java.io.IOException;
// import java.io.OutputStream;
// import java.net.InetSocketAddress;
// import java.nio.ByteBuffer;
// import java.nio.channels.FileChannel;
// import java.net.NetworkInterface;
// import java.util.Enumeration;
// import java.util.concurrent.Executors;
// import java.net.InetAddress;
// import java.util.concurrent.atomic.AtomicLong;

// public class VideoServer {
//     private static final int BUFFER_SIZE = 64 * 1024; // 64 KB buffer
//     private static FileChannel sharedFileChannel;
//     private static AtomicLong sharedPosition = new AtomicLong(0);

//     public static void startServer(String videoFilePath, int port) throws IOException {
//         // Get the IP address of the machine
//         InetAddress ipAddress = getLocalIPAddress();
//         if (ipAddress == null) {
//             System.out.println("Failed to find a network interface with a valid IP address.");
//             System.exit(1);
//         }

//         // Create the server with the IP address and port
//         HttpServer server = HttpServer.create(new InetSocketAddress(ipAddress, port), 0);

//         // Create a thread pool for handling client requests
//         server.setExecutor(Executors.newCachedThreadPool());

//         // Initialize the shared file channel
//         initializeSharedFileChannel(videoFilePath);

//         server.createContext("/", new HttpHandler() {
//             @Override
//             public void handle(HttpExchange exchange) throws IOException {
//                 handleRequest(exchange);
//             }
//         });

//         server.start();
//         System.out.println("Server is listening on " + ipAddress.getHostAddress() + ":" + port);
//     }

//     private static void initializeSharedFileChannel(String videoFilePath) throws IOException {
//         File file = new File(videoFilePath);
//         if (file.exists() && !file.isDirectory()) {
//             FileInputStream fileInputStream = new FileInputStream(file);
//             sharedFileChannel = fileInputStream.getChannel();
//         } else {
//             System.out.println("Video file not found: " + videoFilePath);
//             System.exit(1);
//         }
//     }

//     private static void handleRequest(HttpExchange exchange) throws IOException {
//         exchange.getResponseHeaders().add("Content-Type", "video/mp4");
//         exchange.sendResponseHeaders(200, sharedFileChannel.size());
    
//         try (OutputStream os = exchange.getResponseBody()) {
//             ByteBuffer buffer = ByteBuffer.allocate(BUFFER_SIZE);
//             long position = sharedPosition.getAndIncrement();
//             sharedFileChannel.position(position);
    
//             int bytesRead;
//             while ((bytesRead = sharedFileChannel.read(buffer)) != -1) {
//                 buffer.position(0); // Reset buffer position
//                 os.write(buffer.array(), 0, bytesRead);
    
//                 // Update the shared position
//                 position += bytesRead;
//                 sharedPosition.set(position);
    
//                 buffer.clear();
//             }
//         }
//     }
    
    

//     private static InetAddress getLocalIPAddress() {
//         try {
//             Enumeration<NetworkInterface> interfaces = NetworkInterface.getNetworkInterfaces();
//             while (interfaces.hasMoreElements()) {
//                 NetworkInterface iface = interfaces.nextElement();
//                 // Filter out 127.0.0.1 and inactive interfaces
//                 if (iface.isLoopback() || !iface.isUp())
//                     continue;

//                 Enumeration<InetAddress> addresses = iface.getInetAddresses();
//                 while(addresses.hasMoreElements()) {
//                     InetAddress addr = addresses.nextElement();
//                     // Filter out IPv6 addresses
//                     if (addr instanceof java.net.Inet4Address)
//                         return addr;
//                 }
//             }
//         } catch (Exception e) {
//             e.printStackTrace();
//         }
//         return null;
//     }

//     public static void main(String[] args) throws IOException {
//         if (args.length < 2) {
//             System.out.println("Usage: java VideoServer <videoFilePath> <port>");
//             System.exit(1);
//         }

//         String videoFilePath = args[0];
//         int port = Integer.parseInt(args[1]);

//         startServer(videoFilePath, port);
//     }
// }