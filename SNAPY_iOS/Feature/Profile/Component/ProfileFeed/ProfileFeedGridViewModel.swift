//
//  ProfileFeedGridViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/28/26.
//

import Foundation
import Combine

@MainActor
final class ProfileFeedGridViewModel: ObservableObject {

    func toggleLike(albumId: Int) async -> (liked: Bool, likeCount: Int)? {
        do {
            let result = try await AlbumService.shared.toggleLike(albumId: albumId)
            return (result.liked, result.likeCount)
        } catch {
            print("[FeedDetailCard] 좋아요 실패: \(error)")
            return nil
        }
    }
}
