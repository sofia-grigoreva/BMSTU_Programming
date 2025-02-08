import java.util.List;
import java.util.Scanner;
import java.util.*;

public class Kruskal {
    static class Edge implements Comparable<Edge> {
        int v1, v2;
        double dist;
        Edge (int v1, int v2, double dist){
            this.v1 =v1;
            this.v2 =v2;
            this.dist =dist;
        }
        Edge (){
        }
        public int compareTo(Edge e) {
            return Double.compare(this.dist, e.dist);
        }
    }

    static class Graph {
        List<Edge> g;
        int n;
        int m;
        int parent[];
        Graph(int n){
            this.n = n;
            this.m = n * (n - 1) / 2;
            this.g = new ArrayList<>();
            this.parent = new int[n];
            Arrays.fill(parent, -1);
        }
        int Find(int x) {
            if (parent[x] == -1)
                return x;
            return Find(parent[x]);
        }
        void Union( int u, int v) {
            parent[Find(u)] = Find(v);
        }
        List<Edge> SpanningTree(){
            List<Edge> e = new ArrayList<>();
            int i =0;
            while ( i < m && e.size() < n - 1){
                if (Find(g.get(i).v1) != Find(g.get(i).v2)){
                    e.add(g.get(i));
                    Union(g.get(i).v1, g.get(i).v2);
                }
                i++;
            }
            if (e.size() != n-1){
                System.out.println("!!!");
            }
            return e;
        }

        double MST_Kruskal(){
            Collections.sort(g);
            double mindist = 0;
            List<Edge> e = SpanningTree();
            for (Edge i : e){
                mindist+= i.dist;
            }
            return (double) Math.round(mindist * 100) / 100;
        }
    }

    public static void main(String[] args) {
        Scanner scan = new Scanner(System.in);
        int n = scan.nextInt();
        Graph graph = new Graph(n);
        int a[][] = new int[n][n];
        for (int i = 0, x, y; i < n; i++) {
            x = scan.nextInt();
            y = scan.nextInt();
            a[i][0] = x;
            a[i][1] = y;
        }

        for (int i = 0; i < n - 1; i++) {
            for (int j = i + 1; j < n; j++) {
                double d = Math.sqrt(Math.pow(a[i][0] - a[j][0], 2) +
                        Math.pow(a[i][1] - a[j][1], 2));
                graph.g.add(new Edge(i,j, d));
            }
        }

        System.out.println(graph.MST_Kruskal());
    }
}
