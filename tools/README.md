# Tools & Guides

This directory contains utility scripts, tools and guides relevant for B&R related workflows.

## Scripts

### copilot-wrapper.ps1

This PowerShell script provides a wrapper function for the `copilot` CLI to handle SSL certificate issues by temporarily disabling TLS validation (`NODE_TLS_REJECT_UNAUTHORIZED = '0'`).

This is specifically useful for users getting `unable to fetch` errors when using copilot and Zscaler on the same machine.

**Usage:**

To use this wrapper, you need to dot-source the script in your PowerShell profile or current session.

Add the following line to your PowerShell profile (usually `$PROFILE`):

```powershell
. "path\to\awesome-brdk\tools\copilot-wrapper.ps1"
```

Once loaded, you can use the `copilot` command as usual, and it will automatically handle the environment variable setup.

### install-certs-wsl.ps1

This script automatically exports a root certificate (e.g., Zscaler) from the Windows Certificate Store and installs it into a WSL distribution. This fixes SSL certificate errors (like `self signed certificate in certificate chain`) when running tools like `curl`, `wget`, `git`, or `apt` inside WSL behind a corporate proxy.

It uses `wslpath` to correctly resolve file paths between Windows and Linux, ensuring compatibility regardless of mount points or username differences.

**Usage:**

Run the script from PowerShell:

```powershell
.\install-certs-wsl.ps1
```

**Arguments:**

You **do not** need arguments if:
*   You are using **Zscaler** (the script defaults to searching for `*Zscaler Root CA*`).
*   You want to install it in your **default** WSL distribution.

You **do** need arguments if:
*   **Different Certificate:** If your company uses a different proxy or CA, provide its name:
    ```powershell
    .\install-certs-wsl.ps1 -CertSubject "MyCompany Root CA"
    ```
*   **Specific Distro:** If you want to install it in a specific distro (not your default one):
    ```powershell
    .\install-certs-wsl.ps1 -Distro Ubuntu-20.04
    ```

---

## Docker in WSL (without Docker Desktop)

If you want to use Docker in WSL without Docker Desktop, follow this guide.

### Why?

Commercial use of Docker Desktop in larger enterprises (more than 250 employees or more than $10 million USD in annual revenue) requires a paid subscription. If you don't need the specific features of Docker Desktop (GUI, extensions, etc.), running Docker Engine directly inside WSL is a free and lightweight alternative.

### Installation

Docker runs natively on Linux. We will use the default Ubuntu distribution for WSL, but other distributions work similarly.

#### 1. Install WSL

Open PowerShell as Administrator and run:

```powershell
wsl --install
```

This installs the default distribution (Ubuntu). Restart your computer if prompted.

*   To see installed distros: `wsl --list`
*   To see available online distros: `wsl --list --online`
*   To install a specific distro: `wsl --install -d <DistributionName>`

**Tip:** You can create a profile for Ubuntu in the Windows Terminal app for easy access. Open the Terminal app and go to 'Settings'. Then Profiles -> Add a new profile. In the 'Command line' section add this: `wsl.exe -d Ubuntu`. This will give us a shortcut to the Ubuntu terminal.

#### 2. Install Docker Engine

Open your Ubuntu terminal (WSL) and run the following commands to install Docker.

**Remove conflicting packages:**

```bash
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)
```

**Set up Docker's apt repository:**

```bash
# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
```

**Install Docker packages:**

```bash
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

**Start Docker:**

Make sure that it is running:

```bash
sudo systemctl status docker
```
Otherwise start it:
```bash
sudo systemctl start docker
```

**Configure User Permissions:**

To run Docker without `sudo`, add your user to the `docker` group:

```bash
sudo usermod -aG docker $USER
```

You must close and reopen your terminal (or log out and back in) for this to take effect.

#### 3. Certificates (Zscaler / Corporate Proxy)

If you are behind a corporate proxy like Zscaler, Docker and other tools inside WSL might fail to connect to the internet due to SSL errors.

You can use the provided script `install-certs-wsl.ps1` to fix this.

1.  Open PowerShell.
2.  Navigate to this tools directory.
3.  Run: `.\install-certs-wsl.ps1`

This will trust your corporate root certificate inside WSL.

#### 4. VS Code Integration

1.  Install the **WSL** extension in VS Code.
2.  Install the **Docker** extension in VS Code.
3.  Connect VS Code to WSL (Click the remote indicator in the bottom left -> "Connect to WSL").
4.  The Docker extension should now see the Docker engine running inside WSL.
