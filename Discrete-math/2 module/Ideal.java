import java.util.*;

public class Ideal {
    static class Edge {
        int v1;
        int color;
        int v2;
        Edge(int num, int color) {
            this.v1 = num;
            this.color = color;
            this.v2 = -1;
        }
    }

    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        int n = input.nextInt();
        int m = input.nextInt();

        int[] length = new int[n];
        List<List<Edge>> graph = new ArrayList<>();

        for (int i = 0; i < n; i++){
            graph.add(new ArrayList<>());
        }

        Arrays.fill(length, 10000000);

        for (int i = 0; i < m; i++) {
            int x = input.nextInt() - 1;
            int y = input.nextInt() - 1;
            int color = input.nextInt();
            graph.get(x).add(new Edge(y, color));
            graph.get(y).add(new Edge(x, color));
        }

        int start = n - 1;
        int end = 0;
        length[n - 1] = 0;

        Queue<Integer> q1 = new LinkedList<>();
        Queue<Integer> q2 = new LinkedList<>();
        Queue<Integer> q3 = new LinkedList<>();

        q1.add(start);

        while (!q1.isEmpty()) {
            int ind = q1.remove();
            for (Edge e : graph.get(ind)){
                if (length[e.v1] > length[ind] + 1) {
                    length[e.v1] = length[ind] + 1;
                    q1.add(e.v1);
                }
            }
        }

        System.out.println(length[end]);

        q1.add(end);
        q2.add(end);

        for (int i = 0; i < length[end]; i++) {
            int min = 10000000;

            while (!q1.isEmpty()) {
                int ind = q1.remove();
                for (Edge e : graph.get(ind)){
                    if (length[e.v1] == length[ind] - 1 && e.color < min) {
                        min = e.color;
                    }
                }
            }

            while (!q2.isEmpty()) {
                int ind = q2.remove();
                for (Edge e : graph.get(ind)) {
                    if (length[e.v1] == length[ind] - 1 && e.color == min) {
                        q3.add(e.v1);
                    }
                }
            }

            System.out.print(min + " ");
            while (!q3.isEmpty()) {
                int ind = q3.remove();
                q1.add(ind);
                q2.add(ind);
            }
        }
    }
}
