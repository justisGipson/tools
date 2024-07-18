package main

import (
	"crypto/tls"
	"fmt"
	"os"
	"time"
)

const (
	expirationThreshold = 30 // Number of days before expiration to trigger a notification
)

func main() {
	if len(os.Args) < 2 ||
		os.Args[1] == "help" ||
		os.Args[1] == "--help" ||
		os.Args[1] == "-h" ||
		os.Args[1] == "" {
		fmt.Println("Usage: go run ssl_expiration_checker.go <hostname>")
		os.Exit(1)
	}

	hostname := os.Args[1]
	err := checkSSLExpiration(hostname)
	if err != nil {
		fmt.Printf("Error checking SSL/TLS certificate expiration: %v\n", err)
		os.Exit(1)
	}
}

func checkSSLExpiration(hostname string) error {
	conn, err := tls.Dial("tcp", hostname+":443", nil)
	if err != nil {
		return err
	}
	defer conn.Close()

	cert := conn.ConnectionState().PeerCertificates[0]
	expirationDate := cert.NotAfter
	daysUntilExpiration := int(time.Until(expirationDate).Hours() / 24)

	fmt.Printf("SSL/TLS Certificate Information for %s:\n", hostname)
	fmt.Printf("Issuer: %s\n", cert.Issuer.CommonName)
	fmt.Printf("Subject: %s\n", cert.Subject.CommonName)
	fmt.Printf("Expiration Date: %s\n", expirationDate.Format("2006-01-02"))
	fmt.Printf("Days Until Expiration: %d\n", daysUntilExpiration)

	if daysUntilExpiration <= expirationThreshold {
		fmt.Printf("Warning: SSL/TLS certificate is expiring in %d days\n", daysUntilExpiration)
	}

	return nil
}
