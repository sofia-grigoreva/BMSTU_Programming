package main

import (
	"html/template"
	"log"
	"net/http"
)

type Data struct {
	Menu    []string
	Content string
}

func HomeRouterHandler(w http.ResponseWriter, r *http.Request) {

	selected := r.URL.Query().Get("menu")

	var content string
	switch selected {
	case "lime":
		content = "green"
	case "lemon":
		content = "yellow"
	case "apple":
		content = "red"
	default:
		content = "fruits"
	}

	data := Data{
		Menu:    []string{"lime", "lemon", "apple"},
		Content: content,
	}

	tmpl, err := template.ParseFiles("index.html")
	if err != nil {
		log.Fatal(err)
	}

	err = tmpl.Execute(w, data)
	if err != nil {
		log.Fatal(err)
	}
}

func main() {
	http.HandleFunc("/", HomeRouterHandler)
	err := http.ListenAndServe(":9000", nil)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}
