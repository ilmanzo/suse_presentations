#!/bin/bash
set -euo pipefail

LAB_NAME="selinux-lab"
IMAGE="registry.opensuse.org/opensuse/tumbleweed:latest"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== SELinux Lab Setup ==="

if ! command -v distrobox &>/dev/null; then
    echo "ERROR: distrobox not found. Install with: sudo zypper install distrobox"
    exit 1
fi

if ! command -v podman &>/dev/null; then
    echo "ERROR: podman not found. Install with: sudo zypper install podman"
    exit 1
fi

if distrobox list | grep -q "$LAB_NAME"; then
    echo "Container '$LAB_NAME' already exists. Enter with: distrobox enter $LAB_NAME"
    exit 0
fi

echo "Creating distrobox '$LAB_NAME' with $IMAGE..."
distrobox create --name "$LAB_NAME" --image "$IMAGE" --yes

echo "Installing SELinux tools inside the container..."
distrobox enter "$LAB_NAME" -- sudo zypper install -y \
    policycoreutils-python-utils \
    setroubleshoot-server \
    selinux-policy-devel \
    setools-console \
    nginx \
    audit \
    checkpolicy

echo "Copying sample audit log..."
distrobox enter "$LAB_NAME" -- bash -c "mkdir -p /tmp/selinux-lab"
cp "$SCRIPT_DIR/sample-audit.log" "$HOME/.local/share/containers/storage/" 2>/dev/null || true
distrobox enter "$LAB_NAME" -- bash -c "cp /run/host$SCRIPT_DIR/sample-audit.log /tmp/selinux-lab/ 2>/dev/null || true"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Enter the lab:  distrobox enter $LAB_NAME"
echo ""
echo "Try these commands inside the lab:"
echo "  getenforce"
echo "  ls -Z /etc/nginx/"
echo "  semanage port -l | grep http"
echo "  audit2why < /tmp/selinux-lab/sample-audit.log"
echo "  sealert -a /tmp/selinux-lab/sample-audit.log"
echo ""
echo "Note: SELinux enforcement requires a system with SELinux enabled"
echo "      (Tumbleweed, SLES 16, Leap 16)."
echo "Inside distrobox you can inspect labels and run analysis tools,"
echo "but actual policy enforcement won't be active."
