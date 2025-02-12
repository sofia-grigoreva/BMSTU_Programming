package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"math/big"
	"net"
	"strconv"

	log "github.com/mgutz/logxi/v1"
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

type Client struct {
	logger      log.Logger
	conn        *net.TCPConn
	enc         *json.Encoder
	count       int64
	coordinates [][]int
}

func NewClient(conn *net.TCPConn) *Client {
	return &Client{
		logger:      log.New(fmt.Sprintf("client %s", conn.RemoteAddr().String())),
		conn:        conn,
		enc:         json.NewEncoder(conn),
		count:       0,
		coordinates: [][]int{},
	}
}

// функции обработки данных
func crossProduct(o, a, b []int) int {
	return (a[0]-o[0])*(b[1]-o[1]) - (a[1]-o[1])*(b[0]-o[0])
}

func isConvex(polygon [][]int) bool {
	if len(polygon) <= 3 {
		return true
	}
	sign := 0
	for i := 0; i < len(polygon); i++ {
		cp := crossProduct(polygon[i], polygon[(i+1)%len(polygon)], polygon[(i+2)%len(polygon)])
		if cp != 0 {
			if sign == 0 {
				sign = 1
			}
			if sign*int(cp) < 0 {
				return false
			}
		}
	}
	return true
}

// обработка запросов от клиента
func (client *Client) serve() {
	defer client.conn.Close()
	decoder := json.NewDecoder(client.conn)
	for {
		var req Request
		if err := decoder.Decode(&req); err != nil {
			client.logger.Error("cannot decode message", "reason", err)
			break
		} else {
			client.logger.Info("received command", "command", req.Command)
			if client.handleRequest(&req) {
				client.logger.Info("shutting down connection")
				break
			}
		}
	}
}

// обработка команды клиента
func (client *Client) handleRequest(req *Request) bool {
	switch req.Command {
	case "quit":
		client.respond("ok", nil)
		return true
	case "add":
		errorMsg := ""
		if req.Data == nil {
			errorMsg = "data field is absent"
		} else {
			var p Point
			if err := json.Unmarshal(*req.Data, &p); err != nil {
				errorMsg = "malformed data fieldgg"
			} else {
				var x big.Rat
				x1, err := strconv.Atoi(p.x)
				if err == nil {
					errorMsg = "malformed data field"
				}
				y1, err := strconv.Atoi(p.x)
				if err == nil {
					errorMsg = "malformed data field"
				}
				client.logger.Info("performing addition", "value", x.String())
				client.coordinates = append(client.coordinates, []int{x1, y1})
				client.count++
			}
		}
		if errorMsg == "" {
			client.respond("ok", nil)
		} else {
			client.logger.Error("addition failed", "reason", errorMsg)
			client.respond("failed", errorMsg)
		}
	case "convex":
		if client.count == 0 {
			client.logger.Error("calculation failed", "reason", "division by zero")
			client.respond("failed", "division by zero")
		} else {
			var c bool
			c = isConvex(client.coordinates)
			client.respond("result", &c)
		}
	default:
		client.logger.Error("unknown command")
		client.respond("failed", "unknown command")
	}
	return false
}

// отправка ответа клиенту
func (client *Client) respond(status string, data interface{}) {
	var raw json.RawMessage
	raw, _ = json.Marshal(data)
	client.enc.Encode(&Response{status, &raw})
}

func main() {
	var addrStr string
	flag.StringVar(&addrStr, "addr", "127.0.0.1:2727", "specify ip address and port")
	flag.Parse()
	if addr, err := net.ResolveTCPAddr("tcp", addrStr); err != nil {
		log.Error("address resolution failed", "address", addrStr)
	} else {
		log.Info("resolved TCP address", "address", addr.String())
		if listener, err := net.ListenTCP("tcp", addr); err != nil {
			log.Error("listening failed", "reason", err)
		} else {
			for {
				if conn, err := listener.AcceptTCP(); err != nil {
					log.Error("cannot accept connection", "reason", err)
				} else {
					log.Info("accepted connection", "address", conn.RemoteAddr().String())
					go NewClient(conn).serve()
				}
			}
		}
	}
}
