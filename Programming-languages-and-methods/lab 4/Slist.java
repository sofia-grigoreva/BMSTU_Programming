import java.util.Iterator;
public class Slist implements Iterable {
    private StringBuilder s;
    public Slist ( StringBuilder s ){
        this.s = s;
    }

    public Iterator iterator(){
        return new SIterator();
    }
    private class SIterator implements Iterator{
        private int ind;
        private int l;
        public SIterator () {
            ind = 0;
            l = 1;
        }

        public boolean hasNext (){
            return l <= s.length();
        }

        public String next (){
        int i = ind;
        int len = l;
        ind++;
        if (ind+l > s.length())
        {ind = 0; l++;}
        return s.substring(i, i+len);
        }
    }
}
