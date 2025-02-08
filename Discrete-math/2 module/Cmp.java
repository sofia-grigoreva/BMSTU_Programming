import java.util.*;

public class Cpm {
    static class Vertex implements Comparable<Vertex>{
        String name;
        int length;
        int sumlength;
        ArrayList<Vertex> child;
        String color;
        ArrayList<Vertex> parent;
        int T1;
        int comp;
        int low;
        int parent_count;
        public Vertex(String name,int length) {
            this.name = name;
            this.length = length;
            this.sumlength = length;
            this.color = "none";
            this.child = new ArrayList<>();
            this.T1 = 0;
            this.comp = 0;
            this.parent_count = 0;
            this.parent = new ArrayList<>();
        }

        public int compareTo(Vertex v){
            if (this.sumlength < v.sumlength){
                return 1;
            }
            else if (this.sumlength > v.sumlength){
                return -1;
            }
            return 0;
        }

        public String toString() {
            String s = "";
            for (Vertex i : parent){
                s += i.name;
            }
            return name + " " + length + " " + s + parent_count;
        }
    }
    
    List<Vertex> graph;
    int time, count;
    Stack<Vertex> stack;

    Cpm() {
        this.count = 1;
        this.time = 1;
        this.graph = new ArrayList<>();
    }

    boolean in(List<Vertex> a, String t){
        for (Vertex i : a){
            if (Objects.equals(i.name, t)){
                return true;
            }
        }
        return false;
    }

    int findind(String t){
        for (int i = 0; i < graph.size(); i++){
            if (Objects.equals(graph.get(i).name, t)){
                return i;
            }
        }
        return 0;
    }

    public void Tarjan() {
        stack = new Stack<>();
        for(Vertex v : graph) {
            if (v.T1 == 0)
                VisitVertex_Tarjan(v);
        }
    }
    
    public void VisitVertex_Tarjan(Vertex v) {
        v.T1 = time;
        v.low = time;
        time++;
        stack.push(v);
        for (Vertex u : v.child) {
            if (u.T1 == 0) {
                VisitVertex_Tarjan(u);
            }
            if (u.comp == 0 && v.low > u.low) {
                v.low = u.low;
            }
        }

        if (v.T1 == v.low) {
            List<Vertex> l = new ArrayList<>();
            while (true) {
                Vertex u = stack.pop();
                u.comp = count;
                l.add(u);
                if (Objects.equals(u.name, v.name)) {
                    break;
                }
            }

            if (l.size() > 1) {
                for (Vertex w : l) {
                    make_blue(w);
                }
            }

            if (l.size() == 1) {
                for (Vertex w : l.get(0).child)
                    if (Objects.equals(w.name, l.get(0).name))
                        w.color = "blue";
            }
            count++;
        }
    }

    void make_blue(Vertex v) {
        v.color = "blue";
        v.parent_count = -1;
        v.sumlength = 0;
        for (Vertex p : v.child) {
            if (!Objects.equals(p.color, "blue")) {
                make_blue(p);
            }
        }
    }
    public void BellmanFord() {
        Stack<Vertex> s = new Stack<>();
        for (Vertex v : graph) {
            if (v.parent_count == 0) {
                s.add(v);
            }
        }
        while (!s.isEmpty()) {
            Vertex v = s.pop();
            for(Vertex u : v.child) {
                if (u.parent_count >= 0) {
                    if (u.sumlength < v.sumlength + u.length) {
                        u.sumlength = v.sumlength + u.length;
                        u.parent.clear();
                        u.parent.add(v);
                    }
                    else if (u.sumlength == v.sumlength + u.length) {
                        u.parent.add(v);
                    }
                    u.parent_count--;
                    if (u.parent_count == 0)
                        s.add(u);
                }
            }
        }
    }
    
    void make_red(Vertex v){
        v.color = "red";
        for (Vertex p : v.parent){
            make_red(p);
        }
    }

    void red(){
        Vertex[] g = graph.toArray(new Vertex[0]);
        Arrays.sort(g);
        for (int i = 0; i < graph.size(); i++){
            if (g[0].sumlength != g[i].sumlength){
                break;
            }
            if (!Objects.equals(graph.get(findind(g[i].name)).color, "blue")) {
                make_red(graph.get(findind(g[i].name)));
            }
        }

    }

    public static void main(String[] args) {
        Scanner in = new Scanner(System.in);
        String s = "";
        ArrayList<String> input = new ArrayList<>();
        boolean end = false;

        while (in.hasNextLine()) {
            s += in.nextLine().replaceAll(" ", "");
            if (s.charAt(s.length()-1) != ';' && s.charAt(s.length()-1) != '<') {
                end = true;
            } else if (s.charAt(s.length()-1) == ';'){
                s = s.substring(0, s.length() - 1);
            }
            if (s.charAt(s.length()-1) != '<'){
                input.add(s);
                s = "";
            }
            if (end){
                break;
            }
        }

        Cpm c = new Cpm();
        c.graph = new ArrayList<>();

        for (String i : input){
            String[] str = i.split("<");
            ArrayList<String> t1 = new ArrayList<>(Arrays.asList(str[0].split("\\(|\\)")));
            if (t1.size() != 1){
                Vertex v = new Vertex(t1.get(0), Integer.parseInt(t1.get(t1.size() - 1)));
                c.graph.add(v);
            }
            for (int j = 1; j < str.length; j++){
                ArrayList<String> t = new ArrayList<>(Arrays.asList(str[j].split("\\(|\\)")));
                if (t.size() == 1 && !c.in(c.graph.get(c.findind(Arrays.asList(str[j - 1].split("\\(|\\)")).get(0))).child, t.get(0))){
                   c.graph.get(c.findind(Arrays.asList(str[j - 1].split("\\(|\\)")).get(0))).child.add(c.graph.get(c.findind(t.get(0))));
                   c.graph.get(c.findind(t.get(0))).parent_count++;
                } else if (t.size() != 1){
                    Vertex v = new Vertex(t.get(0), Integer.parseInt(t.get(t.size() - 1)));
                    c.graph.add(v);
                    if (!c.in(c.graph.get(c.findind(Arrays.asList(str[j - 1].split("\\(|\\)")).get(0))).child, v.name)) {
                        v.parent_count++;
                        c.graph.get(c.findind(Arrays.asList(str[j - 1].split("\\(|\\)")).get(0))).child.add(v);
                    }
                }
            }
        }


        c.Tarjan();
        c.BellmanFord();
        c.red();

        System.out.println("digraph {");
        for (Vertex v : c.graph) {
            System.out.print("  ");
            System.out.print(v.name);
            System.out.print(" [label = \"");
            System.out.print(v.name );
            System.out.print("(");
            System.out.print(v.length);
            System.out.print(")\"");
            if (!Objects.equals(v.color, "none")) {
                System.out.print(", color = ");
                System.out.print(v.color);

            }
            System.out.println("]");
        }

        for (Vertex v : c.graph) {
            for (Vertex u : v.child) {
                System.out.print("  ");
                System.out.print(v.name);
                System.out.print(" -> ");
                System.out.print(u.name);
                if (Objects.equals(v.color, u.color) && (!Objects.equals(v.color, "none")) && (u.parent.contains(v) || Objects.equals(v.color, "blue")))
                {
                    System.out.print(" [color = ");
                    System.out.print(v.color);
                    System.out.print("]");
                }
                System.out.println();
            }
        }
        System.out.println("}");
    }
}
