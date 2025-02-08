import static java.lang.Math.sqrt;
public class Circle implements Comparable<Circle> {
    private double x;
    private double y;
    private double r;
    public Circle(double x, double y, double r) {
        this.x = x;
        this.y = y;
        this.r = r;
    }
    public int Zcount() {
        int count = 0;
        for (double x1 = this.x + 1; x1 < this.x + this.r; x1++){
            for (double y1 = this.y; y1 < this.y + this.r; y1++){
                if (Math.sqrt(Math.pow((x1 - this.x),2) + Math.pow((y1 - this.y),2)) < this.r)
                    count++;
            }
        }
        return 4*count+1;
    }

    public int compareTo(Circle c) {
        if (this.Zcount() < c.Zcount())
            return -1;
        else if (this.Zcount()  > c.Zcount() )
            return 1;
        else return 0;
    }

    public String toString() {
        return "Radius: " + r + " " + "Center coordinates: " + x + " " + y + " Integer points: " + this.Zcount();
    }

      public static void main(String[] args) {
        Circle[] a = new Circle[]{
                new Circle(0,0,2),
                new Circle(2,3,4),
                new Circle(1,2,3),

        };
        Arrays.sort(a);
        for (Circle c : a) System.out.println(c);
    }

}
