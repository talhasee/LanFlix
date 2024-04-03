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
import java.net.InetAddress;

public class VideoServer {

    public static void startServer(String videoFilePath, int port) throws IOException {
        // Get the IP address of the machine
        InetAddress ipAddress = getLocalIPAddress();
        if (ipAddress == null) {
            System.out.println("Failed to find a network interface with a valid IP address.");
            System.exit(1);
        }

        // Create the server with the IP address and port
        HttpServer server = HttpServer.create(new InetSocketAddress(ipAddress, port), 0);

        server.createContext("/", new HttpHandler() {
            @Override
            public void handle(HttpExchange exchange) throws IOException {
                File file = new File(videoFilePath);
                if (file.exists() && !file.isDirectory()) {
                    exchange.getResponseHeaders().add("Content-Type", "video/mp4");
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
        });

        server.start();
        System.out.println("Server is listening on " + ipAddress.getHostAddress() + ":" + port);
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
