#!/bin/bash
set -euo pipefail

LAB_NAME="selinux-lab"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== SELinux Lab Setup ==="

if ! command -v podman &>/dev/null; then
    echo "ERROR: podman not found. Install with: sudo zypper install podman"
    exit 1
fi

echo "Building container image..."
podman build -t "$LAB_NAME" "$SCRIPT_DIR"

echo "Creating container '$LAB_NAME'..."
podman rm -f "$LAB_NAME" 2>/dev/null || true
podman create --name "$LAB_NAME" --hostname "$LAB_NAME" -it \
    --security-opt unmask=/sys/fs/selinux \
    --volume /sys/fs/selinux:/sys/fs/selinux \
    --security-opt label=disable \
    "$LAB_NAME"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Enter the lab:    podman start -ai $LAB_NAME"
echo "Attach (if running): podman exec -it $LAB_NAME fish"
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
echo "Inside the container you can inspect labels and run analysis tools,"
echo "but actual policy enforcement won't be active."
