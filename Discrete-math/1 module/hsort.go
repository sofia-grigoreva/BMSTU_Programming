package main

func Heapify(
           less func(i, j int) bool,
           swap func(i, j int), i int, n int) {
    for {
        l := 2 * i + 1 
        r := l + 1 
        j := i
        if l < n && less(i,l){
            i = l
        }
        if r < n && less(i,r){
            i = r
        }
        if i == j {
            break
        }
        swap(i,j)
    }
}

func BuildHeap(n int,
           less func(i, j int) bool,
           swap func(i, j int)) {
    i:= n/2 - 1 
    for i >= 0 {
        Heapify(less, swap, i, n)
        i--
    }
}

func hsort(n int,
           less func(i, j int) bool,
           swap func(i, j int)) {
    BuildHeap (n, less, swap)
    i := n - 1;
    for i > 0 {
        swap(0,i)
         Heapify(less, swap, 0, i)
        i--
    }
}

func main() {
}
