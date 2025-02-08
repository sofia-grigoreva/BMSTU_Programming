public class Listelem {
    public int value;
    public Listelem next;
    public Listelem(int v){
        this.value = v;
        this.next = null;
    }

    public void Append(int v){
        if (this.next == null) {
            this.next = new Listelem(v);
        }
        else {
            this.next.Append(v);
        }
    }

    public String toString(){
        String str = "";
        str+=value + " ";
        Listelem e = next;
        while (e != null){
            str+=e.value + " ";
            e = e.next;
        }
        return str;
    }

    public static void main(String[] args) {
        Listelem e = new Listelem(10);
        e.Append(9);
        e.Append(8);
        e.Append(7);
        e.Append(6);
        e.Append(100000);
        System.out.println(e);
    }

}
