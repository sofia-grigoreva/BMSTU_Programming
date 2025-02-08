package main
import (
    "fmt"
    "strings"
    "bufio"
    "os"
    )

func expression (exp string, ind int) string {
    s:=""
    startbracket := 0
    endbracket := 0
    for i := ind; i>=0; i-- {
        s= string(exp[i]) + s
        if string(exp[i]) == ")" {
            endbracket++
        }
        if string(exp[i]) == "("{
            startbracket++
            if (startbracket == endbracket){
                break
            }
        }
    }
    return s
}

func econom(exp string) int{
    var value int = 0
    var s string = ""
    c:=""
    for i:= 0; i < len(exp); i++{
        if string(exp[i]) == ")"{
            c = expression(exp, i)
            if !strings.Contains(s,"/" + c){
                value+=1
                s+="/"+c
            }
        }
    }
    return value
}

func main() {
    myscanner := bufio.NewScanner(os.Stdin)
    myscanner.Scan()
    exp := myscanner.Text()
    fmt.Println(econom(exp))
}
