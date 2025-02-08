import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

public class VisMealy {

    public static void main(String[] args) {
        Scanner scan = new Scanner(System.in);
        int n = scan.nextInt();
        int m = scan.nextInt();
        int q0 = scan.nextInt();
        List<List<Integer>> p = new ArrayList<>();
        List<List<String>> v = new ArrayList<>();
        int x = 0;
        for (int i = 0; i < n; i++) {
            p.add(new ArrayList<>());
            for (int j = 0; j < m; j++){
                x = scan.nextInt();
                p.get(i).add(x);
            }
        }
        String y = "";
        for (int i = 0; i < n; i++) {
            v.add(new ArrayList<>());
            for (int j = 0; j < m; j++){
                y = scan.next();
                v.get(i).add(y);
            }
        }
        System.out.println("digraph {");
        System.out.println("    rankdir = LR");

        char c;

        for (int i = 0; i < n; i++) {
            c = 'a';
            for (int j = 0; j < m; j++){
                System.out.print("    ");
                System.out.print(i);
                System.out.print(" -> ");
                System.out.print(p.get(i).get(j));
                System.out.print(" [label = \"");
                System.out.print(c);
                System.out.print("(");
                System.out.print(v.get(i).get(j));
                System.out.println(")\"]");
                c++;
            }
        }
        System.out.print("}");

    }
}
