import java.util.*;
public class Vlist implements Iterable {
    private int n;
    private List<List<Integer>> v;
    public Vlist (List<List<Integer>> v, int n){
        this.v = v;
        this.n = n;
    }
    public boolean Ort(List<Integer> a , List<Integer> b){
        int p = 0;
        for (int i =0 ; i < n; i++){
            p+=a.get(i)*b.get(i);
        }
        return p == 0;
    }

    public Iterator iterator(){
        return new VIterator();
    }
    private class VIterator implements Iterator{
        private int ind;
        private int max;
        public VIterator () {
            ind = 0;
            for (int i = 0; i < v.size(); i++){
                int j = 1;
                int c = 1;
                while ((j+i < v.size()) && (Ort(v.get(i+j-1), v.get(i+j)))){
                    c++;
                    j++;
                }
                if (c > max) max = c;
            }
        }

        public boolean hasNext (){
            if (ind>=v.size()){ return false;}
            int i;
            for (i = ind; i < v.size(); i++){
                int t  = 1;
                for (int j = 1; j < max; j++){
                    if (j+i >= v.size()) break;
                    if (!Ort(v.get(i+j-1), v.get(i + j))) break;
                    t++;
                }
                if (t == max) return true;
            }
                return false;
        }

        public List<List<Integer>> next(){
            int i;
            int end=0;
            List<List<Integer>> v1 = new ArrayList<>();
            for (i = ind; i < v.size(); i++){
                v1 = new ArrayList<>();
                v1.add(v.get(i));
                for (int j = 1; j < max; j++){
                    if (!Ort(v.get(i+j-1), v.get(i + j))) break;
                    v1.add(v.get(i+j));
                    end=i+j;
                }
                if (v1.size() == max) break;
            }
            ind=end + 1;
            return v1;
        }

    }
}
