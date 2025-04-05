package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

// getGoBin returns the effective GOBIN path
func getGoBin() string {
	// Prioritaskan GOBIN kalau udah diset user
	if gobin := os.Getenv("GOBIN"); gobin != "" {
		return gobin
	}
	// Fallback ke ~/go/bin
	home, err := os.UserHomeDir()
	if err != nil {
		fmt.Println("[!] Failed to detect home directory.")
		os.Exit(1)
	}
	return filepath.Join(home, "go", "bin")
}

// installTool installs a tool using `go install`
func installTool(name, repo, gobin string) {
	fmt.Printf("[*] Installing %s...\n", name)

	cmd := exec.Command("go", "install", repo)
	cmd.Env = append(os.Environ(), "GOBIN="+gobin)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		fmt.Printf("[!] Failed to install %s: %v\n", name, err)
	} else {
		fmt.Printf("[✔] %s installed successfully at %s!\n", name, filepath.Join(gobin, name))
	}
}

func main() {
	tools := map[string]string{
		"subfinder": "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest",
		"httpx":     "github.com/projectdiscovery/httpx/cmd/httpx@latest",
		"naabu":     "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest",
		"nuclei":    "github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest",
		"katana":    "github.com/projectdiscovery/katana/cmd/katana@latest",
		"notify":    "github.com/projectdiscovery/notify/cmd/notify@latest",
	}

	fmt.Println("🚀 Starting tool installation...\n")

	gobin := getGoBin()

	// Tambahkan ke PATH kalau belum
	fmt.Printf("[ℹ] Binaries will be installed to: %s\n", gobin)
	fmt.Println("[💡] Make sure this path is in your $PATH variable to use the tools globally.\n")

	for name, repo := range tools {
		installTool(name, repo, gobin)
	}

	fmt.Println("\n✅ All tools installed. Happy hacking! 🎯")
}
