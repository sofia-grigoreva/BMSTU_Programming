package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"html/template"
	"log"
	"net"
	"net/http"
	"os"
	"strings"
	"sync"

	"github.com/gorilla/websocket"
)

const INDEX_HTML = `
<!doctype html>
<html lang="ru">
    <head>
        <meta charset="utf-8">
        <title>Hash table</title>
    </head>
    <br/>
    <body>
        <form method="POST" action="commandline">
            <h1>Enter command</h1>
            <h5>add key value</h5>
            <h5>delete key</h5>
            <h5>find key</h5>
            <input type="text" id = "line" name="command" /><br><br>
            <input type="submit" id = "bth" value="Отправить" />
        </form>
    </body>
    <style>

body {
display: flex;
align-items: center;
flex-direction: column;
background: #d2e7ff;
color: #344e7c;
}

h1 {
color: #5883cc;
}

h5 {
color: #344e7c;
margin: 4px;
}

#bth {
  margin-left: auto;
  margin-right: auto;
  position: flex;
  height: 25px;
  background-color: transparent;
  background-size: 100% 100%;
  font-size: 0.7em;
  text-transform: uppercase;
  font-weight: 700;
  border: 1.5px solid #5883cc;
  cursor: pointer;
  color: #5883cc;
}

#line {
  width: 230px;
  margin-left: auto;
  margin-right: auto;
  height: 25px;
  margin-top: 15px;
  background-color: transparent;
  font-size: 0.8em;
  font-weight: 700;
  border: 1.5px solid #5883cc;
  color: #344e7c;
}

</style>
</html>
	`

var indexHtml = template.Must(template.New("index").Parse(INDEX_HTML))

