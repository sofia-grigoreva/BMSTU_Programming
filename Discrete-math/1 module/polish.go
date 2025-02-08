package main
import (
    "fmt"
    "strings"
    "bufio"
    "os"
    )

func stringtonumber (c string) int {
	s := "0123456789"
    for i := 0; i < len(s); i++ {
        if (string(s[i]) == c){
            return i
        }
    }
    return 0
}

func isnumber (c string) bool {
	s := "0123456789"
    for i := 0; i < len(s); i++ {
        if (string(s[i]) == c){
            return true
        }
    }
    return false
}

func next(exp string, num int) string{
    var ind int = 0
    a := ""
    for j:= 0; j < num; j++{
        a = ""
        startbracket := 0
        endbracket := 0
        for i:= ind; i< len(exp); i++{
            
            if string(exp[i]) == "("{
                startbracket++
            }
            
            if (startbracket == 0 && isnumber(string(exp[i]))){
                 a+=string(exp[i])
                 ind = i + 1
                 break
            }
            
            if (startbracket > 0){
                a+=string(exp[i])
            }
            
            if string(exp[i]) == ")"{
                endbracket++
                if endbracket == startbracket{
                    ind = i + 1
                    break
                } 
            }
        }
    }
    return a
}

func polishexp(exp string) int {
    if strings.HasPrefix(exp, "("){
        exp = exp[1:]
    }else {
        return  stringtonumber(exp)
    }
    value := applysignoperator (string(exp[0]), polishexp(next(exp,1)), polishexp(next(exp,2)))
    return value
}


func applysignoperator(signoperator string, num1 int, num2 int) int {
    if (signoperator == "+"){
        return num1 + num2
    }else if (signoperator == "-"){
        return num1 - num2
    }
    return num1 * num2
}


func main() {
    myscanner := bufio.NewScanner(os.Stdin)
    myscanner.Scan()
    exp := myscanner.Text()
    fmt.Println(polishexp(exp))
}
