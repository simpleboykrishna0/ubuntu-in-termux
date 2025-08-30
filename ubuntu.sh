#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

time1="$( date +"%r" )"

directory=ubuntu-fs
UBUNTU_VERSION='24.04.3'
UBUNTU_CODENAME='noble'

install1 () {
if [ -d "$directory" ];then
    echo "[${time1}] [WARNING]: Ubuntu rootfs already exists, skipping download."
    first=1
fi

if [ -z "$(command -v proot)" ];then
    echo "[${time1}] [ERROR]: Please install proot."
    exit 1
fi

if [ -z "$(command -v wget)" ];then
    echo "[${time1}] [ERROR]: Please install wget."
    exit 1
fi

if [ "${first:-0}" != 1 ];then
    rm -f ubuntu.tar.gz

    ARCHITECTURE=$(dpkg --print-architecture)
    case "$ARCHITECTURE" in
        aarch64|arm64) ARCHITECTURE=arm64;;
        arm|armhf) ARCHITECTURE=armhf;;
        amd64|x86_64) ARCHITECTURE=amd64;;
        *) echo "[ERROR] Unknown architecture: $ARCHITECTURE"; exit 1;;
    esac

    url="https://cdimage.ubuntu.com/ubuntu-base/releases/${UBUNTU_CODENAME}/release/ubuntu-base-${UBUNTU_VERSION}-base-${ARCHITECTURE}.tar.gz"
    echo "[DEBUG] Architecture detected: $ARCHITECTURE"
    echo "[DEBUG] Downloading from: $url"

    if ! wget "$url" -O ubuntu.tar.gz; then
        echo "[ERROR] Download failed."
        exit 1
    fi

    echo "[DEBUG] Download complete, file details:"
    ls -lh ubuntu.tar.gz
    file ubuntu.tar.gz || true

    echo "[DEBUG] Starting extraction..."
    mkdir -p $directory
    cur=$(pwd)
    cd $directory
    proot --link2symlink tar -zxf $cur/ubuntu.tar.gz --exclude='dev' ||:
    echo "[INFO] Extraction done!"

    echo "[INFO] Fixing resolv.conf..."
    echo "nameserver 8.8.8.8" > etc/resolv.conf
    echo "nameserver 8.8.4.4" >> etc/resolv.conf

    echo -e "#!/bin/sh\nexit" > usr/bin/groups

    cd $cur
fi

mkdir -p ubuntu-binds
bin=startubuntu.sh
echo "[INFO] Creating start script..."
cat > $bin <<- EOM
#!/bin/bash
cd \$(dirname \$0)
unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r $directory"
if [ -n "\$(ls -A ubuntu-binds)" ]; then
    for f in ubuntu-binds/* ;do
      . \$f
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
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login"
com="\$@"
if [ -z "\$1" ];then
    exec \$command
else
    \$command -c "\$com"
fi
EOM

termux-fix-shebang $bin
chmod +x $bin

rm -f ubuntu.tar.gz
echo "[INFO] Installation complete! Run ./startubuntu.sh to launch Ubuntu."
}

if [ "\${1:-}" = "-y" ];then
    install1
else
    echo -n "[QUESTION]: Do you want to install ubuntu-in-termux? [Y/n] "
    read cmd1
    if [[ "\$cmd1" =~ ^[Yy]$ ]];then
        install1
    else
        echo "[ERROR]: Installation aborted."
    fi
fi
