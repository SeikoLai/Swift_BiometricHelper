// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation
import LocalAuthentication

/// Actor to manage thread-safe access to LAContext
private actor BiometricContextManager {
    
    func canEvaluatePolicy(_ policy: LAPolicy) throws -> Bool {
        let context: LAContext = .init()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(policy, error: &error)
        if let error = error {
            throw error
        }
        return canEvaluate
    }
    
    func biometryType() -> LABiometryType {
        let context: LAContext = .init()
        return context.biometryType
    }
    
    func evaluatePolicy(_ policy: LAPolicy, localizedReason: String) async throws -> Bool {
        let context: LAContext = .init()
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(policy, localizedReason: localizedReason) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
    
    func setLocalizedFallbackTitle(_ title: String?) {
        let context: LAContext = .init()
        context.localizedFallbackTitle = title
    }
}

/// BiometricHelper class to manage biometric authentication
@MainActor
open class BiometricHelper: ObservableObject {
    /// Type of biometric authentication available on the device
    @Published public var type: LABiometryType = .none
    
    /// Flag to indicate if biometric authentication is available
    @Published public var isAvailable: Bool = false
    
    /// Flag to indicate if an error has occurred
    @Published public var hasError: Bool = false
    
    /// The error that occurred during authentication, if any
    @Published public  var error: LAError?
    
    /// Computed property to get the localized description of the error
    public var errorDescription: String? {
        error?.userFriendlyDescription
    }
    
    /// Reason displayed to the user when requesting authentication
    public private(set) var localizedReason: String
    
    /// BiometricContextManager instance to handle biometric operations
    private let contextManager: BiometricContextManager
    
    /// Initializer for BiometricHelper
    /// - Parameter localizedReason: The reason for authentication to be displayed to the user
    public required init(localizedReason: String = "Use biometrics to authenticate") {
        self.contextManager = BiometricContextManager()
        self.localizedReason = localizedReason
        Task {
            await self.updateBiometricType()
        }
    }
    
    /// Function to update the localized reason for authentication
    /// - Parameter localizedReason: The new reason for authentication
    public func changeLocalizedReason(_ localizedReason: String) {
        self.localizedReason = localizedReason
    }
    
    /// Update the biometric type and availability
    private func updateBiometricType() async {
        do {
            isAvailable = try await contextManager.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)
            if isAvailable {
                type = await contextManager.biometryType()
            } else {
                type = .none
            }
        } catch {
            isAvailable = false
            type = .none
            debugPrint("Biometric unavailable: \(error.localizedDescription)")
        }
    }
    
    /// Perform biometric authentication
    /// - Returns: A boolean indicating whether authentication was successful
    public func authenticate() async -> Bool {
        do {
            // Hide "Enter Password" button
            await contextManager.setLocalizedFallbackTitle("")
            
            // Check if biometric authentication is available
            guard isAvailable else {
                self.error = LAError(.biometryNotAvailable)
                self.hasError = true
                return false
            }
            
            // Evaluate biometric policy and return the result
            return try await contextManager.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                                           localizedReason: self.localizedReason)
            
        } catch let authError as LAError {
            self.error = authError
            self.hasError = true
            debugPrint("Authentication failure: \(authError.userFriendlyDescription)")
            return false
        } catch {
            debugPrint("Unexpected error: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Reset the error state
    public func resetError() {
        self.error = nil
        self.hasError = false
    }
}

// MARK: - Helper Extensions

extension LABiometryType {
    /// A user-friendly description of the biometry type
    public var description: String {
        switch self {
        case .none:
            return "None"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        case .opticID:
            return "Optic ID"
        @unknown default:
            return "Unknown"
        }
    }
}

extension LAError {
    /// A user-friendly description of the LAError
    public var userFriendlyDescription: String {
        switch self.code {
        case .authenticationFailed:
            return "Biometric authentication failed. Please try again."
        case .userCancel:
            return "Authentication was cancelled by the user."
        case .userFallback:
            return "User chose to use the fallback authentication method."
        case .biometryNotAvailable:
            return "Biometric authentication is not available on this device."
        case .biometryNotEnrolled:
            return "Biometric authentication is not set up on this device."
        case .biometryLockout:
            return "Biometric authentication is locked out due to too many failed attempts."
        default:
            return self.localizedDescription
        }
    }
}
