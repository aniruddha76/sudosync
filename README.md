# SudoSync

A lightweight **Flutter application** that allows you to **monitor and control your Linux system remotely via SSH**.

SudoSync was created to eliminate the need to repeatedly open a terminal for small tasks like checking CPU usage, disk usage, memory stats, or managing processes. Instead, everything is available through a **clean and simple mobile interface**.

---

# Overview

If you work with Linux systems regularly, you probably run commands like:

```
top
df -h
free -h
```

many times a day.

SudoSync brings these system insights directly to your phone, allowing you to **monitor system health and manage processes remotely without opening a terminal**.

---

# Features

## Remote System Monitoring

* CPU usage
* Memory usage
* Load average
* System temperature
* Storage

## Disk Monitoring

* Displays output of `df -h`
* Shows total storage and used percentage for all mounted drives

## Process Manager

* View **top processes by CPU usage**
* Kill processes directly from the app

## File Explorer

* Browse remote directories
* Open and download files

## Control Panel

* Adjust system volume
* Lock
* Shutdown
* Restart
* Suspend
* Mute
* Display off

## Terminal

* Connect to your Linux machine securely via SSH
* Built using `dartssh2`

---

# Tech Stack

| Technology      | Purpose                    |
| --------------- | -------------------------- |
| Flutter         | Mobile UI framework        |
| Dart            | Programming language       |
| dartssh2        | SSH connection library     |
| Linux CLI Tools | System monitoring commands |

---

# Installation

## 1 Clone the repository

```
git clone https://github.com/yourusername/sudosync.git
cd sudosync
```

## 2 Install dependencies

```
flutter pub get
```

## 3 Run the application

```
flutter run
```

---

# Requirements

* Linux machine with **SSH enabled**
* SSH username and password
* loginctl installed

Enable SSH if it is not already enabled:

```
sudo systemctl enable ssh
sudo systemctl start ssh
```

---

# Usage

1. Launch the application
2. Enter the **server IP address**
3. Enter your **SSH username and password**
4. Tap **Connect**
5. Monitor and control your system remotely

---

# Screenshots

Coming Soon

---

# Project Structure

```
lib/
 ├── screens/
 │   ├── control_panel.dart
 │   ├── file_explorer.dart
 │   ├─── home_page.dart
 │   ├── image_viewer.dart
 │   ├── login_page.dart
 │   ├── system_monitor.dart
 │   └── terminal_screen.dart
 │
 ├── service/
 │   └── ssh_service.dart
 │
 └── main.dart
```

---

# Contributing

Contributions are welcome.

1. Fork the repository
2. Create a new branch
3. Commit your changes
4. Submit a Pull Request

---

# License

This project is licensed under the **MIT License**.

---

# Author

Built by **Aniruddha**

---

If you want, I can also give you a **much stronger README used by trending GitHub projects** (with **feature tables, architecture diagram, GIF demo, and command list used by SudoSync**) which will make the repo look **10x more professional**.
