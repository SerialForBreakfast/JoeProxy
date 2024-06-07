
# Entitlements Documentation

## com.apple.security.app-sandbox
Enables sandboxing to restrict app access to system resources.

## com.apple.security.files.user-selected.read-only
Allows read-only access to user-selected files.

## com.apple.security.network.server
Allows the app to act as a network server.

## com.apple.security.network.client
Allows the app to connect to network services.

## com.apple.security.files.user-selected.read-write
Allows read and write access to user-selected files.

## com.apple.security.files.downloads.read-write
Allows read and write access to files in the Downloads folder.

## com.apple.security.files.bookmarks.app-scope
Allows the app to access file bookmarks within the app’s scope.

## com.apple.security.temporary-exception.files.home-relative-path.read-write
Temporary exception for read-write access to OpenSSL binaries located at:
- `/usr/local/bin/openssl`
- `/usr/bin/openssl`
- `/opt/homebrew/bin/openssl`
- `/opt/local/bin/openssl`

## com.apple.security.temporary-exception.mach-lookup.global-name
Temporary exception for interacting with system services:
- `com.apple.coreservices.launchservicesd`
- `com.apple.coreservices.sharedfilelistd`
