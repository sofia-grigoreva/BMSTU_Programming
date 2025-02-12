package main

import (
	"bytes"
	"html/template"
	"net/http"

	log "github.com/mgutz/logxi/v1"
	"golang.org/x/net/html"
)

func nodeToString(n *html.Node) string {
	var buf bytes.Buffer
	if err := html.Render(&buf, n); err != nil {
		log.Info("Error rendering node:", err)
		return ""
	}
	return buf.String()
}

var Items []Item

const INDEX_HTML = `
    <!doctype html>
    <html lang="ru">
        <head>
            <meta charset="utf-8">
            <title>Список тем с https://glav.su/forum</title>
        </head>
        <body>
            {{if .}}
                {{range .}}
					{{.Title}}
                    <br/>
                {{end}}
            {{else}}
                Не удалось загрузить новости!
            {{end}}
        </body>
		<style>
    body {
    display: flex;
    align-items: center;
    flex-direction: column;
    background: #d2e7ff;
	color: #5883cc;
	font-size:300%
  }
</style>
    </html>
    `

var indexHtml = template.Must(template.New("index").Parse(INDEX_HTML))

func serveClient(response http.ResponseWriter, request *http.Request) {
	path := request.URL.Path
	log.Info("got request", "Method", request.Method, "Path", path)
	if path != "/" && path != "/index.html" {
		log.Error("invalid path", "Path", path)
		response.WriteHeader(http.StatusNotFound)
	} else if err := indexHtml.Execute(response, downloadNews()); err != nil {
		log.Error("HTML creation failed", "error", err)
	} else {
		log.Info("response sent to client successfully")
	}
}

func getAttr(node *html.Node, key string) string {
	for _, attr := range node.Attr {
		if attr.Key == key {
			return attr.Val
		}
	}
	return ""
}

func getChildren(node *html.Node) []*html.Node {
	var children []*html.Node
	for c := node.FirstChild; c != nil; c = c.NextSibling {
		children = append(children, c)
	}
	return children
}

func isElem(node *html.Node, tag string) bool {
	return node != nil && node.Type == html.ElementNode && node.Data == tag
}

func isDiv2(node *html.Node, class string) bool {
	return isElem(node, "div") && getAttr(node, "class") == class
}

type Item struct {
	Title string
}

func search(node *html.Node) []*Item {
	if isDiv2(node, "bl-fbt") {
		var items []*Item
		c := getChildren(node)[1]
		if isElem(c, "div") {
			cs := getChildren(c)[1]
			if isElem(cs, "div") {
				css := getChildren(cs)[1]
				if isElem(css, "a") {
					Items = append(Items, Item{Title: css.FirstChild.FirstChild.Data})
				}

			}
		}
		return items
	}
	for c := node.FirstChild; c != nil; c = c.NextSibling {
		if items := search(c); items != nil {
			return items
		}
	}
	return nil
}

func downloadNews() []Item {
	log.Info("sending request ")
	if response, err := http.Get("https://glav.su/forum"); err != nil {
		log.Error("request to https://glav.su/forum failed", "error", err)
	} else {
		defer response.Body.Close()
		status := response.StatusCode
		log.Info("got response to https://glav.su/forum ", "status", status)
		if status == http.StatusOK {
			if doc, err := html.Parse(response.Body); err != nil {
				log.Error("invalid HTML from https://glav.su/forum", "error", err)
			} else {
				log.Info("HTML from  parsed successfully")
				search(doc)
				return Items
			}
		}
	}
	return nil
}

func main() {
	http.HandleFunc("/", serveClient)
	log.Info("starting listener")
	log.Error("listener failed", "error", http.ListenAndServe("127.0.0.1:2727", nil))
}

// export LOGXI=*
// 	export LOGXI_FORMAT=pretty,happy
