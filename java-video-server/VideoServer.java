import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;

import java.io.File;
import java.io.FileInputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.io.IOException;

public class VideoServer {

    public static void startServer(String videoFilePath, int port) throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);
        server.createContext("/video", new HttpHandler() {
            @Override
            public void handle(HttpExchange exchange) throws IOException {
                File file = new File(videoFilePath);
                exchange.sendResponseHeaders(200, file.length());
                OutputStream os = exchange.getResponseBody();
                FileInputStream fs = new FileInputStream(file);
                final byte[] buffer = new byte[0x10000];
                int count = 0;
                while ((count = fs.read(buffer)) >= 0) {
                    os.write(buffer,0,count);
                }
                os.close();
            }
        });
        server.start();
        System.out.println("Server is listening on port " + port);
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
