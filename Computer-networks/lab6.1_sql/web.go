package main

import (
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"time"

	_ "github.com/go-sql-driver/mysql"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
}

var clients = make(map[*websocket.Conn]bool)
var broadcast = make(chan []byte)

type Article struct {
	Title   string
	Link    string
	Summary string
	Date    string
}

func main() {
	db, err := sql.Open("mysql", "iu9networkslabs:Je2dTYr6@tcp(students.yss.su)/iu9networkslabs")
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	go readNews(db)

	http.HandleFunc("/ws", handleConnections)
	go handleMessages()

	log.Println("started")
	err = http.ListenAndServe("127.0.0.1:2727", nil)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}

func handleConnections(w http.ResponseWriter, r *http.Request) {
	upgrader.CheckOrigin = func(r *http.Request) bool { return true }
	ws, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Fatal(err)
	}
	defer ws.Close()

	clients[ws] = true

	for {
		_, _, err := ws.ReadMessage()
		if err != nil {
			log.Printf("error: %v", err)
			delete(clients, ws)
			break
		}
	}
}

func handleMessages() {
	for {
		msg := <-broadcast
		for client := range clients {
			err := client.WriteMessage(websocket.TextMessage, msg)
			log.Printf("upload")
			if err != nil {
				log.Printf("error: %v", err)
				client.Close()
				delete(clients, client)
			}
		}
	}
}

func readNews(db *sql.DB) {
	for {
		rows, err := db.Query("SELECT Title, Link, Summary, Date FROM iu9gs")
		if err != nil {
			log.Printf("Error", err)
			continue
		}
		defer rows.Close()

		var news []Article
		for rows.Next() {
			var n Article
			if err := rows.Scan(&n.Title, &n.Link, &n.Summary, &n.Date); err != nil {
				log.Printf("Error", err)
				continue
			}
			news = append(news, n)
		}

		if err != nil {
			log.Printf("Error", err)
			continue
		}

		msg, err := json.Marshal(news)
		if err != nil {
			log.Printf("Error", err)
			continue
		}
		broadcast <- msg
		time.Sleep(time.Second)
	}
}
