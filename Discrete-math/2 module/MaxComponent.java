import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

public class MaxComponent {
    int n;
    List<List<Integer>> graph;
    String[] mark;

    public MaxComponent(int n) {
        this.n = n;
        this.graph = new ArrayList<>();
        for (int i = 0; i < n; i++)
            this.graph.add(new ArrayList<>());
        this.mark = new String[n];
    }

    void addEdge(int u, int v) {
        graph.get(u).add(v);
        graph.get(v).add(u);
    }
    List<Integer> VisitVertex(int i, List<Integer> c) {
        mark[i] = "gray";
        for (int j = 0; j < graph.get(i).size(); j++){
            if (mark[graph.get(i).get(j)] == "white"){
                c.add(graph.get(i).get(j));
                c = VisitVertex(graph.get(i).get(j), c);
            }
        }
        mark[i] = "black";
        return c;
    }

    int countedg(List<Integer> c){
        int count = 0;
        for (int i : c){
            count += graph.get(i).size();
        }
        return count / 2;
    }
    List<Integer> DFS() {
        List<Integer> max = new ArrayList<>();
        for (int i = 0; i < n; i++) {
            mark[i] = "white";
        }
        for (int i = 0; i < n; i++){
            if (mark[i] == "white"){
                List<Integer> c = new ArrayList<>();
                c.add(i);
                List<Integer> t = VisitVertex(i, c);
                if (t.size() > max.size() || (t.size() == max.size() && countedg(t) > countedg(max))){
                    max = t;
                }
            }
        }
        return max;
    }

    public static void main(String[] args) {
        Scanner scan = new Scanner(System.in);
        int n = scan.nextInt();
        int m = scan.nextInt();
        MaxComponent g = new MaxComponent(n);
        int[][] ed = new int[m][2];
        for (int i = 0, x, y; i < m; i++) {
            x = scan.nextInt();
            y = scan.nextInt();
            g.addEdge(x, y);
            ed[i][0] = x;
            ed[i][1] = y;
        }

        scan.close();
        List<Integer> maxc = g.DFS();
        System.out.println("graph {");
        for (int i = 0; i < n; i++ ){
            System.out.print("    ");
            if (maxc.contains(i)) {
                System.out.print(i);
                System.out.println(" [color = red]");
            }
            else{
                System.out.println(i);
            }
        }

        for (int i =0; i < m; i++ ){
            System.out.print("    ");
            System.out.print(ed[i][0]);
            System.out.print(" -- ");
            if (maxc.contains(ed[i][0])) {
                System.out.print(ed[i][1]);
                System.out.println(" [color = red]");
            }
            else{
                System.out.println(ed[i][1]);
            }
        }
        System.out.println("}");
    }
}
