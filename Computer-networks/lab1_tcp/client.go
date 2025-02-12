package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"net"

	"github.com/skorobogatov/input"
)

type Request struct {
	Command string           `json:"command"`
	Data    *json.RawMessage `json:"data"`
}

type Response struct {
	Status string           `json:"status"`
	Data   *json.RawMessage `json:"data"`
}

type Point struct {
	x string `json:"X"`
	y string `json:"Y"`
}

// получение и обработка данных с терминала и получение ответа от сервера
func interact(conn *net.TCPConn) {
	defer conn.Close()
	encoder, decoder := json.NewEncoder(conn), json.NewDecoder(conn)
	for {
		fmt.Printf("command = ")
		command := input.Gets()
		switch command {
		case "quit":
			send_request(encoder, "quit", nil)
			return
		case "add":
			var p Point
			fmt.Printf("x = ")
			p.x = input.Gets()
			fmt.Printf("y = ")
			p.y = input.Gets()
			send_request(encoder, "add", &p)
		case "convex":
			send_request(encoder, "convex", nil)
		default:
			fmt.Printf("error: unknown command\n")
			continue
		}

		var resp Response
		if err := decoder.Decode(&resp); err != nil {
			fmt.Printf("error: %v\n", err)
			break
		}

		switch resp.Status {
		case "ok":
			fmt.Printf("ok\n")
		case "failed":
			if resp.Data == nil {
				fmt.Printf("error: data field is absent in response\n")
			} else {
				var errorMsg string
				if err := json.Unmarshal(*resp.Data, &errorMsg); err != nil {
					fmt.Printf("error: malformed data field in response\n")
				} else {
					fmt.Printf("failed: %s\n", errorMsg)
				}
			}
		case "result":
			if resp.Data == nil {
				fmt.Printf("error: data field is absent in response\n")
			} else {
				var c bool
				if err := json.Unmarshal(*resp.Data, &c); err != nil {
					fmt.Printf("error: malformed data field in response\n")
				} else if c {
					fmt.Printf("result: yes\n")
				} else {
					fmt.Printf("result: no\n")
				}
			}
		default:
			fmt.Printf("error: server reports unknown status %q\n", resp.Status)
		}
	}
}

// отправка данных на сервер
func send_request(encoder *json.Encoder, command string, data interface{}) {
	var raw json.RawMessage
	raw, _ = json.Marshal(data)
	encoder.Encode(&Request{command, &raw})
}

func main() {
	var addrStr string
	flag.StringVar(&addrStr, "addr", "127.0.0.1:2727", "specify ip address and port")
	flag.Parse()

	if addr, err := net.ResolveTCPAddr("tcp", addrStr); err != nil {
		fmt.Printf("error: %v\n", err)
	} else if conn, err := net.DialTCP("tcp", nil, addr); err != nil {
		fmt.Printf("error: %v\n", err)
	} else {
		interact(conn)
	}
}
