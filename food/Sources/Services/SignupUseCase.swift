//
//  SignupUseCase.swift
//  food
//
//  Created by eliu giraldo on 2/12/25.
//
import Foundation
import Combine

public final class SignupUseCase {
    private let auth = AuthService.shared
    private var cancellables = Set<AnyCancellable>()

    public init() {}

    public func signUp(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        username: String
    ) async {
        await MainActor.run {
            auth.signUpWithEmail(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName,
                username: username
            )
        }
        await waitForCompletion()
    }

    private func waitForCompletion() async {
        await withCheckedContinuation { continuation in
            var finished = false

            auth.$isAuthenticated
                .dropFirst()
                .sink { isAuth in
                    if isAuth && !finished {
                        finished = true
                        self.cancellables.removeAll()
                        continuation.resume()
                    }
                }
                .store(in: &cancellables)

            auth.$errorMessage
                .compactMap { $0 }
                .sink { _ in
                    if !finished {
                        finished = true
                        self.cancellables.removeAll()
                        continuation.resume()
                    }
                }
                .store(in: &cancellables)
        }
    }
}
