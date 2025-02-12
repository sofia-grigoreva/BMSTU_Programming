package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"strings"

	"golang.org/x/crypto/ssh"
)

// ip: 151.248.113.144
// 	port: 443
// 	login: test
// 	passwd: SDHBCXdsedfs222

func executeCommand(client *ssh.Client, command string) {
	session, err := client.NewSession()
	if err != nil {
		log.Fatal("Failed to create session: ", err)
	}
	defer session.Close()

	output, err := session.CombinedOutput(command)
	if err != nil {
		log.Printf("Failed to execute command %s: %v\n", command, err)
	}
	fmt.Printf("%s\n", output)
}

func main() {
	config := &ssh.ClientConfig{
		User: "test",
		Auth: []ssh.AuthMethod{
			ssh.Password("SDHBCXdsedfs222"),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
	}

	client, err := ssh.Dial("tcp", "151.248.113.144:443", config)
	if err != nil {
		log.Fatal("Failed to connect to SSH server: ", err)
	}
	defer client.Close()

	scanner := bufio.NewScanner(os.Stdin)
	fmt.Println("Connected to SSH server.")
	for {
		fmt.Print("> ")
		if !scanner.Scan() {
			break
		}
		command := scanner.Text()

		if strings.TrimSpace(command) == "exit" {
			break
		}
		executeCommand(client, command)
	}

	if err := scanner.Err(); err != nil {
		log.Fatal("Error reading standard input: ", err)
	}
}
