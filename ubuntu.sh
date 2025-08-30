#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

#######################################
# Logging helpers
#######################################
log_info()    { echo -e "\e[38;5;39m[INFO]\e[0m    $*"; }
log_warn()    { echo -e "\e[38;5;214m[WARN]\e[0m    $*"; }
log_error()   { echo -e "\e[38;5;196m[ERROR]\e[0m   $*" >&2; }
log_debug()   { echo -e "\e[38;5;244m[DEBUG]\e[0m   $*"; }

#######################################
# Config
#######################################
UBUNTU_VERSION="24.04.3"
UBUNTU_CODENAME="noble"
ROOTFS_DIR="ubuntu-fs"
BIND_DIR="ubuntu-binds"
START_SCRIPT="startubuntu.sh"
TARBALL="ubuntu.tar.gz"

#######################################
# Check required commands
#######################################
check_dependencies() {
    for cmd in proot wget tar; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "Missing required command: $cmd"
            exit 1
        fi
    done
}

#######################################
# Detect architecture
#######################################
detect_arch() {
    local arch
    arch=$(dpkg --print-architecture)
    case "$arch" in
        aarch64|arm64) echo "arm64";;
        arm|armhf)     echo "armhf";;
        amd64|x86_64)  echo "amd64";;
        *)
            log_error "Unsupported architecture: $arch"
            exit 1
            ;;
    esac
}

#######################################
# Download rootfs
#######################################
download_rootfs() {
    local arch="$1"
    local url="https://cdimage.ubuntu.com/ubuntu-base/releases/${UBUNTU_CODENAME}/release/ubuntu-base-${UBUNTU_VERSION}-base-${arch}.tar.gz"

    log_info "Downloading Ubuntu $UBUNTU_VERSION rootfs for $arch"
    log_debug "URL: $url"

    rm -f "$TARBALL"
    if ! wget --show-progress -O "$TARBALL" "$url"; then
        log_error "Download failed!"
        exit 1
    fi

    log_debug "Download complete: $(ls -lh "$TARBALL")"
    if ! file "$TARBALL" | grep -q "gzip compressed"; then
        log_error "Downloaded file is not a valid tarball!"
        exit 1
    fi
}

#######################################
# Extract rootfs
#######################################
extract_rootfs() {
    log_info "Extracting rootfs..."
    mkdir -p "$ROOTFS_DIR"
    proot --link2symlink tar -zxf "$TARBALL" -C "$ROOTFS_DIR" --exclude='dev' || true

    # Basic fixes
    echo "nameserver 8.8.8.8" > "$ROOTFS_DIR/etc/resolv.conf"
    echo "nameserver 8.8.4.4" >> "$ROOTFS_DIR/etc/resolv.conf"
    echo -e "#!/bin/sh\nexit" > "$ROOTFS_DIR/usr/bin/groups"

    log_info "Extraction completed!"
}

#######################################
# Create start script
#######################################
create_start_script() {
    log_info "Creating start script: $START_SCRIPT"
    mkdir -p "$BIND_DIR"
    cat > "$START_SCRIPT" <<- 'EOM'
#!/bin/bash
cd "$(dirname "$0")"
unset LD_PRELOAD

command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r ubuntu-fs"

if [ -n "$(ls -A ubuntu-binds 2>/dev/null)" ]; then
    for f in ubuntu-binds/*; do
        . "$f"
    done
fi

command+=" -b /dev"
command+=" -b /proc"
command+=" -b /sys"
command+=" -b ubuntu-fs/tmp:/dev/shm"
command+=" -b /data/data/com.termux"
command+=" -b /:/host-rootfs"
command+=" -b /sdcard"
command+=" -b /storage"
command+=" -b /mnt"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login"

if [ $# -eq 0 ]; then
    exec $command
else
    $command -c "$*"
fi
EOM

    termux-fix-shebang "$START_SCRIPT"
    chmod +x "$START_SCRIPT"
}

#######################################
# Main installer
#######################################
install() {
    check_dependencies

    if [ -d "$ROOTFS_DIR" ]; then
        log_warn "Ubuntu rootfs already exists, skipping download."
    else
        local arch
        arch=$(detect_arch)
        download_rootfs "$arch"
        extract_rootfs
        rm -f "$TARBALL"
    fi

    create_start_script
    log_info "Installation complete! Run: ./startubuntu.sh"
}

#######################################
# Entry point
#######################################
if [ "${1:-}" = "-y" ]; then
    install
else
    read -rp "[QUESTION]: Do you want to install ubuntu-in-termux? [Y/n] " reply
    case "$reply" in
        [Yy]*) install ;;
        *) log_error "Installation aborted." ;;
    esac
fi
