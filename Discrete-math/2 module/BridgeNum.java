import java.util.*;

public class BridgeNum {
    public int n;
    public List<List<Integer>> graph;
    public int time;
    boolean[] mark;
    int[] T1;
    int[] low;
    int[] parent;
    int bridgecount;
    public BridgeNum (int n) {
        this.n = n;
        this.graph = new ArrayList<>();
        for (int i = 0; i < n; i++)
            this.graph.add(new ArrayList<>());
        this.time = 0;
        this.mark= new boolean[n];
        this.T1= new int[n];
        this.low= new int[n];
        this.parent= new int[n];
        this.bridgecount = 0;

    }
    void addEdge(int u, int v) {
        graph.get(u).add(v);
        graph.get(v).add(u);
    }
    void VisitVertex(int u, int c) {
        mark[u] = true;
        T1[u] = low[u] = time++;
        for (int v : graph.get(u)) {
            if (!mark[v]) {
                parent[v] = u;
                VisitVertex(v, c);
                low[u] = Math.min(low[u], low[v]);
                if (low[v] > T1[u])
                    bridgecount++;
            } else if (v != parent[u])
                low[u] = Math.min(low[u], T1[v]);
        }
    }
    void bridgecounter() {
        for (int i = 0; i < n; ++i) {
            parent[i] = -1;
            mark[i] = false;
        }
        for (int i = 0; i < n; ++i)
            if (!mark[i])
                VisitVertex(i, 0);
    }

    public static void main(String[] args) {
        Scanner scan = new Scanner(System.in);
        int n = scan.nextInt();
        int m = scan.nextInt();
        BridgeNum  g = new BridgeNum (n);
        for (int i = 0, x, y; i < m; i++) {
            x = scan.nextInt();
            y = scan.nextInt();
            g.addEdge(x, y);
        }
        g.bridgecounter();
        System.out.print(g.bridgecount);

    }
}
