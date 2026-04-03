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

## 📱 Screenshots

<table>
<tr>
<td><img src="https://github.com/user-attachments/assets/d024a4ce-b922-4c2e-bd7c-b1f9ee963dfb" width="250"/></td>
<td><img src="https://github.com/user-attachments/assets/26fb1c01-49f9-4ad1-9285-176dfff77cb3" width="250"/></td>
<td><img src="https://github.com/user-attachments/assets/b7ac970b-f89b-44ee-8950-6f368efea07a" width="250"/></td>
</tr>

<tr>
<td><img src="https://github.com/user-attachments/assets/486591aa-8ae8-4da6-96cf-72a6b404cf35" width="250"/></td>
<td><img src="https://github.com/user-attachments/assets/66a8155d-b88f-440d-b61d-da2cb5ee8993" width="250"/></td>
<td><img src="https://github.com/user-attachments/assets/20483f35-4107-40e3-937e-ee4377beec53" width="250"/></td>
</tr>

<tr>
<td><img src="https://github.com/user-attachments/assets/c8ded873-409c-493b-b903-c61d10078d84" width="250"/></td>
<td><img src="https://github.com/user-attachments/assets/32c5997c-e5dd-44f2-9a2d-a990ecacb925" width="250"/></td>
<td><img src="https://github.com/user-attachments/assets/ef89d9b3-7e79-4ad6-bc26-530845f354f3" width="250"/></td>
</tr>

<tr>
<td><img src="https://github.com/user-attachments/assets/dc20c668-6c37-4c69-a7dd-0927745cb64d" width="250"/></td>
 <td><img src="https://github.com/user-attachments/assets/21a8cf74-00a6-4523-b5be-3476ef33362b" width="250"></td>
</tr>
</table>


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

