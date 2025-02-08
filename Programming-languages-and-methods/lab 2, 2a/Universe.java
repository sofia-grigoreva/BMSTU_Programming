import java.util.Random;

public class Universe {
    private Point [] planets;
    private int planetnum;
    public Universe (int n){
        Random random = new Random();
        this.planetnum = n;
        this.planets = new Point[n];
        for (int i = 0; i < n; i++){
            this.planets[i] = new Point();
            this.planets[i].setCoord(random.nextDouble(-1000, 1000),
                    random.nextDouble(-1000,1000),
                    random.nextDouble(-1000,1000));
        }
    }
    public void MidVect(){
        double x = 0;
        double y = 0;
        double z = 0;
        for (int i = 0; i < planetnum; i++){
            x+= this.planets[i].getXspeed();
            y+= this.planets[i].getYspeed();
            z+= this.planets[i].getZspeed();
        }
        System.out.println("(" + x/planetnum + ", "+ y/planetnum + ", "+ z/planetnum + ")");
    }
}
