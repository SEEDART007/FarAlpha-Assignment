# Siddhartha: Simple Backend API (GET /sayHello)

## What this project contains
- A minimal Node.js + Express API that listens on port 80 and exposes:
  - `GET /sayHello` -> responds `{ "message": "Hello User" }`
- A GitHub Actions workflow that deploys the code to a VM via SSH (no secrets in repo).
- A remote deployment script that the workflow runs on the VM to install dependencies and run the service via `systemd`.

## Files
- `src/server.js` — the Express server.
- `package.json` — project metadata and dependencies.
- `.github/workflows/deploy.yml` — GitHub Actions workflow to deploy on pushes to `main`.
- `deploy/remote_deploy.sh` — script executed on the VM to finalize deployment.
- `.gitignore`

## How to use

### 1) Create a private GitHub repo and push this project to `main`.
Make sure the repo is **private** as required.

### 2) Add GitHub Secrets (Repository → Settings → Secrets)
- `VM_HOST` — e.g. `20.55.88.72`
- `VM_USER` — e.g. `azureuser`
- `SSH_PRIVATE_KEY` — the private SSH key matching the VM's `authorized_keys`
- `SSH_PORT` — optional (defaults to `22` if not set)

**Do not** put SSH keys or other secrets in the repository files.

### 3) Ensure the VM has the SSH public key installed
- Put the corresponding public key in `~/.ssh/authorized_keys` for `azureuser`.
- The VM user should be able to run `sudo` non-interactively (Azure VMs usually allow `azureuser` sudo).

### 4) Push to `main`
The workflow triggers on pushes to `main`. It will:
- Package repo as `upload.tar.gz`
- Copy `upload.tar.gz` and `remote_deploy.sh` to the VM `/tmp/`
- Move them into `/opt/siddhartha-sayhello` and run the remote deploy script
- Script installs Node (if missing), runs `npm ci`, creates a systemd service and starts it.

### 5) Verify
Open in browser:
