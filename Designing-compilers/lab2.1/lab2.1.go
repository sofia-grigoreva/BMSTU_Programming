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
