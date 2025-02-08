import java.util.*;
public class Mealy2Moore {

    public static class Pair{
        int p1;
        String p2;
        Pair(int p1, String p2){
            this.p1 = p1;
            this.p2 = p2;
        }

        public boolean equals(Object obj) {
            if (this == obj) {
                return true;
            }
            if (obj == null || getClass() != obj.getClass()) {
                return false;
            }
            Pair other = (Pair) obj;
            return p1 == other.p1 && Objects.equals(p2, other.p2);
        }
    }


    public static void main(String[] args) {
        Scanner scan = new Scanner(System.in);
        int k1 = scan.nextInt();
        List<String> alf1 = new ArrayList<>();
        String y = "";
        for (int i = 0; i < k1; i++) {
            y = scan.next();
            alf1.add(y);
        }
        int k2 = scan.nextInt();
        List<String> alf2 = new ArrayList<>();
        for (int i = 0; i < k2; i++) {
            y = scan.next();
            alf2.add(y);
        }

        int n = scan.nextInt();

        List<List<Integer>> p = new ArrayList<>();
        int x = 0;
        for (int i = 0; i < n; i++) {
            p.add(new ArrayList<>());
            for (int j = 0; j < k1; j++){
                x = scan.nextInt();
                p.get(i).add(x);
            }
        }

        List<List<Integer>> v = new ArrayList<>();
        for (int i = 0; i < n; i++) {
            v.add(new ArrayList<>());
            for (int j = 0; j < k1; j++){
                x = scan.nextInt();
                v.get(i).add(x);
            }
        }

        List<Pair> Q = new ArrayList<>();
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < k1; j++){
                Pair pair = new Pair(p.get(i).get(j), alf2.get(v.get(i).get(j)));
                if (!Q.contains(pair)){
                    Q.add(pair);
                }
            }
        }

        System.out.println("digraph {");
        System.out.println("    rankdir = LR");

        for (int i = 0; i < Q.size(); i++) {
            Pair q = Q.get(i);
            System.out.print("    ");
            System.out.print(i);
            System.out.print(" [label = \"(");
            System.out.print(q.p1);
            System.out.print(",");
            System.out.print(q.p2);
            System.out.println(")\"]");
        }

        int ind = 0;
        //System.out.println(Q);
        for (int i = 0; i < Q.size(); i++) {
            Pair q = Q.get(i);
            for (int j = 0; j < k1; j++){
                System.out.print("    ");
                System.out.print(i);
                System.out.print(" -> ");
                Pair pair = new Pair(p.get(q.p1).get(j), alf2.get(v.get(q.p1).get(j)));
                System.out.print(Q.indexOf(pair));
                System.out.print(" [label = \"");
                System.out.print(alf1.get(ind));
                System.out.println("\"]");
                ind++;
                if (ind >= k1){
                    ind = 0;
                }
            }
        }
        System.out.println("}");
    }
}
