import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;

import java.io.File;
import java.io.FileInputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.io.IOException;

public class VideoServer {

    public static void startServer(String contentDir, int port) throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);
        
        // Serve any file within the content directory.
        server.createContext("/", new HttpHandler() {
            @Override
            public void handle(HttpExchange exchange) throws IOException {
                String filePath = contentDir + exchange.getRequestURI().getPath();
                File file = new File(filePath);
                
                if (file.exists() && !file.isDirectory()) {
                    String contentType = "application/octet-stream";
                    if (filePath.endsWith(".m3u8")) {
                        contentType = "application/vnd.apple.mpegurl";
                    } else if (filePath.endsWith(".ts")) {
                        contentType = "video/MP2T";
                    }
                    exchange.getResponseHeaders().add("Content-Type", contentType);
                    exchange.sendResponseHeaders(200, file.length());

                    try (OutputStream os = exchange.getResponseBody(); FileInputStream fs = new FileInputStream(file)) {
                        final byte[] buffer = new byte[0x10000];
                        int count;
                        while ((count = fs.read(buffer)) >= 0) {
                            os.write(buffer, 0, count);
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
        System.out.println("Server is listening on port " + port);
    }

    public static void main(String[] args) throws IOException {
        if (args.length < 2) {
            System.out.println("Usage: java VideoServer <contentDir> <port>");
            System.exit(1);
        }

        String contentDir = args[0];
        int port = Integer.parseInt(args[1]);

        startServer(contentDir, port);
    }
}
