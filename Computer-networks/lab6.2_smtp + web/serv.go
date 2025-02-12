package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/smtp"

	"github.com/gorilla/websocket"
)

type User struct {
	Login    string `json:"login"`
	Password string `json:"password"`
	Host     string
}

type Letter struct {
	To      string `json:"to"`
	Text    string `json:"text"`
	Subject string `json:"sub"`
}

var user User
var l Letter

var clients = make(map[*websocket.Conn]bool)
var broadcast = make(chan Data)

type Data struct {
	Out []string `json:"out"`
}

var history Data

func Send(l Letter) {

	smtpHost := "smtp.mail.ru"
	smtpPort := "587"

	auth := smtp.PlainAuth("", user.Login, user.Password, smtpHost)

	body := `<body style="font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color:  #d2e7ff;">
    <div style="background-color: #1c4792; color: white; padding: 15px; text-align: center; font-size: 32px; border-radius: 5px; box-shadow: 0 2px 5px rgba(0, 0, 0, 0.2);">
        Здравствуйте!
    </div>
    <div style="background-color: white; border: 1px solid #1c4792; border-radius: 5px; padding: 20px; margin-top: 20px; box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);">
        <p style="line-height: 1.6; color: #333; font-size: 20px;">Письмо отправлено с помощью web-интерфейса. Текст письма:</p>
        <p style="line-height: 1.6; color: #333; font-size: 20px;"><strong>` + l.Text + `</strong></p>
        <p style="line-height: 1.6; color: #333; font-size: 20px;">С уважением,<br>SG</p>
    </div>
</body>`

	msg := "MIME-version: 1.0;\nContent-Type: text/html; charset=\"UTF-8\";\r\n"

	msg += fmt.Sprintf("From: %s\r\n", user.Login)
	msg += fmt.Sprintf("To: %s\r\n", l.To)
	msg += fmt.Sprintf("Subject: %s\r\n", l.Subject)
	msg += fmt.Sprintf("\r\n%s\r\n", body)

	err := smtp.SendMail(smtpHost+":"+smtpPort, auth, user.Login, []string{l.To}, []byte(msg))
	if err != nil {
		fmt.Printf("Ошибка при отправке письма: %s\n", err)
		history.Out = append(history.Out, "Ошибка при отправке письма")
	} else {
		fmt.Println("Письмо успешно отправлено!")
		history.Out = append(history.Out, "Письмо отпралено: "+l.To+" C темой: "+l.Subject)
	}
	broadcast <- history
	go handleMessages()
}

var upgrader = websocket.Upgrader{
	ReadBufferSize:    1024,
	WriteBufferSize:   1024,
	EnableCompression: true,
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

func handleConnection(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Error during connection:", err)
		return
	}
	clients[conn] = true
	log.Println("Client connected")

	go func() {
		defer func() {
			conn.Close()
			delete(clients, conn)
			log.Println("Client disconnected")
		}()

		for {
			_, _, err := conn.NextReader()
			if err != nil {
				log.Println("Client disconnected:", err)
				break
			}
		}
	}()
}

func handleMessages() {
	for {
		msg := <-broadcast
		for client := range clients {
			err := client.WriteJSON(msg)
			log.Println("Client get")
			if err != nil {
				log.Printf("Error sending message to client: %v", err)
				client.Close()
				delete(clients, client)
			}
		}
	}
}

func Login(w http.ResponseWriter, r *http.Request) {
	var p map[string]string
	json.NewDecoder(r.Body).Decode(&p)
	fmt.Println(p["server"], p["name"], p["pass"])
	user.Login = p["name"]
	user.Host = p["server"]
	user.Password = p["pass"]
	l.Subject = p["sub"]
	l.To = p["to"]
	l.Text = p["text"]
	Send(l)

}

func main() {
	go handleMessages()
	http.HandleFunc("/ws", handleConnection)
	http.HandleFunc("/login", Login)

	log.Println("Сервер запущен")
	err := http.ListenAndServe("185.102.139.161:2728", nil)
	if err != nil {
		log.Fatal(err)
	}
}

// net2.yss.su
// IP-адрес сервера: 185.102.139.161
// Пользователь: root
// Пароль: Up5b0A1wiLMQ
