# JoeProxy

## Overview

JoeProxy is a macOS application designed to act as an SSL/TLS proxy for inspecting and decrypting network traffic. The application facilitates generating SSL certificates, starting and stopping a proxy server, and displaying decrypted network traffic in a user-friendly interface.

## Features

- Generate and manage SSL certificates
- Start and stop the proxy server
- Real-time decryption and display of network traffic
- Filtering and logging of requests and responses
- User-friendly UI for managing logs and actions

## Prerequisites

- macOS
- Homebrew (for installing OpenSSL)

## Installation

### OpenSSL Installation

1. Install Homebrew (if not already installed):
    ```sh
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ```

2. Install OpenSSL using Homebrew:
    ```sh
    brew install openssl
    ```

3. Ensure the OpenSSL binary is in your PATH:
    ```sh
    echo 'export PATH="/usr/local/opt/openssl/bin:$PATH"' >> ~/.zshrc
    source ~/.zshrc
    ```

### Project Setup

1. Clone the repository:
    ```sh
    git clone https://github.com/yourusername/JoeProxy.git
    cd JoeProxy
    ```

2. Open the project in Xcode:
    ```sh
    open JoeProxy.xcodeproj
    ```

3. Build and run the project in Xcode.

## Usage

### Generating SSL Certificates

1. Open the application.
2. Click on the "Actions" menu.
3. Select "Generate Certificate".

### Starting the Proxy Server

1. Open the application.
2. Click on the "Actions" menu.
3. Select "Start Server".

### Stopping the Proxy Server

1. Open the application.
2. Click on the "Actions" menu.
3. Select "Stop Server".

### Viewing and Filtering Logs

1. Use the text field at the top of the log view to filter logs in real-time.
2. Columns can be moved and resized to customize the view.

## Testing

### Running Unit Tests

Run all unit tests to ensure the application is working correctly:
```sh
swift test