package main
func add(a, b []int32, p int) []int32 {
    k:=0
    if (len (a) < len (b)){
        a,b = b,a;
    }
    sum := make([]int32, 0)
    for i := 0; i < len(b); i++{
         c := int(a[i]+b[i])+k
         if c>=p {
            k = 1;
            sum = append(sum, int32(c%p))
        }else {
            k=0
            sum = append(sum, int32(c))
        }
    }
    for i := len(b); i < len(a); i++{
         c := int(a[i])+k
         if c>=p {
            k = c/p;
            sum = append(sum, int32(c%p))
        }else {
            k=0
            sum = append(sum, int32(c))
        }
    }
    if k > 0{
        sum = append(sum, 1)
    }
    return sum;
}


func main() {
}
