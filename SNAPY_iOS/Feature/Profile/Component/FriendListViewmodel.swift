//
//  FriendListViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/28/26.
//

import Foundation
import Combine

@MainActor
final class FriendListViewModel: ObservableObject {
    @Published var friends: [FriendData] = []
    @Published var isLoading = true

    func loadFriends(handle: String) async {
        isLoading = true
        do {
            friends = try await FriendService.shared.getFriends(handle: handle)
        } catch {
            print("[FriendList] 로드 실패: \(error)")
        }
        isLoading = false
    }
}
