//
//  LoginUseCase.swift
//  food
//
//  Created by eliu giraldo on 2/12/25.
//

import Foundation
import Combine

public final class LoginUseCase {
    private let auth = AuthService.shared
    private var cancellables = Set<AnyCancellable>()

    public init() {}

    public func signIn(identifier: String, password: String) async {
        await MainActor.run {
            auth.signInWithEmailOrUsername(identifier: identifier, password: password)
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
