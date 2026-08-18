import java.io.*;
import java.nio.file.*;
public class B6FileIO {
    public static void main(String[] args) throws Exception {
        int CHUNK = 1024 * 1024, CHUNKS = 4096;
        String fname = args.length > 0 ? args[0] : "../../data/fileio_test_java.tmp";
        byte[] buf = new byte[CHUNK];
        java.util.Arrays.fill(buf, (byte) 'A');
        FileOutputStream fos = new FileOutputStream(fname);
        try (OutputStream os = new BufferedOutputStream(fos)) {
            for (int i = 0; i < CHUNKS; i++) os.write(buf);
            os.flush();
            fos.getFD().sync();
        }
        long total = 0;
        try (InputStream is = new BufferedInputStream(new FileInputStream(fname))) {
            int n; while ((n = is.read(buf)) > 0) total += n;
        }
        System.out.println(total);
        Files.deleteIfExists(Path.of(fname));
    }
}
