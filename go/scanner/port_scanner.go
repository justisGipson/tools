package main

import (
	"bufio"
	"encoding/csv"
	"fmt"
	"net"
	"os"
	"strconv"
	"strings"
	"sync"

	"github.com/Ullaakut/nmap"
)

func scanHost(host string, portRange string) [][]string {
	scanner, err := nmap.NewScanner(
		nmap.WithTargets(host),
		nmap.WithPorts(portRange),
		nmap.WithServiceInfo(),
		nmap.WithMinRate(1000),
	)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating scanner on host %s: %v\n", host, err)
		return nil
	}

	result, _, err := scanner.Run()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error scanning host %s: %v\n", host, err)
		return nil
	}

	var results [][]string

	if len(result.Hosts) > 0 && result.Hosts[0].Status.State == "up" {
		fmt.Printf("Host %s is up\n", host)
		for _, port := range result.Hosts[0].Ports {
			results = append(results, []string{
				host,
				strconv.FormatUint(uint64(port.ID), 10),
				port.Protocol,
				port.Service.Name,
				port.State.String(),
				port.Service.Product,
				port.Service.ExtraInfo,
				port.State.Reason,
				port.Service.Version,
				"",
			})
		}
	}

	return results
}

func scanNetwork(target string, portRange string, maxWorkers int) [][]string {
	ip, ipnet, err := net.ParseCIDR(target)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Invalid target: %s\n", target)
		return nil
	}

	var results [][]string
	var mutex sync.Mutex
	var wg sync.WaitGroup

	jobCh := make(chan string, maxWorkers)

	for i := 0; i < maxWorkers; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for host := range jobCh {
				result := scanHost(host, portRange)
				mutex.Lock()
				results = append(results, result...)
				mutex.Unlock()
			}
		}()
	}

	for ip := ip.Mask(ipnet.Mask); ipnet.Contains(ip); incIP(ip) {
		if !ip.Equal(ipnet.IP) && !ip.Equal(broadcastAddr(ipnet)) {
			jobCh <- ip.String()
		}
	}
	close(jobCh)
	wg.Wait()

	return results
}

func writeToFile(results [][]string, outputFile string) error {
	file, err := os.Create(outputFile)
	if err != nil {
		return err
	}
	defer file.Close()

	writer := csv.NewWriter(bufio.NewWriter(file))
	defer writer.Flush()

	err = writer.Write([]string{
		"host",
		"port",
		"protocol",
		"service_name",
		"state",
		"product",
		"extrainfo",
		"reason",
		"version",
		"conf",
	})
	if err != nil {
		return err
	}

	return writer.WriteAll(results)
}

func main() {
	var target, portRange string
	fmt.Print("Enter the target IP address and subnet (e.g., 192.168.1.0/24): ")
	fmt.Scanln(&target)
	fmt.Print("Enter the port range to scan (e.g., 1-1000): ")
	fmt.Scanln(&portRange)

	outputFile := strings.ReplaceAll(target, "/", "_") + "_port_scan.csv"

	results := scanNetwork(target, portRange, 50)
	if err := writeToFile(results, outputFile); err != nil {
		fmt.Fprintf(os.Stderr, "Error writing to file: %v\n", err)
		return
	}
	fmt.Printf("Scan completed, %d open ports found\n", len(results))
	fmt.Printf("Scan results saved to %s\n", outputFile)
}

func incIP(ip net.IP) {
	for j := len(ip) - 1; j >= 0; j-- {
		ip[j]++
		if ip[j] > 0 {
			break
		}
	}
}

func broadcastAddr(n *net.IPNet) net.IP {
	bc := make(net.IP, len(n.IP))
	copy(bc, n.IP)
	offset := len(bc) - len(n.Mask)
	for i := range bc {
		if i >= offset {
			bc[i] |= ^n.Mask[i-offset]
		}
	}
	return bc
}
