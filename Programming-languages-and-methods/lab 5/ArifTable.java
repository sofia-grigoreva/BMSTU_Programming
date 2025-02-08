import java.util.ArrayList;
import java.util.Optional;
import java.util.stream.IntStream;
import java.util.stream.Stream;
public class ArifTable {

  public class arifp {
    int a0, d;
    arifp(int a0, int d){
        this.a0 = a0;
        this.d =d;
    }
    public boolean in (int x){
        if((x - a0) % d == 0 && (x - a0) > 0){
            return true;
        }
        return false;
    }

    public String toString() {
        return a0 + " " + d;
    }
}
    ArrayList<arifp> Table;
    ArifTable() {
        Table = new ArrayList<arifp>();
    }
    void add(arifp p) {
        Table.add(p);
    }
    public Stream<Double> Stream(int y, int n) {
        ArrayList<Double> result = new ArrayList<>();
        Table.stream().filter(x -> x.in(y)).forEach(x -> result.add((double) (((2 * x.a0 + x.d * (n - 1)) * n) / 2)));
        return result.stream();
    }
    public Optional<arifp> getawith2(int n) {
        ArrayList<arifp> result = new ArrayList<>();
        IntStream.range(0, Table.size()).forEach(i->
                    IntStream.range(0, Table.get(i).a0 + (n-1)*Table.get(i).d + 1)
                            .forEach(j->{
                                    if(Table.get(i).in((int) Math.pow(2, j))){
                                        result.add(Table.get(i));
                                        }
                                    }));
        if (result.size() > 0) {
            return Optional.ofNullable(result.get(0));
        }
        return Optional.empty();
    }

  public static void main(String[] args) {
        ArifTable t = new ArifTable();
        t.add(new arifp(5, 5));
        t.add(new arifp(7, 2));
        t.add(new arifp(3, 4));
        t.add(new arifp(6, 3));
        t.Stream(9,1).forEach(System.out::println);
        System.out.println("-------------");
        System.out.println(t.getawith2(5));
        t.add(new arifp(1, 1));
        System.out.println(t.getawith2(5));
    }

    }
