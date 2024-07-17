package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"regexp"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run log_analyzer.go <filename>")
		os.Exit(1)
	}

	logFile := os.Args[1]
	file, err := os.Open(logFile)
	if err != nil {
		log.Fatalf("Failed to open file: %v", err)
		os.Exit(1)
	}
	defer file.Close()

	// define regex for patterns to match
	errorPattern := regexp.MustCompile(`(?i)error`)
	warningPattern := regexp.MustCompile(`(?i)warning`)

	// initialize counters
	errorCount := 0
	warningCount := 0

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if errorPattern.MatchString(line) {
			errorCount++
		}
		if warningPattern.MatchString(line) {
			warningCount++
		}
	}

	if err := scanner.Err(); err != nil {
		log.Fatalf("Error scanning file: %v", err)
		os.Exit(1)
	}

	fmt.Printf("Log Analysis Results:\n")
	fmt.Printf("Error Count: %d\n", errorCount)
	fmt.Printf("Warning Count: %d\n", warningCount)

}
