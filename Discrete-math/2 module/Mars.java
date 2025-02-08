import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

public class Mars {
    static int min_difference = Integer.MAX_VALUE;
    static List<Integer> bestg = null;

    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        List<List<Boolean>> m = new ArrayList<>();
        int n = scanner.nextInt();
        for (int i = 0; i < n; i++) {
            List<Boolean> t = new ArrayList<>();
            for (int j = 0; j < n; j++){
                char c = scanner.next().charAt(0);
                if (c == '+'){
                    t.add(false);
                }
                else{
                    t.add(true);
                }
            }
            m.add(t);
        }
        team_selection(0, new ArrayList<>(), new ArrayList<>(),m);
        if (bestg == null) {
            System.out.println("No solution");
        } else {
            print_group(bestg);
        }
    }
    static void team_selection (int c, List<Integer> g1, List<Integer> g2, List<List<Boolean>> m) {
        if (c == m.size()) {
            int difference = Math.abs(g1.size() - g2.size());
            if (g1.size() > g2.size()) {
                if (difference < min_difference || (difference == min_difference && lexmin(g2, bestg))) {
                    min_difference = difference;
                    bestg = new ArrayList<>(g2);
                }
            }
            else{
                if (difference < min_difference || (difference == min_difference && lexmin(g1, bestg))) {
                    min_difference = difference;
                    bestg = new ArrayList<>(g1);
                }
            }
            //System.out.println(bestg);
            return;
        }

        if (can_add(m, g1, c) ) {
            g1.add(c + 1);
            team_selection(c + 1, g1, g2, m);
            g1.remove(g1.size() - 1);
        }

        if (can_add(m, g2, c) ) {
            g2.add(c + 1);
            team_selection(c + 1, g1, g2, m);
            g2.remove(g2.size() - 1);
        }
    }

    private static boolean can_add (List<List<Boolean>> m, List<Integer> g, int num) {
        for (int i : g) {
            if (!m.get(i - 1).get(num)) {
                return false;
            }
        }
        return true;
    }

    private static boolean lexmin (List<Integer> g1, List<Integer> g2) {
        if (g2 == null){
            return true;
        }
        for (int i = 0; i < Math.min(g1.size(), g2.size()); i++) {
            if (g1.get(i) < g2.get(i)) {
                return true;
            }
            if (g1.get(i) > g2.get(i)) {
                return false;
            }
        }
        return g1.size() < g2.size();
    }
    private static void print_group (List<Integer> g){
        for (int i : g){
            System.out.print(i + " ");
        }
    }
}
