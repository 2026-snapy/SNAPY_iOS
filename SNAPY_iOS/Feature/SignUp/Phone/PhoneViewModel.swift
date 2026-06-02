//
//  PhoneViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/19/26.
//

import Foundation
import Combine

@MainActor
final class PhoneViewModel: ObservableObject {
    @Published var codeSent = false
    @Published var isSending = false
    @Published var sendError: String?

    func requestCode(digits: String) async {
        guard digits.count == 11 else { return }
        isSending = true
        sendError = nil

        do {
            try await ProfileService.shared.requestPhoneCode(digits)
            codeSent = true
            isSending = false
        } catch {
            sendError = error.localizedDescription
            isSending = false
        }
    }
}
