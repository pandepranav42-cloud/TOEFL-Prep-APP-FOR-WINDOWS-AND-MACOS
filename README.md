# TOEFL Vocabulary Widget 📚

A lightweight desktop vocabulary widget designed to help users improve their **TOEFL vocabulary** through quick and repeated exposure to English words.

This repository contains **two versions of the application**:

- 🍎 **macOS Version** — built with Swift and Xcode
- 🪟 **Windows Version** — built with HTML, CSS, JavaScript and Electron

---

## ✨ Features

- 📚 TOEFL vocabulary words
- 💡 Word meanings and definitions
- 🔄 Automatically changes vocabulary
- 🖥️ Desktop widget-style interface
- 🎨 Clean and simple UI
- ⚡ Lightweight and fast
- 💻 Separate implementations for macOS and Windows

---

# 🍎 macOS Version

### Technologies

- Swift
- SwiftUI
- Xcode
- macOS

### Description

The macOS version is a native desktop application developed specifically for macOS using **Swift and SwiftUI**.

It provides a lightweight widget-style experience that can run directly on a Mac.

### Project Location

```text
macOS/
```

### Development

Open the Xcode project located inside the `macOS` folder:

```text
TOEFLWidget.xcodeproj
```

Then build and run the application using Xcode.

### Distribution

The macOS application can be packaged and distributed as:

```text
.dmg
```

---

# 🪟 Windows Version

### Technologies

- HTML
- CSS
- JavaScript
- Electron
- Node.js

### Description

The Windows version uses a web-based interface built with **HTML, CSS and JavaScript**, packaged as a desktop application using **Electron**.

### Project Location

```text
Windows/
```

### Installation

Navigate to the Windows directory:

```bash
cd Windows
```

Install the required dependencies:

```bash
npm install
```

Run the application:

```bash
npm start
```

### Distribution

The Windows application can be packaged as a Windows installer:

```text
.exe
```

---

# 🔄 Platform Comparison

| Feature | macOS | Windows |
|---|---|---|
| Platform | macOS | Windows |
| Language | Swift | JavaScript |
| UI | SwiftUI | HTML / CSS |
| Framework | SwiftUI | Electron |
| Development Tool | Xcode | Node.js / Electron |
| Application | Native macOS | Electron Desktop App |
| Installer | `.dmg` | `.exe` |

---

# 🏗️ Project Structure

```text
TOEFL-Vocabulary-Widget/
│
├── macOS/
│   ├── TOEFLWidget.xcodeproj
│   ├── TOEFLWidget/
│   └── ...
│
├── Windows/
│   ├── main.js
│   ├── index.html
│   ├── style.css
│   ├── renderer.js
│   ├── package.json
│   └── ...
│
├── README.md
└── LICENSE
```

---

# 🎯 Purpose

The purpose of this project is to make **TOEFL vocabulary learning simple and consistent**.

Instead of opening a separate study application every time, users can keep the widget available on their desktop and learn new vocabulary through repeated exposure.

The project focuses on:

- Vocabulary building
- TOEFL preparation
- Quick revision
- Passive learning
- Simple desktop accessibility

---

# 🛠️ Architecture

## macOS

```text
Swift
  ↓
SwiftUI
  ↓
Xcode
  ↓
Native macOS Application
```

## Windows

```text
HTML + CSS + JavaScript
            ↓
         Electron
            ↓
    Windows Application
```

---

# 🚀 Future Improvements

Planned improvements may include:

- 🔊 Word pronunciation
- 📝 Example sentences
- ⭐ Favorite words
- 📊 Learning progress
- 🔍 Vocabulary search
- 🎯 Difficulty levels
- ⚙️ Custom refresh intervals
- 🌙 Improved themes
- 📚 Larger vocabulary database
- 📱 Mobile version

---

# 📌 Version

**Version:** `1.0.0`

This release contains the first versions of the TOEFL Vocabulary Widget for **macOS and Windows**.

---

# 👨‍💻 Author

**Pranav Pande**

B.Tech Computer Science Engineering

---

# ⭐ Support

If you find this project useful, consider giving the repository a ⭐ on GitHub.

---

## 📄 License

This project is available under the license included in this repository.
