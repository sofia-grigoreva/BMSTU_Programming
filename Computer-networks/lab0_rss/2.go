package main

import (
	"fmt"

	"github.com/SlyMarbo/rss"
)

func main() {
	feed, err := rss.Fetch("https://news.rambler.ru/rss/Ivanovo/")
	if err != nil {
		fmt.Println("Error fetching RSS feed:", err)
		return
	}

	fmt.Printf("Title: %s\n", feed.Title)
	fmt.Printf("Description: %s\n", feed.Description)
	fmt.Printf("Link: %s\n", feed.Link)
	fmt.Printf("Language: %s\n", feed.Language)

	fmt.Println("\nItems:")
	for _, item := range feed.Items {
		fmt.Printf("Title: %s\n", item.Title)
		fmt.Printf("Link: %s\n", item.Link)
		fmt.Println("---------------------")
	}
}
