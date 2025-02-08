import java.util.ArrayList;
import java.util.List;

public class Matr {
    List<List<Integer>> m;

    public Matr(List<List<Integer>> data) {
        this.m = data;
    }

    public Matr sum(Matr a, Matr b) {
        List<List<Integer>> sum = new ArrayList<>();
        for (int i = 0; i < a.m.size(); i++) {
            sum.add(new ArrayList<>());
            for (int j = 0; j < a.m.get(0).size(); j++) {
                sum.get(i).add(a.m.get(i).get(j) + b.m.get(i).get(j));
            }
        }
        return new Matr(sum);
    }

    public Matr pr(Matr a, Matr b) {
        List<List<Integer>> p = new ArrayList<>();

        for (int i = 0; i < a.m.size(); i++) {
            p.add(new ArrayList<>());
            for (int j = 0; j < b.m.get(0).size(); j++) {
                int sum = 0;
                for (int k = 0; k < a.m.get(0).size(); k++) {
                    sum += a.m.get(i).get(k) * b.m.get(k).get(j);
                }
                p.get(i).add(sum);
            }
        }
        return new Matr(p);
    }

    public static void main(String[] args) {
        List<List<Integer>> sum = new ArrayList<>();
        sum.add(new ArrayList<>());
        sum.add(new ArrayList<>());
        sum.get(0).add(1);
        sum.get(0).add(2);
        sum.get(1).add(1);
        sum.get(1).add(2);

        Matr a = new Matr(sum);

        List<List<Integer>> sum2 = new ArrayList<>();
        sum2.add(new ArrayList<>());
        sum2.add(new ArrayList<>());
        sum2.get(0).add(3);
        sum2.get(0).add(3);
        sum2.get(1).add(3);
        sum2.get(1).add(3);
        Matr b = new Matr(sum2);

        System.out.println(a.pr(a, b).m);
        System.out.println(a.sum(a, b).m);
    }
}
