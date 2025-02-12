package main

import (
	"database/sql"
	"fmt"
	"log"
	"time"

	"github.com/SlyMarbo/rss"
	_ "github.com/go-sql-driver/mysql"
)

// Параметры доступа к базе данных:
// ◦ adminer: http://students.yss.su/adminer/
// ◦ host: students.yss.su
// ◦ db: iu9networkslabs
// ◦ login: iu9networkslabs
// ◦ passwd: Je2dTYr6
// net4.yss.su
// IP-адрес сервера: 185.102.139.169
// Пользователь: root
// Пароль: w3Bt8hjge8oV

type Article struct {
	Title   string
	Link    string
	Summary string
	Date    time.Time
}

func update(db *sql.DB, articles []Article) {
	for _, a := range articles {
		var f bool
		err := db.QueryRow("SELECT EXISTS(SELECT 1 FROM iu9gs WHERE Title = ?)", a.Title).Scan(&f)
		if err != nil {
			log.Println("1", err)
			continue
		}

		if !f {
			_, err := db.Exec("INSERT INTO iu9gs (Title, Link, Summary, Date) VALUES (BINARY ?, ?, ?, ?)", a.Title, a.Link, a.Summary, a.Date)
			if err != nil {
				log.Println("2", err)
			}
		}
	}
}

func main() {
	fmt.Println("start")
	db, err := sql.Open("mysql", "iu9networkslabs:Je2dTYr6@tcp(students.yss.su:3306)/iu9networkslabs")
	if err != nil {
		log.Fatal("Error opening database:", err)
	}
	defer db.Close()

	feed, err := rss.Fetch("https://news.rambler.ru/rss/Ivanovo/")
	if err != nil {
		log.Println("Error fetching RSS feed:", err)
		return
	}
	var articles []Article
	for _, item := range feed.Items {
		articles = append(articles, Article{Title: item.Title, Link: item.Link, Summary: item.Summary, Date: item.Date})
	}

	update(db, articles)
}
