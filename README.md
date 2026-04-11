<div align="center">

<img width="100" height="100" alt="android_icon" src="https://github.com/user-attachments/assets/042fb5b1-8bcd-4f96-b9dd-16fe241930ba" styele="border-radius: 50%" />

<h1>SudoSync</h1>

<img src="https://img.shields.io/github/stars/aniruddha76/sudosync?style=for-the-badge" />
<img src="https://img.shields.io/github/forks/aniruddha76/sudosync?style=for-the-badge" />
<img src="https://img.shields.io/github/downloads/aniruddha76/sudosync/total?style=for-the-badge" />
<img src="https://img.shields.io/github/last-commit/aniruddha76/sudosync?style=for-the-badge" />
<img src="https://img.shields.io/github/license/aniruddha76/sudosync?style=for-the-badge" />
<img src="https://img.shields.io/github/issues/aniruddha76/sudosync?style=for-the-badge" />
<img src="https://img.shields.io/github/issues-pr/aniruddha76/sudosync?style=for-the-badge" />

<br />

<h3><b>Monitor and control your Linux system remotely via phone</b></h3>

A lightweight Flutter app that allows Linux administration with a clean and simple mobile interface.

<a href="#features">Features</a> •
<a href="#installation">Installation</a> •
<a href="#usage">Usage</a> •
<a href="#screenshots">Screenshots</a> •
<a href="#contributing">Contributing</a>

</div>

---

## Overview

SudoSync is a lightweight, modern Flutter application designed to simplify remote Linux system management over SSH. It provides an intuitive interface for monitoring system performance, managing files, and executing essential controls without relying on a terminal for routine tasks.

The app brings together key administrative functions into a unified dashboard, allowing users to view real-time system metrics such as CPU usage, memory consumption, disk utilization, and running processes. It also includes a built-in file explorer with support for uploading and downloading files, making remote file management seamless and efficient.

If you work with Linux systems regularly, you probably run:

```bash
top
df -h
````

multiple times a day.

**SudoSync** eliminates that repetition by bringing system monitoring and control directly to your phone.

---

## Features

### System Monitoring

* CPU usage
* Temperature
* Memory usage
* Load average
* Disk usage

### Disk Monitoring

* Displays `df -h` output
* Shows storage usage across mounted drives

### Process Manager

* View top processes by CPU usage
* Kill processes directly

### File Explorer

* Browse remote directories
* Download files

### Control Panel

* Volume control
* Lock system
* Shutdown
* Restart
* Suspend
* Mute
* Turn display off

### Terminal

* Full SSH terminal access
* Powered by `dartssh2`

### Services

* Display all servieces  
* Search services via name, string or status(Running or Dead)

### Network Monitoring 

* Network traffic chart
* Connectins, latency and other information
* Open ports information.

### Profile

* Output of `hostnamectl`

---

## Tech Stack

| Technology | Purpose              |
| ---------- | -------------------- |
| Flutter    | UI framework         |
| Dart       | Programming language |
| dartssh2   | SSH connection       |
| Linux CLI  | System data          |

---

## Installation

You can simply download APK from <a href="https://github.com/aniruddha76/sudosync/releases/">Release</a> section and Install

OR if you are nerd like me follow below steps. 

1. Clone the repository

```bash
git clone https://github.com/aniruddha76/sudosync.git
cd sudosync
```

2. Install dependencies

```bash
flutter pub get
```

3. Connect your phone

```bash
With Developer mode on
with USB debugging on
```

3.Run the app

```bash
flutter run
```
---

## Requirements

* Linux machine with **SSH enabled** if not please follow below commands
* SSH credentials
* `loginctl` installed

Enable SSH:

```bash
sudo systemctl enable ssh
sudo systemctl start ssh
```

---

## Usage

1. Open the app
2. Enter server IP
3. Enter SSH credentials (Username and Password)
4. Tap **Connect**
5. Start managing your system

---

## Screenshots
<div align="center">
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
<td><img src="https://github.com/user-attachments/assets/21a8cf74-00a6-4523-b5be-3476ef33362b" width="250"/></td>
</tr>

</table>
</div>

---

## Project Structure

```bash
lib/
├── screens/
│   ├── control_panel.dart
│   ├── file_explorer.dart
│   ├── home_page.dart
│   ├── image_viewer.dart
│   ├── login_page.dart
│   ├── network_page.dart
│   ├── profile_page.dart
│   ├── server_list_page.dart
│   ├── services_page.dart
│   ├── system_monitor.dart
│   └── terminal_screen.dart
│
├── service/
│   ├── server_storage.dart
│   └── ssh_service.dart
│
└── main.dart
```
---

## Contributing

Contributions are welcome.

* Open issue
* Fork the repo
* Create a branch
* Make changes
* Open a Pull Request

---

## License

This project is under MIT License

---

## Author

**Aniruddha**
[https://github.com/aniruddha76](https://github.com/aniruddha76)

---

## Support

If you like this project, consider giving it a ⭐
and open issues if you find bugs or have suggestions.
