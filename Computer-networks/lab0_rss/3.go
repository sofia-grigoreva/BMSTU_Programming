package main

import (
	"fmt"
	"html/template"
	"log"
	"net/http"

	"github.com/SlyMarbo/rss"
)

type Data struct {
	Title       string
	Description string
	Link        string
	List        []Article
}

type Article struct {
	Title string
	Link  string
}

func HomeRouterHandler(w http.ResponseWriter, r *http.Request) {

	feed, err := rss.Fetch("https://news.rambler.ru/rss/Ivanovo/")

	if err != nil {
		fmt.Println("Error fetching RSS feed:", err)
		return
	}

	var Articles []Article

	for _, item := range feed.Items {
		Articles = append(Articles, Article{Title: item.Title, Link: item.Link})
	}

	data := Data{
		Title:       feed.Title,
		Description: feed.Description,
		Link:        feed.Link,
		List:        Articles,
	}

	tmpl, err := template.ParseFiles("index2.html")
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
	err := http.ListenAndServe(":2727", nil)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}
