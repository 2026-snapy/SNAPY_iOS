//
//  BlockedUsersViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/28/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class BlockedUsersViewModel: ObservableObject {
    @Published var blockedUsers: [BlockedUserData] = []
    @Published var isLoading = true

    func loadBlockedUsers() async {
        isLoading = true
        do {
            blockedUsers = try await BlockService.shared.getBlockedUsers()
        } catch {
            print("[BlockedUsersView] 로드 실패: \(error)")
        }
        isLoading = false
    }

    func unblock(user: BlockedUserData) async {
        do {
            try await BlockService.shared.unblockUser(handle: user.handle)
            withAnimation(.easeInOut(duration: 0.3)) {
                blockedUsers.removeAll { $0.id == user.id }
            }
        } catch {
            print("[BlockedUsersView] 차단 해제 실패: \(error)")
        }
    }
}
