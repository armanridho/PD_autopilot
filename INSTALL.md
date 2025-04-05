# 🛠️ INSTALL.md

## ✅ Prerequisites

Make sure you have **Go (Golang)** installed in your system.  
This script uses `go install` to fetch tools from official ProjectDiscovery & other repos.

### 🔍 Check Go installation

```bash
go version
```

If it returns something like `go version go1.20.5 linux/amd64`, you're good to go.

---

## 🚀 Installation Steps

1. Clone this repository (if you haven't):
```bash
git clone https://github.com/armanridho/PD_autopilot.git
cd PD_autopilot
```

2. Run the installer:
```bash
go run install_tools.go
```

This will automatically download and install all required tools using `go install`.

---

## 📁 Where are the tools installed?

By default, Go will install binaries to:

- `$GOBIN` (if it's set), or
- `$GOPATH/bin`, or
- fallback to `/usr/local/bin`

🧠 To check where they go:
```bash
go env GOBIN
```

🔧 Make sure that directory is in your `$PATH`. Example:
```bash
export PATH=$PATH:$(go env GOBIN)
```

You can also move tools manually to `/usr/local/bin/` if needed.

---

## 🧪 Tools Installed

- [`subfinder`](https://github.com/projectdiscovery/subfinder)
- [`httpx`](https://github.com/projectdiscovery/httpx)
- [`nuclei`](https://github.com/projectdiscovery/nuclei)
- [`katana`](https://github.com/projectdiscovery/katana)
- [`notify`](https://github.com/projectdiscovery/notify) *(optional)*

---

## 💬 Having Issues?

- ❌ **Command not found?**  
  → Make sure your `$PATH` includes where Go installs binaries (`$GOBIN` or `$GOPATH/bin`)

- 🔒 **Permission denied?**  
  → Try `sudo go install` or move binaries to a path with write access.

- 🪓 **Still stuck?**  
  → [Open an issue](https://github.com/armanridho/PD_autopilot/issues) – we got you covered!

---

## 🤝 Contribute

Feel free to update this script to support other OS, tools, or package managers (like Brew, APT, etc).  
Pull requests welcome!
