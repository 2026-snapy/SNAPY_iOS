//
//  RegisterProfileImageViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/28/26.
//

import UIKit
import Combine

@MainActor
final class RegisterProfileImageViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    func upload(profileImage: UIImage?, bannerImage: UIImage?) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            if let image = profileImage {
                _ = try await ProfileService.shared.updateProfileImage(image)
            }
            if let image = bannerImage {
                _ = try await ProfileService.shared.updateBackgroundImage(image)
            }
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
}
