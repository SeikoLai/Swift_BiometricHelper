# BiometricHelper

BiometricHelper is a Swift library that simplifies the implementation of biometric authentication in iOS and macOS applications. It provides a clean, easy-to-use interface for integrating Touch ID, Face ID, and Optic ID into your apps.

## Features

- Easy setup and integration
- Support for Touch ID, Face ID, and Optic ID
- Thread-safe implementation using Swift concurrency
- Detailed error handling and user-friendly error messages
- SwiftUI compatible with `@Published` properties

## Requirements

- iOS 14.0+ / macOS 11.0+
- Swift 5.5+
- Xcode 13.0+

## Installation

### Swift Package Manager

You can install BiometricHelper using the [Swift Package Manager](https://swift.org/package-manager/):

1. In Xcode, select "File" > "Swift Packages" > "Add Package Dependency"
2. Enter the repository URL: `https://github.com/SeikoLai/Swift_BiometricHelper.git`
3. Select the version you want to use

Alternatively, you can add the following line to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/SeikoLai/Swift_BiometricHelper.git", from: "1.0.0")
]
```

## Usage

Here's a basic example of how to use BiometricHelper:

```swift
import SwiftUI
import BiometricHelper

struct ContentView: View {
    @StateObject private var biometricHelper = BiometricHelper()
    
    var body: some View {
        VStack {
            Text("Biometric Type: \(biometricHelper.type.description)")
            Text("Is Available: \(biometricHelper.isAvailable ? "Yes" : "No")")
            
            Button("Authenticate") {
                Task {
                    let success = await biometricHelper.authenticate()
                    if success {
                        print("Authentication successful")
                    } else {
                        print("Authentication failed: \(biometricHelper.errorDescription ?? "Unknown error")")
                    }
                }
            }
            .disabled(!biometricHelper.isAvailable)
        }
    }
}
```

## Advanced Usage

### Customizing the Authentication Reason

You can customize the reason displayed to the user during authentication:

```swift
let biometricHelper = BiometricHelper(localizedReason: "Authenticate to access secure data")
```

### Handling Errors

BiometricHelper provides detailed error information:

```swift
if !success {
    if let error = biometricHelper.error {
        print("Authentication error: \(error.userFriendlyDescription)")
    }
}
```

## Contributing

Contributions to BiometricHelper are welcome! Please feel free to submit a Pull Request.

## License

BiometricHelper is available under the MIT license. See the LICENSE file for more info.
