import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import java.io.IOException;
import java.io.OutputStream;
import java.io.RandomAccessFile;
import java.net.InetSocketAddress;
import java.net.NetworkInterface;
import java.net.InetAddress;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;

public class HLSServerEncoder {
    private static final String HLS_PLAYLIST_FILE = "playlist.m3u8";
    private static final String HLS_SEGMENT_PREFIX = "segment";
    private static final String HLS_SEGMENT_EXTENSION = ".ts";
    private static final int SEGMENT_DURATION_SECONDS = 10;
    private static final int SEGMENT_SIZE = 188 * 1024;

    public static void main(String[] args) throws IOException {
        if (args.length < 2) {
            System.out.println("Usage: java HLSServerEncoder <videoFilePath> <port>");
            System.exit(1);
        }

        String videoFilePath = args[0];
        int port = Integer.parseInt(args[1]);

        encodeVideo(videoFilePath, port);
    }

    private static void encodeVideo(String inputVideoFile, int port) {
        Thread encoderThread = new Thread(() -> {
            try {
                Path outputDir = Paths.get(inputVideoFile).getParent();
                Files.createDirectories(outputDir);

                RandomAccessFile videoFile = new RandomAccessFile(inputVideoFile, "r");
                FileChannel videoChannel = videoFile.getChannel();

                List<String> segmentFiles = new ArrayList<>();
                ByteBuffer segmentBuffer = ByteBuffer.allocate(SEGMENT_SIZE);

                int segmentIndex = 0;
                long segmentStartTime = 0;
                long totalBytesRead = 0;

                while (videoChannel.read(segmentBuffer) > 0) {
                    segmentBuffer.flip();
                    String segmentFileName = outputDir.resolve(HLS_SEGMENT_PREFIX + segmentIndex + HLS_SEGMENT_EXTENSION).toString();
                    Files.write(Paths.get(segmentFileName), segmentBuffer.array());
                    segmentFiles.add(segmentFileName);
                    segmentBuffer.clear();

                    long segmentEndTime = segmentStartTime + SEGMENT_DURATION_SECONDS;
                    totalBytesRead += SEGMENT_SIZE;

                    segmentIndex++;
                    segmentStartTime = segmentEndTime;
                }

                videoChannel.close();
                videoFile.close();

                createPlaylistFile(outputDir, segmentFiles);
                System.out.println("HLS encoding completed successfully.");

                startServer(outputDir, port);
            } catch (IOException e) {
                System.err.println("Error during HLS encoding: " + e.getMessage());
            }
        });
        encoderThread.start();
    }

    private static void startServer(Path outputDir, int port) throws IOException {
        InetAddress ipAddress = getLocalIPAddress();
        if (ipAddress == null) {
            System.out.println("Failed to find a network interface with a valid IP address.");
            System.exit(1);
        }

        HttpServer server = HttpServer.create(new InetSocketAddress(ipAddress, port), 0);
        server.createContext("/", new HttpHandler() {
            @Override
            public void handle(HttpExchange exchange) throws IOException {
                String requestPath = exchange.getRequestURI().getPath();
                if (requestPath.equals("/") || requestPath.equals("/" + HLS_PLAYLIST_FILE)) {
                    servePlaylistFile(exchange, outputDir);
                } else if (requestPath.startsWith("/" + HLS_SEGMENT_PREFIX)) {
                    serveSegmentFile(exchange, outputDir, requestPath);
                } else {
                    String response = "Not Found";
                    exchange.sendResponseHeaders(404, response.getBytes().length);
                    try (OutputStream os = exchange.getResponseBody()) {
                        os.write(response.getBytes());
                    }
                }
            }
        });
        server.start();
        System.out.println("HLS Server is listening on " + ipAddress.getHostAddress() + ":" + port);
    }

    private static void servePlaylistFile(HttpExchange exchange, Path outputDir) throws IOException {
        Path playlistPath = outputDir.resolve(HLS_PLAYLIST_FILE);
        byte[] playlistBytes = Files.readAllBytes(playlistPath);
        exchange.getResponseHeaders().add("Content-Type", "application/vnd.apple.mpegurl");
        exchange.sendResponseHeaders(200, playlistBytes.length);
        try (OutputStream os = exchange.getResponseBody()) {
            os.write(playlistBytes);
        }
    }

    private static void serveSegmentFile(HttpExchange exchange, Path outputDir, String requestPath) throws IOException {
        String segmentFileName = requestPath.substring(requestPath.lastIndexOf('/') + 1);
        Path segmentPath = outputDir.resolve(segmentFileName);
        byte[] segmentBytes = Files.readAllBytes(segmentPath);
        exchange.getResponseHeaders().add("Content-Type", "video/MP2T");
        exchange.sendResponseHeaders(200, segmentBytes.length);
        try (OutputStream os = exchange.getResponseBody()) {
            os.write(segmentBytes);
        }
    }

    private static InetAddress getLocalIPAddress() {
        try {
            Enumeration<NetworkInterface> interfaces = NetworkInterface.getNetworkInterfaces();
            while (interfaces.hasMoreElements()) {
                NetworkInterface iface = interfaces.nextElement();
                if (iface.isLoopback() || !iface.isUp()) continue;
                Enumeration<InetAddress> addresses = iface.getInetAddresses();
                while (addresses.hasMoreElements()) {
                    InetAddress addr = addresses.nextElement();
                    if (addr instanceof java.net.Inet4Address) return addr;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private static void createPlaylistFile(Path outputDir, List<String> segmentFiles) throws IOException {
        StringBuilder playlistBuilder = new StringBuilder();
        playlistBuilder.append("#EXTM3U\n");
        playlistBuilder.append("#EXT-X-VERSION:3\n");
        playlistBuilder.append("#EXT-X-MEDIA-SEQUENCE:0\n");
        playlistBuilder.append("#EXT-X-TARGETDURATION:").append(SEGMENT_DURATION_SECONDS).append("\n");
        playlistBuilder.append("#EXT-X-PLAYLIST-TYPE:VOD\n");

        for (int i = 0; i < segmentFiles.size(); i++) {
            String segmentFile = Paths.get(segmentFiles.get(i)).getFileName().toString();
            playlistBuilder.append("#EXTINF:").append(SEGMENT_DURATION_SECONDS).append(",\n");
            playlistBuilder.append(segmentFile).append("\n");
        }
        playlistBuilder.append("#EXT-X-ENDLIST\n");

        Files.write(outputDir.resolve(HLS_PLAYLIST_FILE), playlistBuilder.toString().getBytes());
    }
}