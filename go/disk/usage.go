package main

import (
	"fmt"
	"os"
	"syscall"
)

const (
	thresholdPercentage = 80
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run usage.go <path>")
		os.Exit(1)
	}

	directory := os.Args[1]
	err := checkDiskUsage(directory)
	if err != nil {
		fmt.Printf("Error checking disk usage: %v\n", err)
		os.Exit(1)
	}
}

func checkDiskUsage(directory string) error {
	var stat syscall.Statfs_t
	err := syscall.Statfs(directory, &stat)
	if err != nil {
		return err
	}

	total := stat.Blocks * uint64(stat.Bsize)
	free := stat.Bfree * uint64(stat.Bsize)
	used := total - free

	usedPercentage := (float64(used) / float64(total)) * 100

	fmt.Printf("Disk Usage for %s:\n", directory)
	fmt.Printf("Total: %d bytes\n", total)
	fmt.Printf("Used: %d bytes\n", used)
	fmt.Printf("Free: %d bytes\n", free)
	fmt.Printf("Used Percentage: %.2f%%\n", usedPercentage)

	if usedPercentage > thresholdPercentage {
		fmt.Printf("Warning: disk usage is above threshold of %d%%\n", thresholdPercentage)
	}

	return nil
}
