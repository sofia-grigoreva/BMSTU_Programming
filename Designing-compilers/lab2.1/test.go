package main

func assert(condition bool) {
    if !condition {
        panic("assertion failed")
    }
}

func main() {
    x := 8
    y := 3
    assert(x > y)
    assert(x < y)
}