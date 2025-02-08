public class Soldier implements Comparable<Soldier> {
    private String name;
    private int year;
    private String surname;
    private String fathername;
    private String rank;

    public Soldier(String rank, String surname, String name, String fathername, int year) {
        this.rank = rank;
        this.fathername = fathername;
        this.name = name;
        this.surname = surname;
        this.year = year;
    }
    public int Ranktoid() {
        if (this.rank == "General") return 0;
        if (this.rank == "Polkovnik") return 1;
        if (this.rank == "Podpolkovnik") return 2;
        if (this.rank == "Mayor") return 3;
        if (this.rank == "Kapitan") return 4;
        if (this.rank == "Leytenant") return 5;
        return 100;
    }

    public int compareTo(Soldier c) {
        if (this.Ranktoid() < c.Ranktoid())
            return -1;
        else if (this.Ranktoid()  > c.Ranktoid())
            return 1;
        else return 0;
    }

    public String toString() {
        return "Rank: " + this.rank + " " + "Surname: " + this.surname + " Name: " + this.name + " " + " Fathername: " + this.fathername + " Year of birth: " + this.year;
    }

  public static void main(String[] args) {
        Soldier[] s = new Soldier[]{
                new Soldier("General","Ivanov","Ivan","Ivanovich", 1999),
                new Soldier("Leytenant","Petrov","Petr","Petrovich", 2000),
                new Soldier("Kapitan","Sidorov","Alexey","Alecseevich", 1998),
        };
        Arrays.sort(s);
        for (Soldier c : s) System.out.println(c);
    }

}