var upgrader = websocket.Upgrader{
	ReadBufferSize:    1024,
	WriteBufferSize:   1024,
	EnableCompression: true,
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

var clients = make(map[*websocket.Conn]bool)
var broadcast = make(chan Data)

type Data struct {
	Comment []string          `json:"comment"`
	dict    map[string]string `json:"dict"`
	Out     [][]string        `json:"out"`
}

type Peer struct {
	Addr   string
	Peers  []string
	Logger *log.Logger
	mu     sync.Mutex
	data   *Data
	comm   []string
}

func NewPeer(addr string, peers []string) *Peer {
	logger := log.New(os.Stdout, fmt.Sprintf("Peer %s: ", addr), log.LstdFlags)
	return &Peer{
		Addr:   addr,
		Peers:  peers,
		Logger: logger,
		data: &Data{
			dict:    make(map[string]string),
			Comment: []string{},
			Out:     [][]string{},
		},
		comm: []string{},
	}
}

func arrtomap(a [][]string) map[string]string {
	d := make(map[string]string)
	for _, pair := range a {
		key := pair[0]
		value := pair[1]
		d[key] = value
	}
	return d
}

func maptoarr(m map[string]string, s []string) [][]string {
	res := make([][]string, 0, len(m))
	for key, value := range m {
		pair := []string{key, value}
		res = append(res, pair)
	}
	return res
}

func (p *Peer) send(d Data, peerAddr string) {
	conn, err := net.Dial("tcp", peerAddr)
	if err != nil {
		p.Logger.Printf("Failed to connect to peer %s: %v", peerAddr, err)
		return
	}
	defer conn.Close()
	data, err := json.Marshal(d)

	if err != nil {
		p.Logger.Printf("Failed to marshal message: %v", err)
		return
	}

	if _, err := conn.Write(append(data, '\n')); err != nil {
		p.Logger.Printf("Failed to send message to peer %s: %v", peerAddr, err)
	}
}

func (p *Peer) update(text string) {

	p.data.Comment = append(p.data.Comment, text)
	p.comm = append(p.comm, text)

	m := Data{Comment: p.data.Comment, Out: maptoarr(p.data.dict, p.data.Comment)}
	m2 := Data{Comment: p.comm, Out: maptoarr(p.data.dict, p.data.Comment)}

	broadcast <- m2
	go shandleMessages()
	peers := p.Peers

	for _, peerAddr := range peers {
		if peerAddr != "" && peerAddr != p.Addr {
			p.send(m, peerAddr)
		}
	}
}

func (p *Peer) handleUserInput() {
	reader := bufio.NewReader(os.Stdin)
	for {
		fmt.Print("Enter command (add/delete/find): ")
		command, _ := reader.ReadString('\n')
		command = command[:len(command)-1]
		text := ""
		switch command {
		case "add":
			fmt.Print("key: ")
			k, _ := reader.ReadString('\n')
			k = k[:len(k)-1]
			fmt.Print("value: ")
			v, _ := reader.ReadString('\n')
			v = v[:len(v)-1]
			p.mu.Lock()
			text = p.Addr + " add key: " + k + " value: " + v
			p.data.dict[k] = v
			p.mu.Unlock()

		case "delete":
			fmt.Print("key: ")
			k, _ := reader.ReadString('\n')
			k = k[:len(k)-1]
			p.mu.Lock()
			text = p.Addr + " deleted by key: " + k + " value: " + p.data.dict[k]
			delete(p.data.dict, k)
			p.mu.Unlock()

		case "find":
			fmt.Print("key: ")
			k, _ := reader.ReadString('\n')
			k = k[:len(k)-1]
			p.mu.Lock()
			v, ok := p.data.dict[k]
			if ok {
				text = p.Addr + " find by key: " + k + " value: " + v
			} else {
				text = "key is not in the hash table"
			}
			p.mu.Unlock()
		default:
			text = "Unknown command"
		}

		fmt.Println(text)
		p.update(text)
	}
}

func (p *Peer) serveClientforGet(response http.ResponseWriter, request *http.Request) {
	path := request.URL.Path
	command := request.URL.Query().Get("command")
	splited := strings.Split(command, "_")
	text := ""
	switch splited[0] {
	case "/add":
		k := splited[1]
		v := splited[2]
		p.mu.Lock()
		text = p.Addr + " add key: " + k + " value: " + v
		p.data.dict[k] = v
		p.mu.Unlock()

	case "/delete":
		k := splited[1]
		p.mu.Lock()
		text = p.Addr + " deleted by key: " + k + " value: " + p.data.dict[k]
		delete(p.data.dict, k)
		p.mu.Unlock()

	case "/find":
		k := splited[1]
		p.mu.Lock()
		v, ok := p.data.dict[k]
		if ok {
			text = p.Addr + " find by key: " + k + " value: " + v
		} else {
			text = "key is not in the hash table"
		}
		p.mu.Unlock()
	default:
		text = "Unknown command uuuu"
	}
	if splited[0] == "" {
		text = ""
	}

	p.update(text)

	if path != "/" && path != "/index.html" {
		response.WriteHeader(http.StatusNotFound)
	} else if err := indexHtml.Execute(response, "ff"); err != nil {
	}
}

func (p *Peer) serveClientforPost(w http.ResponseWriter, r *http.Request) {
	command := r.FormValue("command")
	splited := strings.Split(command, " ")
	text := ""
	text = "Unknown command uuuu"
	switch splited[0] {
	case "add":
		k := splited[1]
		v := splited[2]
		p.mu.Lock()
		text = p.Addr + " add key: " + k + " value: " + v
		p.data.dict[k] = v
		p.mu.Unlock()

	case "delete":
		k := splited[1]
		p.mu.Lock()
		text = p.Addr + " deleted by key: " + k + " value: " + p.data.dict[k]
		delete(p.data.dict, k)
		p.mu.Unlock()

	case "find":
		k := splited[1]
		p.mu.Lock()
		v, ok := p.data.dict[k]
		if ok {
			text = p.Addr + " find by key: " + k + " value: " + v
		} else {
			text = "key is not in the hash table"
		}
		p.mu.Unlock()
	}

	p.update(text)
	http.Redirect(w, r, "/", http.StatusSeeOther)
}

func (p *Peer) listen() {
	listener, err := net.Listen("tcp", p.Addr)
	if err != nil {
		p.Logger.Fatalf("Error listening: %v", err)
	}
	defer listener.Close()
	for {
		conn, err := listener.Accept()
		if err != nil {
			p.Logger.Printf("Error accepting: %v", err)
			continue
		}
		go p.handleConnection(conn)
	}
}

func (p *Peer) handleConnection(conn net.Conn) {
	defer conn.Close()
	var (
		buffer  = make([]byte, 512)
		message string
		d       Data
	)
	for {
		length, err := conn.Read(buffer)
		if err != nil {
			break
		}
		message += string(buffer[:length])
	}

	err := json.Unmarshal([]byte(message), &d)
	if err != nil {
		return
	}

	d.dict = arrtomap(d.Out)
	p.mu.Lock()
	p.data.dict = d.dict
	p.data.Comment = d.Comment
	p.mu.Unlock()
}

func shandleConnection(w http.ResponseWriter, r *http.Request) {
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

func shandleMessages() {
	for {
		msg := <-broadcast
		for client := range clients {
			err := client.WriteJSON(msg)
			if err != nil {
				log.Printf("Error sending message to client: %v", err)
				client.Close()
				delete(clients, client)
			}
		}
	}
}

func main() {
	address := os.Args[1]
	ip := "127.0.0.1:"
	commandlineadd := ip + address + "1"
	websocketadd := ip + address + "2"
	peers := os.Args[2:]
	peer := NewPeer(commandlineadd, peers)
	go peer.listen()
	go peer.handleUserInput()
	go shandleMessages()
	http.HandleFunc("/", peer.serveClientforGet)
	http.HandleFunc("/ws", shandleConnection)
	http.HandleFunc("/commandline", peer.serveClientforPost)
	err := http.ListenAndServe(websocketadd, nil)
	if err != nil {
		log.Fatal("Error starting server:", err)
	}
}

/*


go run wbt.go 606 127.0.0.1:7071 127.0.0.1:8081 127.0.0.1:9091
go run wbt.go 707 127.0.0.1:6061 127.0.0.1:8081 127.0.0.1:9091
go run wbt.go 808 127.0.0.1:7071 127.0.0.1:6061 127.0.0.1:9091
go run wbt.go 909 127.0.0.1:7071 127.0.0.1:8081 127.0.0.1:6061

/?command=/add_8_4
/?command=/find_1


IP-адрес сервера: 185.104.251.226
Пароль: fMs0m69gIGQ3

go run wbt.go 606 185.102.139.161:7071 185.102.139.168:8081 185.102.139.169:9091


IP-адрес сервера: 185.102.139.161
Пароль: Up5b0A1wiLMQ

go run wbt.go 707 185.104.251.226:6061 185.102.139.168:8081 185.102.139.169:9091


IP-адрес сервера: 185.102.139.168
Пароль: gOsQ5p7FUJ9w

go run wbt.go 808 185.102.139.161:7071 185.104.251.226:6061 185.102.139.169:9091


IP-адрес сервера: 185.102.139.169
Пароль: w3Bt8hjge8oV

go run wbt.go 909 185.102.139.161:7071 185.102.139.168:8081 185.104.251.226:6061







go run wbt.go 606 185.102.139.168:8081
go run wbt.go 808 185.104.251.226:6061
*/
