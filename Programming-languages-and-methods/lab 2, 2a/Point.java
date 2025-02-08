import static java.lang.Math.*;
public class Point
{
    private double xspeed;
    private double yspeed;
    private double zspeed;
    private static int n;
    public static int val;

    public void setCoord(double varX, double varY, double varZ)
    {
        this.xspeed=varX;
        this.yspeed=varY;
        this.zspeed=varZ;
    }
    public double getXspeed()
    {
        return this.xspeed;
    }
    public double getYspeed()
    {
        return this.yspeed;
    }
    public double getZspeed()
    {
        return this.zspeed;
    }
}
