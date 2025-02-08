import java.util.*;

public class Prim {
    static class Graph {
        List<List<List<Integer>>> graph;
        int n;
        boolean mark[];
        Graph(int n){
            this.n = n;
            this.graph = new ArrayList<>(n);
            for (int i = 0; i < n; i++)
                this.graph.add(new ArrayList<>());
            this.mark = new boolean[n];
            Arrays.fill(this.mark, false);
        }
        void addEdge(int u, int v, int d) {
            graph.get(u).add(List.of(v,d));
            graph.get(v).add(List.of(u,d));
        }
        int prim(){
            int mindist = 0;
            int count = 1;
            mark[0] = true;
            int nextvertex = 0;
            while (count < n){
                int nextmind = (int) Math.pow(10, 100);
                for (int i = 0; i < n; i++){
                    if (mark[i]){
                        for (int j = 0; j < graph.get(i).size(); j++){
                            int u = graph.get(i).get(j).get(0);
                            int d = graph.get(i).get(j).get(1);
                            if ((!mark[u]) && d < nextmind){
                                nextmind = d;
                                nextvertex  = u;
                            }
                        }
                    }
                }
                mark[nextvertex] = true;
                mindist += nextmind;
                count++;
            }
            return mindist;
        }
    }

    public static void main(String[] args) {
        Scanner scan = new Scanner(System.in);
        int n = scan.nextInt();
        int m = scan.nextInt();
        Prim.Graph graph = new Prim.Graph(n);
        for (int i = 0, x, y, d; i < m; i++) {
            x = scan.nextInt();
            y = scan.nextInt();
            d = scan.nextInt();
            graph.addEdge(x,y,d);
        }
        System.out.println(graph.prim());
    }
}
