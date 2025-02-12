package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"html/template"
	"log"
	"net/http"
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

func LogPage(w http.ResponseWriter, r *http.Request) {
	tmpl, _ := template.ParseFiles("log.html")
	_ = tmpl.Execute(w, "")
}

func MailPage(w http.ResponseWriter, r *http.Request) {
	tmpl, _ := template.ParseFiles("index.html")
	_ = tmpl.Execute(w, "")

}

func HandleLogin(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodPost {
		err := json.NewDecoder(r.Body).Decode(&user)
		if err != nil {
			http.Error(w, "Ошибка декодирования JSON", http.StatusBadRequest)
			return
		}
		fmt.Print("Логин: ", user.Login, "Пароль: ", user.Password)
	} else {
		http.Error(w, "Метод не разрешен", http.StatusMethodNotAllowed)
	}
}

func HandleMail(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodPost {
		var l Letter
		err := json.NewDecoder(r.Body).Decode(&l)
		if err != nil {
			http.Error(w, "Ошибка декодирования JSON", http.StatusBadRequest)
			return
		}
		fmt.Print("Кому: ", l.To, "Текст: ", l.Text, "Тема: ", l.Subject)
		bodyMap := map[string]interface{}{
			"server": user.Host,
			"name":   user.Login,
			"pass":   user.Password,
			"to":     l.To,
			"text":   l.Text,
			"sub":    l.Subject,
		}

		requestBody, err := json.Marshal(bodyMap)
		if err != nil {
			panic(err)
		}
		body := bytes.NewBuffer(requestBody)

		resp, err := http.Post("http://185.102.139.161:2728/login", "application/json", body)
		if err != nil {
			panic(err)
		}
		fmt.Println(resp.StatusCode)
		http.ServeFile(w, r, "sender.html")
	} else {
		http.Error(w, "Метод не разрешен", http.StatusMethodNotAllowed)
	}

}

func main() {
	http.HandleFunc("/", LogPage)
	http.HandleFunc("/mail", MailPage)

	http.HandleFunc("/l", HandleLogin)
	http.HandleFunc("/m", HandleMail)
	log.Println("Сервер запущен")
	err := http.ListenAndServe(":2727", nil)
	if err != nil {
		log.Fatal(err)
	}
}
