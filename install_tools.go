package main

import (
	"fmt"
	"os"
	"os/exec"
)

// installTool installs a tool using go install
func installTool(tool string, repo string) {
	fmt.Printf("[*] Installing %s...\n", tool)
	cmd := exec.Command("go", "install", repo)
	cmd.Env = append(os.Environ(), "GOBIN="+os.Getenv("HOME")+"/go/bin")
	err := cmd.Run()
	if err != nil {
		fmt.Printf("[!] Failed to install %s: %v\n", tool, err)
	} else {
		fmt.Printf("[✔] %s installed successfully!\n", tool)
	}
}

func main() {
	tools := map[string]string{
		"Subfinder": "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest",
		"Httpx":     "github.com/projectdiscovery/httpx/cmd/httpx@latest",
		"Naabu":     "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest",
		"Nuclei":    "github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest",
		"Katana":    "github.com/projectdiscovery/katana/cmd/katana@latest",
		"Notify":    "github.com/projectdiscovery/notify/cmd/notify@latest",
	}

	fmt.Println("Starting tool installation...")

	// Iterate over tools and install each one
	for tool, repo := range tools {
		installTool(tool, repo)
	}

	fmt.Println("All tools installed successfully!")
}
