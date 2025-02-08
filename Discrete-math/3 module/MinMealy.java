import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Scanner;

public class MinMealy {
    sost[] Q;
    int[] mark;
    int num;
    int[] pi;
    int count;
    int count2;
    int m;
    int n;
    List<List<Integer>> p;
    List<List<String>> v;
    public MinMealy(int n, int m, List<List<Integer>> p, List<List<String>> v) {
        this.n = n;
        this.m = m;
        this.p = p;
        this.v = v;
        this.pi = new int[n];
        this.count = n;
        this.count2 = n;
        this.Q = new sost[n];
        for (int i = 0; i < n; i++){
            Q[i] = new sost(i);
        }
        this.num = 0;
    }

    public class sost{
        sost parent;
        int depth;
        int i;
        public sost(int i){
            this.i = i;
        }
    }
    sost Find (sost q){
        if (q.parent == q){
            return q;
        }
        return Find(q.parent);
    }

    void Union (sost q1, sost q2){
        q1 = Find(q1);
        q2 = Find(q2);
        if (q1 != q2){
            if (q1.depth < q2.depth){
                sost c =q1;
                q1 = q2;
                q2 = c;
            }
            q2.parent = q1;
            if (q1.depth == q2.depth){
                q1.depth++;
            }
        }
    }

    void Split1 (){
        for (sost q : Q){
            q.parent = q;
            q.depth = 0;
        }
        for (sost q1 : Q){
            for (sost q2 : Q){
                if (Find(q1) != Find(q2)){
                    boolean eq = true;
                    for (int x = 0; x < m; x++){
                        if (!v.get(q1.i).get(x).equals(v.get(q2.i).get(x))){
                            eq = false;
                            break;
                        }
                    }
                    if (eq){
                        Union(q1,q2);
                        count--;
                    }
                }
            }
        }
        for (sost q : Q){
            pi[q.i] = Find(q).i;
        }
    }

    void Split (){
        count2 = n;
        for (sost q : Q){
            q.parent = q;
            q.depth = 0;
        }
        for (sost q1 : Q){
            for (sost q2 : Q){
                if (Find(q1) != Find(q2) && pi[q1.i] == pi[q2.i]){
                    boolean eq = true;
                    for (int x = 0; x < m; x++){
                        if (pi[p.get(q1.i).get(x)] != pi[p.get(q2.i).get(x)]){
                            eq = false;
                            break;
                        }
                    }
                    if (eq){
                        Union(q1,q2);
                        count2--;
                    }
                }
            }
        }
        for (sost q : Q){
            pi[q.i] = Find(q).i;
        }
    }

    boolean in (int x, List<Integer> array){
        for (int i : array){
            if (x == i){
                return true;
            }
        }
        return false;
    }

    List<Integer> AufenkampHohn (){
        Split1();
        while(true){
            Split();
            if (count == count2){
                break;
            }
            count = count2;
        }

        List<Integer> Q2 = new ArrayList<>();
        for (sost q : Q){
            int q2 = pi[q.i];
            if (!in(q2,Q2)){
                Q2.add(q2);
                for (int x = 0; x < m; x++){
                    p.get(q2).set(x, pi[p.get(q.i).get(x)]);
                    v.get(q2).set(x, v.get(q.i).get(x));
                }
            }
        }
        this.mark = new int[Q2.size()];
        Arrays.fill(mark , -1);
        return Q2;
    }

    void DFS(int start, List<List<Integer>> p2){
        mark[start] = num;
        num++;
        for (int i = 0; i < m; i++){
            if (mark[p2.get(start).get(i)] == -1){
                DFS(p2.get(start).get(i), p2);
            }
        }
    }


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

        MinMealy mealy = new MinMealy(n, m, p, v);
        List<List<Integer>> p2 = new ArrayList<>();
        List<List<String>> v2 = new ArrayList<>();
        List<Integer> Q = mealy.AufenkampHohn();

        for (int i : Q){
            v2.add(v.get(i));
            p2.add(p.get(i));
        }

        for (List<Integer> i : p2){
            for (int j = 0; j < m; j++){
                i.set(j, Q.indexOf(i.get(j)));
            }
        }

        //System.out.println(Q);
        //System.out.println(Arrays.toString(mealy.pi));
        //System.out.println(v2);

        if (Q.indexOf(q0) == -1){
            q0 = Q.indexOf(mealy.pi[q0]);
        }
        else {
            q0 = Q.indexOf(q0);
        }

        n = Q.size();
        mealy.DFS(q0, p2);
        List<List<Integer>> p3 = new ArrayList<>();
        List<List<String>> v3 = new ArrayList<>();

        for (int i = 0; i < n; i++) {
            p3.add(new ArrayList<>());
            for (int j = 0; j < m; j++){
                p3.get(i).add(1);
            }
        }

        int j = 0;
        for (int i : mealy.mark){
            p3.set(i, p2.get(j));
            j++;
        }

        for (int i = 0; i < n; i++) {
            for (j = 0; j < m; j++){
                p3.get(i).set(j, mealy.mark[p3.get(i).get(j)]);
            }
        }

        for (int i = 0; i < n; i++) {
            v3.add(new ArrayList<>());
            for (j = 0; j < m; j++){
                v3.get(i).add("");
            }
        }

        j = 0;
        for (int i : mealy.mark){
            v3.set(i, v2.get(j));
            j++;
        }


        System.out.println("digraph {");
        System.out.println("    rankdir = LR");

        char s;

        for (int i = 0; i < Q.size(); i++) {
            s = 'a';
            for (j = 0; j < m; j++){
                System.out.print("    ");
                System.out.print(i);
                System.out.print(" -> ");
                System.out.print(p3.get(i).get(j));
                System.out.print(" [label = \"");
                System.out.print(s);
                System.out.print("(");
                System.out.print(v3.get(i).get(j));
                System.out.println(")\"]");
                s++;
            }
        }
        System.out.println("}");

    }
}
