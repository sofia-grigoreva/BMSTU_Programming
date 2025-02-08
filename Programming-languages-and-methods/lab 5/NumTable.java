import java.util.ArrayList;
import java.util.Comparator;
import java.util.Optional;
import java.util.stream.IntStream;
import java.util.stream.Stream;
public class NumTable {
    ArrayList<Double> Table;
    NumTable() {
        Table = new ArrayList<Double>();
    }
    void add(double p) {
        Table.add(p);
    }

    private boolean in(double p) {
        for (double n : Table) {
            if (p == n) {
                return true;
            }
        }
        return  false;
    }

    public Stream<Double> Stream(double k) {
        ArrayList<Double> result = new ArrayList<>();
        Table.stream().forEach(x -> {
        for (double i = 1; i < x; i++) {
            if (x%i == 0 && this.in(Math.pow(i,k))) {
                result.add(x);
                break;
            }}});
        return result.stream();
    }
    public Optional<Double> findX() {

        ArrayList<Double> sorted = new ArrayList<>();
        ArrayList<Double> trash = new ArrayList<>();

        IntStream.range(0, Table.size()).forEach(i->
                    IntStream.range(0, Table.size())
                            .forEach(j->{
                                if(i != j){
                                    if(Table.get(i) <= Table.get(j)){
                                        if(Table.get(j) % Table.get(i) == 0){
                                            if(!sorted.contains(Table.get(i))){
                                                sorted.add(Table.get(i));
                                            }
                                        }else{
                                            if(!trash.contains(Table.get(i))){
                                                trash.add(Table.get(i));
                                            }
                                        }
                                    }
                                }
                            }));

        Optional<Double> result = Optional.empty();
        Optional<Double> tmp = sorted.stream().filter(e -> !trash.contains(e)).min(Comparator.naturalOrder());
        if (tmp.isPresent()) {
            result = Optional.ofNullable(tmp.get());
        }
        return result;
    }

      public static void main(String[] args) {
        NumTable t = new NumTable();
        t.add(4);
        t.add(8);
        t.add(16);
        t.add(20);
        t.add(24);
        t.Stream(3).forEach(System.out::println);
        System.out.println("-------------");
        System.out.println(t.findX());
        t.add(25);
        System.out.println(t.findX());
    }

}
