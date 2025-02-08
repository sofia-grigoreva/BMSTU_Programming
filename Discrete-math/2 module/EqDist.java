import java.util.*;

public class EqDist {
    int n;
    List<List<Integer>> graph;
    List<Integer> op;
    Boolean[] mark;
    public EqDist(int n) {
        this.n = n;
        this.graph = new ArrayList<>();
        this.op = new ArrayList<>();
        for (int i = 0; i < n; i++)
            this.graph.add(new ArrayList<>());
        this.mark = new Boolean[n];
    }

    void addEdge(int u, int v) {
        graph.get(u).add(v);
        graph.get(v).add(u);
    }

    int[] BFS(int v1) {
        int dist[] = new int[n];
        for (int i = 0; i < n; i++) {
            mark[i] = false;
        }
        mark[v1] = true;
        dist[v1] = 0;
        Queue<Integer> q = new LinkedList<>();
        q.add(v1);
        while (!q.isEmpty()) {
            int v = q.poll();
            for (int j = 0; j < graph.get(v).size(); j++) {
                int u = graph.get(v).get(j);
                if (!mark[u]) {
                    mark[u] = true;
                    q.add(u);
                    dist[u] = dist[v] + 1;
                }
            }
        }
        return dist;
    }
     void equal (){
        List<Integer> ans = new ArrayList<>();
         List<int[]> dists = new ArrayList<>();
         for ( int j : op){
             dists.add(BFS(j));
         }
         for (int i = 0; i < n; i++){
            boolean t = true;
            int d = dists.get(0)[i];
            for (int j = 1; j < dists.size(); j++){
                if (d != dists.get(j)[i] || i == op.get(j) || d == 0){
                    t = false;
                    break;
                }
            }
            if (t){
                ans.add(i);
            }
        }
        if (ans.isEmpty()){
            System.out.println("-");
            return;
        }
        for (int i : ans){
            System.out.println(i);
        }
     }

    public static void main(String[] args) {
        Scanner scan = new Scanner(System.in);
        int n = scan.nextInt();
        int m = scan.nextInt();
        EqDist g = new EqDist(n);
        for (int i = 0, x, y; i < m; i++) {
            x = scan.nextInt();
            y = scan.nextInt();
            g.addEdge(x, y);
        }
        int k = scan.nextInt();
        for (int i = 0, x; i < k; i++) {
            x = scan.nextInt();
            g.op.add(x);
        }
        scan.close();
        g.equal();
    }
}
