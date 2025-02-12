// bxhmnefmujoqkweu
// posevin@mail.ru, danila@posevin.com, posevin@bmstu.ru и себе;
// EUufkx3dTikvCuG6gqn0
package main

import (
	"fmt"
	"net/smtp"
	"os"
	"strings"
	"time"
)

func main() {
	smtpHost := "smtp.mail.ru"
	smtpPort := "587"
	username := "nikia1928@mail.ru"
	password := "Ussd0cT14XVDThyeWhcJ"

	from := "nikia1928@mail.ru"
	subject := "Lab\n"

	auth := smtp.PlainAuth("", username, password, smtpHost)

	to := []string{"nikia1928@mail.ru"}
	//body := `<p>Здравствуйте!<b> письмо отправленно ` + to[0] + `</b></p>`
	body := `<p>Hello stranger!<b> ` + to[0] + `</b></p>`
	msg := "MIME-version: 1.0;\nContent-Type: text/html; charset=\"UTF-8\";\r\n"
	msg += fmt.Sprintf("From: %s\r\n", from)
	msg += fmt.Sprintf("To: %s\r\n", strings.Join(to, ";"))
	msg += fmt.Sprintf("Subject: %s\r\n", subject)
	msg += fmt.Sprintf("\r\n%s\r\n", body)
	err := smtp.SendMail(smtpHost+":"+smtpPort, auth, from, to, []byte(msg))

	if err != nil {
		fmt.Printf("Ошибка при отправке письма: %s\n", err)
		os.Exit(1)
	}
	fmt.Println("Письмо успешно отправлено!")
	time.Sleep(1)

	to = []string{"danila@posevin.com"}
	body = `<p>Здравствуйте ` + to[0] + ` !<b> письмо отправленно</b></p>`
	msg = "MIME-version: 1.0;\nContent-Type: text/html; charset=\"UTF-8\";\r\n"
	msg += fmt.Sprintf("From: %s\r\n", from)
	msg += fmt.Sprintf("To: %s\r\n", strings.Join(to, ";"))
	msg += fmt.Sprintf("Subject: %s\r\n", subject)
	msg += fmt.Sprintf("\r\n%s\r\n", body)
	err = smtp.SendMail(smtpHost+":"+smtpPort, auth, from, to, []byte(msg))

	if err != nil {
		fmt.Printf("Ошибка при отправке письма: %s\n", err)
		os.Exit(1)
	}
	fmt.Println("Письмо успешно отправлено!")
	time.Sleep(2)

	to = []string{"posevin@bmstu.ru"}
	body = `<p>Здравствуйте!<b> письмо отправленно ` + to[0] + `</b></p>`
	msg = "MIME-version: 1.0;\nContent-Type: text/html; charset=\"UTF-8\";\r\n"
	msg += fmt.Sprintf("From: %s\r\n", from)
	msg += fmt.Sprintf("To: %s\r\n", strings.Join(to, ";"))
	msg += fmt.Sprintf("Subject: %s\r\n", subject)
	msg += fmt.Sprintf("\r\n%s\r\n", body)
	err = smtp.SendMail(smtpHost+":"+smtpPort, auth, from, to, []byte(msg))

	if err != nil {
		fmt.Printf("Ошибка при отправке письма: %s\n", err)
		os.Exit(1)
	}
	fmt.Println("Письмо успешно отправлено!")
	time.Sleep(1)

	to = []string{"posevin@mail.ru"}
	body = `<p>Здравствуйте!<b> письмо отправленно ` + to[0] + `</b></p>`
	msg = "MIME-version: 1.0;\nContent-Type: text/html; charset=\"UTF-8\";\r\n"
	msg += fmt.Sprintf("From: %s\r\n", from)
	msg += fmt.Sprintf("To: %s\r\n", strings.Join(to, ";"))
	msg += fmt.Sprintf("Subject: %s\r\n", subject)
	msg += fmt.Sprintf("\r\n%s\r\n", body)
	err = smtp.SendMail(smtpHost+":"+smtpPort, auth, from, to, []byte(msg))

	if err != nil {
		fmt.Printf("Ошибка при отправке письма: %s\n", err)
		os.Exit(1)
	}
	fmt.Println("Письмо успешно отправлено!")

}
