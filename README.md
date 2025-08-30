# ubuntu-in-termux (by Krishna)

[![DISCORD](https://img.shields.io/badge/Chat-On%20Discord-738BD7.svg?style=for-the-badge)](https://discord.gg/Xaqkdeh)

## What's This?

This is a script that allows you to install **Ubuntu 24.04.3 LTS** in
your Termux application without a rooted device.

## Updates

**• Updated to Ubuntu 24.04.3 (Noble Numbat)**\
**• Improved installer script with logging, error handling & stability**

## Important Notes

-   If you have to use Ubuntu in Termux with a **x86/i\*86
    architecture** or prefer **Ubuntu 19.10**, you can use this branch:\
    👉 https://github.com/MFDGaming/ubuntu-in-termux/tree/ubuntu19.10

-   If you get an error message that says **"Fatal Kernel too old"**,
    you have to **uncomment** the line that reads:

    ``` bash
    command+=" -k 4.14.81"
    ```

    (remove the `#` at the beginning) inside the `startubuntu.sh` file.

------------------------------------------------------------------------

## 🔧 Installation Steps

1.  **Update Termux packages**

    ``` bash
    apt-get update && apt-get upgrade -y
    ```

2.  **Install dependencies**

    ``` bash
    apt-get install wget proot git -y
    ```

3.  **Go to home directory**

    ``` bash
    cd ~
    ```

4.  **Clone the repository**

    ``` bash
    git clone https://github.com/simpleboykrishna0/ubuntu-in-termux.git
    ```

5.  **Go to the script folder**

    ``` bash
    cd ubuntu-in-termux
    ```

6.  **Give execution permission**

    ``` bash
    chmod +x ubuntu.sh
    ```

7.  **Run the installer**

    ``` bash
    ./ubuntu.sh -y
    ```

8.  **Start Ubuntu**

    ``` bash
    ./startubuntu.sh
    ```

------------------------------------------------------------------------

## 🎉 Done!

You now have **Ubuntu 24.04.3 LTS** running inside Termux on your
Android device 🚀\
Maintained by **Krishna (simpleboykrishna0)**
