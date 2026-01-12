## Docker in WSL (without Docker Desktop)

If you want to use Docker in WSL without Docker Desktop, follow this guide.

### Why?

Commercial use of Docker Desktop in larger enterprises (more than 250 employees or more than $10 million USD in annual revenue) requires a paid subscription. If you don't need the specific features of Docker Desktop (GUI, extensions, etc.), running Docker Engine directly inside WSL is a free and lightweight alternative.

### Installation

Docker runs natively on Linux. We will use the default Ubuntu distribution for WSL, but other distributions work similarly but might need extra work.

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

You can use the [provided script](./install-certs-wsl.ps1) to fix this.

1.  Open PowerShell.
2.  Navigate to this tools directory.
3.  Run: `.\install-certs-wsl.ps1`

This will trust your corporate root certificate inside WSL.

#### 4. Connect Docker to Windows using Docker CLI

**In WSL add an override service to listen on a tcp port:**
```bash
sudo systemctl edit docker.service
```

**Add this in the override section:**
```bash
# Added after the first two lines of comments
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375
```

**Apply and restart Docker:**
```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```
**Verify Docker is listening on port 2375:**
```bash
# Command needs `net-tools` to be installed in wsl
sudo netstat -tlnp | grep 2375
```
Should show: `tcp6  0  0  :::2375  :::*  LISTEN  <pid>/dockerd`


**Install Docker CLI on Windows:**
```powershell
# In PowerShell (Admin)
winget install Docker.DockerCLI
```
**Edit host file in Windows:**
```powershell
# In PowerShell (Admin)
notepad C:\Windows\System32\drivers\etc\hosts
```
**Ensure these two lines exists and are not commented out:**
```
127.0.0.1       localhost
::1             localhost
```

**Set the DOCKER_HOST Environment variable in Windows:**
``` powershell
# In PowerShell (Admin)
[System.Environment]::SetEnvironmentVariable('DOCKER_HOST', 'tcp://localhost:2375', 'User')
```

**Verify that the default context is pointing to localhost:2375:**
```powershell
# In Windows PowerShell
docker context list
```

**Restart the PC:**

Then start WSL and VSCode

#### 5. VS Code Integration

1.  Install the **Docker** extension in VS Code.
2.  The Docker extension should now see the Docker engine running inside WSL.
