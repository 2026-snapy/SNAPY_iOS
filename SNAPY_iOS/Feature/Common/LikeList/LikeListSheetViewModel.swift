//
//  LikeListSheetViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/28/26.
//

import Foundation
import Combine

@MainActor
final class LikeListSheetViewModel: ObservableObject {
    @Published var likeUsers: [AlbumLikeUserData] = []
    @Published var isLoading = true
    @Published var myFriends: Set<String> = []
    @Published var requestedHandles: Set<String> = []

    func loadData(albumId: Int) async {
        let myHandle = UserDefaults.standard.string(forKey: "myHandle") ?? ""

        async let likesTask: [AlbumLikeUserData] = {
            (try? await AlbumService.shared.fetchLikes(albumId: albumId)) ?? []
        }()
        async let friendsTask: [FriendData] = {
            (try? await FriendService.shared.getFriends(handle: myHandle)) ?? []
        }()

        let likes = await likesTask
        let friends = await friendsTask

        likeUsers = likes.sorted { ($0.likedAt ?? "") > ($1.likedAt ?? "") }
        myFriends = Set(friends.map { $0.handle })

        // 친구가 아닌 유저들의 요청 상태 확인
        for user in likeUsers {
            if user.handle != myHandle && !myFriends.contains(user.handle) {
                if let status = try? await FriendService.shared.getRequestStatus(handle: user.handle),
                   status == .pending {
                    requestedHandles.insert(user.handle)
                }
            }
        }

        isLoading = false
    }

    func sendFriendRequest(handle: String) {
        Task {
            do {
                try await FriendService.shared.sendRequest(handle: handle)
                requestedHandles.insert(handle)
            } catch {
                requestedHandles.insert(handle)
            }
        }
    }
}
