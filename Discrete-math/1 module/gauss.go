package main
import (
	"fmt"
)

func gcd(a int , b int) int{
    if (b == 0){
        return a
    }else {
        return gcd (b, a % b)
    }
}
        
        
func socr (a [2]int) [2]int {
    c, z := a[0], a[1]
    
    if (c == 0 || z == 0){
        c = 0
        z = 1
        return [2]int{c, z}
    }
    
    var g int= gcd(c,z)
    c /=g;
    z /=g;
    
    if (z < 0){
        c*= -1;
        z *= -1;
    }
    return [2]int{c, z}
}


func main() {
    var n int
	fmt.Scan(&n)
	
	var m [5][6][2]int
	var ans [5][2]int
	
	for i := 0; i < n; i++ {
		for j := 0; j < n + 1; j++ {
			fmt.Scan(&m[i][j][0])
			m[i][j][1]=1;
		}
	}
	
	var d [2]int
	var p [2]int
	if (m[0][0][0] == 0){
	    for j := 0; j < n + 1; j++ {
	        m[0][j][0], m[1][j][0] = m[1][j][0], m[0][j][0]
	        m[0][j][1], m[1][j][1] = m[1][j][1], m[0][j][1]
	    }
	}
	for k:=0; k < n - 1; k++ {
	    for i := k + 1; i < n; i++ {
	        if (m[i][k][0] == 0){
	            continue
	        }
	        d[0]= m[i][k][0] * m[k][k][1];
	        d[1]= m[i][k][1] * m[k][k][0];
	        
            for j := 0; j < n + 1; j++ {
                p[0]= m[k][j][0] * d[0]
                p[1] = m[k][j][1] * d[1]
                m[i][j][0] = m[i][j][0]*p[1] - p[0]*m[i][j][1]
                m[i][j][1] *= p[1]
                //fmt.Print(m[i][j][0],"/",m[i][j][1], " ")
                m[i][j]=socr(m[i][j])
                //fmt.Println(m[i][j][0],"/",m[i][j][1], " ")
            }
        }
	}
	 
    var a [2]int
    for i:= n - 1; i >= 0; i--{
        a[0]=m[i][n][0]
        a[1]=m[i][n][1]
        for k:= i + 1; k < n; k++{
            a[0]= a[0]*m[i][k][1] *ans[k][1]- m[i][k][0]*ans[k][0]*a[1]
            a[1]*= m[i][k][1] *ans[k][1]
        }
        
        ans[i][0]=a[0] * m[i][i][1]
        ans[i][1]=a[1] * m[i][i][0]
        ans[i]=socr(ans[i])
    }
    
    for i := 0; i < n; i++ {
	    if (ans[i][0] == 0){
	        fmt.Print("No solution")
	        return
	    }
    }

    for i := 0; i < n; i++ {
	fmt.Print(ans[i][0])
        fmt.Print("/")
        fmt.Println(ans[i][1])
    }
	
}
