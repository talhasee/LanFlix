import java.io.IOException;

public class VideoEncoder {

    public static boolean encodeVideo(String inputPath, String outputPath) {
        ProcessBuilder processBuilder = new ProcessBuilder(
                "ffmpeg", "-i", inputPath, "-vcodec", "libx264", "-crf", "23", outputPath);
        try {
            Process process = processBuilder.start();
            int exitCode = process.waitFor();
            return exitCode == 0;
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();

            System.out.println("Error while Encoding"+e.toString());
            return false;
        }
    }

    public static void main(String[] args) {
        if (args.length < 2) {
            System.out.println("Usage: java VideoEncoder <inputPath> <outputPath>");
            System.exit(1);
        }

        String inputPath = args[0];
        String outputPath = args[1];

        boolean success = encodeVideo(inputPath, outputPath);
        if (success) {
            System.out.println("Video encoded successfully.");
        } else {
            System.out.println("Video encoding failed.");
        }
    }
}
