package main

import (
	"fmt"
	"io"
	"log"
	"os/exec"
	"strings"

	"github.com/gliderlabs/ssh"
	"golang.org/x/crypto/ssh/terminal"
)

func obr(command string, term *terminal.Terminal) {
	commands := strings.Split(command, " ")
	switch commands[0] {
	case "ls":
		if len(commands) == 1 {
			cmd := exec.Command("bash", "-c", "ls")
			output, _ := cmd.Output()
			term.Write([]byte(output))
		} else if len(commands) == 2 {
			cmd_to_exec := "ls " + commands[1]
			cmd := exec.Command("bash", "-c", cmd_to_exec)
			output, _ := cmd.Output()
			term.Write([]byte(output))
		} else {
			term.Write(append([]byte("Usage: ls or ls <name>"), '\n'))
		}
	case "mkdir":
		if len(commands) != 2 {
			term.Write(append([]byte("Usage: mkdir <name>"), '\n'))
		} else {
			cmd_to_exec := "mkdir " + commands[1]
			cmd := exec.Command("bash", "-c", cmd_to_exec)
			cmd.Start()
		}
	case "rmdir":
		if len(commands) != 2 {
			term.Write(append([]byte("Usage: rmdir <name>"), '\n'))
		} else {
			cmd_to_exec := "rm -rf " + commands[1]
			cmd := exec.Command("bash", "-c", cmd_to_exec)
			cmd.Start()
		}
	case "mv":
		if len(commands) != 3 {
			term.Write(append([]byte("Usage: mv <path_from> <path_to>"), '\n'))
		} else {
			cmd_to_exec := "mv " + commands[1] + " " + commands[2]
			cmd := exec.Command("bash", "-c", cmd_to_exec)
			cmd.Start()
		}
	case "rmfile":
		if len(commands) != 2 {
			term.Write(append([]byte("Usage: rmfile <name>"), '\n'))
		} else {
			cmd_to_exec := "rm -r " + commands[1]
			cmd := exec.Command("bash", "-c", cmd_to_exec)
			cmd.Start()
		}
	case "command":
		cmd_to_exec := strings.Join(commands[1:], " ")
		cmd := exec.Command("bash", "-c", cmd_to_exec)
		output, _ := cmd.Output()
		term.Write([]byte(output))
	}
}

func main() {
	ssh.Handle(func(s ssh.Session) {
		io.WriteString(s, fmt.Sprintf("Hello %s\n", s.User()))
	})

	ssh.Handle(func(s ssh.Session) {
		term := terminal.NewTerminal(s, "")
		for {
			line, err := term.ReadLine()
			if err != nil {
				if err == io.EOF {
					args := s.Command()
					if len(args) == 0 {
						io.WriteString(s, "No command provided\n")
						return
					}
					obr(strings.Join(args, " "), term)
					break
				}
				io.WriteString(s, fmt.Sprintf("Error reading command: %v\n", err))
				continue
			}
			obr(line, term)
		}
		log.Println("terminal closed")
	})

	log.Println("Starting SSH server on localhost:2222")
	log.Fatal(ssh.ListenAndServe(":2222", nil))
}
