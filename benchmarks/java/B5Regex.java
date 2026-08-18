import java.io.*;
import java.util.regex.*;
public class B5Regex {
    public static void main(String[] args) throws Exception {
        String fn = args.length > 0 ? args[0] : "../../data/regex_input.txt";
        Pattern pat = Pattern.compile("[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}");
        BufferedReader br = new BufferedReader(new FileReader(fn));
        String line; int count = 0;
        while ((line = br.readLine()) != null) { if (pat.matcher(line).find()) count++; }
        br.close();
        System.out.println(count);
    }
}
