package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
)

func main() {
	// Clean up package caches and logs
	fmt.Println("Cleaning up package caches and logs...")
	runCommand("sudo", "apt-get", "clean")
	runCommand("sudo", "apt-get", "autoclean")
	runCommand("sudo", "journalctl", "--vacuum-size=50M")

	// Remove unused packages
	fmt.Println("Removing unused packages...")
	runCommand("sudo", "apt-get", "autoremove", "--purge", "-y")

	// Clean up Docker
	fmt.Println("Cleaning up Docker...")
	runCommand("sudo", "docker", "system", "prune", "-a", "-f")

	// Remove old kernel images
	fmt.Println("Removing old kernel images...")
	removeOldKernelImages()

	// Update the system
	fmt.Println("Updating the system...")
	runCommand("sudo", "apt-get", "update")
	runCommand("sudo", "apt-get", "upgrade", "-y")

	// Clean up Yarn/NPM caches
	cleanupYarnNPMCaches()

	// Print the difference in disk usage
	fmt.Println("Checking disk usage...")
	runCommand("df", "-h", "/")
}

func runCommand(name string, args ...string) {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		fmt.Printf("Error running command: %s %v\n", name, args)
		os.Exit(1)
	}
}

func removeOldKernelImages() {
	out, err := exec.Command("dpkg", "-l", "linux-image-*").Output()
	if err != nil {
		fmt.Printf("Error running dpkg command: %v\n", err)
		os.Exit(1)
	}

	currentKernel := strings.TrimSpace(strings.Split(string(out), "\n")[0])
	currentKernelName := strings.Fields(currentKernel)[2]

	var packageNames []string
	for _, line := range strings.Split(string(out), "\n") {
		if strings.HasPrefix(line, "ii") && !strings.Contains(line, currentKernelName) {
			packageName := strings.Fields(line)[1]
			packageNames = append(packageNames, packageName)
		}
	}

	if len(packageNames) > 0 {
		args := append([]string{"apt-get", "purge", "-y"}, packageNames...)
		runCommand("sudo", args...)
	}
}

func cleanupYarnNPMCaches() {
	if _, err := exec.LookPath("yarn"); err == nil {
		fmt.Println("Cleaning up Yarn cache...")
		runCommand("yarn", "cache", "clean")
	}

	if _, err := exec.LookPath("npm"); err == nil {
		fmt.Println("Cleaning up NPM cache...")
		runCommand("npm", "cache", "clean", "--force")
	}
}
