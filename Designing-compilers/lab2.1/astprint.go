package main

import (
	"fmt"
	"go/ast"
	"go/format"
	"go/parser"
	//"go/printer"
	"go/token"
	"os"
)

func insertHello(file *ast.File) {
	ast.Inspect(file, func(node ast.Node) bool {
		if ifStmt, ok := node.(*ast.IfStmt); ok {
			ifStmt.Body.List = append(
				[]ast.Stmt{
					&ast.ExprStmt{
						X: &ast.CallExpr{
							Fun: &ast.SelectorExpr{
								X:   ast.NewIdent("fmt"),
								Sel: ast.NewIdent("Printf"),
							},
							Args: []ast.Expr{
								&ast.BasicLit{
									Kind:  token.STRING,
									Value: "\"hello\"",
								},
							},
						},
					},
				},
				ifStmt.Body.List...,
			)
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
		insertHello(file)

		if format.Node(os.Stdout, fset, file) != nil {
			fmt.Printf("Formatter error: %v\n", err)
		}
		//ast.Fprint(os.Stdout, fset, file, nil)
	} else {
		fmt.Printf("Errors in %s\n", os.Args[1])
	}
}
