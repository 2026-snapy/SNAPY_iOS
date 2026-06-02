//
//  OAuthPhoneViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/28/26.
//

import Foundation
import Combine

@MainActor
final class OAuthPhoneViewModel: ObservableObject {
    @Published var codeSent = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    func requestCode(phone: String) async {
        let digits = phone.filter { $0.isNumber }
        isLoading = true
        errorMessage = nil

        do {
            try await ProfileService.shared.requestPhoneCode(digits)
            codeSent = true
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func verifyAndRegister(phone: String, code: String) async -> Bool {
        let digits = phone.filter { $0.isNumber }
        let codeDigits = code.filter { $0.isNumber }
        isLoading = true
        errorMessage = nil

        do {
            try await ProfileService.shared.updatePhone(digits, code: codeDigits)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
}
