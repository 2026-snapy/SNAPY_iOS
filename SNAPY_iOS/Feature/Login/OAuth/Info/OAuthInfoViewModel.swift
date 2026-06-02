//
//  OAuthInfoViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/28/26.
//

import Foundation
import Combine

@MainActor
final class OAuthInfoViewModel: ObservableObject {
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var handleValidation: String?

    func saveAndNext(handle: String, username: String) async -> Bool {
        isSaving = true
        errorMessage = nil

        do {
            // 핸들 중복 확인
            let available = try await ProfileService.shared.checkHandle(handle)
            if !available {
                errorMessage = "이미 사용 중인 사용자 ID입니다."
                isSaving = false
                return false
            }

            // 핸들 + 이름 저장
            try await ProfileService.shared.updateHandle(handle)
            try await ProfileService.shared.updateUsername(username)

            isSaving = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
            return false
        }
    }

    func validateHandle(_ value: String) {
        if value.isEmpty {
            handleValidation = nil
            return
        }
        if value.count < 5 {
            handleValidation = "5자 이상 입력해주세요"
            return
        }
        if value.count > 24 {
            handleValidation = "24자 이하로 입력해주세요"
            return
        }
        if value.contains(" ") {
            handleValidation = "공백은 사용할 수 없습니다"
            return
        }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_."))
        if !value.unicodeScalars.allSatisfy({ allowed.contains($0) }) {
            handleValidation = "영문, 숫자, 밑줄(_), 마침표(.)만 사용 가능합니다"
            return
        }
        handleValidation = nil
    }
}
