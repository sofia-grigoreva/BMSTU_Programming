import java.util.*;

public class GraphBase {
    List<List<Integer>> graph;
    List<List<Integer>> base;
    int n, time, count;
    Stack<Integer> stack;
    int T1[];
    int low[];
    int comp[];
    boolean mark[];
    int min[];

    GraphBase(int n) {
        this.n = n;
        this.count = 1;
        this.time = 1;
        this.graph = new ArrayList<>(n);
        for (int i = 0; i < n; i++)
            this.graph.add(new ArrayList<>());
        this.comp = new int[n];
        this.T1 = new int[n];
        this.low = new int[n];
    }

    void addEdge(int u, int v) {
        graph.get(u).add(v);
    }

    public void Tarjan() {
        stack = new Stack<>();
        for (int i = 0; i < n; i++) {
            if (T1[i] == 0) {
                VisitVertex_Tarjan(i);
            }
        }
    }

    public void VisitVertex_Tarjan(int v) {
        T1[v] = time;
        low[v] = time;
        time++;
        stack.push(v);
        for (int u : graph.get(v)) {
            if (T1[u] == 0) {
                VisitVertex_Tarjan(u);
            }
            if (comp[u] == 0 && low[v] > low[u]) {
                low[v] = low[u];
            }
        }
        if (T1[v] == low[v]) {
            while (true) {
                int u = stack.pop();
                comp[u] = count;
                if (u == v) {
                    break;
                }
            }
            count++;
        }
    }

    public void Base() {
        base = new ArrayList<>();
        for (int i = 0; i < count; i++)
            base.add(new ArrayList<>());
        mark = new boolean[count];
        min = new int[count];
        Arrays.fill(mark, true);
        for (int i = 0; i < n; i++) {
            if (base.get(comp[i]).isEmpty()) {
                min[comp[i]] = i;
            }
            base.get(comp[i]).add(i);
        }

        for (int i = 0; i < n; i++) {
            for (int j : graph.get(i)) {
                if (comp[i] != comp[j])
                    mark[comp[j]] = false;
            }
        }

        for (int i = 1; i < count; i++) {
            if (mark[i]) {
                System.out.print(min[i] + " ");
            }
        }
    }

    public static void main(String[] args) {
        Scanner scan = new Scanner(System.in);
        int n = scan.nextInt();
        int m = scan.nextInt();
        GraphBase graph = new GraphBase(n);
        for (int i = 0; i < m; i++) {
            int x = scan.nextInt();
            int y = scan.nextInt();
            graph.addEdge(x, y);
        }
        graph.Tarjan();
        graph.Base();

    }
}
