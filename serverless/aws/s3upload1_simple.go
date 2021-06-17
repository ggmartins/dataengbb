package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"strings"
)

type Upload struct {
	Message   string `json:"message"`
	UploadURL string `json:"url"`
}

type User struct {
	Name  string
	Email string
}

func main() {
	fmt.Println(os.Args[1])

	req, err := http.NewRequest("POST", "https://.execute-api.us-east-1.amazonaws.com/upload/test",
		strings.NewReader("{}"))
	if err != nil {
		log.Fatal(err)
	}
	req.Header.Set("Content-Type", "application/json")
	client := &http.Client{}
	res, err := client.Do(req)
	if err != nil {
		log.Fatal(err)
	}
	defer res.Body.Close()

	decoder := json.NewDecoder(res.Body)
	var uploadResp Upload
	err = decoder.Decode(&uploadResp)
	if err != nil {
		e, err := ioutil.ReadAll(res.Body)
		if err != nil {
			log.Fatal(err)
		}

		fmt.Printf("Returned: [%s]\n", e)
		panic(err)
	}
	defer res.Body.Close()
	fmt.Printf("\nPre-signed URL:\n%s\n", uploadResp.UploadURL)

	data, err := ioutil.ReadFile(os.Args[1])
	if err != nil {
		panic(err)
	}
	req, err = http.NewRequest(http.MethodPut, uploadResp.UploadURL, bytes.NewBuffer(data))
	if err != nil {
		log.Fatal(err)
	}
	//req.Header.Set("User-Agent", "curl/7.71.1")
	//req.Header.Set("Content-Type", "application/json; charset=utf-8")
	//req.Header.Set("x-amz-acl", "public-read")
	//req.Header.Set("Host", ".s3.amazonaws.com")
	//req.Header.Set("Accept", "*/*")

	//fmt.Printf("%#v", req.Header)

	client = &http.Client{}
	res, err = client.Do(req)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("%#v\n\n", req.Header)

	if res.StatusCode != 200 {
		log.Printf("Error: %d", res.StatusCode)
		r, _ := ioutil.ReadAll(res.Body)
		fmt.Printf("%s", r)
	} else {
		log.Printf("INFO: OK.")
	}
	defer res.Body.Close()

}
