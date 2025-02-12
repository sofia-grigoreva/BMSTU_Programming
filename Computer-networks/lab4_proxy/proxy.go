package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"strings"
)

var s string
var a string

func main() {
	a = "http://localhost:2727/"
	//a = "http://185.102.139.161:2727/"
	http.Handle("/styles/", http.StripPrefix("/styles/", http.FileServer(http.Dir("./styles/"))))
	http.Handle("/images/", http.StripPrefix("/images/", http.FileServer(http.Dir("./images/"))))
	http.HandleFunc("/", proxyHandler)
	http.ListenAndServe(":2727", nil)
}

func exists(path string) bool {
	_, err := os.Stat(path)
	if err == nil {
		return true
	}
	if os.IsNotExist(err) {
		return false
	}
	return false
}

func proxyHandler(w http.ResponseWriter, r *http.Request) {
	s = "/" + strings.TrimPrefix(r.URL.Path, "/")
	targetURL := "http:/" + s + strings.TrimPrefix(r.URL.Path, s)
	resp, err := http.Get(targetURL)
	if err != nil {
		http.Error(w, "Ошибка при получении данных", http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		http.Error(w, "Ошибка при чтении ответа", http.StatusInternalServerError)
		return
	}

	modifiedBody := string(body)

	modifiedBody = strings.ReplaceAll(modifiedBody, "'", "\"")

	modifiedBody = strings.ReplaceAll(modifiedBody, "href=\"http://", "href=\""+a)
	modifiedBody = strings.ReplaceAll(modifiedBody, "href=\"https://", "href=\""+a)
	modifiedBody = strings.ReplaceAll(modifiedBody, "href=\"//", "href=\""+a)

	bodySplited := strings.Split(modifiedBody, "\n")

	for index, line := range bodySplited {
		if strings.Contains(line, "stylesheet") {
			if !strings.Contains(line, "href=\"") {
				continue
			}
			style := strings.Split(strings.Split(line, "href=\"")[1], "\"")[0]
			link := targetURL + "/" + style
			splited := strings.Split(link, "/")
			new_s := strings.Split(s[1:], "/")[0]
			path := new_s + "_" + splited[len(splited)-1]
			if exists("./styles/"+path) == false {
				cmd := exec.Command("bash", "-c", "wget -P ./styles/ -O ./styles/"+path+" "+link)
				cmd.Run()
			}
			bodySplited[index] = strings.ReplaceAll(line, "href=\""+style+"\"", "href=\"/styles/"+path+"\"")
		}

		if strings.Contains(line, ".html") && !strings.Contains(line, "http") {
			addr := strings.Split(s, "/")[1]
			bodySplited[index] = strings.ReplaceAll(line, "href=\"", "href=\""+a+addr+"/")
		}

		if strings.Contains(line, "https") {
			fmt.Println(line)
		}

		if strings.Contains(line, "<img") {
			if strings.Contains(line, "'") {
				line = strings.ReplaceAll(line, "'", "\"")
			}
			if !strings.Contains(line, "src=") {
				continue
			}
			if !strings.Contains(line, "src=\"") {
				continue
			}
			style := strings.Split(strings.Split(line, "src=\"")[1], "\"")[0]
			link := targetURL + "/" + style
			splited := strings.Split(link, "/")
			new_s := strings.Split(s[1:], "/")[0]
			path := new_s + "_" + splited[len(splited)-1]
			if exists("./images/"+path) == false {
				cmd := exec.Command("bash", "-c", "wget -P ./images/ -O ./images/"+path+" "+link)
				cmd.Run()
			}
			bodySplited[index] = strings.ReplaceAll(line, "src=\""+style+"\"", "src=\"/images/"+path+"\"")
		}
	}

	modifiedBody = strings.Join(bodySplited, "\n")
	w.Write([]byte(modifiedBody))
}

//http://localhost:2727/www.openbsd.org

// http://www.gnuplot.info/
// https://netlib.sandia.gov/
// https://putty.org/
// https://www.openbsd.org/
// https://netbsd.org/
// https://www.freebsd.org/

// net2.yss.su
// IP-адрес сервера: 185.102.139.161
// Пользователь: root
// Пароль: Up5b0A1wiLMQ
