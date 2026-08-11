% Лабораторная работа № 2.1. Синтаксические деревья
% 17 февраля 2026 г.
% Софья Григорьева, ИУ9-61Б

# Цель работы
Целью данной работы является изучение представления синтаксических деревьев в памяти компилятора и 
приобретение навыков преобразования синтаксических деревьев.

# Индивидуальный вариант
Заменить вызов функции assert(expr) на конструкцию if ! expr { fmt.Println("filename.go:NN:assertion failed"); }, где вместо filename.go и NN должны находиться имя файла и номер строки с assert.

# Реализация

Демонстрационная программа:

```go
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
```

Программа, осуществляющая преобразование синтаксического дерева:

```go
package main

import (
    "fmt"
	"go/ast"
	"go/format"
	"go/parser"
	"go/token"
	"os"
	"strconv"
)

func replaceAssert(fset *token.FileSet, file *ast.File) {
	ast.Inspect(file, func(node ast.Node) bool {
		block, ok := node.(*ast.BlockStmt)
		if !ok {
			return true
		}

		for i, stmt := range block.List {
			
			exprStmt, ok := stmt.(*ast.ExprStmt)

			if !ok {
				continue
			}

			call, ok := exprStmt.X.(*ast.CallExpr)

			if !ok {
				continue
			}

			ident, ok := call.Fun.(*ast.Ident)

			if !ok || ident.Name != "assert" {
				continue
			}

			if len(call.Args) != 1 {
				continue
			}

			pos := fset.Position(call.Pos())
			filename := pos.Filename
			line := pos.Line

			msg := fmt.Sprintf("%s:%d:assertion failed", filename, line)

			newIf := &ast.IfStmt{
				Cond: &ast.UnaryExpr{
					Op: token.NOT,
					X:  call.Args[0],
				},
				Body: &ast.BlockStmt{
					List: []ast.Stmt{
						&ast.ExprStmt{
							X: &ast.CallExpr{
								Fun: &ast.SelectorExpr{
									X:   ast.NewIdent("fmt"),
									Sel: ast.NewIdent("Println"),
								},
								Args: []ast.Expr{
									&ast.BasicLit{
										Kind:  token.STRING,
										Value: strconv.Quote(msg),
									},
								},
							},
						},
					},
				},
			}

			block.List[i] = newIf
		}

		return true
	})
}


func main() {
	if len(os.Args) != 2 {
		return
	}

	fset := token.NewFileSet()
	if file, err := parser.ParseFile(fset, os.Args[1], nil, parser.ParseComments); err == nil {

		replaceAssert(fset, file)

		if format.Node(os.Stdout, fset, file) != nil {
			fmt.Printf("Formatter error: %v\n", err)
		}
		//ast.Fprint(os.Stdout, fset, file, nil)
	} else {
		fmt.Printf("Errors in %s\n", os.Args[1])
	}
}
```

# Тестирование

Результат трансформации демонстрационной программы:

```go
package main

func assert(condition bool) {
        if !condition {
                panic("assertion failed")
        }
}

func main() {
        x := 8
        y := 3
        if !(x > y) {
                fmt.Println("test.go:12:assertion failed")
        }
        if !(x < y) {
                fmt.Println("test.go:13:assertion failed")
        }
}
```

# Вывод
В ходе выполнения лабораторной работы изучены принципы представления синтаксических деревьев в памяти компилятора Go. 
Освоены методы обхода, анализа и преобразования узлов AST. 
Реализовано преобразование синтаксического дерева с последующим изменением исходного кода тестовой программы.