#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

time1="$( date +"%r" )"

install1 () {
directory=ubuntu-fs
UBUNTU_VERSION='24.04.3'
UBUNTU_CODENAME='noble'

if [ -d "$directory" ];then
    first=1
    printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;227m[WARNING]:\e[0m \x1b[38;5;87m Skipping the download and the extraction\n"
elif [ -z "$(command -v proot)" ];then
    printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;203m[ERROR]:\e[0m \x1b[38;5;87m Please install proot.\n"
    exit 1
elif [ -z "$(command -v wget)" ];then
    printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;203m[ERROR]:\e[0m \x1b[38;5;87m Please install wget.\n"
    exit 1
fi

if [ "$first" != 1 ];then
    if [ -f "ubuntu.tar.gz" ];then
        rm -rf ubuntu.tar.gz
    fi

    printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;83m[INFO]:\e[0m Downloading Ubuntu rootfs...\n"
    ARCHITECTURE=$(dpkg --print-architecture)
    case "$ARCHITECTURE" in
        aarch64|arm64) ARCHITECTURE=arm64;;
        arm|armhf) ARCHITECTURE=armhf;;
        amd64|x86_64) ARCHITECTURE=amd64;;
        *) printf "[${time1}] [ERROR]: Unknown architecture: $ARCHITECTURE\n"; exit 1;;
    esac

    url="https://cdimage.ubuntu.com/ubuntu-base/releases/${UBUNTU_CODENAME}/release/ubuntu-base-${UBUNTU_VERSION}-base-${ARCHITECTURE}.tar.gz"
    echo "[DEBUG] Download URL: $url"

    # quiet (-q) hata diya, taki error dikhe
    if ! wget "$url" -O ubuntu.tar.gz; then
        echo "[ERROR] Download failed. Check your internet or URL."
        exit 1
    fi

    echo "[DEBUG] Download complete:"
    ls -lh ubuntu.tar.gz
    file ubuntu.tar.gz || true

    cur=`pwd`
    mkdir -p $directory
    cd $directory
    printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;83m[INFO]:\e[0m Extracting Ubuntu rootfs...\n"
    proot --link2symlink tar -zxf $cur/ubuntu.tar.gz --exclude='dev' ||:
    printf "[INFO]: Extraction done!\n"

    printf "[INFO]: Fixing resolv.conf...\n"
    printf "nameserver 8.8.8.8\nnameserver 8.8.4.4\n" > etc/resolv.conf

    stubs=('usr/bin/groups')
    for f in ${stubs[@]};do
        echo -e "#!/bin/sh\nexit" > "$f"
    done

    cd $cur
fi

mkdir -p ubuntu-binds
bin=startubuntu.sh
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
printf "\n[INFO]: Installation complete! Run ./startubuntu.sh to launch Ubuntu.\n"
}

if [ "\${1:-}" = "-y" ];then
    install1
else
    printf "[QUESTION]: Do you want to install ubuntu-in-termux? [Y/n] "
    read cmd1
    if [[ "\$cmd1" =~ ^[Yy]$ ]];then
        install1
    else
        echo "[ERROR]: Installation aborted."
    fi
fi
