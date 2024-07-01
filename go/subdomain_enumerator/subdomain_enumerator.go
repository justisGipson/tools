package main

import (
	"bufio"
	"fmt"
	"net"
	"os"
	"sync"
)

func main() {
	if len(os.Args) != 3 {
		fmt.Println("Usage: go run subdomain_enum.go <domain> <wordlist>")
		os.Exit(1)
	}

	domain := os.Args[1]
	wordlistFile := os.Args[2]

	wordlist, err := readWordlist(wordlistFile)
	if err != nil {
		fmt.Printf("Error reading wordlist: %v\n", err)
		os.Exit(1)
	}

	var wg sync.WaitGroup
	subdomainChan := make(chan string, 100)

	for i := 0; i < 50; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for subdomain := range subdomainChan {
				checkSubdomain(subdomain)
			}
		}()
	}

	for _, word := range wordlist {
		subdomain := word + "." + domain
		subdomainChan <- subdomain
	}

	close(subdomainChan)
	wg.Wait()
}

func readWordlist(file string) ([]string, error) {
	f, err := os.Open(file)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	var wordlist []string
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		wordlist = append(wordlist, scanner.Text())
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}

	return wordlist, nil
}

func checkSubdomain(subdomain string) {
	_, err := net.LookupHost(subdomain)
	if err == nil {
		fmt.Printf("Discovered subdomain: %s\n", subdomain)
	}
}
